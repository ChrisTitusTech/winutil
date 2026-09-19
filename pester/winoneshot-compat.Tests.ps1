#===========================================================================
# Tests - WinOneShot Catalog Compatibility
#===========================================================================
# WinOneShot downloads these files from WinUtil's main/config raw GitHub URLs.
# Keep the known field types aligned with WinOneShot Models.cs; extra fields are allowed.

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$catalogCases = @(
    @{
        Name = "applications.json"
        Path = Join-Path $repoRoot "config\applications.json"
        ScalarFields = @{
            category = "String"
            choco = "String"
            content = "String"
            description = "String"
            foss = "Boolean"
            link = "String"
            winget = "String"
        }
        ArrayFields = @{}
    }
    @{
        Name = "appx.json"
        Path = Join-Path $repoRoot "config\appx.json"
        ScalarFields = @{
            Category = "String"
            Content = "String"
            Description = "String"
            Panel = "String"
            PackageId = "String"
            StoreId = "String"
        }
        ArrayFields = @{}
    }
    @{
        Name = "feature.json"
        Path = Join-Path $repoRoot "config\feature.json"
        ScalarFields = @{
            Content = "String"
            Description = "String"
            category = "String"
            panel = "String"
            Order = "String"
            link = "String"
            Type = "String"
            ButtonWidth = "String"
            function = "String"
        }
        ArrayFields = @{
            feature = "StringArray"
            InvokeScript = "StringArray"
        }
    }
    @{
        Name = "tweaks.json"
        Path = Join-Path $repoRoot "config\tweaks.json"
        ScalarFields = @{
            Content = "String"
            Description = "String"
            category = "String"
            panel = "String"
            Order = "String"
            Type = "String"
            Checked = "String"
            ButtonWidth = "String"
            ComboItems = "String"
            link = "String"
        }
        ArrayFields = @{
            registry = "RegistryArray"
            service = "ServiceArray"
            ScheduledTask = "ScheduledTaskArray"
            appx = "StringArray"
            InvokeScript = "StringArray"
            UndoScript = "StringArray"
        }
    }
)
$invalidCatalogCases = @(
    @{
        Name = "applications.json"
        Json = '[{"App":{}}]'
        ScalarFields = $catalogCases[0].ScalarFields
        ArrayFields = $catalogCases[0].ArrayFields
        ExpectedError = "must contain a JSON object"
    }
    @{
        Name = "applications.json"
        Json = "{}"
        ScalarFields = $catalogCases[0].ScalarFields
        ArrayFields = $catalogCases[0].ArrayFields
        ExpectedError = "does not contain any entries"
    }
    @{
        Name = "applications.json"
        Json = '{"Broken":null}'
        ScalarFields = $catalogCases[0].ScalarFields
        ArrayFields = $catalogCases[0].ArrayFields
        ExpectedError = "applications.json.Broken is null"
    }
    @{
        Name = "applications.json"
        Json = '{"App":{"foss":"yes"}}'
        ScalarFields = $catalogCases[0].ScalarFields
        ArrayFields = $catalogCases[0].ArrayFields
        ExpectedError = "foss must be a Boolean"
    }
    @{
        Name = "appx.json"
        Json = '{"App":{"PackageId":[]}}'
        ScalarFields = $catalogCases[1].ScalarFields
        ArrayFields = $catalogCases[1].ArrayFields
        ExpectedError = "PackageId must be a string or null"
    }
    @{
        Name = "feature.json"
        Json = '{"Feature":{"feature":"Example-Feature"}}'
        ScalarFields = $catalogCases[2].ScalarFields
        ArrayFields = $catalogCases[2].ArrayFields
        ExpectedError = "feature must be an array or null"
    }
    @{
        Name = "tweaks.json"
        Json = '{"Tweak":{"registry":{}}}'
        ScalarFields = $catalogCases[3].ScalarFields
        ArrayFields = $catalogCases[3].ArrayFields
        ExpectedError = "registry must be an array or null"
    }
)

