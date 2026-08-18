function Get-WinUtilIconCacheDirectory {
    <#
        .SYNOPSIS
            Where downloaded app icons are kept between runs
    #>

    $path = Join-Path $sync.winutildir "icons"
    if (-not (Test-Path $path)) {
        $null = New-Item -ItemType Directory -Path $path -Force
    }
    return $path
}

function Get-WinUtilIconCacheFile {
    <#
        .SYNOPSIS
            The cache file a given app link maps to

        .DESCRIPTION
            The link is hashed rather than sanitised, because two different links can reduce to
            the same name once the characters a file name cannot hold are stripped out.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Link
    )

    $sha = [System.Security.Cryptography.SHA1]::Create()
    try {
        $bytes = $sha.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($Link.ToLowerInvariant()))
    } finally {
        $sha.Dispose()
    }
    $name = [System.BitConverter]::ToString($bytes).Replace("-", "").Substring(0, 16)
    return Join-Path (Get-WinUtilIconCacheDirectory) "$name.img"
}

function Get-WinUtilFrozenIcon {
    <#
        .SYNOPSIS
            Decodes an icon file into a bitmap that any thread may use

        .DESCRIPTION
            A frozen Freezable is safe to hand between runspaces, which is what lets the download
            and the decode happen off the interface thread and only the assignment happen on it.
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        $bytes = [System.IO.File]::ReadAllBytes($Path)
        if ($bytes.Length -eq 0) { return $null }

        $stream = New-Object System.IO.MemoryStream(, $bytes)
        $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
        $bitmap.BeginInit()
        $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.StreamSource = $stream
        $bitmap.EndInit()
        $bitmap.Freeze()
        return $bitmap
    } catch {
        return $null
    }
}

function Start-WinUtilIconFetch {
    <#
        .SYNOPSIS
            Downloads the app icons that are not cached yet, away from the interface thread

        .DESCRIPTION
            Assigning a remote address to an Image makes WPF fetch and decode it, and the part
            that lands back on the interface thread does so whenever the network answers. With
            a few hundred entries that arrives as stalls spread over the whole first minute.

            Here the fetch and the decode happen on a worker and only the finished bitmap is
            handed to the control, in batches, at background priority. Nothing is downloaded
            twice, on this run or on any later one.
    #>

    $pending = $sync.PendingIcons
    if ($null -eq $pending -or $pending.Count -eq 0) {
        return
    }

    # One fetch at a time. This is called after every render batch so icons appear while the
    # list is still filling in rather than only once all of it has been drawn; anything that
    # accumulates while a fetch runs is picked up when that fetch ends.
    [System.Threading.Monitor]::Enter($sync.SyncRoot)
    try {
        if ($sync.IconFetchRunning) { return }
        $sync.IconFetchRunning = $true
    } finally {
        [System.Threading.Monitor]::Exit($sync.SyncRoot)
    }

    # Copied out so the worker is not reading a collection the interface thread still appends to
    $work = @($pending.GetEnumerator() | ForEach-Object { [pscustomobject]@{ Key = $_.Key; Link = $_.Value } })
    $sync.PendingIcons = [hashtable]::Synchronized(@{})

    Write-WinUtilLog -Component "Icons" -Message "Fetching $($work.Count) app icon(s) that are not cached yet."

    # The leading comma matters: @(("IconWork", $work)) is a two element array, not a list
    # holding one pair, and the parameter loop would read its characters as a name and a value
    $handle = Invoke-WPFRunspace -ParameterList (, ("IconWork", $work)) -ScriptBlock {
        param($IconWork)

        Add-Type -AssemblyName System.Net.Http
        $client = [System.Net.Http.HttpClient]::new()
        $client.Timeout = [timespan]::FromSeconds(20)

        $fetched = 0
        $failed = 0
        $batch = @{}

        function Publish-Batch {
            param($Icons)

            if ($Icons.Count -eq 0) { return }
            Invoke-WPFUIThread -Async -Parameters @{ Icons = $Icons } -ScriptBlock {
                param($Icons)

                foreach ($entry in $Icons.GetEnumerator()) {
                    $image = $sync.IconImages[$entry.Key]
                    if ($null -eq $image) { continue }
                    $image.Source = $entry.Value
                    $image.Visibility = "Visible"
                    if ($image.Parent -and $image.Parent.Children.Count -gt 0) {
                        $image.Parent.Children[0].Visibility = "Collapsed"
                    }
                }
            }
        }

        try {
            # Requested in waves rather than one at a time. Setting a remote address on an Image
            # let WPF fetch every icon at once, so downloading them serially here turned a first
            # run with an empty cache from seconds into minutes of blank entries.
            $waveSize = 8

            for ($offset = 0; $offset -lt @($IconWork).Count; $offset += $waveSize) {
                $last = [Math]::Min($offset + $waveSize - 1, @($IconWork).Count - 1)
                $wave = @($IconWork[$offset..$last])

                # Started together, then collected: the wait is the slowest of the wave rather
                # than the sum of all of them
                $requests = @()
                foreach ($item in $wave) {
                    $file = Get-WinUtilIconCacheFile -Link $item.Link
                    if (Test-Path $file) {
                        $requests += $null
                        continue
                    }
                    $url = "https://www.google.com/s2/favicons?sz=64&domain_url=$([uri]::EscapeDataString($item.Link))"
                    try {
                        $requests += $client.GetByteArrayAsync($url)
                    } catch {
                        $requests += $null
                    }
                }

                for ($index = 0; $index -lt $wave.Count; $index++) {
                    $item = $wave[$index]
                    $file = Get-WinUtilIconCacheFile -Link $item.Link

                    try {
                        $request = $requests[$index]
                        if ($null -ne $request) {
                            $bytes = $request.GetAwaiter().GetResult()
                            if ($bytes.Length -gt 0) {
                                [System.IO.File]::WriteAllBytes($file, $bytes)
                            }
                        }

                        $bitmap = if (Test-Path $file) { Get-WinUtilFrozenIcon -Path $file } else { $null }
                        if ($bitmap) {
                            $batch[$item.Key] = $bitmap
                            $fetched++
                        } else {
                            # An error page or a truncated body would otherwise sit in the cache
                            # and be skipped by the Test-Path above on every later run
                            Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
                            $failed++
                        }
                    } catch {
                        Remove-Item -LiteralPath $file -Force -ErrorAction SilentlyContinue
                        $failed++
                    }
                }

                # Handed over a wave at a time, so the interface does a handful of assignments
                # now and then rather than several hundred when the last one lands
                Publish-Batch -Icons $batch
                $batch = @{}
            }

            Publish-Batch -Icons $batch
        } finally {
            $client.Dispose()
            $sync.IconFetchRunning = $false
        }

        Write-WinUtilLog -Component "Icons" -Message "Icon fetch finished: $fetched cached, $failed unavailable."

        if ($sync.PendingIcons -and $sync.PendingIcons.Count -gt 0) {
            Start-WinUtilIconFetch
        }
    }

    if ($null -eq $handle) {
        # Refused, so no worker will run and nothing would clear the gate
        $sync.IconFetchRunning = $false
    }
}
