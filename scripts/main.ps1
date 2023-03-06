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
try { $Form = [Windows.Markup.XamlReader]::Load( $reader ) }
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

$xaml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name) }

$buttons = get-variable | Where-Object {$psitem.name -like "WPF*" -and $psitem.value -ne $null -and $psitem.value.GetType().name -eq "Button"}
foreach ($button in $buttons){
    $button.value.Add_Click({
        [System.Object]$Sender = $args[0]
        Invoke-WPFButton "WPF$($Sender.name)"
    })
}

$WPFToggleDarkMode.IsChecked = Get-WinUtilDarkMode

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
$form.title = $form.title + " " + $sync.version
$Form.ShowDialog() | out-null
Stop-Transcript
