# Adobe Network Block

Last Updated: 2024-08-05


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
  "Content": "Adobe Network Block",
  "Description": "Reduce user interruptions by selectively blocking connections to Adobe's activation and telemetry servers. Credit: Ruddernation-Designs",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a021_",
  "InvokeScript": [
    "\n      # Define the URL of the remote HOSTS file and the local paths\n      $remoteHostsUrl = \"https://raw.githubusercontent.com/Ruddernation-Designs/Adobe-URL-Block-List/master/hosts\"\n      $localHostsPath = \"C:\\Windows\\System32\\drivers\\etc\\hosts\"\n      $tempHostsPath = \"C:\\Windows\\System32\\drivers\\etc\\temp_hosts\"\n\n      # Download the remote HOSTS file to a temporary location\n      try {\n          Invoke-WebRequest -Uri $remoteHostsUrl -OutFile $tempHostsPath\n          Write-Output \"Downloaded the remote HOSTS file to a temporary location.\"\n      }\n      catch {\n          Write-Error \"Failed to download the HOSTS file. Error: $_\"\n      }\n\n      # Check if the AdobeNetBlock has already been started\n      try {\n          $localHostsContent = Get-Content $localHostsPath -ErrorAction Stop\n\n          # Check if AdobeNetBlock markers exist\n          $blockStartExists = $localHostsContent -like \"*#AdobeNetBlock-start*\"\n          if ($blockStartExists) {\n              Write-Output \"AdobeNetBlock-start already exists. Skipping addition of new block.\"\n          } else {\n              # Load the new block from the downloaded file\n              $newBlockContent = Get-Content $tempHostsPath -ErrorAction Stop\n              $newBlockContent = $newBlockContent | Where-Object { $_ -notmatch \"^\\s*#\" -and $_ -ne \"\" } # Exclude empty lines and comments\n              $newBlockHeader = \"#AdobeNetBlock-start\"\n              $newBlockFooter = \"#AdobeNetBlock-end\"\n\n              # Combine the contents, ensuring new block is properly formatted\n              $combinedContent = $localHostsContent + $newBlockHeader, $newBlockContent, $newBlockFooter | Out-String\n\n              # Write the combined content back to the original HOSTS file\n              $combinedContent | Set-Content $localHostsPath -Encoding ASCII\n              Write-Output \"Successfully added the AdobeNetBlock.\"\n          }\n      }\n      catch {\n          Write-Error \"Error during processing: $_\"\n      }\n\n      # Clean up temporary file\n      Remove-Item $tempHostsPath -ErrorAction Ignore\n\n      # Flush the DNS resolver cache\n      try {\n          Invoke-Expression \"ipconfig /flushdns\"\n          Write-Output \"DNS cache flushed successfully.\"\n      }\n      catch {\n          Write-Error \"Failed to flush DNS cache. Error: $_\"\n      }\n      "
  ],
  "UndoScript": [
    "\n      # Define the local path of the HOSTS file\n      $localHostsPath = \"C:\\Windows\\System32\\drivers\\etc\\hosts\"\n\n      # Load the content of the HOSTS file\n      try {\n          $hostsContent = Get-Content $localHostsPath -ErrorAction Stop\n      }\n      catch {\n          Write-Error \"Failed to load the HOSTS file. Error: $_\"\n          return\n      }\n\n      # Initialize flags and buffer for new content\n      $recording = $true\n      $newContent = @()\n\n      # Iterate over each line of the HOSTS file\n      foreach ($line in $hostsContent) {\n          if ($line -match \"#AdobeNetBlock-start\") {\n              $recording = $false\n          }\n          if ($recording) {\n              $newContent += $line\n          }\n          if ($line -match \"#AdobeNetBlock-end\") {\n              $recording = $true\n          }\n      }\n\n      # Write the filtered content back to the HOSTS file\n      try {\n          $newContent | Set-Content $localHostsPath -Encoding ASCII\n          Write-Output \"Successfully removed the AdobeNetBlock section from the HOSTS file.\"\n      }\n      catch {\n          Write-Error \"Failed to write back to the HOSTS file. Error: $_\"\n      }\n\n      # Flush the DNS resolver cache\n      try {\n          Invoke-Expression \"ipconfig /flushdns\"\n          Write-Output \"DNS cache flushed successfully.\"\n      }\n      catch {\n          Write-Error \"Failed to flush DNS cache. Error: $_\"\n      }\n      "
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/BlockAdobeNet"
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

