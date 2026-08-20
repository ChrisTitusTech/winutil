#===========================================================================
# Tests - Get-WinUtilVariables
#===========================================================================

BeforeAll {
    $script:repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
    $script:originalSyncVariable = Get-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
    if ($script:originalSyncVariable) {
        $script:originalSyncValue = $script:originalSyncVariable.Value
    }
    $global:sync = [Hashtable]::Synchronized(@{})

    # Setup some test variables
    $global:sync["WPFTestString"] = "I am a string"
    $global:sync["WPFTestObj1"] = [PSCustomObject]@{ Name = "Test1" }
    $global:sync["WPFTestObj2"] = [PSCustomObject]@{ Name = "Test2" }
    $global:sync["WPFTestButton"] = [System.Version]::new("1.0.0.0")
    $global:sync["OtherVar"] = "Not a WPF variable"

    . (Join-Path $script:repoRoot "functions\private\Get-WinUtilVariables.ps1")
}

AfterAll {
    if ($script:originalSyncVariable) {
        Set-Variable -Name sync -Value $script:originalSyncValue -Scope Global -Force
    } else {
        Remove-Variable -Name sync -Scope Global -ErrorAction SilentlyContinue
    }
}

Describe "Get-WinUtilVariables" {

    It "returns all WPF-prefixed keys when no type is provided" {
        $result = Get-WinUtilVariables
        $result.Count | Should -Be 4
        $result | Should -Contain "WPFTestString"
        $result | Should -Contain "WPFTestObj1"
        $result | Should -Contain "WPFTestObj2"
        $result | Should -Contain "WPFTestButton"
        $result | Should -Not -Contain "OtherVar"
    }

    It "returns only WPF keys matching the specified exact type" {
        $result = Get-WinUtilVariables -Type "String"
        $result.Count | Should -Be 1
        $result | Should -Contain "WPFTestString"
    }

    It "returns multiple objects matching PSCustomObject" {
        $result = Get-WinUtilVariables -Type "PSCustomObject"
        $result.Count | Should -Be 2
        $result | Should -Contain "WPFTestObj1"
        $result | Should -Contain "WPFTestObj2"
    }

    It "returns an empty list when no matching type is found" {
        $result = Get-WinUtilVariables -Type "Int32"
        $result | Should -BeNullOrEmpty
    }
}
