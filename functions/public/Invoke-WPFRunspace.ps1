function Invoke-WPFRunspace {

    <#
    
        .DESCRIPTION
        Simple function to make it easier to invoke a runspace from inside the script. 

        .EXAMPLE

        $params = @{
            ScriptBlock = $sync.ScriptsInstallPrograms
            ArgumentList = "Installadvancedip,Installbitwarden"
            Verbose = $true
        }

        Invoke-WPFRunspace @params
    
    #>

    [CmdletBinding()]
    Param (
        $ScriptBlock,
        $ArgumentList
    ) 

    #Crate a PowerShell instance.
    $script:powershell = [powershell]::Create()

    #Add Scriptblock and Arguments to runspace
    $script:powershell.AddScript($ScriptBlock)
    $script:powershell.AddArgument($ArgumentList)
    $script:powershell.RunspacePool = $sync.runspace
    
    #Run our RunspacePool.
    $script:handle = $script:powershell.BeginInvoke()

    #Cleanup our RunspacePool threads when they are complete ie. GC.
    if ($script:handle.IsCompleted)
    {
        $script:powershell.EndInvoke($script:handle)
        $script:powershell.Dispose()
        $sync.runspace.Dispose()
        $sync.runspace.Close()
        [System.GC]::Collect()
    }
}