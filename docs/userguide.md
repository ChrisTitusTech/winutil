# 演练

## 安装
---

=== "安装和更新"

    * 选择您要安装或升级的程序。
        * 对于当前未安装的程序，此操作将安装它们。
        * 对于已安装的程序，此操作将将其更新到最新版本。
    * 单击 `安装/升级选定项` 按钮开始安装或升级过程。

=== "全部升级"

    * 只需按 `全部升级` 按钮。
    * 这将升级所有已安装的适用程序，无需单独选择。

=== "卸载"

    * 选择您要卸载的程序。
    * 单击 `卸载选定项` 按钮以删除选定的程序。

=== "获取已安装的"

    * 单击 `获取已安装的` 按钮。
    * 这将扫描并选择 WinUtil 中 WinGet 支持的所有已安装程序。

=== "清除选择"
    * 单击 `清除选择` 按钮。
    * 这将取消选择所有已选中的程序。

=== "首选 Chocolatey"
    * 选中 `首选 Chocolatey` 复选框
    * 默认情况下，Winutil 将使用 winget 安装/升级/删除软件包，并在失败时回退到 Chocolatey。此选项反转了偏好设置。
    * 此偏好设置将用于“安装”页面上的所有按钮，并在 Winutil 重新启动后保持不变。

![安装图片](assets/Install-Tab-Dark.png#only-dark#gh-dark-mode-only)
![安装图片](assets/Install-Tab-Light.png#only-light#gh-light-mode-only)

!!! tip

     如果您在查找应用程序时遇到困难，请按 `ctrl + f` 并搜索其名称。应用程序将根据您的输入进行筛选。

## 调整
---

![调整图片](assets/Tweaks-Tab-Dark.png#only-dark#gh-dark-mode-only)
![调整图片](assets/Tweaks-Tab-Light.png#only-light#gh-light-mode-only)

### 运行调整
* **打开调整选项卡**：导航到应用程序中的“调整”选项卡。
* **选择调整**：选择要应用的调整。为方便起见，您可以使用顶部的可用预设。
* **运行调整**：选择所需的调整后，单击屏幕底部的“运行调整”按钮。

### 撤销调整
* **打开调整选项卡**：转到“安装”旁边的“调整”选项卡。
* **选择要删除的调整**：选择要禁用或删除的调整。
* **撤销调整**：单击屏幕底部的“撤销选定的调整”按钮以应用更改。

### 基本调整
基本调整是大多数用户可以安全实施的修改和优化。这些调整旨在增强系统性能、提高隐私并减少不必要的系统活动。它们被认为是低风险的，建议希望确保系统平稳高效运行而无需深入研究复杂配置的用户使用。基本调整的目标是以最小的风险提供显着的改进，使其适用于广泛的用户，包括那些可能不具备高级技术知识的用户。

### 高级调整 - 注意
高级调整适用于对自己的系统以及进行深层更改的潜在影响有深入了解的经验丰富的用户。这些调整涉及对操作系统的更重大更改，并且可以提供实质性的自定义。但是，如果实施不当，它们也更有可能导致系统不稳定或意外的副作用。选择应用高级调整的用户应谨慎操作，确保他们拥有足够的知识和备份，以便在出现问题时进行恢复。不建议新手用户或不熟悉其操作系统内部工作原理的用户使用这些调整。

### O&O Shutup


[O&O ShutUp10++](https://www.oo-software.com/en/shutup10) 只需单击一下按钮即可从 WinUtil 启动。它是一款适用于 Windows 的免费隐私工具，可让用户轻松管理其隐私设置。它可以禁用遥测、控制更新并管理应用程序权限以增强安全性和隐私性。该工具只需单击几下即可提供建议的设置以实现最佳隐私。

<iframe width="640" height="360" src="https://www.youtube.com/embed/3HvNr8eMcv0" title="O&O ShutUp10++：适用于 Windows 10 和 11，具有深色模式" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>


### DNS

该实用程序提供了一个方便的 DNS 选择功能，允许用户在各种 DNS 提供商之间选择 IPv4 和 IPv6。这使用户能够根据其特定需求优化其互联网连接的速度、安全性和隐私性。以下是可用选项：

* **默认**：使用 ISP 或网络配置的默认 DNS 设置。
* **DHCP**：自动从 DHCP 服务器获取 DNS 设置。
* [**Google**](https://developers.google.com/speed/public-dns?hl=en)：由 Google 提供的可靠且快速的 DNS 服务。
* [**Cloudflare**](https://developers.cloudflare.com/1.1.1.1/)：以速度和隐私着称，Cloudflare DNS 是增强互联网性能的热门选择。
* [**Cloudflare_Malware**](https://developers.cloudflare.com/1.1.1.1/setup/#:~:text=Use%20the%20following%20DNS%20resolvers%20to%20block%20malicious%20content%3A)：通过阻止恶意软件站点提供额外的保护。
* [**Cloudflare_Malware_Adult**](https://developers.cloudflare.com/1.1.1.1/setup/#:~:text=Use%20the%20following%20DNS%20resolvers%20to%20block%20malware%20and%20adult%20content%3A)：阻止恶意软件和成人内容，提供更全面的过滤。
* [**Open_DNS**](https://www.opendns.com/setupguide/#familyshield)：提供可自定义的过滤和增强的安全功能。
* [**Quad9**](https://quad9.net/)：通过阻止已知的恶意域来关注安全性。
* [**AdGuard_Ads_Trackers**](https://adguard-dns.io/en/welcome.html) AdGuard DNS 将阻止广告、跟踪器或任何其他 DNS 请求。访问网站并登录以获取仪表板、统计信息并在服务器设置中自定义您的体验。
* [**AdGuard_Ads_Trackers_Malware_Adult**](https://adguard-dns.io/en/welcome.html) AdGuard DNS 将阻止广告、跟踪器、成人内容，并在可能的情况下启用安全搜索和安全模式。
* [**dns0.eu_Open**](https://www.dns0.eu/) 使您的互联网更安全的欧洲公共 DNS。提供通用过滤以阻止恶意软件、网络钓鱼和跟踪域，从而增强隐私和安全性。
* [**dns0.eu_ZERO**](https://www.dns0.eu/zero) 通过强大的过滤器为高度敏感的环境提供高级安全性，使用威胁情报和复杂启发式算法（如新注册域 (NRD) 和域生成算法 (DGA)）阻止高风险域。
* [**dns0.eu_KIDS**](https://www.dns0.eu/kids) 一种儿童安全的 DNS，可阻止成人内容、露骨的搜索结果、成熟视频、约会网站、盗版和广告，从而在任何设备或网络上为儿童创造安全的互联网体验。

### 自定义首选项

“自定义首选项”部分允许用户通过切换各种视觉和功能特性来个性化其 Windows 体验。这些首选项旨在增强可用性并根据用户的特定需求和偏好定制系统。

### 性能计划

“性能计划”部分允许用户管理其系统上的“卓越性能配置文件”。此功能旨在优化系统以获得最大性能。

#### 添加并激活卓越性能配置文件：
* 启用并激活卓越性能配置文件，通过最大限度地减少延迟和提高效率来增强系统性能。
#### 删除卓越性能配置文件：
* 停用卓越性能配置文件，将系统更改为平衡配置文件。

### 快捷方式

该实用程序包含一个可轻松创建桌面快捷方式的功能，从而可以快速访问脚本。

## 配置
---

### 功能
* 通过选中复选框并单击“安装功能”来安装最常用的 **Windows 功能**。

* 所有 .Net Framework (2, 3, 4)
* HyperV 虚拟化
* 旧版媒体 (WMP, DirectPlay)
* NFS - 网络文件系统
* 在注册表中启用搜索框 Web 建议（资源管理器重新启动）
* 在注册表中禁用搜索框 Web 建议（资源管理器重新启动）
* 启用每日注册表备份任务（凌晨 12:30）
* 启用旧版 F8 启动恢复
* 禁用旧版 F8 启动恢复
* 适用于 Linux 的 Windows 子系统
* Windows Sandbox

### 修复
* 如果您遇到问题，可以快速修复您的系统。

* 设置自动登录
* 重置 Windows 更新
* 重置网络
* 系统损坏扫描
* WinGet 重新安装
* 删除 Adobe Creative Cloud

### 旧版 Windows 面板

直接从 WinUtil 打开旧版 Windows 面板。以下面板可用：

* 控制面板
* 网络连接
* 电源面板
* 区域
* 声音设置
* 系统属性
* 用户帐户

### 远程访问

在您的 Windows 计算机上启用 OpenSSH 服务器。

## 更新
---

该实用程序提供了三种不同的设置来管理 Windows 更新：“默认（开箱即用）设置”、“安全（推荐）设置”和“禁用所有更新（不推荐！）”。每种设置都提供了不同的更新处理方法，以满足各种用户需求和偏好。

### 默认（开箱即用）设置
- **说明**：此设置保留 Windows 附带的默认配置，确保不进行任何修改。
- **功能**：它将删除以前应用的任何自定义 Windows 更新设置。
- **注意**：如果更新错误仍然存在，请在配置选项卡中重置所有更新，以将所有 Microsoft 更新服务恢复到其默认设置，并从其服务器重新安装它们。

### 安全（推荐）设置
- **说明**：这是所有计算机的推荐设置。
- **更新计划**：
    - **功能更新**：将功能更新延迟 2 年，以避免潜在的错误和不稳定。
    - **安全更新**：在发布 4 天后安装安全更新，以确保系统免受紧迫的安全漏洞的侵害。
- **基本原理**：
    - **功能更新**：通常会引入新功能和错误；延迟这些更新可以最大限度地降低系统中断的风险。
    - **安全更新**：对于修补关键安全漏洞至关重要。将其延迟几天可以验证稳定性和兼容性，而不会使系统长时间暴露在外。

### 禁用所有更新（不推荐！）
- **说明**：此设置完全禁用所有 Windows 更新。
- **适用性**：可能适用于用于不需要主动浏览互联网的特定目的的系统。
- **警告**：禁用更新会因缺乏安全补丁而显着增加系统被黑客入侵或感染的风险。
- **注意**：由于安全风险增加，强烈建议不要使用此设置。

!!! bug

     “更新”选项卡当前无法使用。我们正在积极努力解决问题以恢复其功能。

## MicroWin
---

* **MicroWin** 允许您通过根据需要进行精简来自定义 Windows 10 和 11 安装映像。

![Microwin](assets/Microwin-Dark.png#only-dark#gh-dark-mode-only)
![Microwin](assets/Microwin-Light.png#only-light#gh-light-mode-only)

#### 基本用法

1. 指定要自定义的源 Windows ISO。

    * 如果您没有准备好 Windows ISO 文件，可以使用相应 Windows 版本的媒体创建工具下载它。[此处](https://go.microsoft.com/fwlink/?linkid=2156295)是 Windows 11 版本，[此处](https://go.microsoft.com/fwlink/?LinkId=2265055)是 Windows 10 版本

2. 配置精简过程。
3. 指定新 ISO 文件的目标位置。
4. 见证奇迹发生！

!!! warning "注意"

     此功能仍在开发中，您可能会遇到一些生成的映像的问题。如果发生这种情况，请随时报告问题！

#### 选项

* **从 CTT GitHub 仓库下载 oscdimg.exe** 将从 GitHub 仓库而不是 Chocolatey 软件包中获取 OSCDIMG 可执行文件。

!!! info

     OSCDIMG 是允许程序创建 ISO 映像的工具。通常，您可以在 [Windows 评估和部署工具包](https://learn.microsoft.com/en-us/windows-hardware/get-started/adk-install) 中找到它

* 选择临时目录会将 ISO 文件的内容复制到您指定的目录，而不是 `%TEMP%` 目录中自动生成的文件夹。
* 您可以使用方便的下拉菜单选择要精简的 Windows 版本 (**SKU**)。

默认情况下，MicroWin 将精简 Pro 版本，但您可以选择任何您想要的版本。


##### 驱动程序集成选项

* **注入驱动程序** 会将您在指定文件夹中的驱动程序添加到目标 Windows 映像中。
* **从当前系统导入驱动程序** 将添加活动安装中存在的所有第三方驱动程序。

这使得目标映像具有与活动安装相同的硬件兼容性。但是，这意味着您只能在具有**相同硬件**的计算机上安装目标 Windows 映像并充分利用它。为避免这种情况，您需要在 `sources` 文件夹中自定义目标 ISO 的 `install.wim` 文件。

##### 自定义用户设置

使用 MicroWin，如果您不想使用默认的 `User` 帐户，也可以在继续之前配置您的用户。为此，只需键入帐户名称（最多 20 个字符）和密码即可。然后，让 MicroWin 完成其余的工作。

!!! info

     请确保记住您的密码。MicroWin 将配置自动登录设置，因此您无需输入密码。但是，如果要求您输入密码，最好不要忘记它。


##### Ventoy 选项

* **复制到 Ventoy** 会将目标 ISO 文件复制到安装了 [Ventoy](https://ventoy.net/en/index.html) 的任何 USB 驱动器
!!! info

     Ventoy 是一种解决方案，可让您启动存储在驱动器上的任何 ISO 文件。可以将其视为将多个可启动 USB 集于一身。但请注意，您的驱动器需要有足够的可用空间来容纳目标 ISO 文件。

## 自动化

* 某些功能可通过自动化实现。这使您可以保存配置文件，将其传递给 WinUtil，然后离开，回来时系统已完成配置。以下是目前如何使用 Winutil >24.01.15 进行设置的方法

* 在“安装”选项卡上，单击“获取已安装的”，这将获取系统上**受 Winutil 支持的**所有已安装应用程序。
![GetInstalled](assets/Get-Installed-Dark.png#only-dark#gh-dark-mode-only)
![GetInstalled](assets/Get-Installed-Light.png#only-light#gh-light-mode-only)

* 单击右上角的设置齿轮，然后选择“导出”。选择文件和位置；这将导出设置文件。
![SettingsExport](assets/Settings-Export-Dark.png#only-dark#gh-dark-mode-only)
![SettingsExport](assets/Settings-Export-Light.png#only-light#gh-light-mode-only)

* 将此文件复制到 USB 或 Windows 安装后可以使用的某个位置。

!!! tip

     使用 Microwin 选项卡创建自定义 Windows 映像并安装 Windows 映像。

* 在任何受支持的 Windows 计算机上，以**管理员身份**打开 PowerShell 并运行以下命令以自动应用调整并从配置文件安装应用程序。
    ```ps1
    iex "& { $(irm https://christitus.com/win) } -Config [path-to-your-config] -Run"
    ```
* 喝杯咖啡吧！完成后再回来。
