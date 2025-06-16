# 删除卓越性能配置文件

最后更新时间：2024-08-07


!!! info
     开发文档是在每次编译 WinUtil 时自动生成的，这意味着其中一部分将始终保持最新状态。**开发人员确实可以添加自定义内容，这些内容不会自动更新。**


<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>预览代码</summary>

```json
{
  "Content": "Remove Ultimate Performance Profile",
  "category": "Performance Plans",
  "panel": "2",
  "Order": "a081_",
  "Type": "Button",
  "ButtonWidth": "300",
  "link": "https://christitustech.github.io/winutil/dev/tweaks/Performance-Plans/RemoveUltPerf"
}
```

</details>

## 函数：Invoke-WPFUltimatePerformance

```powershell
Function Invoke-WPFUltimatePerformance {
    <#

    .SYNOPSIS
        创建或删除卓越性能电源计划

    .PARAMETER State
        指示是启用还是禁用卓越性能电源计划

    #>
    param($State)
    try {
        # 检查是否安装了卓越性能计划
        $ultimatePlan = powercfg -list | Select-String -Pattern "Ultimate Performance"
        if($state -eq "Enable") {
            if ($ultimatePlan) {
                Write-Host "卓越性能计划已安装。"
            } else {
                Write-Host "正在安装卓越性能计划..."
                powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
                Write-Host "> 卓越性能计划已安装。"
            }

            # 将卓越性能计划设置为活动状态
            $ultimatePlanGUID = (powercfg -list | Select-String -Pattern "Ultimate Performance").Line.Split()[3]
            powercfg -setactive $ultimatePlanGUID

            Write-Host "卓越性能计划现已激活。"


        }
        elseif($state -eq "Disable") {
            if ($ultimatePlan) {
                # 提取卓越性能计划的 GUID
                $ultimatePlanGUID = $ultimatePlan.Line.Split()[3]

                # 在删除卓越性能计划之前将其他电源计划设置为活动状态
                $balancedPlanGUID = (powercfg -list | Select-String -Pattern "Balanced").Line.Split()[3]
                powercfg -setactive $balancedPlanGUID

                # 删除卓越性能计划
                powercfg -delete $ultimatePlanGUID

                Write-Host "卓越性能计划已卸载。"
                Write-Host "> 平衡计划现已激活。"
            } else {
                Write-Host "未安装卓越性能计划。"
            }
        }
    } catch {
        Write-Warning $psitem.Exception.Message
    }
}

```


<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[查看 JSON 文件](https://github.com/ChrisTitusTech/winutil/tree/main/config/tweaks.json)
