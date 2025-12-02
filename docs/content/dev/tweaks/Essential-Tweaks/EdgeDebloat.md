# Debloat Edge

Last Updated: 2024-08-07


> [!NOTE]
     The Development Documentation is auto generated for every compilation of Winutil, meaning a part of it will always stay up-to-date. **Developers do have the ability to add custom content, which won't be updated automatically.**
## Description

Disables various telemetry options, popups, and other annoyances in Edge.

<!-- BEGIN CUSTOM CONTENT -->

<!-- END CUSTOM CONTENT -->

<details>
<summary>Preview Code</summary>

```json
{
  "Content": "Debloat Edge",
  "Description": "Disables various telemetry options, popups, and other annoyances in Edge.",
  "category": "Essential Tweaks",
  "panel": "1",
  "Order": "a016_",
  "registry": [
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\EdgeUpdate",
      "Name": "CreateDesktopShortcutDefault",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "EdgeEnhanceImagesEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "PersonalizationReportingEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "ShowRecommendationsEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "HideFirstRunExperience",
      "Type": "DWord",
      "Value": "1",
      "OriginalValue": "0"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "UserFeedbackAllowed",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "ConfigureDoNotTrack",
      "Type": "DWord",
      "Value": "1",
      "OriginalValue": "0"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "AlternateErrorPagesEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "EdgeCollectionsEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "EdgeFollowEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "EdgeShoppingAssistantEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "MicrosoftEdgeInsiderPromotionEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "PersonalizationReportingEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "ShowMicrosoftRewards",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "WebWidgetAllowed",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "DiagnosticData",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "EdgeAssetDeliveryServiceEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "EdgeCollectionsEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "CryptoWalletEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "ConfigureDoNotTrack",
      "Type": "DWord",
      "Value": "1",
      "OriginalValue": "0"
    },
    {
      "Path": "HKLM:\\SOFTWARE\\Policies\\Microsoft\\Edge",
      "Name": "WalletDonationEnabled",
      "Type": "DWord",
      "Value": "0",
      "OriginalValue": "1"
    }
  ],
  "link": "https://christitustech.github.io/Winutil/dev/tweaks/Essential-Tweaks/EdgeDebloat"
}
```

</details>

## Registry Changes
Applications and System Components store and retrieve configuration data to modify windows settings, so we can use the registry to change many settings in one place.


You can find information about the registry on [Wikipedia](https://www.wikiwand.com/en/Windows_Registry) and [Microsoft's Website](https://learn.microsoft.com/en-us/windows/win32/sysinfo/registry).

### Registry Key: CreateDesktopShortcutDefault

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: EdgeEnhanceImagesEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: PersonalizationReportingEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: ShowRecommendationsEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: HideFirstRunExperience

**Type:** DWord

**Original Value:** 0

**New Value:** 1

### Registry Key: UserFeedbackAllowed

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: ConfigureDoNotTrack

**Type:** DWord

**Original Value:** 0

**New Value:** 1

### Registry Key: AlternateErrorPagesEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: EdgeCollectionsEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: EdgeFollowEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: EdgeShoppingAssistantEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: MicrosoftEdgeInsiderPromotionEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: PersonalizationReportingEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: ShowMicrosoftRewards

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: WebWidgetAllowed

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: DiagnosticData

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: EdgeAssetDeliveryServiceEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: EdgeCollectionsEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: CryptoWalletEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0

### Registry Key: ConfigureDoNotTrack

**Type:** DWord

**Original Value:** 0

**New Value:** 1

### Registry Key: WalletDonationEnabled

**Type:** DWord

**Original Value:** 1

**New Value:** 0



<!-- BEGIN SECOND CUSTOM CONTENT -->

<!-- END SECOND CUSTOM CONTENT -->


[View the JSON file](https://github.com/ChrisTitusTech/Winutil/tree/main/config/tweaks.json)

