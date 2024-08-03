# Adobe Network Block

Last Updated: 2024-08-03


!!! info
     The Development Documentation is auto generated for every compilation of WinUtil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**


## Description

Reduce user interruptions by selectively blocking connections to Adobe's activation and telemetry servers. Credit: Ruddernation-Designs

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
    "Content":  "Adobe Network Block",
    "Description":  "Reduce user interruptions by selectively blocking connections to Adobe\u0027s activation and telemetry servers. Credit: Ruddernation-Designs",
    "link":  "https://christitustech.github.io/winutil/dev/tweaks/Shortcuts/Shortcut",
    "category":  "z__Advanced Tweaks - CAUTION",
    "panel":  "1",
    "Order":  "a021_",
    "InvokeScript":  [
                         "\r\n      # Define the URL of the remote HOSTS file and the local paths\r\n      $remoteHostsUrl = \"https://raw.githubusercontent.com/Ruddernation-Designs/Adobe-URL-Block-List/master/hosts\"\r\n      $localHostsPath = \"C:\\Windows\\System32\\drivers\\etc\\hosts\"\r\n      $tempHostsPath = \"C:\\Windows\\System32\\drivers\\etc\\temp_hosts\"\r\n\r\n      # Download the remote HOSTS file to a temporary location\r\n      try {\r\n          Invoke-WebRequest -Uri $remoteHostsUrl -OutFile $tempHostsPath\r\n          Write-Output \"Downloaded the remote HOSTS file to a temporary location.\"\r\n      }\r\n      catch {\r\n          Write-Error \"Failed to download the HOSTS file. Error: $_\"\r\n      }\r\n\r\n      # Check if the AdobeNetBlock has already been started\r\n      try {\r\n          $localHostsContent = Get-Content $localHostsPath -ErrorAction Stop\r\n\r\n          # Check if AdobeNetBlock markers exist\r\n          $blockStartExists = $localHostsContent -like \"*#AdobeNetBlock-start*\"\r\n          if ($blockStartExists) {\r\n              Write-Output \"AdobeNetBlock-start already exists. Skipping addition of new block.\"\r\n          } else {\r\n              # Load the new block from the downloaded file\r\n              $newBlockContent = Get-Content $tempHostsPath -ErrorAction Stop\r\n              $newBlockContent = $newBlockContent | Where-Object { $_ -notmatch \"^\\s*#\" -and $_ -ne \"\" } # Exclude empty lines and comments\r\n              $newBlockHeader = \"#AdobeNetBlock-start\"\r\n              $newBlockFooter = \"#AdobeNetBlock-end\"\r\n\r\n              # Combine the contents, ensuring new block is properly formatted\r\n              $combinedContent = $localHostsContent + $newBlockHeader, $newBlockContent, $newBlockFooter | Out-String\r\n\r\n              # Write the combined content back to the original HOSTS file\r\n              $combinedContent | Set-Content $localHostsPath -Encoding ASCII\r\n              Write-Output \"Successfully added the AdobeNetBlock.\"\r\n          }\r\n      }\r\n      catch {\r\n          Write-Error \"Error during processing: $_\"\r\n      }\r\n\r\n      # Clean up temporary file\r\n      Remove-Item $tempHostsPath -ErrorAction Ignore\r\n\r\n      # Flush the DNS resolver cache\r\n      try {\r\n          Invoke-Expression \"ipconfig /flushdns\"\r\n          Write-Output \"DNS cache flushed successfully.\"\r\n      }\r\n      catch {\r\n          Write-Error \"Failed to flush DNS cache. Error: $_\"\r\n      }\r\n      "
                     ],
    "UndoScript":  [
                       "\r\n      # Define the local path of the HOSTS file\r\n      $localHostsPath = \"C:\\Windows\\System32\\drivers\\etc\\hosts\"\r\n\r\n      # Load the content of the HOSTS file\r\n      try {\r\n          $hostsContent = Get-Content $localHostsPath -ErrorAction Stop\r\n      }\r\n      catch {\r\n          Write-Error \"Failed to load the HOSTS file. Error: $_\"\r\n          return\r\n      }\r\n\r\n      # Initialize flags and buffer for new content\r\n      $recording = $true\r\n      $newContent = @()\r\n\r\n      # Iterate over each line of the HOSTS file\r\n      foreach ($line in $hostsContent) {\r\n          if ($line -match \"#AdobeNetBlock-start\") {\r\n              $recording = $false\r\n          }\r\n          if ($recording) {\r\n              $newContent += $line\r\n          }\r\n          if ($line -match \"#AdobeNetBlock-end\") {\r\n              $recording = $true\r\n          }\r\n      }\r\n\r\n      # Write the filtered content back to the HOSTS file\r\n      try {\r\n          $newContent | Set-Content $localHostsPath -Encoding ASCII\r\n          Write-Output \"Successfully removed the AdobeNetBlock section from the HOSTS file.\"\r\n      }\r\n      catch {\r\n          Write-Error \"Failed to write back to the HOSTS file. Error: $_\"\r\n      }\r\n\r\n      # Flush the DNS resolver cache\r\n      try {\r\n          Invoke-Expression \"ipconfig /flushdns\"\r\n          Write-Output \"DNS cache flushed successfully.\"\r\n      }\r\n      catch {\r\n          Write-Error \"Failed to flush DNS cache. Error: $_\"\r\n      }\r\n      "
                   ]
}
```
</details>

## Invoke Script

```powershell

      # Define the URL of the remote HOSTS file and the local paths
      $remoteHostsUrl = "https://raw.githubusercontent.com/Ruddernation-Designs/Adobe-URL-Block-List/master/hosts"
      $localHostsPath = "C:\Windows\System32\drivers\etc\hosts"
      $tempHostsPath = "C:\Windows\System32\drivers\etc\temp_hosts"

      # Download the remote HOSTS file to a temporary location
      try {
          Invoke-WebRequest -Uri $remoteHostsUrl -OutFile $tempHostsPath
          Write-Output "Downloaded the remote HOSTS file to a temporary location."
      }
      catch {
          Write-Error "Failed to download the HOSTS file. Error: $_"
      }

      # Check if the AdobeNetBlock has already been started
      try {
          $localHostsContent = Get-Content $localHostsPath -ErrorAction Stop

          # Check if AdobeNetBlock markers exist
          $blockStartExists = $localHostsContent -like "*#AdobeNetBlock-start*"
          if ($blockStartExists) {
              Write-Output "AdobeNetBlock-start already exists. Skipping addition of new block."
          } else {
              # Load the new block from the downloaded file
              $newBlockContent = Get-Content $tempHostsPath -ErrorAction Stop
              $newBlockContent = $newBlockContent | Where-Object { $_ -notmatch "^\s*#" -and $_ -ne "" } # Exclude empty lines and comments
              $newBlockHeader = "#AdobeNetBlock-start"
              $newBlockFooter = "#AdobeNetBlock-end"

              # Combine the contents, ensuring new block is properly formatted
              $combinedContent = $localHostsContent + $newBlockHeader, $newBlockContent, $newBlockFooter | Out-String

              # Write the combined content back to the original HOSTS file
              $combinedContent | Set-Content $localHostsPath -Encoding ASCII
              Write-Output "Successfully added the AdobeNetBlock."
          }
      }
      catch {
          Write-Error "Error during processing: $_"
      }

      # Clean up temporary file
      Remove-Item $tempHostsPath -ErrorAction Ignore

      # Flush the DNS resolver cache
      try {
          Invoke-Expression "ipconfig /flushdns"
          Write-Output "DNS cache flushed successfully."
      }
      catch {
          Write-Error "Failed to flush DNS cache. Error: $_"
      }
      

