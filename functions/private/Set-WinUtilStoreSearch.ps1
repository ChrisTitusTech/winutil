function Set-WinUtilStoreSearch {
    param([switch]$Undo)

    $storeData = "$env:LocalAppData\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState"
    if (-not (Test-Path -LiteralPath $storeData)) { return }

    $statePath = 'HKCU:\Software\WinUtil\StoreSearch'
    $stateKey = if (Test-Path -LiteralPath $statePath) { Get-Item -LiteralPath $statePath -ErrorAction Stop }
    $accessSection = [System.Security.AccessControl.AccessControlSections]::Access
    $everyone = [System.Security.Principal.SecurityIdentifier]::new('S-1-1-0')

    $updateTarget = {
        param($name)
        # State can only refer to this Store folder or its immediate catalog files.
        if ($name -ne '.' -and ($name -notlike 'store*.db' -or $name -match '[/\\:]')) {
            throw "Invalid Store search ACL state name '$name'."
        }
        $path = if ($name -eq '.') { $storeData } else { Join-Path $storeData $name }
        $saved = if ($null -ne $stateKey) { $stateKey.GetValue($name) }
        $state = if ($saved) { $saved | ConvertFrom-Json -ErrorAction Stop }
        if (-not (Test-Path -LiteralPath $path)) {
            if ($Undo) { Remove-ItemProperty -LiteralPath $statePath -Name $name -ErrorAction Stop }
            return
        }
        $created = (Get-Item -LiteralPath $path -ErrorAction Stop).CreationTimeUtc.Ticks
        $acl = Get-Acl -LiteralPath $path -ErrorAction Stop
        $current = $acl.GetSecurityDescriptorSddlForm($accessSection)

        if ($state) {
            if ($created -ne $state.Created) {
                if ($Undo) {
                    # The Store replaced the catalog; its old ACL must not be applied to a new file.
                    Remove-ItemProperty -LiteralPath $statePath -Name $name -ErrorAction Stop
                    return
                }
                throw "Store search target '$path' was replaced; undo its saved state before applying again."
            }
            if ($current -ne $state.Original -and $current -ne $state.Applied) {
                throw "Permissions on '$path' changed after the Store search tweak; leaving them intact."
            }
            $desired = if ($Undo) { $state.Original } else { $state.Applied }
            if ($current -ne $desired) {
                $acl.SetSecurityDescriptorSddlForm($desired, $accessSection)
                Set-WinUtilStoreSearchAcl -Path $path -AclObject $acl
            }
            if ($Undo) { Remove-ItemProperty -LiteralPath $statePath -Name $name -ErrorAction Stop }
            return
        }

        if ($Undo) { return }
        $rights = if ($name -eq '.') { [System.Security.AccessControl.FileSystemRights]::WriteData } else { [System.Security.AccessControl.FileSystemRights]::FullControl }
        $rules = $acl.GetAccessRules($true, $false, [System.Security.Principal.SecurityIdentifier])
        if ($rules | Where-Object {
            $_.AccessControlType -eq 'Deny' -and $_.IdentityReference -eq $everyone -and
            $_.PropagationFlags -notmatch 'InheritOnly' -and ($_.FileSystemRights -band $rights) -eq $rights
        }) { return }

        $acl.AddAccessRule([System.Security.AccessControl.FileSystemAccessRule]::new($everyone, $rights, 'Deny'))
        $state = [ordered]@{ Created = $created; Original = $current; Applied = $acl.GetSecurityDescriptorSddlForm($accessSection) }
        if ($null -eq $stateKey) {
            $stateKey = New-Item -Path $statePath -Force -ErrorAction Stop
        }
        # Persist both states before changing permissions, so a failed write can be retried or undone.
        New-ItemProperty -LiteralPath $statePath -Name $name -Value ($state | ConvertTo-Json -Compress) -PropertyType String -ErrorAction Stop | Out-Null
        Set-WinUtilStoreSearchAcl -Path $path -AclObject $acl
    }
    if ($Undo) {
        if ($null -eq $stateKey) { return }
        foreach ($name in @($stateKey.GetValueNames())) { . $updateTarget $name }
    } else {
        # Block catalog creation before taking the snapshot of existing catalog files.
        . $updateTarget '.'
        $catalogs = @(Get-ChildItem -LiteralPath $storeData -File -Force -ErrorAction Stop | Where-Object Name -like 'store*.db')
        foreach ($catalog in $catalogs) { . $updateTarget $catalog.Name }
    }
}

function Set-WinUtilStoreSearchAcl {
    param([string]$Path, [System.Security.AccessControl.FileSystemSecurity]$AclObject)

    # Persist only the modified access section; the provider can also rewrite SACL flags.
    $item = if ($AclObject -is [System.Security.AccessControl.DirectorySecurity]) {
        [System.IO.DirectoryInfo]::new($Path)
    } else {
        [System.IO.FileInfo]::new($Path)
    }
    if ($PSVersionTable.PSEdition -eq 'Core') {
        [System.IO.FileSystemAclExtensions]::SetAccessControl($item, $AclObject)
    } else {
        $item.SetAccessControl($AclObject)
    }
}
