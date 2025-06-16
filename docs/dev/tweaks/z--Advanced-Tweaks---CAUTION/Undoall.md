# 撤销选定的调整

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Undo Selected Tweaks",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a042_",
  "Type": "Button",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/Undoall"
}
```

</details>

## 函数：Invoke-WPFundoall

```powershell
function Invoke-WPFundoall {
    <#

    .SYNOPSIS
        撤销每个选定的调整

    #>

    if($sync.ProcessRunning) {
        $msg = "[Invoke-WPFundoall] 安装过程当前正在运行。"
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    $tweaks = (Get-WinUtilCheckBoxes)["WPFtweaks"]

    if ($tweaks.count -eq 0) {
        $msg = "请选中您希望撤销的调整。"
        [System.Windows.MessageBox]::Show($msg, "Winutil", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning)
        return
    }

    Invoke-WPFRunspace -ArgumentList $tweaks -DebugPreference $DebugPreference -ScriptBlock {
        param($tweaks, $DebugPreference)

        $sync.ProcessRunning = $true
        if ($tweaks.count -eq 1) {
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Indeterminate" -value 0.01 -overlay "logo" })
        } else {
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "Normal" -value 0.01 -overlay "logo" })
        }


        for ($i = 0; $i -lt $tweaks.Count; $i++) {
            Set-WinUtilProgressBar -Label "正在撤销 $($tweaks[$i])" -Percent ($i / $tweaks.Count * 100)
            Invoke-WinUtiltweaks $tweaks[$i] -undo $true
            $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -value ($i/$tweaks.Count) })
        }

        Set-WinUtilProgressBar -Label "撤销调整已完成" -Percent 100
        $sync.ProcessRunning = $false
        $sync.form.Dispatcher.Invoke([action]{ Set-WinUtilTaskbaritem -state "None" -overlay "checkmark" })
        Write-Host "=================================="
        Write-Host "---  撤销调整已完成  ---"
        Write-Host "=================================="

    }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
