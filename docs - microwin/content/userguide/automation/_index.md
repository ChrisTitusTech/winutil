Automation option in winutil allows you to run winutil from a config file,
you can get your own config file inside winutil by clicking the gear icon on the top right and clicking export and saving it as a file

you can automate winutil launch with this command
```powershell
& ([ScriptBlock]::Create((irm "https://christitus.com/win"))) -Config C:\Path\To\Config -Run
```
