<#PSScriptInfo

.VERSION 2.0.2

.GUID 3b581edb-5d90-4fa1-ba15-4f2377275463

.AUTHOR asheroto, 1ckov, MisterZeus, ChrisTitusTech

.COMPANYNAME asheroto

.TAGS PowerShell Windows winget win get install installer fix script

.PROJECTURI https://github.com/asheroto/winget-install

.RELEASENOTES
[Version 0.0.1] - Initial Release.
[Version 0.0.2] - Implemented function to get the latest version of winget and its license.
[Version 0.0.3] - Signed file for PSGallery.
[Version 0.0.4] - Changed URI to grab latest release instead of releases and preleases.
[Version 0.0.5] - Updated version number of dependencies.
[Version 1.0.0] - Major refactor code, see release notes for more information.
[Version 1.0.1] - Fixed minor bug where version 2.8 was hardcoded in URL.
[Version 1.0.2] - Hardcoded UI Xaml version 2.8.4 as a failsafe in case the API fails. Added CheckForUpdates, Version, Help functions. Various bug fixes.
[Version 1.0.3] - Added error message to catch block. Fixed bug where appx package was not being installed.
[Version 1.0.4] - MisterZeus optimized code for readability.
[Version 2.0.0] - Major refactor. Reverted to UI.Xaml 2.7.3 for stability. Adjusted script to fix install issues due to winget changes (thank you ChrisTitusTech). Added in all architecture support.
[Version 2.0.1] - Renamed repo and URL references from winget-installer to winget-install. Added extra space after the last line of output.
[Version 2.0.2] - Adjusted CheckForUpdates to include Install-Script instructions and extra spacing.

#>

<#
.SYNOPSIS
	Downloads the latest version of winget, its dependencies, and installs everything. PATH variable is adjusted after installation. Reboot required after installation.
.DESCRIPTION
	The Install-winget function automates the process of installing the winget package manager. It downloads the latest version of winget and its required dependencies from the source. After downloading, the function installs winget and updates the PATH environment variable to include directories necessary for winget's operation.

    This function is designed to be straightforward and easy to use, removing the hassle of manually downloading, installing, and configuring winget. To make the newly installed winget available for use, a system reboot may be required after the execution of this function. This function should be run with administrative privileges.
.EXAMPLE
	winget-install
.PARAMETER Version
    Displays the version of the script.
.PARAMETER Help
    Displays the help information for the script.
.PARAMETER CheckForUpdate
    Checks for updates of the script.
.NOTES
	Version      : 2.0.2
	Created by   : asheroto
.LINK
	Project Site: https://github.com/asheroto/winget-install
#>
[CmdletBinding()]
param (
    [switch]$Version,
    [switch]$Help,
    [switch]$CheckForUpdates
)

# Version
$CurrentVersion = '2.0.2'
$RepoOwner = 'asheroto'
$RepoName = 'winget-install'

# Versions
$ProgressPreference = 'SilentlyContinue' # Suppress progress bar (makes downloading super fast)

# Check if -Version is specified
if ($Version.IsPresent) {
    $CurrentVersion
    exit 0
}

# Help
if ($Help) {
    Get-Help -Name $MyInvocation.MyCommand.Source -Full
    exit 0
}

# If user runs "winget-install -Verbose", output their PS and Host info.
if ($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters['Verbose']) {
    $PSVersionTable
    Get-Host
}

function Get-GitHubRelease {
    <#
        .SYNOPSIS
        Fetches the latest release information of a GitHub repository.

        .DESCRIPTION
        This function uses the GitHub API to get information about the latest release of a specified repository, including its version and the date it was published.

        .PARAMETER Owner
        The GitHub username of the repository owner.

        .PARAMETER Repo
        The name of the repository.

        .EXAMPLE
        Get-GitHubRelease -Owner "asheroto" -Repo "winget-install"
        This command retrieves the latest release version and published datetime of the winget-install repository owned by asheroto.
    #>
    [CmdletBinding()]
    param (
        [string]$Owner,
        [string]$Repo
    )
    try {
        $url = "https://api.github.com/repos/$Owner/$Repo/releases/latest"
        $response = Invoke-RestMethod -Uri $url -ErrorAction Stop

        $latestVersion = $response.tag_name
        $publishedAt = $response.published_at

        # Convert UTC time string to local time
        $UtcDateTime = [DateTime]::Parse($publishedAt, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::RoundtripKind)
        $PublishedLocalDateTime = $UtcDateTime.ToLocalTime()

        [PSCustomObject]@{
            LatestVersion     = $latestVersion
            PublishedDateTime = $PublishedLocalDateTime
        }
    } catch {
        Write-Error "Unable to check for updates.`nError: $_"
        exit 1
    }
}

