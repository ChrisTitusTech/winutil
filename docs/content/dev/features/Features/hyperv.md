---
title: "HyperV Virtualization"
description: ""
---
```json {filename="config/feature.json",linenos=inline,linenostart=15}
  "WPFFeatureshyperv": {
    "Content": "HyperV Virtualization",
    "Description": "Hyper-V is a hardware virtualization product developed by Microsoft that allows users to create and manage virtual machines.",
    "category": "Features",
    "panel": "1",
    "Order": "a011_",
    "feature": [
      "Microsoft-Hyper-V-All"
    ],
    "InvokeScript": [
      "bcdedit /set hypervisorschedulertype classic"
    ],
```
