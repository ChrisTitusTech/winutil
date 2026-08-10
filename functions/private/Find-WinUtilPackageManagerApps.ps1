function Find-WinUtilPackageManagerApps {
    <#
        .SYNOPSIS
            Searches the repository of the currently selected package manager (Winget or Choco).

        .DESCRIPTION
            Executes a search query against Winget or Chocolatey CLI and parses output
            into custom objects with Name and Id properties. Handles errors gracefully.

        .PARAMETER SearchString
            The term to search for in the package manager repository.

        .PARAMETER ManagerPreference
            The selected package manager preference ("Winget" or "Choco").

        .NOTES
            - Keep parser lightweight and fail safe without external dependencies.
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$SearchString = "",

        [Parameter(Mandatory = $false)]
        [string]$ManagerPreference = "Winget"
    )

    if ([string]::IsNullOrWhiteSpace($SearchString)) {
        return ,@()
    }

    $results = [System.Collections.Generic.List[PSObject]]::new()

    try {
        if ($ManagerPreference -eq "Choco") {
            if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                return ,@()
            }

            # choco --limit-output provides id|version format
            $out = @(choco search $SearchString --limit-output 2>&1)
            if ($LASTEXITCODE -ne 0) { return ,@() }
            foreach ($line in $out) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                $parts = [string]$line -split '\|'
                if ($parts.Count -ge 2 -and -not [string]::IsNullOrWhiteSpace($parts[0])) {
                    $id = $parts[0].Trim()
                    if ($id -notmatch '\s') {
                        $results.Add([pscustomobject]@{
                            Name = $id
                            Id   = $id
                        })
                    }
                }
            }
        }
        else {
            if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
                return ,@()
            }

            $originalEncoding = [Console]::OutputEncoding
            try {
                try {
                    [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
                } catch {
                    # Ignore encoding failure, proceed with search
                }
                $out = @(winget search $SearchString --accept-source-agreements --disable-interactivity 2>&1)
                if ($LASTEXITCODE -ne 0) { return ,@() }
            }
            finally {
                try { [Console]::OutputEncoding = $originalEncoding } catch {}
            }

            $lines = ($out -join "`n") -split '\r?\n'
            $dashIndex = -1
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match '^-{3,}') {
                    $dashIndex = $i
                    break
                }
            }

            if ($dashIndex -ge 0) {
                for ($i = $dashIndex + 1; $i -lt $lines.Count; $i++) {
                    $l = $lines[$i].Trim()
                    if ([string]::IsNullOrWhiteSpace($l)) { continue }

                    $cols = @($l -split '\s{2,}')
                    if ($cols.Count -ge 2) {
                        $name = $cols[0].Trim()
                        $id = $cols[1].Trim()
                        if ($name -and $id -and ($id -notmatch '\s')) {
                            $results.Add([pscustomobject]@{
                                Name = $name
                                Id   = $id
                            })
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Warning "Find-WinUtilPackageManagerApps: Search failed for manager '$ManagerPreference': $_"
        return ,@()
    }

    return ,($results.ToArray())
}