BeforeAll {
    function script:Get-WinOneShotJsonKind {
        param($Value)

        if ($null -eq $Value) {
            return "Null"
        }
        if ($Value -is [string]) {
            return "String"
        }
        if ($Value -is [bool]) {
            return "Boolean"
        }
        if ($Value -is [array]) {
            return "Array"
        }
        if ($Value -is [pscustomobject]) {
            return "Object"
        }

        return $Value.GetType().Name
    }

    function script:Get-WinOneShotProperty {
        param(
            [Parameter(Mandatory)]
            [pscustomobject]$Object,

            [Parameter(Mandatory)]
            [string]$Name
        )

        foreach ($property in $Object.PSObject.Properties) {
            if ($property.Name -ieq $Name) {
                $property
            }
        }
    }

    function script:Get-WinOneShotTypeError {
        param(
            [Parameter(Mandatory)]
            [string]$Location,

            $Value,

            [Parameter(Mandatory)]
            [string]$ExpectedType
        )

        $actualKind = Get-WinOneShotJsonKind -Value $Value

        if ($ExpectedType -eq "String") {
            if ($actualKind -notin @("String", "Null")) {
                return "$Location must be a string or null; found $actualKind"
            }
            return
        }

        if ($ExpectedType -eq "Boolean") {
            if ($actualKind -ne "Boolean") {
                return "$Location must be a Boolean; found $actualKind"
            }
            return
        }

        if ($actualKind -eq "Null") {
            return
        }
        if ($actualKind -ne "Array") {
            return "$Location must be an array or null; found $actualKind"
        }

        if ($ExpectedType -eq "StringArray") {
            for ($index = 0; $index -lt $Value.Count; $index++) {
                $elementKind = Get-WinOneShotJsonKind -Value $Value[$index]
                if ($elementKind -notin @("String", "Null")) {
                    "$Location[$index] must be a string or null; found $elementKind"
                }
            }
            return
        }

        $nestedFields = switch ($ExpectedType) {
            "RegistryArray" {
                @("Path", "Name", "Value", "OriginalValue", "DefaultState", "Type")
            }
            "ServiceArray" {
                @("Name", "StartupType", "OriginalType")
            }
            "ScheduledTaskArray" {
                @("Name")
            }
            default {
                throw "Unknown WinOneShot contract type: $ExpectedType"
            }
        }

        for ($index = 0; $index -lt $Value.Count; $index++) {
            $element = $Value[$index]
            $elementKind = Get-WinOneShotJsonKind -Value $element
            if ($elementKind -eq "Null") {
                continue
            }
            if ($elementKind -ne "Object") {
                "$Location[$index] must be an object or null; found $elementKind"
                continue
            }

            foreach ($field in $nestedFields) {
                foreach ($property in (Get-WinOneShotProperty -Object $element -Name $field)) {
                    $propertyKind = Get-WinOneShotJsonKind -Value $property.Value
                    if ($propertyKind -notin @("String", "Null")) {
                        "$Location[$index].$($property.Name) must be a string or null; found $propertyKind"
                    }
                }
            }
        }
    }

    function script:Get-WinOneShotCatalogError {
        param(
            [Parameter(Mandatory)]
            [string]$Name,

            [Parameter(Mandatory)]
            [string]$Json,

            [Parameter(Mandatory)]
            [hashtable]$ScalarFields,

            [Parameter(Mandatory)]
            [hashtable]$ArrayFields
        )

        try {
            $catalog = $Json | ConvertFrom-Json -NoEnumerate -ErrorAction Stop
        } catch {
            return "WinOneShot cannot parse ${Name}: $_"
        }

        if ((Get-WinOneShotJsonKind -Value $catalog) -ne "Object") {
            return "$Name must contain a JSON object."
        }

        $entries = @($catalog.PSObject.Properties)
        if ($entries.Count -eq 0) {
            return "$Name does not contain any entries."
        }

        foreach ($entry in $entries) {
            $entryKind = Get-WinOneShotJsonKind -Value $entry.Value
            if ($entryKind -eq "Null") {
                "$Name.$($entry.Name) is null"
                continue
            }
            if ($entryKind -ne "Object") {
                "$Name.$($entry.Name) must be an object; found $entryKind"
                continue
            }

            foreach ($field in $ScalarFields.Keys) {
                foreach ($property in (Get-WinOneShotProperty -Object $entry.Value -Name $field)) {
                    Get-WinOneShotTypeError -Location "$Name.$($entry.Name).$($property.Name)" -Value $property.Value -ExpectedType $ScalarFields[$field]
                }
            }

            foreach ($field in $ArrayFields.Keys) {
                foreach ($property in (Get-WinOneShotProperty -Object $entry.Value -Name $field)) {
                    Get-WinOneShotTypeError -Location "$Name.$($entry.Name).$($property.Name)" -Value $property.Value -ExpectedType $ArrayFields[$field]
                }
            }
        }
    }
}

Describe "WinOneShot catalog download contract" {
    foreach ($catalogCase in $catalogCases) {
        It "publishes <Name> at the exact raw-download path" -TestCases $catalogCase {
            param([string]$Path)

            Test-Path -LiteralPath $Path -PathType Leaf | Should -BeTrue
            $exactNameMatch = @(
                Get-ChildItem -LiteralPath (Split-Path -Path $Path -Parent) -File |
                    Where-Object { $_.Name -ceq (Split-Path -Path $Path -Leaf) }
            )
            $exactNameMatch.Count | Should -Be 1
        }

        It "loads <Name> with WinOneShot-compatible field types" -TestCases $catalogCase {
            param(
                [string]$Name,
                [string]$Path,
                [hashtable]$ScalarFields,
                [hashtable]$ArrayFields
            )

            $json = Get-Content -LiteralPath $Path -Raw
            $errors = @(Get-WinOneShotCatalogError -Name $Name -Json $json -ScalarFields $ScalarFields -ArrayFields $ArrayFields)

            if ($errors.Count -gt 0) {
                throw ($errors -join "`n")
            }
        }
    }
}

Describe "WinOneShot catalog contract guard" {
    It "rejects consumer-breaking <Name> fixture: <ExpectedError>" -TestCases $invalidCatalogCases {
        param(
            [string]$Name,
            [string]$Json,
            [hashtable]$ScalarFields,
            [hashtable]$ArrayFields,
            [string]$ExpectedError
        )

        $errors = @(Get-WinOneShotCatalogError -Name $Name -Json $Json -ScalarFields $ScalarFields -ArrayFields $ArrayFields)

        $errors -join "`n" | Should -BeLike "*$ExpectedError*"
    }
}
