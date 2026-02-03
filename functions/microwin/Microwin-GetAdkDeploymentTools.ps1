function Microwin-GetAdkDeploymentTools {
    <#
        .DESCRIPTION
        This function will download the deployment tools from Microsoft

        .EXAMPLE
        Microwin-GetAdkDeploymentTools
    #>

    $tempDir = [IO.Path]::GetTempPath().TrimEnd("\")

    # ADK 10.1.28000.1 download link is the same; no need to guess it
    $adkDownloadLink = "https://download.microsoft.com/download/615540bc-be0b-433a-b91b-1f2b0642bb24/adk/adksetup.exe"
    $adkVersion = "10.1.28000.1"
    Write-Host "Downloading ADK version $adkVersion ..."
    Invoke-WebRequest -UseBasicParsing -Uri "$adkDownloadLink" -OutFile "$tempDir\adksetup.exe"

    if ((-not ($?)) -or (-not (Test-Path -Path "$tempDir\adksetup.exe" -PathType Leaf))) {
        Write-Host "ADK could not be downloaded."
        return $false
    }

    Write-Host "Installing ADK version $adkVersion -- This may take a few minutes..."
    Start-Process -FilePath "$tempDir\adksetup.exe" -ArgumentList "/features OptionId.DeploymentTools /q /ceip off" -Wait

    return $?
}
