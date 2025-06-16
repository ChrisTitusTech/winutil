# Adobe 网络阻止

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

通过选择性地阻止与 Adobe 激活和遥测服务器的连接来减少用户中断。鸣谢：Ruddernation-Designs

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Adobe Network Block",
  "Description": "Reduce user interruptions by selectively blocking connections to Adobe's activation and telemetry servers. Credit: Ruddernation-Designs",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a021_",
  "InvokeScript": [
    "
      # Define the URL of the remote HOSTS file and the local paths
      $remoteHostsUrl = \"https://raw.githubusercontent.com/Ruddernation-Designs/Adobe-URL-Block-List/master/hosts\"
      $localHostsPath = \"C:\\Windows\\System32\\drivers\\etc\\hosts\"
      $tempHostsPath = \"C:\\Windows\\System32\\drivers\\etc\\temp_hosts\"

      # Download the remote HOSTS file to a temporary location
      try {
          Invoke-WebRequest -Uri $remoteHostsUrl -OutFile $tempHostsPath
          Write-Output \"Downloaded the remote HOSTS file to a temporary location.\"
      } catch {
          Write-Error \"Failed to download the HOSTS file. Error: $_\"
      }

      # Check if the AdobeNetBlock has already been started
      try {
          $localHostsContent = Get-Content $localHostsPath -ErrorAction Stop

          # Check if AdobeNetBlock markers exist
          $blockStartExists = $localHostsContent -like \"*#AdobeNetBlock-start*\"
          if ($blockStartExists) {
              Write-Output \"AdobeNetBlock-start already exists. Skipping addition of new block.\"
          } else {
              # Load the new block from the downloaded file
              $newBlockContent = Get-Content $tempHostsPath -ErrorAction Stop
              $newBlockContent = $newBlockContent | Where-Object { $_ -notmatch \"^\\s*#\" -and $_ -ne \"\" } # Exclude empty lines and comments
              $newBlockHeader = \"#AdobeNetBlock-start\"
              $newBlockFooter = \"#AdobeNetBlock-end\"

              # Combine the contents, ensuring new block is properly formatted
              $combinedContent = $localHostsContent + $newBlockHeader, $newBlockContent, $newBlockFooter | Out-String

              # Write the combined content back to the original HOSTS file
              $combinedContent | Set-Content $localHostsPath -Encoding ASCII
              Write-Output \"Successfully added the AdobeNetBlock.\"
          }
      } catch {
          Write-Error \"Error during processing: $_\"
      }

      # Clean up temporary file
      Remove-Item $tempHostsPath -ErrorAction Ignore

      # Flush the DNS resolver cache
      try {
          Invoke-Expression \"ipconfig /flushdns\"
          Write-Output \"DNS cache flushed successfully.\"
      } catch {
          Write-Error \"Failed to flush DNS cache. Error: $_\"
      }
      "
  ],
  "UndoScript": [
    "
      # Define the local path of the HOSTS file
      $localHostsPath = \"C:\\Windows\\System32\\drivers\\etc\\hosts\"

      # Load the content of the HOSTS file
      try {
          $hostsContent = Get-Content $localHostsPath -ErrorAction Stop
      } catch {
          Write-Error \"Failed to load the HOSTS file. Error: $_\"
          return
      }

      # Initialize flags and buffer for new content
      $recording = $true
      $newContent = @()

      # Iterate over each line of the HOSTS file
      foreach ($line in $hostsContent) {
          if ($line -match \"#AdobeNetBlock-start\") {
              $recording = $false
          }
          if ($recording) {
              $newContent += $line
          }
          if ($line -match \"#AdobeNetBlock-end\") {
              $recording = $true
          }
      }

      # Write the filtered content back to the HOSTS file
      try {
          $newContent | Set-Content $localHostsPath -Encoding ASCII
          Write-Output \"Successfully removed the AdobeNetBlock section from the HOSTS file.\"
      } catch {
          Write-Error \"Failed to write back to the HOSTS file. Error: $_\"
      }

      # Flush the DNS resolver cache
      try {
          Invoke-Expression \"ipconfig /flushdns\"
          Write-Output \"DNS cache flushed successfully.\"
      } catch {
          Write-Error \"Failed to flush DNS cache. Error: $_\"
      }
      "
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/BlockAdobeNet"
}
```

</details>

## 调用脚本

```powershell

      # 定义远程 HOSTS 文件的 URL 和本地路径
      $remoteHostsUrl = "https://raw.githubusercontent.com/Ruddernation-Designs/Adobe-URL-Block-List/master/hosts"
      $localHostsPath = "C:\Windows\System32\drivers\etc\hosts"
      $tempHostsPath = "C:\Windows\System32\drivers\etc\temp_hosts"

      # 将远程 HOSTS 文件下载到临时位置
      try {
          Invoke-WebRequest -Uri $remoteHostsUrl -OutFile $tempHostsPath
          Write-Output "已将远程 HOSTS 文件下载到临时位置。"
      } catch {
          Write-Error "下载 HOSTS 文件失败。错误：$_"
      }

      # 检查 AdobeNetBlock 是否已启动
      try {
          $localHostsContent = Get-Content $localHostsPath -ErrorAction Stop

          # 检查 AdobeNetBlock 标记是否存在
          $blockStartExists = $localHostsContent -like "*#AdobeNetBlock-start*"
          if ($blockStartExists) {
              Write-Output "AdobeNetBlock-start 已存在。正在跳过添加新阻止。"
          } else {
              # 从下载的文件加载新的阻止
              $newBlockContent = Get-Content $tempHostsPath -ErrorAction Stop
              $newBlockContent = $newBlockContent | Where-Object { $_ -notmatch "^\s*#" -and $_ -ne "" } # 排除空行和注释
              $newBlockHeader = "#AdobeNetBlock-start"
              $newBlockFooter = "#AdobeNetBlock-end"

              # 合并内容，确保新阻止格式正确
              $combinedContent = $localHostsContent + $newBlockHeader, $newBlockContent, $newBlockFooter | Out-String

              # 将合并的内容写回原始 HOSTS 文件
              $combinedContent | Set-Content $localHostsPath -Encoding ASCII
              Write-Output "已成功添加 AdobeNetBlock。"
          }
      } catch {
          Write-Error "处理过程中出错：$_"
      }

      # 清理临时文件
      Remove-Item $tempHostsPath -ErrorAction Ignore

      # 刷新 DNS 解析器缓存
      try {
          Invoke-Expression "ipconfig /flushdns"
          Write-Output "DNS 缓存已成功刷新。"
      } catch {
          Write-Error "刷新 DNS 缓存失败。错误：$_"
      }


```
## 撤销脚本

```powershell

      # 定义 HOSTS 文件的本地路径
      $localHostsPath = "C:\Windows\System32\drivers\etc\hosts"

      # 加载 HOSTS 文件的内容
      try {
          $hostsContent = Get-Content $localHostsPath -ErrorAction Stop
      } catch {
          Write-Error "加载 HOSTS 文件失败。错误：$_"
          return
      }

      # 初始化标志和新内容缓冲区
      $recording = $true
      $newContent = @()

      # 遍历 HOSTS 文件的每一行
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

      # 将筛选后的内容写回 HOSTS 文件
      try {
          $newContent | Set-Content $localHostsPath -Encoding ASCII
          Write-Output "已成功从 HOSTS 文件中删除 AdobeNetBlock 部分。"
      } catch {
          Write-Error "写回 HOSTS 文件失败。错误：$_"
      }

      # 刷新 DNS 解析器缓存
      try {
          Invoke-Expression "ipconfig /flushdns"
          Write-Output "DNS 缓存已成功刷新。"
      } catch {
          Write-Error "刷新 DNS 缓存失败。错误：$_"
      }


```

<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
