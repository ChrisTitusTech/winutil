function Get-LocalizedYesNo {
    <#
    .SYNOPSIS
    This function runs choice.exe and captures its output to extract yes no in a localized Windows 
    
    .DESCRIPTION
    The function retrieves the output of the command 'cmd /c "choice <nul 2>nul"' and converts the default output for Yes and No
    in the localized format, such as "Yes=<first character>, No=<second character>".
    
    .EXAMPLE
    $yesNoArray = Get-LocalizedYesNo
    Write-Host "Yes=$($yesNoArray[0]), No=$($yesNoArray[1])"
    #>
  
    # Run choice and capture its options as output
    # The output shows the options for Yes and No as "[Y,N]?" in the (partitially) localized format.
    # eg. English: [Y,N]?
    # Dutch: [Y,N]?
    # German: [J,N]?
    # French: [O,N]?
    # Spanish: [S,N]?
    # Italian: [S,N]?
    # Russian: [Y,N]?
    
    $line = cmd /c "choice <nul 2>nul"
    $charactersArray = @()
    $regexPattern = '([a-zA-Z])'
    $charactersArray = [regex]::Matches($line, $regexPattern) | ForEach-Object { $_.Groups[1].Value }

    Write-Debug "According to takeown.exe local Yes is $charactersArray[0]"
    # Return the array of characters
    return $charactersArray
  }
  

function Get-LocalizedYesNoTakeown {
    <#
    .SYNOPSIS
    This function runs takeown.exe and captures its output to extract yes no in a localized Windows 
    
    .DESCRIPTION
    The function retrieves lines from the output of takeown.exe until there are at least 2 characters
    captured in a specific format, such as "Yes=<first character>, No=<second character>".
    
    .EXAMPLE
    $yesNoArray = Get-LocalizedYesNo
    Write-Host "Yes=$($yesNoArray[0]), No=$($yesNoArray[1])"
    #>
  
    # Run takeown.exe and capture its output
    $takeownOutput = & takeown.exe /? | Out-String

    # Parse the output and retrieve lines until there are at least 2 characters in the array
    $found = $false
    $charactersArray = @()
    foreach ($line in $takeownOutput -split "`r`n") 
    {
        # skip everything before /D flag help
        if ($found) 
        {
            # now that /D is found start looking for a single character in double quotes
            # in help text there is another string in double quotes but it is not a single character
            $regexPattern = '"([a-zA-Z])"'

            $charactersArray = [regex]::Matches($line, $regexPattern) | ForEach-Object { $_.Groups[1].Value }
            
            # if ($charactersArray.Count -gt 0) {
            #     Write-Output "Extracted symbols: $($matches -join ', ')"
            # } else {
            #     Write-Output "No matches found."
            # }

            if ($charactersArray.Count -ge 2) 
            {
                break
            }    
        }
        elseif ($line -match "/D   ") 
        {
            $found = $true
        }
    }

    Write-Debug "According to takeown.exe local Yes is $charactersArray[0]"
    # Return the array of characters
    return $charactersArray
  }