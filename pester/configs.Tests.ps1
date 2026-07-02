#===========================================================================
# Tests - Config Files
#===========================================================================

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$configRoot = Join-Path $PSScriptRoot "..\config"
$functionRoot = Join-Path $repoRoot "functions"
$xamlPath = Join-Path $repoRoot "xaml\inputXML.xaml"
$mainScriptPath = Join-Path $repoRoot "scripts\main.ps1"
$buttonScriptPath = Join-Path $repoRoot "functions\public\Invoke-WPFButton.ps1"
$configCases = @(
    Get-ChildItem -Path $configRoot -Filter *.json | ForEach-Object {
        @{
            Name = $_.Name
            Path = $_.FullName
        }
    }
)

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:configRoot = Join-Path $script:repoRoot "config"
    $script:functionRoot = Join-Path $script:repoRoot "functions"
    $script:xamlPath = Join-Path $script:repoRoot "xaml\inputXML.xaml"
    $script:mainScriptPath = Join-Path $script:repoRoot "scripts\main.ps1"
    $script:buttonScriptPath = Join-Path $script:repoRoot "functions\public\Invoke-WPFButton.ps1"

function script:Get-WinUtilConfigObject {
    param([string]$Name)

    Get-Content -Path (Join-Path $script:configRoot "$Name.json") -Raw | ConvertFrom-Json
}

function script:Test-WinUtilHasProperty {
    param(
        [Parameter(Mandatory)]
        [psobject]$Object,

        [Parameter(Mandatory)]
        [string]$Name
    )

    return @($Object.PSObject.Properties.Name) -contains $Name
}

function script:Test-WinUtilHasNonEmptyProperty {
    param(
        [Parameter(Mandatory)]
        [psobject]$Object,

        [Parameter(Mandatory)]
        [string]$Name
    )

    if (-not (Test-WinUtilHasProperty -Object $Object -Name $Name)) {
        return $false
    }

    $value = $Object.$Name
    if ($null -eq $value) {
        return $false
    }

    if ($value -is [string]) {
        return -not [string]::IsNullOrWhiteSpace($value)
    }

    if ($value -is [array]) {
        return @($value).Count -gt 0
    }

    return -not [string]::IsNullOrWhiteSpace([string]$value)
}

function script:Get-WinUtilMissingRequiredFields {
    param(
        [Parameter(Mandatory)]
        [string]$EntryName,

        [Parameter(Mandatory)]
        [psobject]$Entry,

        [Parameter(Mandatory)]
        [string[]]$RequiredFields
    )

    foreach ($field in $RequiredFields) {
        if (-not (Test-WinUtilHasNonEmptyProperty -Object $Entry -Name $field)) {
            "$EntryName missing $field"
        }
    }
}

function script:Get-WinUtilTopLevelFunctionNames {
    Get-ChildItem -Path $script:functionRoot -Filter *.ps1 -Recurse | ForEach-Object {
        $tokens = $null
        $syntaxErrors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$tokens, [ref]$syntaxErrors)
        if ($syntaxErrors.Count -ne 0) {
            throw ($syntaxErrors | Out-String)
        }

        $ast.EndBlock.Statements |
            Where-Object { $_ -is [System.Management.Automation.Language.FunctionDefinitionAst] } |
            ForEach-Object { $_.Name }
    } | Sort-Object -Unique
}

function script:Get-WinUtilButtonSwitchNames {
    $buttonSource = Get-Content -Path $script:buttonScriptPath -Raw
    [regex]::Matches($buttonSource, '"(WPF[A-Za-z0-9_]+)"\s*\{') |
        ForEach-Object { $_.Groups[1].Value } |
        Sort-Object -Unique
}
}

Describe "Config files" {
    foreach ($configCase in $configCases) {
        It "imports $($configCase.Name) with no JSON errors" -TestCases $configCase {
            param([string]$Name, [string]$Path)

            try {
                Get-Content -Path $Path -Raw | ConvertFrom-Json | Out-Null
            } catch {
                throw "Failed to import ${Name}: $_"
            }
        }
    }
}

