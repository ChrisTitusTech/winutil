function Invoke-WPFPopup {
    param (
        [Parameter(position=0)]
        [ValidateSet("Show","Hide","Toggle", ErrorMessage="Action '{0}' is not part of the valid set '{1}'.")]
        [string]$Action = "",

        [Parameter(position=1)]
        [string[]]$Popups = @(),

        [Parameter(position=2)]
        [ValidateScript({
            $PossibleActions = @("Show", "Hide", "Toggle")
            [hashtable]$UnExpectedPairs = @{}
            Foreach ($pair in $_.GetEnumerator()) {
                $key = $pair.Name
                $value = $pair.Value
                if (-not ($value -in $PossibleActions)) {
                    $UnExpectedPairs.Add("$key", "$value")
                }
            }

            if ($UnExpectedPairs.Count -gt 0) {
                $UnExpectedPairsAsString = "@{"
                Foreach ($pair in $UnExpectedPairs.GetEnumerator()) { $UnExpectedPairsAsString += "`"$($pair.Name)`" = `"$($pair.Value)`"; " }
                $UnExpectedPairsAsString = $UnExpectedPairsAsString -replace (';\s*$', '')
                $UnExpectedPairsAsString += "}"
                throw "Found Unexpected pair(s), these Popup & Action pair(s) are: $UnExpectedPairsAsString"
            }

            # Return true for passing validation checks
            $true
        })]
        [hashtable]$PopupActionTable = @{}
    )

    if ($PopupActionTable.Count -eq 0 -and $Action -eq "" -and $Popups.Count -eq 0) {
        throw [GenericException]::new("No Parameter was provided, please use either 'PopupActionTable' on its own, or use 'Action' and 'Popups' on their own, depending on your use case.")
    }
    if ($PopupActionTable.Count -gt 0 -and ($Action -ne "" -or $Popups.Count -gt 0)) {
        throw [GenericException]::new("Only use 'PopupActionTable' on its own, or use 'Action' and 'Popups' on their own, depending on your use case.")
    }

    $PopupsNotFound = [System.Collections.Generic.List[string]]::new($Popups.Count)

    if ($PopupActionTable.Count -gt 0) {
        Foreach ($popupActionPair in $PopupActionTable.GetEnumerator()) {
            $popup = $popupActionPair.Name + "Popup"
            $action = $popupActionPair.Value
            if ($sync.$popup -eq $null) {
                $PopupsNotFound.Add("$popup") | Out-Null
                continue
            }
            switch ($action) {
                'Show' { $actionAsBool = $true }
                'Hide' { $actionAsBool = $false }
                'Toggle' { $actionAsBool = -not $sync.$popup.IsOpen }
                default { throw [GenericException]::new("Action can only be `"Show`" or `"Hide`" or `"Toggle`".") }
            }
            $sync.$popup.IsOpen = $actionAsBool
        }
    } else {
        if ($Action -eq "" -or $Popups.Count -eq 0) {
            throw [GenericException]::new("Please provide both the 'Action' and 'Popups' Parameters, with the appropriate values foreach parameter.")
        }
        Foreach ($popup in $Popups) {
            $popup += "Popup"
            if ($sync.$popup -eq $null) {
                $PopupsNotFound.Add("$popup") | Out-Null
                continue
            }
            switch ($action) {
                'Show' { $actionAsBool = $true }
                'Hide' { $actionAsBool = $false }
                'Toggle' { $actionAsBool = -not $sync.$popup.IsOpen }
                default { throw [GenericException]::new("Action can only be `"Show`" or `"Hide`" or `"Toggle`".") }
            }
            $sync.$popup.IsOpen = $actionAsBool
        }
    }

    if ($PopupsNotFound.Count -gt 0) {
        $PopupsNotFoundAsString = "@("
        Foreach ($popupNotFound in $PopupsNotFound) {
            $PopupsNotFoundAsString += "$popupNotFound"
            $PopupsNotFoundAsString += ", "
        }
        $PopupsNotFoundAsString = $PopupsNotFoundAsString -replace (',\s*$', '')
        $PopupsNotFoundAsString += ")"
        throw [GenericException]::new("Could not find $PopupsNotFoundAsString Popups in `$sync variable.")
    }
}
