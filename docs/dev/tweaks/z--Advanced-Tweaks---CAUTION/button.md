# 运行调整

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Run Tweaks",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a041_",
  "Type": "Button",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/button"
}
```

</details>

## 函数：Invoke-WPFtweaksbutton

```powershell
function Invoke-WPFtweaksbutton {
  <#

    .SYNOPSIS
        调用与每组复选框关联的函数

  #>

  if($sync.ProcessRunning) {
    $msg = "[Invoke-WPFtweaksbutton] 安装过程当前正在运行。"
    [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    return
  }

  $Tweaks = (Get-WinUtilCheckBoxes)["WPFTweaks"]

  Set-WinUtilDNS -DNSProvider $sync["WPFchangedns"].text

  if ($tweaks.count -eq 0 -and  $sync["WPFchangedns"].text -eq "Default") {
    $msg = "请选中您希望执行的调整。"
    [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
    return
  }

  Write-Debug "要处理的调整数量：$($Tweaks.Count)"

  Invoke-WPFRunspace -ArgumentList $Tweaks -DebugPreference $DebugPreference -ScriptBlock {
    param($Tweaks, $DebugPreference)
    Write-Debug "内部要处理的调整数量：$($Tweaks.Count)"

    $sync.ProcessRunning = $true

    if ($Tweaks.count -eq 1) {
        $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo" })
    } else {
        $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Normal" -value 0.01 -overlay "logo" })
    }
    # 执行其他选定的调整

    for ($i = 0; $i -lt $Tweaks.Count; $i++) {
      Set-WinUtilProgressBar -Label "正在应用 $($tweaks[$i])" -Percent ($i / $Tweaks.Count * 100)
      Invoke-WinUtilTweaks $tweaks[$i]$sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -value ($i/$Tweaks.Count) })
    }
    Set-WinUtilProgressBar -Label "调整已完成" -Percent 100
    $sync.ProcessRunning = $false
    $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" })
    Write-Host "================================="
    Write-Host "--     调整已完成    ---"
    Write-Host "================================="

    # $ButtonType = [System.Windows.MessageBoxButton]::OK
    # $MessageboxTitle = "调整已完成 "
    # $Messageboxbody = ("完成")
    # $MessageIcon = [System.Windows.MessageBoxImage]::Information
    # [System.Windows.MessageBox]::Show($Messageboxbody, $MessageboxTitle, $ButtonType, $MessageIcon)
  }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
