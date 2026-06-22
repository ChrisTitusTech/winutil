---
title: Known Issues
toc: true
---

### Download not working

If you run WinUtil and get an error like:

`< : The term '<' is not recognized as the name of a cmdlet, function, script file, or operable program.`

try using a **VPN** and if that doesn't work than report the issue to https://github.com/ChrisTitusTech/winutil/issues

### Script Won't Run

If you run WinUtil and get the error:

`"WinUtil is unable to run on your system. PowerShell execution is restricted by security policies"`

this means that your PowerShell session is in **Constrained Language Mode**, which prevents WinUtil from running.

### Ultimate Performance Plan Not Working

The Ultimate Performance power plan may not work on some laptops that do not fully support this power plan.

In these cases, the power plan may fail to apply, This is expected behavior on unsupported hardware.

### Revert start menu tweak not working

Revert start menu tweak stops working starting with **Windows 11 update KB5089573** (released in May 2026).

In this update, Microsoft completely removed the old Start Menu code from Windows, so we aren't able to bring it back.
