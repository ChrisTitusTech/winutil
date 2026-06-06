#===========================================================================
# Tests - Functions
#===========================================================================
$ps1Files = Get-ChildItem -Path (Join-Path $PSScriptRoot '..\functions') -Filter *.ps1 -Recurse

Describe "Comprehensive Checks for PS1 Files in Functions Folder" -ForEach $ps1Files {
    It "Should have no syntax errors for $($_.Name)" {
        $syntaxErrors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $_.FullName -Raw), [ref]$syntaxErrors)
        $syntaxErrors.Count | Should -Be 0
    }

    It "Should not use deprecated cmdlets or aliases in $($_.Name)" {
        $content = Get-Content -Path $_.FullName -Raw
        $content | Should -Not -Match 'DeprecatedCmdlet'
    }

    It "Should follow naming conventions for functions in $($_.Name)" {
        $tokens = [System.Management.Automation.PSParser]::Tokenize((Get-Content -Path $_.FullName -Raw), [ref]$null)
        $functionNames = @()
        for ($i = 0; $i -lt $tokens.Count; $i++) {
            if ($tokens[$i].Type -eq 'Keyword' -and $tokens[$i].Content -eq 'function' -and ($i + 1) -lt $tokens.Count) {
                $functionNames += $tokens[$i + 1].Content
            }
        }
        foreach ($functionName in $functionNames) {
            $functionName | Should -Match '^[A-Za-z][A-Za-z0-9]*(-[A-Za-z][A-Za-z0-9]*)*$'
        }
    }
}