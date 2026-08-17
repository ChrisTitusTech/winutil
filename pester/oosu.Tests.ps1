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
    function Start-WinUtilJob {
        param([string]$Name, [scriptblock]$ScriptBlock, [hashtable]$Parameters, [string]$Description, [switch]$DisableAppList)
    }
    function Step-WinUtilJob {
        param([string]$Status, [int]$Percent, [string]$State, [string]$Overlay)
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
        $script:capturedJob = $null

        Mock Start-WinUtilJob {
            $script:capturedJob = [pscustomobject]@{
                Name = $Name
                ScriptBlock = $ScriptBlock
                Parameters = $Parameters
            }
        }
        Mock Step-WinUtilJob { }
        Mock Show-WinUtilMessage { }
        Mock Write-WinUtilLog { }
        Mock Start-Process { }
    }

    AfterEach {
        Remove-Variable -Name sync -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name capturedJob -Scope Script -ErrorAction SilentlyContinue
    }

    It "queues the download as a job with the download path" {
        Invoke-WPFOOSU

        Should -Invoke Start-WinUtilJob -Times 1 -Exactly -ParameterFilter { $Name -eq "OOSU" }
        $script:capturedJob.Parameters.DownloadPath | Should -Be (Join-Path $TestDrive "ooshutup10.exe")
    }

    It "maps download progress to the job indicator and launches O&O ShutUp10++" {
        Mock Save-WinUtilFile {
            & $ProgressCallback 35
            & $ProgressCallback 100
        }

        Invoke-WPFOOSU
        $jobParameters = $script:capturedJob.Parameters
        & $script:capturedJob.ScriptBlock @jobParameters

        Should -Invoke Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Downloading O&O ShutUp10++ (35%)" -and $Percent -eq 35
        }
        Should -Invoke Step-WinUtilJob -Times 1 -Exactly -ParameterFilter {
            $Status -eq "Launching O&O ShutUp10++" -and $Percent -eq 100
        }
        Should -Invoke Start-Process -Times 1 -Exactly -ParameterFilter {
            $FilePath -eq (Join-Path $TestDrive "ooshutup10.exe")
        }
    }

    It "lets a download failure surface so the job layer can handle it" {
        Mock Save-WinUtilFile { throw "download failed" }

        Invoke-WPFOOSU
        $jobParameters = $script:capturedJob.Parameters

        { & $script:capturedJob.ScriptBlock @jobParameters } | Should -Throw "download failed"
        Should -Not -Invoke Start-Process
    }
}