Describe "Applications config" {
    $testCase = @{ Path = (Join-Path $configRoot "applications.json") }

    It "contains at least one application" -TestCases $testCase {
        param([string]$Path)

        $applications = Get-Content -Path $Path -Raw | ConvertFrom-Json
        $applicationEntries = @($applications.PSObject.Properties)

        if ($applicationEntries.Count -eq 0) {
            throw "applications.json does not contain any application entries."
        }
    }

    It "contains required display fields and at least one install source" -TestCases $testCase {
        param([string]$Path)

        $applications = Get-Content -Path $Path -Raw | ConvertFrom-Json
        $requiredFields = @("category", "content", "description", "link")
        $invalidEntries = New-Object System.Collections.Generic.List[string]

        foreach ($entry in $applications.PSObject.Properties) {
            $entryFields = @($entry.Value.PSObject.Properties.Name)

            foreach ($field in $requiredFields) {
                if ($entryFields -notcontains $field -or [string]::IsNullOrWhiteSpace([string]$entry.Value.$field)) {
                    $invalidEntries.Add("$($entry.Name) missing $field")
                }
            }

            $hasInstallSource = $false
            foreach ($sourceField in @("winget", "choco")) {
                if ($entryFields -contains $sourceField -and -not [string]::IsNullOrWhiteSpace([string]$entry.Value.$sourceField)) {
                    $hasInstallSource = $true
                }
            }

            if (-not $hasInstallSource) {
                $invalidEntries.Add("$($entry.Name) missing winget/choco install source")
            }
        }

        if ($invalidEntries.Count -gt 0) {
            throw ($invalidEntries -join "`n")
        }
    }
}

Describe "Tweaks config" {
    $testCase = @{ Path = (Join-Path $configRoot "tweaks.json") }

    It "contains undo metadata for registry and service actions" -TestCases $testCase {
        param([string]$Path)

        $tweaks = Get-Content -Path $Path -Raw | ConvertFrom-Json
        $invalidTweaks = New-Object System.Collections.Generic.List[string]

        foreach ($tweak in $tweaks.PSObject.Properties) {
            foreach ($registryEntry in @($tweak.Value.registry)) {
                if ($null -eq $registryEntry) { continue }

                if ($registryEntry.PSObject.Properties.Name -notcontains "OriginalValue" -or
                    [string]::IsNullOrWhiteSpace([string]$registryEntry.OriginalValue)) {
                    $invalidTweaks.Add("$($tweak.Name),registry")
                }
            }

            foreach ($serviceEntry in @($tweak.Value.service)) {
                if ($null -eq $serviceEntry) { continue }

                if ($serviceEntry.PSObject.Properties.Name -notcontains "OriginalType" -or
                    [string]::IsNullOrWhiteSpace([string]$serviceEntry.OriginalType)) {
                    $invalidTweaks.Add("$($tweak.Name),service")
                }
            }
        }

        if ($invalidTweaks.Count -gt 0) {
            throw ($invalidTweaks -join "`n")
        }
    }
}

Describe "Preset config" {
    It "references existing config entries or supported actions" {
        $preset = Get-WinUtilConfigObject -Name "preset"
        $applications = Get-WinUtilConfigObject -Name "applications"
        $tweaks = Get-WinUtilConfigObject -Name "tweaks"
        $feature = Get-WinUtilConfigObject -Name "feature"
        $appx = Get-WinUtilConfigObject -Name "appx"

        $validReferences = @(
            $tweaks.PSObject.Properties.Name
            $feature.PSObject.Properties.Name
            $appx.PSObject.Properties.Name
            $applications.PSObject.Properties.Name | ForEach-Object { "WPFInstall$_" }
            Get-WinUtilButtonSwitchNames
        ) | Sort-Object -Unique

        $invalidReferences = New-Object System.Collections.Generic.List[string]
        foreach ($presetEntry in $preset.PSObject.Properties) {
            foreach ($reference in @($presetEntry.Value)) {
                if ($validReferences -notcontains $reference) {
                    $invalidReferences.Add("$($presetEntry.Name) references missing item $reference")
                }
            }
        }

        if ($invalidReferences.Count -gt 0) {
            throw ($invalidReferences -join "`n")
        }
    }
}

