#===========================================================================
# Tests - Win11 Creator
#===========================================================================

Describe "Win11 Creator setup media" {
    It "autounattend template does not force a product key" {
        [xml]$xml = Get-Content -Path ".\tools\autounattend.xml" -Raw
        $nsMgr = New-Object System.Xml.XmlNamespaceManager($xml.NameTable)
        $nsMgr.AddNamespace("u", "urn:schemas-microsoft-com:unattend")

        $xml.SelectNodes("//u:ProductKey", $nsMgr).Count | Should Be 0
    }

    It "ISO script accepts selected edition setup metadata" {
        $content = Get-Content -Path ".\functions\private\Invoke-WinUtilISOScript.ps1" -Raw

        $content | Should Match '\[string\]\$InstallEditionId'
        $content | Should Match '\[int\]\$InstallImageIndex'
        $content | Should Match 'sources\\ei\.cfg'
        $content | Should Match 'PID\.txt'
    }
}
