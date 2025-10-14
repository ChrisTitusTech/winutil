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
    # The output shows the options for Yes and No as "[Y,N]?" in the (partially) localized format.
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