```
## Undo Script

```powershell

      # Define the local path of the HOSTS file
      $localHostsPath = "C:\Windows\System32\drivers\etc\hosts"

      # Load the content of the HOSTS file
      try {
          $hostsContent = Get-Content $localHostsPath -ErrorAction Stop
      }
      catch {
          Write-Error "Failed to load the HOSTS file. Error: $_"
          return
      }

      # Initialize flags and buffer for new content
      $recording = $true
      $newContent = @()

      # Iterate over each line of the HOSTS file
      foreach ($line in $hostsContent) {
          if ($line -match "#AdobeNetBlock-start") {
              $recording = $false
          }
          if ($recording) {
              $newContent += $line
          }
          if ($line -match "#AdobeNetBlock-end") {
              $recording = $true
          }
      }

      # Write the filtered content back to the HOSTS file
      try {
          $newContent | Set-Content $localHostsPath -Encoding ASCII
          Write-Output "Successfully removed the AdobeNetBlock section from the HOSTS file."
      }
      catch {
          Write-Error "Failed to write back to the HOSTS file. Error: $_"
      }

      # Flush the DNS resolver cache
      try {
          Invoke-Expression "ipconfig /flushdns"
          Write-Output "DNS cache flushed successfully."
      }
      catch {
          Write-Error "Failed to flush DNS cache. Error: $_"
      }
      

```
<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->

[View the JSON file](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)

