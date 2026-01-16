$FEATURE_ID = "3036241548"
$BASE_PATH = "HKLM:\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides"

$NOT_CONFIGURED = 0
$DISABLED = 1
$ENABLED = 2

<#
    By default, it seems even Administrator accounts can't edit this key's value.
    Even trying to set ACL resulted in a 'Requested registry access is not allowed.'
    errors, and thus, we need to modify the access token of our PowerShell process
    to enable the privilege we need for editing the key. This requires using Windows
    API methods via C#, and it's honestly kind of ugly, but it works.
#>
function takeKeyPermissions {
    param(
        [string]$registryPath
    )

    $definition = @"
    using System;
    using System.Runtime.InteropServices;
    public class TokenManipulator {
        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
        internal static extern bool AdjustTokenPrivileges(IntPtr htok, bool disall, ref TokPriv1Luid newst, int len, IntPtr prev, IntPtr relen);
        [DllImport("kernel32.dll", ExactSpelling = true)]
        internal static extern IntPtr GetCurrentProcess();
        [DllImport("advapi32.dll", ExactSpelling = true, SetLastError = true)]
        internal static extern bool OpenProcessToken(IntPtr h, int acc, ref IntPtr phtok);
        [DllImport("advapi32.dll", SetLastError = true)]
        internal static extern bool LookupPrivilegeValue(string host, string name, ref long pluid);
        [StructLayout(LayoutKind.Sequential, Pack = 1)]
        internal struct TokPriv1Luid {
            public int Count;
            public long Luid;
            public int Attr;
        }
        internal const int SE_PRIVILEGE_ENABLED = 0x00000002;
        internal const int TOKEN_QUERY = 0x00000008;
        internal const int TOKEN_ADJUST_PRIVILEGES = 0x00000020;
        public static bool AddPrivilege(string privilege) {
            try {
                bool retVal;
                TokPriv1Luid tp;
                IntPtr hproc = GetCurrentProcess();
                IntPtr htok = IntPtr.Zero;
                retVal = OpenProcessToken(hproc, TOKEN_ADJUST_PRIVILEGES | TOKEN_QUERY, ref htok);
                tp.Count = 1;
                tp.Luid = 0;
                tp.Attr = SE_PRIVILEGE_ENABLED;
                retVal = LookupPrivilegeValue(null, privilege, ref tp.Luid);
                retVal = AdjustTokenPrivileges(htok, false, ref tp, 0, IntPtr.Zero, IntPtr.Zero);
                return retVal;
            } catch (Exception ex) {
                throw ex;
            }
        }
    }
"@

    Add-Type -TypeDefinition $definition -PassThru | Out-Null
    [TokenManipulator]::AddPrivilege("SeRestorePrivilege") | Out-Null
    [TokenManipulator]::AddPrivilege("SeTakeOwnershipPrivilege") | Out-Null

    # Take ownership
    $hivelessPath = (("$registryPath" -split '\\', 2)[1].TrimStart('\'))

    $key = [Microsoft.Win32.Registry]::LocalMachine.OpenSubKey(
        $hivelessPath,
        [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree,
        [System.Security.AccessControl.RegistryRights]::TakeOwnership
    )
    $acl = $key.GetAccessControl()
    $acl.SetOwner([System.Security.Principal.NTAccount]"Administrators")
    $key.SetAccessControl($acl)

    # Grant full control
    $acl = $key.GetAccessControl()
    $rule = New-Object System.Security.AccessControl.RegistryAccessRule("Administrators", "FullControl", "Allow")
    $acl.SetAccessRule($rule)
    $key.SetAccessControl($acl)
    $key.Close()
}

# Check if the feature override exists
$configurationPriority = Get-ChildItem -Path $BASE_PATH | Where-Object {
    Test-Path -Path (Join-Path $_.PSPath $FEATURE_ID)
}

if ($configurationPriority) {
    Write-Host "Override found at: $($configurationPriority)"
    $targetPath = Join-Path $configurationPriority $FEATURE_ID

    try {
        takeKeyPermissions -registryPath $targetPath
    }
    catch {
        Write-Error "Could not take key permissions: $($_.Exception.Message)"
        return
    }

    $currentState = (Get-ItemProperty -Path "Registry::$targetPath" -Name "EnabledState" -ErrorAction Stop).EnabledState
    if (($currentState -eq $ENABLED) -or ($currentState -eq $NOT_CONFIGURED)) {
        try {
            Set-ItemProperty -Path "Registry::$targetPath" -Name "EnabledState" -Value $DISABLED -Type DWord -Force -ErrorAction Stop
            "New start menu layout disabled", "Please restart your computer for the changes to apply!" | Write-Host
        } catch {
            Write-Error "Could not set key value"
        }
    } elseif ($currentState -eq $DISABLED) {
        try {
            Set-ItemProperty -Path "Registry::$targetPath" -Name "EnabledState" -Value $ENABLED -Type DWord -Force -ErrorAction Stop
            "New start menu layout enabled", "Please restart your computer for the changes to apply!" | Write-Host
        } catch {
            Write-Error "Could not set key value"
        }
    } else {
        Write-Error "Unexpected state value"
    }

} else {
    Write-Error "Feature override not present"
}