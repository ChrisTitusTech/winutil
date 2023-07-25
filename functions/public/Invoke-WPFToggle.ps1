function Invoke-WPFToggle {

    <#
    
        .DESCRIPTION
        Meant to make creating toggle switches easier. There is a section below in the gui that will assign this function to every switch.
        This way you can dictate what each button does from this function. 
    
        Input will be the name of the toggle that is checked. 
    #>
    
    Param ([string]$Button) 

    #Use this to get the name of the button
    #[System.Windows.MessageBox]::Show("$Button","Chris Titus Tech's Windows Utility","OK","Info")

    Switch -Wildcard ($Button){

        "WPFToggleDarkMode" {Invoke-WinUtilDarkMode -DarkMoveEnabled $(Get-WinUtilToggleStatus WPFToggleDarkMode)}
        "WPFToggleBingSearch" {Invoke-WinUtilBingSearch $(Get-WinUtilToggleStatus WPFToggleBingSearch)}

    }
}