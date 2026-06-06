Describe 'Invoke-WPFtweaksbutton runspace script' {
    It 'Uses totalSteps for progress mode instead of outer-scope Tweaks' {
        $source = Get-Content (Join-Path $PSScriptRoot '..\functions\public\Invoke-WPFtweaksbutton.ps1') -Raw
        $source | Should -Match '\$totalSteps -eq 1'
        $runspaceBlock = ($source -split 'Invoke-WPFRunspace')[1]
        $runspaceBlock.Contains('$Tweaks.Count') | Should -Be $false
    }
}