Describe "App navigation config" {
    It "is wired to an existing XAML target grid" {
        $mainScript = Get-Content -Path $script:mainScriptPath -Raw
        $targetGridMatch = [regex]::Match(
            $mainScript,
            'Invoke-WPFUIElements\s+-configVariable\s+\$sync\.configs\.appnavigation\s+-targetGridName\s+"([^"]+)"'
        )

        if (-not $targetGridMatch.Success) {
            throw "scripts/main.ps1 does not wire appnavigation through Invoke-WPFUIElements."
        }

        $xamlText = Get-Content -Path $script:xamlPath -Raw
        $targetGridName = $targetGridMatch.Groups[1].Value
        if ($xamlText -notmatch "Name=`"$([regex]::Escape($targetGridName))`"") {
            throw "appnavigation target grid '$targetGridName' was not found in xaml/inputXML.xaml."
        }
    }

    It "contains renderable entries with valid button and radio groups" {
        $appnavigation = Get-WinUtilConfigObject -Name "appnavigation"
        $feature = Get-WinUtilConfigObject -Name "feature"
        $requiredFields = @("Content", "Category", "Type", "Order", "Description")
        $allowedTypes = @("Button", "RadioButton", "Note")
        $supportedButtons = @(
            Get-WinUtilButtonSwitchNames
            $feature.PSObject.Properties.Name
        ) | Sort-Object -Unique
        $invalidEntries = New-Object System.Collections.Generic.List[string]

        foreach ($entry in $appnavigation.PSObject.Properties) {
            foreach ($missingField in (Get-WinUtilMissingRequiredFields -EntryName $entry.Name -Entry $entry.Value -RequiredFields $requiredFields)) {
                $invalidEntries.Add($missingField)
            }

            if ($allowedTypes -notcontains $entry.Value.Type) {
                $invalidEntries.Add("$($entry.Name) has unsupported Type '$($entry.Value.Type)'")
            }

            if ($entry.Value.Type -eq "Button" -and $supportedButtons -notcontains $entry.Name) {
                $invalidEntries.Add("$($entry.Name) is not handled by Invoke-WPFButton or feature config")
            }

            if ($entry.Value.Type -eq "RadioButton") {
                if (-not (Test-WinUtilHasNonEmptyProperty -Object $entry.Value -Name "GroupName")) {
                    $invalidEntries.Add("$($entry.Name) missing GroupName")
                }

                if (-not (Test-WinUtilHasProperty -Object $entry.Value -Name "Checked")) {
                    $invalidEntries.Add("$($entry.Name) missing Checked")
                }
            }
        }

        $radioButtons = @($appnavigation.PSObject.Properties | Where-Object { $_.Value.Type -eq "RadioButton" })
        foreach ($group in ($radioButtons | Group-Object -Property { $_.Value.GroupName })) {
            if ([string]::IsNullOrWhiteSpace($group.Name)) {
                $invalidEntries.Add("RadioButton group name is blank")
                continue
            }

            $checkedCount = @($group.Group | Where-Object { $_.Value.Checked -eq $true }).Count
            if ($checkedCount -ne 1) {
                $invalidEntries.Add("RadioButton group '$($group.Name)' has $checkedCount checked entries")
            }
        }

        if ($invalidEntries.Count -gt 0) {
            throw ($invalidEntries -join "`n")
        }
    }
}

