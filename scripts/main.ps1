#Configure max thread count for RunspacePool.
$maxthreads = [int]$env:NUMBER_OF_PROCESSORS

#Create a new session state for parsing variables ie hashtable into our runspace.
$hashVars = New-object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'sync',$sync,$Null
$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()

#Add the variable to the RunspacePool sessionstate
$InitialSessionState.Variables.Add($hashVars)

#Add functions
$functions = Get-ChildItem function:\ | Where-Object {$_.name -like "*winutil*" -or $_.name -like "*WPF*"}
foreach ($function in $functions){
    $functionDefinition = Get-Content function:\$($function.name)
    $functionEntry = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList $($function.name), $functionDefinition
    
    # And add it to the iss object
    $initialSessionState.Commands.Add($functionEntry)
}

#Create our runspace pool. We are entering three parameters here min thread count, max thread count and host machine of where these runspaces should be made.
$sync.runspace = [runspacefactory]::CreateRunspacePool(1,$maxthreads,$InitialSessionState, $Host)

#Open a RunspacePool instance.
$sync.runspace.Open()

#region exception classes

    class WingetFailedInstall : Exception {
        [string] $additionalData

        WingetFailedInstall($Message) : base($Message) {}
    }
    
    class ChocoFailedInstall : Exception {
        [string] $additionalData

        ChocoFailedInstall($Message) : base($Message) {}
    }

    class GenericException : Exception {
        [string] $additionalData

        GenericException($Message) : base($Message) {}
    }
    
#endregion exception classes

$inputXML = $inputXML -replace 'mc:Ignorable="d"', '' -replace "x:N", 'N' -replace '^<Win.*', '<Window'
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
try { $sync["Form"] = [Windows.Markup.XamlReader]::Load( $reader ) }
catch [System.Management.Automation.MethodInvocationException] {
    Write-Warning "We ran into a problem with the XAML code.  Check the syntax for this control..."
    Write-Host $error[0].Exception.Message -ForegroundColor Red
    If ($error[0].Exception.Message -like "*button*") {
        write-warning "Ensure your &lt;button in the `$inputXML does NOT have a Click=ButtonClick property.  PS can't handle this`n`n`n`n"
    }
}
catch {
    # If it broke some other way <img draggable="false" role="img" class="emoji" alt="😀" src="https://s0.wp.com/wp-content/mu-plugins/wpcom-smileys/twemoji/2/svg/1f600.svg">
    Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."
}

#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================

$xaml.SelectNodes("//*[@Name]") | ForEach-Object {$sync["$("$($psitem.Name)")"] = $sync["Form"].FindName($psitem.Name)}

$sync.keys | ForEach-Object {
    if($sync.$psitem){
        if($($sync["$psitem"].GetType() | Select-Object -ExpandProperty Name) -eq "Button"){
            $sync["$psitem"].Add_Click({
                [System.Object]$Sender = $args[0]
                Invoke-WPFButton $Sender.name
            })
        }
    }
}

$sync["WPFToggleDarkMode"].Add_Click({    
  Invoke-WPFDarkMode -DarkMoveEnabled $(Get-WinUtilDarkMode)
})

$sync["WPFToggleDarkMode"].IsChecked = Get-WinUtilDarkMode

#===========================================================================
# Setup background config
#===========================================================================

#Load information in the background
Invoke-WPFRunspace -ScriptBlock {
    $sync.ConfigLoaded = $False

    $sync.ComputerInfo = Get-ComputerInfo

    $sync.ConfigLoaded = $True
} | Out-Null

#===========================================================================
# Shows the form
#===========================================================================

Invoke-WPFFormVariables

try{
    Install-WinUtilChoco
}
Catch [ChocoFailedInstall]{
    Write-Host "==========================================="
    Write-Host "--    Chocolatey failed to install      ---"
    Write-Host "==========================================="
}
$sync["Form"].title = $sync["Form"].title + " " + $sync.version
$sync["Form"].Add_Closing({
    $sync.runspace.Dispose()
    $sync.runspace.Close()
    [System.GC]::Collect()
})

$sync["Form"].ShowDialog() | out-null
Stop-Transcript
