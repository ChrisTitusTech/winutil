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
    $script:runspace = [runspacefactory]::CreateRunspacePool(1,$maxthreads,$InitialSessionState, $Host)


    #Crate a PowerShell instance.
    $script:powershell = [powershell]::Create()

    #Open a RunspacePool instance.
    $script:runspace.Open()

    #Add Scriptblock and Arguments to runspace
    $script:powershell.AddScript($ScriptBlock)
    $script:powershell.AddArgument($ArgumentList)
    $script:powershell.RunspacePool = $script:runspace
    
    #Run our RunspacePool.
    $script:handle = $script:powershell.BeginInvoke()

    #Cleanup our RunspacePool threads when they are complete ie. GC.
    if ($script:handle.IsCompleted)
    {
        $script:powershell.EndInvoke($script:handle)
        $script:powershell.Dispose()
        $script:runspace.Dispose()
        $script:runspace.Close()
        [System.GC]::Collect()
    }
}