# Generates a section divider for easy reading of the output.
function Write-Section($text) {
    <#
        .SYNOPSIS
        Prints a text block surrounded by a section divider for enhanced output readability.

        .DESCRIPTION
        This function takes a string input and prints it to the console, surrounded by a section divider made of hash characters. It is designed to enhance the readability of console output.

        .PARAMETER text
        The text to be printed within the section divider.

        .EXAMPLE
        Write-Section "Downloading Files..."
        This command prints the text "Downloading Files..." surrounded by a section divider.
    #>
    Write-Output ""
    Write-Output ("#" * ($text.Length + 4))
    Write-Output "# $text #"
    Write-Output ("#" * ($text.Length + 4))
    Write-Output ""
}

function Get-NewestLink($match) {
    <#
        .SYNOPSIS
        Retrieves the download URL of the latest release asset that matches a specified pattern from the GitHub repository.

        .DESCRIPTION
        This function uses the GitHub API to get information about the latest release of the winget-cli repository. It then retrieves the download URL for the release asset that matches a specified pattern.

        .PARAMETER match
        The pattern to match in the asset names.

        .EXAMPLE
        Get-NewestLink "msixbundle"
        This command retrieves the download URL for the latest release asset with a name that contains "msixbundle".
    #>
    [CmdletBinding()]
    $uri = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
    Write-Verbose "Getting information from $uri"
    $get = Invoke-RestMethod -uri $uri -Method Get -ErrorAction stop
    Write-Verbose "Getting latest release..."
    $data = $get.assets | Where-Object name -Match $match
    return $data.browser_download_url
}

function Update-PathEnvironmentVariable {
    <#
        .SYNOPSIS
        Updates the PATH environment variable with a new path for both the User and Machine levels.

        .DESCRIPTION
        The function will add a new path to the PATH environment variable, making sure it is not a duplicate.
        If the new path is already in the PATH variable, the function will skip adding it.
        This function operates at both User and Machine levels.

        .PARAMETER NewPath
        The new directory path to be added to the PATH environment variable.

        .EXAMPLE
        Update-PathEnvironmentVariable -NewPath "C:\NewDirectory"
        This command will add the directory "C:\NewDirectory" to the PATH variable at both the User and Machine levels.
    #>
    param(
        [string]$NewPath
    )

    foreach ($Level in "Machine", "User") {
        # Get the current PATH variable
        $path = [Environment]::GetEnvironmentVariable("PATH", $Level)

        # Check if the new path is already in the PATH variable
        if (!$path.Contains($NewPath)) {
            Write-Output "Adding $NewPath to PATH variable for $Level..."

            # Add the new path to the PATH variable
            $path = ($path + ";" + $NewPath).Split(';') | Select-Object -Unique
            $path = $path -join ';'

            # Set the new PATH variable
            [Environment]::SetEnvironmentVariable("PATH", $path, $Level)
        } else {
            Write-Output "$NewPath already present in PATH variable for $Level, skipping."
        }
    }
}

function Handle-Error {
    <#
        .SYNOPSIS
            Handles common errors that may occur during an installation process.

        .DESCRIPTION
            This function takes an ErrorRecord object and checks for certain known error codes.
            Depending on the error code, it writes appropriate warning messages or throws the error.

        .PARAMETER ErrorRecord
            The ErrorRecord object that represents the error that was caught. This object contains
            information about the error, including the exception that was thrown.

        .EXAMPLE
            try {
                # Some code that may throw an error...
            } catch {
                Handle-Error $_
            }
            This example shows how you might use the Handle-Error function in a try-catch block.
            If an error occurs in the try block, the catch block catches it and calls Handle-Error,
            passing the error (represented by the $_ variable) to the function.
    #>
    param($ErrorRecord)

    # Store current value
    $OriginalErrorActionPreference = $ErrorActionPreference

    # Set to silently continue
    $ErrorActionPreference = 'SilentlyContinue'

    if ($ErrorRecord.Exception.Message -match '0x80073D06') {
        Write-Warning "Higher version already installed."
        Write-Warning "That's okay, continuing..."
    } elseif ($ErrorRecord.Exception.Message -match '0x80073CF0') {
        Write-Warning "Same version already installed."
        Write-Warning "That's okay, continuing..."
    } elseif ($ErrorRecord.Exception.Message -match '0x80073D02') {
        # Stop execution and return the ErrorRecord so that the calling try/catch block throws the error
        Write-Warning "Resources modified are in-use. Try closing Windows Terminal / PowerShell / Command Prompt and try again."
        Write-Warning "If the problem persists, restart your computer."
        return $ErrorRecord
    } else {
        # For other errors, we should stop the execution and return the ErrorRecord so that the calling try/catch block throws the error
        return $ErrorRecord
    }

    # Reset to original value
    $ErrorActionPreference = $OriginalErrorActionPreference
}

