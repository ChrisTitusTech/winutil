# Adobe 精简

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

管理 Adobe 服务、Adobe 桌面服务和 Acrobat 更新

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Adobe Debloat",
  "Description": "Manages Adobe Services, Adobe Desktop Service, and Acrobat Updates",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a021_",
  "InvokeScript": [
    "
      function CCStopper {
        $path = \"C:\\Program Files (x86)\\Common Files\\Adobe\\Adobe Desktop Common\\ADS\\Adobe Desktop Service.exe\"

        # Test if the path exists before proceeding
        if (Test-Path $path) {
            Takeown /f $path
            $acl = Get-Acl $path
            $acl.SetOwner([System.Security.Principal.NTAccount]\"Administrators\")
            $acl | Set-Acl $path

            Rename-Item -Path $path -NewName \"Adobe Desktop Service.exe.old\" -Force
        } else {
            Write-Host \"Adobe Desktop Service is not in the default location.\"
        }
      }


      function AcrobatUpdates {
        # Editing Acrobat Updates. The last folder before the key is dynamic, therefore using a script.
        # Possible Values for the edited key:
        # 0 = Do not download or install updates automatically
        # 2 = Automatically download updates but let the user choose when to install them
        # 3 = Automatically download and install updates (default value)
        # 4 = Notify the user when an update is available but don't download or install it automatically
        #   = It notifies the user using Windows Notifications. It runs on startup without having to have a Service/Acrobat/Reader running, therefore 0 is the next best thing.

        $rootPath = \"HKLM:\\SOFTWARE\\WOW6432Node\\Adobe\\Adobe ARM\\Legacy\\Acrobat\"

        # Get all subkeys under the specified root path
        $subKeys = Get-ChildItem -Path $rootPath | Where-Object { $_.PSChildName -like \"{*}\" }

        # Loop through each subkey
        foreach ($subKey in $subKeys) {
            # Get the full registry path
            $fullPath = Join-Path -Path $rootPath -ChildPath $subKey.PSChildName
            try {
                Set-ItemProperty -Path $fullPath -Name Mode -Value 0
                Write-Host \"Acrobat Updates have been disabled.\"
            } catch {
                Write-Host \"Registry Key for changing Acrobat Updates does not exist in $fullPath\"
            }
        }
      }

      CCStopper
      AcrobatUpdates
      "
  ],
  "UndoScript": [
    "
      function RestoreCCService {
        $originalPath = \"C:\\Program Files (x86)\\Common Files\\Adobe\\Adobe Desktop Common\\ADS\\Adobe Desktop Service.exe.old\"
        $newPath = \"C:\\Program Files (x86)\\Common Files\\Adobe\\Adobe Desktop Common\\ADS\\Adobe Desktop Service.exe\"

        if (Test-Path -Path $originalPath) {
            Rename-Item -Path $originalPath -NewName \"Adobe Desktop Service.exe\" -Force
            Write-Host \"Adobe Desktop Service has been restored.\"
        } else {
            Write-Host \"Backup file does not exist. No changes were made.\"
        }
      }

      function AcrobatUpdates {
        # Default Value:
        # 3 = Automatically download and install updates

        $rootPath = \"HKLM:\\SOFTWARE\\WOW6432Node\\Adobe\\Adobe ARM\\Legacy\\Acrobat\"

        # Get all subkeys under the specified root path
        $subKeys = Get-ChildItem -Path $rootPath | Where-Object { $_.PSChildName -like \"{*}\" }

        # Loop through each subkey
        foreach ($subKey in $subKeys) {
            # Get the full registry path
            $fullPath = Join-Path -Path $rootPath -ChildPath $subKey.PSChildName
            try {
                Set-ItemProperty -Path $fullPath -Name Mode -Value 3
            } catch {
                Write-Host \"Registry Key for changing Acrobat Updates does not exist in $fullPath\"
            }
        }
      }

      RestoreCCService
      AcrobatUpdates
      "
  ],
  "service": [
    {
      "Name": "AGSService",
      "StartupType": "Disabled",
      "OriginalType": "Automatic"
    },
    {
      "Name": "AGMService",
      "StartupType": "Disabled",
      "OriginalType": "Automatic"
    },
    {
      "Name": "AdobeUpdateService",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "Adobe Acrobat Update",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "Adobe Genuine Monitor Service",
      "StartupType": "Disabled",
      "OriginalType": "Automatic"
    },
    {
      "Name": "AdobeARMservice",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "Adobe Licensing Console",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "CCXProcess",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "AdobeIPCBroker",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    },
    {
      "Name": "CoreSync",
      "StartupType": "Manual",
      "OriginalType": "Automatic"
    }
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/DebloatAdobe"
}
```

</details>

## 调用脚本

```powershell

      function CCStopper {
        $path = "C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\ADS\Adobe Desktop Service.exe"

        # 在继续之前测试路径是否存在
        if (Test-Path $path) {
            Takeown /f $path
            $acl = Get-Acl $path
            $acl.SetOwner([System.Security.Principal.NTAccount]"Administrators")
            $acl | Set-Acl $path

            Rename-Item -Path $path -NewName "Adobe Desktop Service.exe.old" -Force
        } else {
            Write-Host "Adobe 桌面服务不在默认位置。"
        }
      }


      function AcrobatUpdates {
        # 编辑 Acrobat 更新。密钥之前的最后一个文件夹是动态的，因此使用脚本。
        # 编辑密钥的可能值：
        # 0 = 不自动下载或安装更新
        # 2 = 自动下载更新，但让用户选择何时安装
        # 3 = 自动下载并安装更新（默认值）
        # 4 = 当有可用更新时通知用户，但不自动下载或安装
        #   = 它使用 Windows 通知通知用户。它在启动时运行，无需运行服务/Acrobat/Reader，因此 0 是次优选择。

        $rootPath = "HKLM:\SOFTWARE\WOW6432Node\Adobe\Adobe ARM\Legacy\Acrobat"

        # 获取指定根路径下的所有子项
        $subKeys = Get-ChildItem -Path $rootPath | Where-Object { $_.PSChildName -like "{*}" }

        # 遍历每个子项
        foreach ($subKey in $subKeys) {
            # 获取完整的注册表路径
            $fullPath = Join-Path -Path $rootPath -ChildPath $subKey.PSChildName
            try {
                Set-ItemProperty -Path $fullPath -Name Mode -Value 0
                Write-Host "Acrobat 更新已禁用。"
            } catch {
                Write-Host "用于更改 Acrobat 更新的注册表项在 $fullPath 中不存在"
            }
        }
      }

      CCStopper
      AcrobatUpdates


```
## 撤销脚本

```powershell

      function RestoreCCService {
        $originalPath = "C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\ADS\Adobe Desktop Service.exe.old"
        $newPath = "C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\ADS\Adobe Desktop Service.exe"

        if (Test-Path -Path $originalPath) {
            Rename-Item -Path $originalPath -NewName "Adobe Desktop Service.exe" -Force
            Write-Host "Adobe 桌面服务已还原。"
        } else {
            Write-Host "备份文件不存在。未进行任何更改。"
        }
      }

      function AcrobatUpdates {
        # 默认值：
        # 3 = 自动下载并安装更新

        $rootPath = "HKLM:\SOFTWARE\WOW6432Node\Adobe\Adobe ARM\Legacy\Acrobat"

        # 获取指定根路径下的所有子项
        $subKeys = Get-ChildItem -Path $rootPath | Where-Object { $_.PSChildName -like "{*}" }

        # 遍历每个子项
        foreach ($subKey in $subKeys) {
            # 获取完整的注册表路径
            $fullPath = Join-Path -Path $rootPath -ChildPath $subKey.PSChildName
            try {
                Set-ItemProperty -Path $fullPath -Name Mode -Value 3
            } catch {
                Write-Host "用于更改 Acrobat 更新的注册表项在 $fullPath 中不存在"
            }
        }
      }

      RestoreCCService
      AcrobatUpdates


```
## 服务更改

Windows 服务是用于系统功能或应用程序的后台进程。将某些服务设置为手动可以通过仅在需要时启动它们来优化性能。

您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_service) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/dotnet/framework/windows-services/introduction-to-windows-service-applications)上找到有关服务的信息。

### 服务名称：AGSService

**启动类型：** 已禁用

**原始类型：** 自动

### 服务名称：AGMService

**启动类型：** 已禁用

**原始类型：** 自动

### 服务名称：AdobeUpdateService

**启动类型：** 手动

**原始类型：** 自动

### 服务名称：Adobe Acrobat Update

**启动类型：** 手动

**原始类型：** 自动

### 服务名称：Adobe Genuine Monitor Service

**启动类型：** 已禁用

**原始类型：** 自动

### 服务名称：AdobeARMservice

**启动类型：** 手动

**原始类型：** 自动

### 服务名称：Adobe Licensing Console

**启动类型：** 手动

**原始类型：** 自动

### 服务名称：CCXProcess

**启动类型：** 手动

**原始类型：** 自动

### 服务名称：AdobeIPCBroker

**启动类型：** 手动

**原始类型：** 自动

### 服务名称：CoreSync

**启动类型：** 手动

**原始类型：** 自动



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
