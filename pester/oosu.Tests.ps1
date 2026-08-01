#===========================================================================
# Tests - O&O ShutUp10++ Download Workflow
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    . (Join-Path $script:repoRoot "functions\private\Save-WinUtilFile.ps1")
    . (Join-Path $script:repoRoot "functions\public\Invoke-WPFOOSU.ps1")

    function Invoke-WPFRunspace {
        param($ArgumentList, $ParameterList, [scriptblock]$ScriptBlock)
    }
    function Set-WinUtilTweaksProgressIndicator {
        param($Visible, $Label, $Percent)
    }
    function Show-WinUtilMessage {
        param($Message, $Title, $Button, $Icon)
    }
    function Write-WinUtilLog {
        param($Message, $Level, $Component)
    }

    function script:New-WinUtilOOSUTestContext {
        param([bool]$ProcessRunning = $false)

        $script:sync = [Hashtable]::Synchronized(@{
            ProcessRunning = $ProcessRunning
            winutildir = $TestDrive
            Form = [pscustomobject]@{
                Dispatcher = [pscustomobject]@{}
            }
        })
    }
}

Describe "Save-WinUtilFile" {
    It "copies a download and reports its percentage" {
        $sourcePath = Join-Path $TestDrive "source.bin"
        $destinationPath = Join-Path $TestDrive "destination.bin"
        $sourceBytes = [byte[]](0..255)
        [System.IO.File]::WriteAllBytes($sourcePath, $sourceBytes)
        $reportedProgress = [System.Collections.Generic.List[int]]::new()

        Save-WinUtilFile -Uri ([uri]$sourcePath) -DestinationPath $destinationPath -ProgressCallback {
            param($percent)
            $reportedProgress.Add($percent)
        }

        [System.IO.File]::ReadAllBytes($destinationPath) | Should -Be $sourceBytes
        $reportedProgress[-1] | Should -Be 100
    }
}

Describe "Invoke-WPFOOSU" {
    BeforeEach {
        New-WinUtilOOSUTestContext
        $script:capturedScriptBlock = $null
        $script:capturedParameterList = $null

        Mock Invoke-WPFRunspace {
            $script:capturedScriptBlock = $ScriptBlock
            $script:capturedParameterList = $ParameterList
            [pscustomobject]@{ MockHandle = $true }
        }
        Mock Set-WinUtilTweaksProgressIndicator { }
        Mock Show-WinUtilMessage { }
        Mock Write-WinUtilLog { }
        Mock Start-Process { }
        Mock Write-Error { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedScriptBlock -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedParameterList -Scope Script -ErrorAction SilentlyContinue
    }

    It "queues the download in a background runspace" {
        Invoke-WPFOOSU

        $script:sync.ProcessRunning | Should -BeTrue
        Should -Invoke Invoke-WPFRunspace -Times 1 -Exactly
        $script:capturedParameterList[0][0] | Should -Be "downloadPath"
        $script:capturedParameterList[0][1] | Should -Be (Join-Path $TestDrive "ooshutup10.exe")
    }

    It "does not start while another process is running" {
        New-WinUtilOOSUTestContext -ProcessRunning $true

        Invoke-WPFOOSU

        Should -Invoke Show-WinUtilMessage -Times 1 -Exactly -ParameterFilter {
            $Message -eq "Another process is currently running." -and
                $Title -eq "WinUtil" -and
                $Button -eq "OK" -and
                $Icon -eq "Warning"
        }
        Should -Not -Invoke Invoke-WPFRunspace
    }

    It "maps download progress to the window indicator and launches O&O ShutUp10++" {
        Mock Save-WinUtilFile {
            & $ProgressCallback 35
            & $ProgressCallback 100
        }

        Invoke-WPFOOSU
        & $script:capturedScriptBlock -downloadPath $script:capturedParameterList[0][1]

        Should -Invoke Set-WinUtilTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "Downloading O&O ShutUp10++ (0%)" -and $Percent -eq 0
        }
        Should -Invoke Set-WinUtilTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "Downloading O&O ShutUp10++ (35%)" -and $Percent -eq 35
        }
        Should -Invoke Set-WinUtilTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "O&O ShutUp10++ launched" -and $Percent -eq 100
        }
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq (Join-Path $TestDrive "ooshutup10.exe")
        }
        $script:sync.ProcessRunning | Should -BeFalse
    }

    It "shows failure progress and clears the running state when the download fails" {
        Mock Save-WinUtilFile { throw "download failed" }

        Invoke-WPFOOSU
        & $script:capturedScriptBlock -downloadPath $script:capturedParameterList[0][1]

        Should -Invoke Set-WinUtilTweaksProgressIndicator -Times 1 -Exactly -ParameterFilter {
            $Visible -eq $true -and $Label -eq "O&O ShutUp10++ download failed" -and $Percent -eq 100
        }
        Should -Not -Invoke Start-Process
        Should -Invoke Write-Error -Times 1 -Exactly
        $script:sync.ProcessRunning | Should -BeFalse
    }
}
