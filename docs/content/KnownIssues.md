---
title: Known Issues
toc: true
---

### Download not working

If you run WinUtil and get an error like:

`< : The term '<' is not recognized as the name of a cmdlet, function, script file, or operable program.`

try using a **VPN** and if that didn't work than report the issue to https://github.com/ChrisTitusTech/winutil/issues

### Script Won't Run

If you run WinUtil and get the error:

`"WinUtil is unable to run on your system, powershell execution is restricted by security policies,"`

this means that your PowerShell session is in **Constrained Language Mode**, which prevents WinUtil from running.
