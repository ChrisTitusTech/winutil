function Show-Message {
    param (
        [ValidateSet("OK", "OKCancel", "YesNo", "YesNoCancel")]
        [string]$PromptType = "OK",
        [string]$Title = $null,
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [ValidateSet("Asterisk", "Error", "Exclamation", "Hand", "Information", "None", "Question", "Stop", "Warning")]
        [string]$Severity = "Information"
    )
    switch (Get-UserInterfaceType) {
        "CLI" {  
            Show-MessageCLI -PromptType $PromptType -Title $Title -Text $Text -Severity $Severity
        }
        "WPF" {
            Show-MessageWPF -PromptType $PromptType -Title $Title -Text $Text -Severity $Severity
        }
        Default {
            throw "Unknown UserInterfaceType"
        }
    }
}

function Show-MessageCLI {
  # TODO: implement this? add support for confrim and whatif?
  # https://jcallaghan.com/2011/10/adding-a-yes-no-cancel-prompt-to-a-powershell-script/
    param (
        [ValidateSet("OK", "OKCancel", "YesNo", "YesNoCancel")]
        [string]$PromptType = "OK",
        [string]$Title = $null,
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [ValidateSet("Asterisk", "Error", "Exclamation", "Hand", "Information", "None", "Question", "Stop", "Warning")]
        [string]$Severity = "Information"
    )
    $foregroundColors = @{
        "Information" = "White"
        "Warning"     = "Red"
    }
    if (![string]::IsNullOrEmpty($Title)) {
        Write-Host $Title -ForegroundColor $foregroundColors[$Severity]
        Write-Host $Text -ForegroundColor White
    }
    else {
        Write-Host $Text -ForegroundColor $foregroundColors[$Severity]
    }
    switch ($PromptType) {
        "OK" { 
            Read-Host "Press Enter to continue..."
            break
        }
        { "YesNo", "OKCancel" -eq $_ } {
            $answer = Read-Host "Press Y for Yes or N for No"
            if ($answer -eq "Y") {
                return "YES"
            }
            if ($answer -eq "N") {
                return "NO"
            }
            break
        }
        "YesNoCancel" {
            $answer = Read-Host "Press Y for Yes, N for No, or C for Cancel"
            if ($answer -eq "Y") {
                return "YES"
            }
            if ($answer -eq "N") {
                return "NO"
            }
            if ($answer -eq "C") {
                return "CANCEL"
            }
            break
        }
        Default {
            throw "Invalid PromptType"
        }
    }
}

function Show-MessageWPF {
    param (
        [ValidateSet("OK", "OKCancel", "YesNo", "YesNoCancel")]
        [string]$PromptType = "OK",
        [string]$Title = $null,
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [ValidateSet("Asterisk", "Error", "Exclamation", "Hand", "Information", "None", "Question", "Stop", "Warning")]
        [string]$Severity = "Information"
    )
    $ButtonTypes = @{
        "OK"          = [System.Windows.MessageBoxButton]::OK
        "OKCancel"    = [System.Windows.MessageBoxButton]::OKCancel
        "YesNo"       = [System.Windows.MessageBoxButton]::YesNo
        "YesNoCancel" = [System.Windows.MessageBoxButton]::YesNoCancel
    }
    $MessageIcons = @{
        "Asterisk"    = [System.Windows.MessageBoxImage]::Asterisk
        "Error"       = [System.Windows.MessageBoxImage]::Error
        "Exclamation" = [System.Windows.MessageBoxImage]::Exclamation
        "Hand"        = [System.Windows.MessageBoxImage]::Hand
        "Information" = [System.Windows.MessageBoxImage]::Information
        "None"        = [System.Windows.MessageBoxImage]::None
        "Question"    = [System.Windows.MessageBoxImage]::Question
        "Stop"        = [System.Windows.MessageBoxImage]::Stop
        "Warning"     = [System.Windows.MessageBoxImage]::Warning
    }
    $ButtonType = $ButtonTypes[$PromptType]
    $MessageIcon = $MessageIcons[$Severity]
    return [System.Windows.MessageBox]::Show($Text, $Title, $ButtonType, $MessageIcon)
}

