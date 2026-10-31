#===========================================================================
# Tests - Install tab category filter chips match the catalog
#===========================================================================
# A category with no chip cannot be filtered, and a chip for a category no
# app uses is a control that never matches anything.

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

    $applications = Get-Content (Join-Path $script:repoRoot "config\applications.json") -Raw | ConvertFrom-Json
    $script:catalogCategories = @(
        $applications.PSObject.Properties |
            ForEach-Object { [string]$_.Value.category } |
            Where-Object { $_ } |
            Sort-Object -Unique
    )

    $interfaceSource = Get-Content (Join-Path $script:repoRoot "functions\private\Start-WinUtilUserInterface.ps1") -Raw
    $script:chips = @(
        [regex]::Matches($interfaceSource, '@\{\s*Name\s*=\s*"(?<name>WPFSearchChip\w+)";\s*Category\s*=\s*"(?<category>[^"]*)"\s*\}') |
            ForEach-Object {
                [pscustomobject]@{
                    Name     = $_.Groups['name'].Value
                    Category = $_.Groups['category'].Value
                }
            }
    )

    $xamlSource = Get-Content (Join-Path $script:repoRoot "xaml\inputXML.xaml") -Raw
    $script:xamlChipNames = @(
        [regex]::Matches($xamlSource, '<ToggleButton\s+Name="(?<name>WPFSearchChip\w+)"') |
            ForEach-Object { $_.Groups['name'].Value }
    )
}

Describe "Install tab category chips" {
    It "registers a chip for every category used by an app" {
        $chipCategories = @($script:chips | ForEach-Object { $_.Category } | Where-Object { $_ } | Sort-Object -Unique)
        $missing = @($script:catalogCategories | Where-Object { $chipCategories -notcontains $_ })

        $missing | Should -BeNullOrEmpty -Because "each category needs a filter chip: $($missing -join ', ')"
    }

    It "has no chip for a category no app uses" {
        $chipCategories = @($script:chips | ForEach-Object { $_.Category } | Where-Object { $_ })
        $unused = @($chipCategories | Where-Object { $script:catalogCategories -notcontains $_ })

        $unused | Should -BeNullOrEmpty -Because "a chip that matches nothing is a dead control: $($unused -join ', ')"
    }

    It "keeps one 'All' chip with an empty category" {
        @($script:chips | Where-Object { -not $_.Category }).Count | Should -Be 1
    }

    It "defines every registered chip in the XAML" {
        $undefined = @($script:chips | Where-Object { $script:xamlChipNames -notcontains $_.Name } | ForEach-Object { $_.Name })

        $undefined | Should -BeNullOrEmpty -Because "a chip wired in code must exist in the UI: $($undefined -join ', ')"
    }

    It "registers every chip defined in the XAML" {
        $chipNames = @($script:chips | ForEach-Object { $_.Name })
        $unwired = @($script:xamlChipNames | Where-Object { $chipNames -notcontains $_ })

        $unwired | Should -BeNullOrEmpty -Because "a chip in the UI must be wired to a category: $($unwired -join ', ')"
    }

    It "covers the security tooling categories" {
        $chipCategories = @($script:chips | ForEach-Object { $_.Category })

        foreach ($category in @("Security", "Networking", "Red Team", "Blue Team")) {
            $chipCategories | Should -Contain $category
            $script:catalogCategories | Should -Contain $category
        }
    }
}