Describe "UI-rendered config entries" {
    It "contains required AppX fields" {
        $appx = Get-WinUtilConfigObject -Name "appx"
        $requiredFields = @("Category", "Content", "Description", "Panel", "PackageId")
        $invalidEntries = New-Object System.Collections.Generic.List[string]

        foreach ($entry in $appx.PSObject.Properties) {
            foreach ($missingField in (Get-WinUtilMissingRequiredFields -EntryName $entry.Name -Entry $entry.Value -RequiredFields $requiredFields)) {
                $invalidEntries.Add($missingField)
            }
        }

        if ($invalidEntries.Count -gt 0) {
            throw ($invalidEntries -join "`n")
        }
    }

    It "contains required DNS fields with parseable IP addresses" {
        $dns = Get-WinUtilConfigObject -Name "dns"
        $requiredFields = @("Primary", "Secondary", "Primary6", "Secondary6")
        $invalidEntries = New-Object System.Collections.Generic.List[string]

        foreach ($entry in $dns.PSObject.Properties) {
            foreach ($missingField in (Get-WinUtilMissingRequiredFields -EntryName $entry.Name -Entry $entry.Value -RequiredFields $requiredFields)) {
                $invalidEntries.Add($missingField)
            }

            foreach ($field in $requiredFields) {
                if (-not (Test-WinUtilHasNonEmptyProperty -Object $entry.Value -Name $field)) {
                    continue
                }

                try {
                    [System.Net.IPAddress]::Parse([string]$entry.Value.$field) | Out-Null
                } catch {
                    $invalidEntries.Add("$($entry.Name) $field is not a parseable IP address")
                }
            }
        }

        if ($invalidEntries.Count -gt 0) {
            throw ($invalidEntries -join "`n")
        }
    }

    It "contains required feature fields and valid configured functions" {
        $feature = Get-WinUtilConfigObject -Name "feature"
        $functionNames = Get-WinUtilTopLevelFunctionNames
        $requiredFields = @("Content", "category", "panel", "link")
        $invalidEntries = New-Object System.Collections.Generic.List[string]

        foreach ($entry in $feature.PSObject.Properties) {
            foreach ($missingField in (Get-WinUtilMissingRequiredFields -EntryName $entry.Name -Entry $entry.Value -RequiredFields $requiredFields)) {
                $invalidEntries.Add($missingField)
            }

            if ($entry.Value.Type -and $entry.Value.Type -ne "Button") {
                $invalidEntries.Add("$($entry.Name) has unsupported Type '$($entry.Value.Type)'")
            }

            if ($entry.Value.Type -eq "Button") {
                if (-not $entry.Value.function -and -not $entry.Value.InvokeScript) {
                    $invalidEntries.Add("$($entry.Name) button missing function or InvokeScript")
                }
            } else {
                if (-not (Test-WinUtilHasNonEmptyProperty -Object $entry.Value -Name "Description")) {
                    $invalidEntries.Add("$($entry.Name) missing Description")
                }

                if (-not $entry.Value.feature -and -not $entry.Value.InvokeScript) {
                    $invalidEntries.Add("$($entry.Name) missing feature or InvokeScript action")
                }
            }

            if ($entry.Value.function -and $functionNames -notcontains $entry.Value.function) {
                $invalidEntries.Add("$($entry.Name) references missing function $($entry.Value.function)")
            }
        }

        if ($invalidEntries.Count -gt 0) {
            throw ($invalidEntries -join "`n")
        }
    }

    It "contains required tweak fields and valid action metadata" {
        $tweaks = Get-WinUtilConfigObject -Name "tweaks"
        $requiredFields = @("Content", "category", "panel", "link")
        $allowedTypes = @("Button", "Combobox", "Toggle", "ToggleButton")
        $supportedButtons = Get-WinUtilButtonSwitchNames
        $invalidEntries = New-Object System.Collections.Generic.List[string]

        foreach ($entry in $tweaks.PSObject.Properties) {
            foreach ($missingField in (Get-WinUtilMissingRequiredFields -EntryName $entry.Name -Entry $entry.Value -RequiredFields $requiredFields)) {
                $invalidEntries.Add($missingField)
            }

            if ($entry.Value.Type -and $allowedTypes -notcontains $entry.Value.Type) {
                $invalidEntries.Add("$($entry.Name) has unsupported Type '$($entry.Value.Type)'")
            }

            if ($entry.Value.Type -eq "Button") {
                if ($supportedButtons -notcontains $entry.Name) {
                    $invalidEntries.Add("$($entry.Name) is not handled by Invoke-WPFButton")
                }
            } elseif ($entry.Value.Type -eq "Combobox") {
                if (-not (Test-WinUtilHasNonEmptyProperty -Object $entry.Value -Name "ComboItems")) {
                    $invalidEntries.Add("$($entry.Name) combobox missing ComboItems")
                }
            } else {
                if (-not (Test-WinUtilHasNonEmptyProperty -Object $entry.Value -Name "Description")) {
                    $invalidEntries.Add("$($entry.Name) missing Description")
                }

                if (-not $entry.Value.registry -and -not $entry.Value.service -and -not $entry.Value.InvokeScript -and -not $entry.Value.appx) {
                    $invalidEntries.Add("$($entry.Name) missing registry, service, InvokeScript, or appx action")
                }
            }

            foreach ($registryEntry in @($entry.Value.registry)) {
                if ($null -eq $registryEntry) { continue }

                foreach ($missingField in (Get-WinUtilMissingRequiredFields -EntryName "$($entry.Name),registry" -Entry $registryEntry -RequiredFields @("Path", "Name", "Type", "Value", "OriginalValue"))) {
                    $invalidEntries.Add($missingField)
                }
            }

            foreach ($serviceEntry in @($entry.Value.service)) {
                if ($null -eq $serviceEntry) { continue }

                foreach ($missingField in (Get-WinUtilMissingRequiredFields -EntryName "$($entry.Name),service" -Entry $serviceEntry -RequiredFields @("Name", "StartupType", "OriginalType"))) {
                    $invalidEntries.Add($missingField)
                }
            }
        }

        if ($invalidEntries.Count -gt 0) {
            throw ($invalidEntries -join "`n")
        }
    }

    It "defines theme resources required by XAML rendering" {
        $themes = Get-WinUtilConfigObject -Name "themes"
        $invalidEntries = New-Object System.Collections.Generic.List[string]

        foreach ($themeName in @("shared", "Light", "Dark")) {
            if (-not (Test-WinUtilHasProperty -Object $themes -Name $themeName)) {
                $invalidEntries.Add("themes.json missing $themeName")
                continue
            }

            foreach ($property in $themes.$themeName.PSObject.Properties) {
                if ([string]::IsNullOrWhiteSpace([string]$property.Value)) {
                    $invalidEntries.Add("$themeName.$($property.Name) is blank")
                }
            }
        }

        $lightKeys = @($themes.Light.PSObject.Properties.Name)
        $darkKeys = @($themes.Dark.PSObject.Properties.Name)
        foreach ($key in $lightKeys) {
            if ($darkKeys -notcontains $key) {
                $invalidEntries.Add("Dark theme missing $key")
            }
        }
        foreach ($key in $darkKeys) {
            if ($lightKeys -notcontains $key) {
                $invalidEntries.Add("Light theme missing $key")
            }
        }

        $xamlText = Get-Content -Path $script:xamlPath -Raw
        $dynamicResourceNames = @(
            [regex]::Matches($xamlText, '\{DynamicResource\s+([^\}\s]+)') |
                ForEach-Object { $_.Groups[1].Value }
        ) | Sort-Object -Unique
        $xamlDefinedResourceNames = @(
            [regex]::Matches($xamlText, 'x:Key="([^"]+)"') |
                ForEach-Object { $_.Groups[1].Value }
        ) | Sort-Object -Unique
        $themeResourceNames = @(
            $themes.shared.PSObject.Properties.Name
            $themes.Light.PSObject.Properties.Name
            $themes.Dark.PSObject.Properties.Name
            "CBorderColor"
            "CButtonBackgroundMouseoverColor"
        ) | Sort-Object -Unique

        foreach ($resourceName in $dynamicResourceNames) {
            if ($xamlDefinedResourceNames -notcontains $resourceName -and $themeResourceNames -notcontains $resourceName) {
                $invalidEntries.Add("XAML DynamicResource '$resourceName' is not defined in themes.json or XAML resources")
            }
        }

        if ($invalidEntries.Count -gt 0) {
            throw ($invalidEntries -join "`n")
        }
    }
}

Describe "Embedded config scripts" {
    It "parse as PowerShell scriptblocks" {
        $invalidScripts = New-Object System.Collections.Generic.List[string]

        foreach ($configFile in (Get-ChildItem -Path $script:configRoot -Filter *.json)) {
            $config = Get-Content -Path $configFile.FullName -Raw | ConvertFrom-Json
            foreach ($entry in $config.PSObject.Properties) {
                foreach ($field in @("InvokeScript", "UndoScript")) {
                    if (-not (Test-WinUtilHasProperty -Object $entry.Value -Name $field)) {
                        continue
                    }

                    $index = 0
                    foreach ($scriptText in @($entry.Value.$field)) {
                        $index++
                        if ([string]::IsNullOrWhiteSpace([string]$scriptText)) {
                            continue
                        }

                        try {
                            [scriptblock]::Create([string]$scriptText) | Out-Null
                        } catch {
                            $invalidScripts.Add("$($configFile.Name):$($entry.Name).$field[$index] $($psitem.Exception.Message)")
                        }
                    }
                }
            }
        }

        if ($invalidScripts.Count -gt 0) {
            throw ($invalidScripts -join "`n")
        }
    }
}
