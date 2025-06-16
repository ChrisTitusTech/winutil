# 禁用全屏优化

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**
## 描述

在所有应用程序中禁用 FSO。注意：这将在独占全屏模式下禁用颜色管理

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Disable Fullscreen Optimizations",
  "Description": "Disables FSO in all applications. NOTE: This will disable Color Management in Exclusive Fullscreen",
  "category": "z__Advanced Tweaks - CAUTION",
  "panel": "1",
  "Order": "a024_",
  "registry": [
    {
      "Path": "HKCU:\\System\\GameConfigStore",
      "Name": "GameDVR_DXGIHonorFSEWindowsCompatible",
      "Value": "1",
      "OriginalValue": "0",
      "Type": "DWord"
    }
  ],
  "link": "https://christitustech.github.io/winutil/dev/tweaks/z--Advanced-Tweaks---CAUTION/DisableFSO"
}
```

</details>

## 注册表更改
应用程序和系统组件存储和检索配置数据以修改 Windows 设置，因此我们可以使用注册表在一个位置更改许多设置。


您可以在 [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) 和 [Microsoft 网站](https://learn.microsoft.com/zh-cn/windows/win32/sysinfo/registry)上找到有关注册表的信息。

### 注册表项：GameDVR_DXGIHonorFSEWindowsCompatible

**类型：** DWord

**原始值：** 0

**新值：** 1



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
