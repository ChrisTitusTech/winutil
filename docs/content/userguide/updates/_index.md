---
title: Updates
weight: 6
---

Winutil provides three update modes so you can choose how aggressively Windows Update is managed on your system:

- **Default (Out of Box) Settings**: Restores standard Windows Update behavior
- **Security (Recommended) Settings**: Prioritizes stability while still receiving security updates
- **Disable ALL Updates**: Turns off Windows Update entirely and should only be used with extreme caution

### Default (Out of Box) Settings

- **What it does**: Restores the default Windows Update configuration.
- **Best for**: Systems where you want Windows to manage updates normally.
- **Notes**: This removes custom update settings previously applied by Winutil. If update errors continue, use the reset option in the **Config** tab to restore Microsoft Update services to their default state.

### Security (Recommended) Settings

- **What it does**: Applies a more conservative update strategy designed for most users.
- **Feature updates**: Delayed by **365 days** to reduce the chance of disruption from major Windows changes.
- **Security updates**: Delayed by **4 days** to allow time for early issues to surface while still keeping the system protected.
- **Why use it**: This mode offers the best balance between security and stability, which is why it is the recommended option for most PCs.

### Disable ALL Updates (NOT RECOMMENDED!)

- **What it does**: Disables all Windows updates.
- **Best for**: Highly controlled or special-purpose systems where updates must remain off temporarily.
- **Warning**: This leaves the system without security patches and significantly increases security risk.
- **Recommendation**: Avoid this mode unless you fully understand the tradeoffs and have a specific reason to use it.
