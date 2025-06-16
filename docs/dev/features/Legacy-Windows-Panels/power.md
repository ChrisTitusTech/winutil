# 电源面板

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Power Panel",
  "category": "Legacy Windows Panels",
  "panel": "2",
  "Type": "Button",
  "ButtonWidth": "300",
  "link": "https://christitustech.github.io/winutil/dev/features/Legacy-Windows-Panels/power"
}
```

</details>

## 函数：Invoke-WPFControlPanel

```powershell
function Invoke-WPFControlPanel {
    <#

    .SYNOPSIS
        打开请求的旧版面板

    .PARAMETER Panel
        要打开的面板

    #>
    param($Panel)

    switch ($Panel) {
        "WPFPanelcontrol" {cmd /c control}
        "WPFPanelnetwork" {cmd /c ncpa.cpl}
        "WPFPanelpower"   {cmd /c powercfg.cpl}
        "WPFPanelregion"  {cmd /c intl.cpl}
        "WPFPanelsound"   {cmd /c mmsys.cpl}
        "WPFPanelsystem"  {cmd /c sysdm.cpl}
        "WPFPaneluser"    {cmd /c "control userpasswords2"}
    }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/feature.json)