# Check for updates
if ($CheckForUpdates) {
    $Data = Get-GitHubRelease -Owner $RepoOwner -Repo $RepoName

    if ($Data.LatestVersion -gt $CurrentVersion) {
        Write-Output "`nA new version of $RepoName is available.`n"
        Write-Output "Current version: $CurrentVersion."
        Write-Output "Latest version: $($Data.LatestVersion)."
        Write-Output "Published at: $($Data.PublishedDateTime).`n"
        Write-Output "You can download the latest version from https://github.com/$RepoOwner/$RepoName/releases`n"
        Write-Output "Or you can run the following command to update:"
        Write-Output "Install-Script winget-install -Force`n"
    } else {
        Write-Output "`n$RepoName is up to date.`n"
        Write-Output "Current version: $CurrentVersion."
        Write-Output "Latest version: $($Data.LatestVersion)."
        Write-Output "Published at: $($Data.PublishedDateTime)."
        Write-Output "`nRepository: https://github.com/$RepoOwner/$RepoName/releases`n"
    }
    exit 0
}

try {
    # Using temp directory for downloads
    $tempFolder = [System.IO.Path]::GetTempPath()

    # Determine architecture
    $cpuArchitecture = (Get-CimInstance -ClassName Win32_Processor).Architecture
    # 0 - x86, 9 - x64, 5 - ARM, 12 - ARM64
    switch ($cpuArchitecture) {
        0 { $arch = "x86" }
        9 { $arch = "x64" }
        5 { $arch = "arm" }
        12 { $arch = "arm64" }
        default { throw "Unknown CPU architecture detected." }
    }

    ########################
    # VCLibs
    ########################

    # Vars
    $vcLibsVersion = "14.00"

    $vcLibs = @{
        url = "https://aka.ms/Microsoft.VCLibs.$arch.$($vcLibsVersion).Desktop.appx"
    }

    # Output
    Write-Section "Downloading & installing ${arch} VCLibs..."
    switch ($cpuArchitecture) {
        0 { $arch = "x86" }
        9 { $arch = "x64" }
        5 { $arch = "arm" }
        12 { $arch = "arm64" }
        default { throw "Unknown CPU architecture detected." }
    }

    ########################
    # VCLibs
    ########################

    # Vars
    $vcLibsVersion = "14.00"

    $vcLibs = @{
        url = "https://aka.ms/Microsoft.VCLibs.$arch.$($vcLibsVersion).Desktop.appx"
    }

    # Output
    Write-Section "Downloading & installing ${arch} VCLibs..."
    Write-Output "URL: $($vcLibs.url)"

    # Try to install VCLibs
    try {
        # Add-AppxPackage will throw an error if the app is already installed or higher version installed, so we need to catch it and continue
        Add-AppxPackage $vcLibs.url -ErrorAction Stop
    } catch {
        $errorHandled = Handle-Error $_
        if ($null -ne $errorHandled) {
            throw $errorHandled
        }
        $errorHandled = $null
    }

    ########################
    # UI.Xaml
    ########################

    # Vars
    $uiXamlNupkgVersion = "2.7.3"
    $uiXamlAppxFileVersion = "2.7"
    $uiXaml = @{
        url           = "https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/$uiXamlNupkgVersion"
        appxFolder    = "tools/AppX/$arch/Release/"
        appxFilename  = "Microsoft.UI.Xaml.$uiXamlAppxFileVersion.appx"
        nupkgFilename = Join-Path -Path $tempFolder -ChildPath "Microsoft.UI.Xaml.$uiXamlNupkgVersion.nupkg"
        nupkgFolder   = Join-Path -Path $tempFolder -ChildPath "Microsoft.UI.Xaml.$uiXamlNupkgVersion"
    }

    # Output
    Write-Section "Downloading & installing ${arch} UI.Xaml..."
    Write-Output "Downloading: $($uiXaml.url)"
    Write-Output "Saving as: $($uiXaml.nupkgFilename)"

    # Downloads from URL, saves as nupkg
    Invoke-WebRequest -Uri $uiXaml.url -OutFile $uiXaml.nupkgFilename

    # Extracts the nupkg file
    Write-Output "Extracting into: $($uiXaml.nupkgFolder)`n"
    Add-Type -Assembly System.IO.Compression.FileSystem

    # Extracts the nupkg file
    Write-Output "Extracting into: $($uiXaml.nupkgFolder)`n"
    Add-Type -Assembly System.IO.Compression.FileSystem
    # Check if folder exists and delete if needed
    if (Test-Path -Path $uiXaml.nupkgFolder) {
        Remove-Item -Path $uiXaml.nupkgFolder -Recurse
    }
    [IO.Compression.ZipFile]::ExtractToDirectory($uiXaml.nupkgFilename, $uiXaml.nupkgFolder)

    # Install XAML
    Write-Output "Installing ${arch} XAML..."
    $XamlAppxFolder = Join-Path -Path $uiXaml.nupkgFolder -ChildPath $uiXaml.appxFolder
    $XamlAppxPath = Join-Path -Path $XamlAppxFolder -ChildPath $uiXaml.appxFilename
    Write-Output "Installing Appx Packages in: $XamlAppxFolder"

    # For each appx file in the folder, try to install it
    Get-ChildItem -Path $XamlAppxPath -Filter *.appx | ForEach-Object {
        try {
            Write-Output "Installing Appx Package: $($_.Name)"
            # Add-AppxPackage will throw an error if the app is already installed
            # or a higher version is installed, so we need to catch it and continue
            Add-AppxPackage $_.FullName -ErrorAction Stop
        } catch {
            $errorHandled = Handle-Error $_
            if ($null -ne $errorHandled) {
                throw $errorHandled
            }
            $errorHandled = $null
        }
    }

    ########################
    # winget
    ########################

    # Download winget
    Write-Section "Downloading winget..."

    Write-Output "Retrieving download URL for winget from GitHub..."
    $wingetUrl = Get-NewestLink("msixbundle")
    $wingetPath = Join-Path -Path $tempFolder -ChildPath "winget.msixbundle"
    $wingetLicenseUrl = Get-NewestLink("License1.xml")
    $wingetLicensePath = Join-Path -Path $tempFolder -ChildPath "license1.xml"

    Write-Output "`nDownloading: $wingetUrl"
    Write-Output "Saving as: $wingetPath"
    Invoke-WebRequest -Uri $wingetUrl -OutFile $wingetPath

    Write-Output "`nDownloading: $wingetLicenseUrl"
    Write-Output "Saving as: $wingetLicensePath"
    Invoke-WebRequest -Uri $wingetLicenseUrl -OutFile $wingetLicensePath

    # Install winget
    Write-Section "Installing winget..."

    Write-Output "wingetPath: $wingetPath"
    Write-Output "wingetLicensePath: $wingetLicensePath"

    # Try to install winget
    try {
        # Add-AppxPackage will throw an error if the app is already installed or higher version installed, so we need to catch it and continue
        Add-AppxPackage -Path $wingetPath -ErrorAction SilentlyContinue
    } catch {
        $errorHandled = Handle-Error $_
        if ($null -ne $errorHandled) {
            throw $errorHandled
        }
        $errorHandled = $null
    }

    # Add the WindowsApps directory to the PATH variable
    Write-Section "Checking and adding WindowsApps directory to PATH variable for current user if not present..."
    $WindowsAppsPath = [IO.Path]::Combine([Environment]::GetEnvironmentVariable("LOCALAPPDATA"), "Microsoft", "WindowsApps")
    Update-PathEnvironmentVariable -NewPath $WindowsAppsPath

    ########################
    # Cleanup
    ########################

    Write-Section "Cleaning up..."
    Remove-Item -Path $uiXaml.nupkgFilename
    Remove-Item -Path $uiXaml.nupkgFolder -Recurse
    Remove-Item -Path $wingetPath
    Remove-Item -Path $wingetLicensePath

    ########################
    # Finished
    ########################

    Write-Section "Installation complete!"
    Write-Output "If winget doesn't work right now, you may need to restart your computer.`n"
} catch {
    ########################
    # Error handling
    ########################

    Write-Section "WARNING! An error occurred during installation!"

    Write-Warning "Something went wrong. If messages above don't help and the problem persists,"
    Write-Warning "Please open an issue at https://github.com/$RepoOwner/$RepoName/issues`n"

    # If it's not 0x80073D02 (resources in use), show error
    if ($_.Exception.Message -notmatch '0x80073D02') {
        Write-Warning "Line number : $($_.InvocationInfo.ScriptLineNumber)"
        Write-Warning "Error: $($_.Exception.Message)`n"
    }
}
