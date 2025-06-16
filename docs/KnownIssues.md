## 启动问题

### 被杀毒软件阻止
Windows 安全中心（以前称为 Defender）和其他杀毒软件已知会阻止该脚本。该脚本被标记是因为它需要管理员权限并进行重大的系统更改。

要解决此问题，请在您的杀毒软件设置中允许/将脚本列入白名单，或暂时禁用实时保护。由于该项目是开源的，如果安全是您关心的问题，您可以审核代码。

### 下载不起作用
如果 `https://christitus.com/win` 不起作用，或者您想直接从 GitHub 下载代码，可以使用直接下载链接：

```ps1
irm https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1 | iex
```

如果您看到引用 TLS 或安全性的错误，则可能正在运行较旧版本的 Windows，其中 TLS 1.2 不是用于网络连接的默认安全协议。以下命令将强制 .NET 使用 TLS 1.2，并直接使用 .NET 而不是 PowerShell 下载脚本：

```ps1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
iex (New-Object Net.WebClient).DownloadString('https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1')
```

如果仍然不起作用并且您居住在印度，则可能是因为印度阻止了 GitHub 的内容域并阻止了下载。有关更多信息，请参阅[印度时报](https://timesofindia.indiatimes.com/gadgets-news/github-content-domain-blocked-for-these-indian-users-reports/articleshow/96687992.cms)。

如果您仍有问题，请尝试使用 **VPN**，或将您的 **DNS 提供商** 更改为以下两个提供商之一：

|   提供商   | 主 DNS  | 辅助 DNS |
|:------------:|:------------:|:-------------:|
| Cloudflare   | `1.1.1.1`    | `1.0.0.1`     |
| Google       | `8.8.8.8`    | `8.8.4.4`     |


### 脚本被执行策略阻止
1. 确保以管理员身份运行 PowerShell：按 `Windows 键`+`X` 并在 Windows 10 中选择 *PowerShell (管理员)*，或在 Windows 11 中选择 `Windows 终端 (管理员)`。
2. 在 PowerShell 窗口中，键入以下内容以允许执行未签名的代码并运行安装脚本：
    ```ps1
    Set-ExecutionPolicy Unrestricted -Scope Process -Force
    irm https://christitus.com/win | iex
    ```

## 运行时问题

### WinGet 配置
如果您以前从未使用 PowerShell 安装过任何内容，系统可能会提示您配置 WinGet。这需要在首次运行时进行用户交互。您需要手动在 PowerShell 控制台中键入 `y` 并按 Enter键才能继续。首次执行此操作后，将不再提示您。

### MicroWin：错误 `0x80041031`
此错误代码通常表示与 Windows Management Instrumentation (WMI) 相关的问题。您可以尝试以下几个步骤来解决该问题：

1. **重新启动计算机：**

    有时，简单的重新启动可以解决临时问题。重新启动计算机，然后再次尝试装载 ISO。

3. **检查系统损坏：**

    运行系统文件检查器 (SFC) 实用程序以扫描和修复可能已损坏的系统文件。
    ```powershell
    sfc /scannow
    ```

4. **更新您的系统：**

    确保您的操作系统是最新的。检查 Windows 更新并安装所有挂起的更新。

5. **检查 WMI 服务：**

    确保 Windows Management Instrumentation (WMI) 服务正在运行。您可以通过服务应用程序执行此操作：
    - 按 `Win`+`R` 打开“运行”对话框。
    - 键入 `services.msc` 并按 Enter。
    - 在列表中找到 *Windows Management Instrumentation*。
    - 确保将其状态设置为“正在运行”并将启动类型设置为“自动”。

6. **检查安全软件干扰：**

    安全软件有时会干扰 WMI 操作。暂时禁用您的防病毒软件或安全软件，然后检查问题是否仍然存在。WMI 是一种常见的攻击/感染媒介，因此许多防病毒程序会限制其使用。

7. **事件查看器：**

    检查事件查看器以获取更详细的错误信息。查找与 `80041031` 错误相关的条目，并检查是否有任何其他详细信息可以帮助确定原因。

    - 按 `Win`+`X` 并选择 *事件查看器*。
    - 导航到 *Windows 日志* > *应用程序* 或 *系统*。
    - 查找与 WMI 或用于装载 ISO 的应用程序相关的源条目。

8. **ISO 文件完整性：**

    确保您尝试装载的 ISO 文件未损坏。尝试装载另一个 ISO 文件以查看问题是否仍然存在。

如果尝试这些步骤后问题仍然存在，则需要进行其他故障排除。请考虑从 Microsoft 支持或社区论坛寻求帮助，以获取基于您的系统配置和用于装载 ISO 的软件的更具体的指导。

## Windows 问题

### Windows 关闭时间过长
这可能是由多种原因造成的：
- 打开快速启动：按 `Windows 键`+`R`，然后键入：
    ```bat
    control /name Microsoft.PowerOptions /page pageGlobalSettings
    ```
- 如果这不起作用，请禁用休眠：
    - 按 `Windows 键`+`X` 并在 Windows 10 中选择 *PowerShell (管理员)*，或在 Windows 11 中选择 `Windows 终端 (管理员)`。
    - 在 PowerShell 窗口中，键入：
        ```bat
        powercfg /H off
        ```
相关问题：[#69](https://github.com/ChrisTitusTech/winutil/issues/69)

### Windows 搜索不起作用
启用后台应用程序。相关问题：[#69](https://github.com/ChrisTitusTech/winutil/issues/69) [95](https://github.com/ChrisTitusTech/winutil/issues/95) [#232](https://github.com/ChrisTitusTech/winutil/issues/232)

### Xbox Game Bar 激活损坏
将 Xbox 配件管理服务设置为自动：

```ps1
Get-Service -Name "XboxGipSvc" | Set-Service -StartupType Automatic
```

相关问题：[#198](https://github.com/ChrisTitusTech/winutil/issues/198)

### Windows 11：快速设置不再起作用
启动脚本并单击*启用操作中心*。

### 资源管理器（文件浏览器）不再启动
 - 按 `Windows 键`+`R` 然后键入：
    ```bat
    control /name Microsoft.FolderOptions
    ```
- 将*打开文件资源管理器到*选项更改为*此电脑*。

### 电池耗电过快
如果您使用的是笔记本电脑或平板电脑，并且发现电池耗电过快，请尝试以下故障排除步骤，并将结果报告给 Winutil 社区。

1. **检查电池健康状况：**
    - 按 `Windows 键`+`X` 并在 Windows 10 中选择 *PowerShell (管理员)*，或在 Windows 11 中选择 `Windows 终端 (管理员)`。
    - 运行以下命令以生成电池报告：
        ```powershell
        powercfg /batteryreport /output "C:\battery_report.html"
        ```
    - 打开生成的 HTML 报告以查看有关电池健康状况和使用情况的信息。健康状况不佳的电池可能会减少电量、更快地放电或导致其他问题。

2. **查看电源设置：**
    - 打开“设置”应用，然后转到*系统* > *电源和睡眠*。
    - 根据您的偏好和使用模式调整电源计划设置。
    - 单击*其他电源设置*以访问可能有帮助的高级电源设置。

3. **识别耗电量大的应用程序：**
    - 右键单击任务栏并选择*任务管理器*。
    - 导航到*进程*选项卡以识别 CPU 或内存使用率高的应用程序。
    - 考虑重新配置、关闭、禁用或卸载占用大量资源的应用程序。

4. **更新驱动程序：**
    - 访问您的设备制造商的网站或使用 Windows 更新检查驱动程序更新。
    - 确保图形、芯片组和其他基本驱动程序是最新的。

5. **检查 Windows 更新：**
    - 打开“设置”应用，然后转到*更新和安全* > *Windows 更新*。
    - 检查并安装适用于您的操作系统的任何可用更新。

6. **降低屏幕亮度：**
    - 打开“设置”应用，然后转到*系统* > *显示*。
    - 根据您的偏好和照明条件调整屏幕亮度。

7. **启用节电模式：**
    - 打开“设置”应用，然后转到*系统* > *电池*。
    - 打开*节电模式*以限制后台活动并节省电量。

8. **检查设置中的电源使用情况：**
    - 打开“设置”应用，然后转到*系统* > *电池* > *按应用划分的电池使用情况*。
    - 查看应用程序列表及其电源使用情况。禁用或卸载您不需要的任何应用程序。

9. **检查后台应用程序：**
    - 打开“设置”应用，然后转到*隐私* > *后台应用*。
    - 禁用或卸载在后台运行的不必要的应用程序。

10. **使用 `powercfg` 进行分析：**
    - 按 `Windows 键`+`X` 并在 Windows 10 中选择 *PowerShell (管理员)*，或在 Windows 11 中选择 `Windows 终端 (管理员)`。
    - 运行以下命令以分析能源使用情况并生成报告：
        ```powershell
        powercfg /energy /output "C:\energy_report.html"
        ```
    - 打开生成的 HTML 报告以识别能源消耗模式。

11. **查看事件日志：**
    - 通过在“开始”菜单中搜索来打开事件查看器。
    - 导航到*Windows 日志* > *系统*。
    - 查找源为 *Power-Troubleshooter* 的事件以识别与电源相关的事件。这些事件可能会突出显示电池、输入电源和其他问题。

12. **检查唤醒源：**
    - 按 `Windows 键`+`X` 并在 Windows 10 中选择 *PowerShell (管理员)*，或在 Windows 11 中选择 `Windows 终端 (管理员)`。
    - 使用命令 `powercfg /requests` 识别阻止睡眠的进程。
    - 使用命令 `powercfg /waketimers` 查看活动的唤醒计时器。
    - 检查任务计划程序以查看是否有任何发现的进程计划在启动时或定期启动。

13. **高级识别耗电量大的应用程序：**
    - 从“开始”菜单打开资源监视器。
    - 导航到 *CPU*、*内存*、*网络* 和其他选项卡以识别资源使用率高的进程。
    - 考虑重新配置、关闭、禁用或卸载占用大量资源的应用程序。

14. **禁用活动历史记录：**
    - 打开“设置”应用，然后转到*隐私* > *活动历史记录*。
    - 关闭*让 Windows 从此电脑收集我的活动*。

15. **阻止网络适配器唤醒电脑：**
    - 通过在“开始”菜单中搜索来打开设备管理器。
    - 找到您的网络适配器，右键单击，然后转到*属性*。
    - 在*电源管理*选项卡下，取消选中允许设备唤醒计算机的选项。

16. **查看已安装的应用程序：**
    - 通过在“开始”菜单中搜索*添加或删除程序*来手动查看已安装的应用程序。
    - 检查各个应用程序的设置/首选项以查找与电源相关的选项。
    - 卸载不必要或有问题的软件。

这些故障排除步骤是通用的，但在大多数情况下应该会有所帮助。您应该记住以下要点：
- 电池健康状况是设备运行时间的最大限制因素。健康状况不佳的电池通常无法通过关闭某些应用程序来像以前一样持久。请考虑更换电池。
- 在后台运行的应用程序会占用 CPU 和内存、发出大量或大型网络请求、频繁读/写磁盘，或者在电脑可以节省能源时使其保持唤醒状态，这些是下一个主要问题。避免安装不需要的程序，仅使用您信任的程序，并将应用程序配置为尽可能少地使用电源并尽可能不频繁地运行。
- Windows 默认执行许多可能影响电池续航时间的任务。更改设置、停止计划任务和禁用功能可以帮助系统保持在较低功耗状态以节省电池。
- 劣质充电器、不稳定的电源输入和高温会导致电池退化和更快地放电。使用值得信赖的高质量充电器，确保电源输入稳定，清洁任何风扇或气流端口，并保持电池/电脑凉爽。
