function Invoke-WinUtilScript {
    <#

    .SYNOPSIS
        Invokes the provided scriptblock. Intended for things that can't be handled with the other functions.

    .PARAMETER Name
        The name of the scriptblock being invoked

    .PARAMETER scriptblock
        The scriptblock to be invoked

    .EXAMPLE
        $Scriptblock = [scriptblock]::Create({"Write-output 'Hello World'"})
        Invoke-WinUtilScript -ScriptBlock $scriptblock -Name "Hello World"

    #>
    param (
        $Name,
        [scriptblock]$scriptblock
    )

    try {
        Write-Host "Running Script for $name"
        Invoke-Command $scriptblock -ErrorAction Stop
    } catch [System.Management.Automation.CommandNotFoundException] {
        Write-Warning "The specified command was not found."
        if ($_.Exception -and -not [string]::IsNullOrWhiteSpace($_.Exception.Message)) {
            Write-Warning $_.Exception.Message
        }
    } catch [System.Management.Automation.RuntimeException] {
        Write-Warning "A runtime exception occurred."
        if ($_.Exception -and -not [string]::IsNullOrWhiteSpace($_.Exception.Message)) {
            Write-Warning $_.Exception.Message
        }
    } catch [System.Security.SecurityException] {
        Write-Warning "A security exception occurred."
        if ($_.Exception -and -not [string]::IsNullOrWhiteSpace($_.Exception.Message)) {
            Write-Warning $_.Exception.Message
        }
    } catch [System.UnauthorizedAccessException] {
        Write-Warning "Access denied. You do not have permission to perform this operation."
        if ($_.Exception -and -not [string]::IsNullOrWhiteSpace($_.Exception.Message)) {
            Write-Warning $_.Exception.Message
        }
    } catch {
        # Generic catch block to handle any other type of exception
        Write-Warning "Unable to run script for $name due to unhandled exception"
        if ($_.Exception) {
            if (-not [string]::IsNullOrWhiteSpace($_.Exception.Message)) {
                Write-Warning $_.Exception.Message
            }
            if (-not [string]::IsNullOrWhiteSpace($_.Exception.StackTrace)) {
                Write-Warning $_.Exception.StackTrace
            }
        }
    }

}
