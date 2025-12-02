# Remove Adobe Creative Cloud

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Remove Adobe Creative Cloud",
  "category": "Fixes",
  "panel": "1",
  "Order": "a045_",
  "Type": "Button",
  "ButtonWidth": "300",
  "link": "https://christitustech.github.io/Winutil/dev/features/Fixes/RunAdobeCCCleanerTool"
}
```

</details>

## Function: Invoke-WPFRunAdobeCCCleanerTool

```powershell
function Invoke-WPFRunAdobeCCCleanerTool {
    <#
    .SYNOPSIS
        It removes or fixes problem files and resolves permission issues in registry keys.
    .DESCRIPTION
        The Creative Cloud Cleaner tool is a utility for experienced users to clean up corrupted installations.
    #>

    [string]$url="https://swupmf.adobe.com/webfeed/CleanerTool/win/AdobeCreativeCloudCleanerTool.exe"

    Write-Host "The Adobe Creative Cloud Cleaner tool is hosted at"
    Write-Host "$url"

    try {
        # Don't show the progress because it will slow down the download speed
        $ProgressPreference='SilentlyContinue'

        Invoke-WebRequest -Uri $url -OutFile "$env:TEMP\AdobeCreativeCloudCleanerTool.exe" -UseBasicParsing -ErrorAction SilentlyContinue -Verbose

        # Revert back the ProgressPreference variable to the default value since we got the file desired
        $ProgressPreference='Continue'

        Start-Process -FilePath "$env:TEMP\AdobeCreativeCloudCleanerTool.exe" -Wait -ErrorAction SilentlyContinue -Verbose
    } catch {
        Write-Error $_.Exception.Message
    } finally {
        if (Test-Path -Path "$env:TEMP\AdobeCreativeCloudCleanerTool.exe") {
            Write-Host "Cleaning up..."
            Remove-Item -Path "$env:TEMP\AdobeCreativeCloudCleanerTool.exe" -Verbose
        }
    }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/feature.json)

