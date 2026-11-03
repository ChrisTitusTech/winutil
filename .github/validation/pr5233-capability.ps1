param([string]$SourcePath = '.\functions\public\Invoke-WPFUpdatesdefault.ps1')
$ErrorActionPreference = 'Stop'
if ($env:GITHUB_ACTIONS -ne 'true' -or $env:RUNNER_ENVIRONMENT -ne 'github-hosted' -or $env:RUNNER_OS -ne 'Windows') { throw 'Disposable GitHub-hosted Windows runner required; never run on a workstation.' }
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Elevated runner required.' }
$report = [ordered]@{ OS = [Environment]::OSVersion.VersionString; PSVersion = "$($PSVersionTable.PSVersion)"; SourceHash = (Get-FileHash -LiteralPath $SourcePath).Hash; Keys = @(); Operations = @(); Cleanup = @(); ProductionLog = @(); Synthetic = @() }
$script:productionLog = [Collections.Generic.List[object]]::new()
function Write-WinUtilLog { param($Level = 'INFO', $Component, $Message) $script:productionLog.Add([pscustomobject]@{ Level=$Level; Message=$Message }) }
function Invoke-Probe { param([string]$ProbeLabel, [scriptblock]$Body)
    try { & $Body | Out-Null; $script:report.Operations += [pscustomobject]@{ Name=$ProbeLabel; Succeeded=$true; Error=$null }; return $true }
    catch { $script:report.Operations += [pscustomobject]@{ Name=$ProbeLabel; Succeeded=$false; Error=$_.Exception.Message }; return $false }
}
$tokens = $null; $parseErrors = $null
$ast = [Management.Automation.Language.Parser]::ParseFile((Resolve-Path -LiteralPath $SourcePath).Path,[ref]$tokens,[ref]$parseErrors)
if ($parseErrors.Count) { throw 'PR source did not parse.' }
$aclLoop = @($ast.FindAll({param($n) $n -is [Management.Automation.Language.ForEachStatementAst] -and $n.Variable.VariablePath.UserPath -eq 'serviceName'},$true))
if ($aclLoop.Count -ne 1) { throw 'Expected one production service ACL loop.' }
# Reuse the production loop body after its path assignment, pointed at a temporary real registry key.
$aclStatements = @($aclLoop[0].Body.Statements)
$aclBody = [scriptblock]::Create(($aclStatements | Select-Object -Skip 1 | ForEach-Object {$_.Extent.Text}) -join "`n")
$medicIf = @($ast.FindAll({param($n) $n -is [Management.Automation.Language.IfStatementAst] -and $n.Extent.Text -like '*Get-ItemProperty -Path $waaSMedicKeyPath*'},$true))
if ($medicIf.Count -ne 1) { throw 'Expected one production WaaSMedic restore block.' }
$medicBody = [scriptblock]::Create($medicIf[0].Extent.Text)
$services = @('BITS','wuauserv','UsoSvc','WaaSMedicSvc')
$snapshots = @{}
$syntheticRoot = 'HKLM:\SOFTWARE\WinUtilCapability_' + [guid]::NewGuid().ToString('N')
$cleanupFailed = $false
try {
    foreach ($name in $services) {
        $keyPath = "HKLM:\SYSTEM\CurrentControlSet\Services\$name"
        try {
            $acl = Get-Acl -LiteralPath $keyPath -ErrorAction Stop
            $key = Get-Item -LiteralPath $keyPath -ErrorAction Stop
            $service = Get-Service -Name $name -ErrorAction Stop
            $delayedExists = $key.GetValueNames() -contains 'DelayedAutoStart'
            $snapshot = [pscustomobject]@{ Path=$keyPath; Acl=$acl; Sddl=$acl.Sddl; Start=[int]$key.GetValue('Start'); DelayedExists=$delayedExists; Delayed=$key.GetValue('DelayedAutoStart'); StartupType="$($service.StartType)"; Status="$($service.Status)"; ValuesTouched=$false; AclTouched=$false; ServiceTouched=$false }
            $snapshots[$name] = $snapshot
            $report.Keys += [pscustomobject]@{ Name=$name; Owner=$acl.Owner; Sddl=$acl.Sddl; Start=$snapshot.Start; Status=$snapshot.Status; StartupType=$snapshot.StartupType; ExplicitSystemDeny=@($acl.GetAccessRules($true,$false,[Security.Principal.SecurityIdentifier]) | Where-Object { $_.AccessControlType -eq 'Deny' -and $_.IdentityReference.Value -eq 'S-1-5-18' }).Count; InheritedSystemDeny=@($acl.GetAccessRules($false,$true,[Security.Principal.SecurityIdentifier]) | Where-Object { $_.AccessControlType -eq 'Deny' -and $_.IdentityReference.Value -eq 'S-1-5-18' }).Count }
            $snapshot.ValuesTouched = Invoke-Probe "$name actual Start same-value write" { Set-ItemProperty -LiteralPath $keyPath -Name Start -Type DWord -Value $snapshot.Start -ErrorAction Stop }
            $snapshot.AclTouched = Invoke-Probe "$name actual DACL same-value write" { Set-Acl -Path $keyPath -AclObject $acl -ErrorAction Stop }
            if ($name -ne 'WaaSMedicSvc') {
                $snapshot.ServiceTouched = Invoke-Probe "$name actual SCM startup restore" { $mode=if($name -eq 'UsoSvc'){'Automatic'}else{'Manual'}; Set-Service -Name $name -StartupType $mode -ErrorAction Stop }
            }
        } catch { $report.Operations += [pscustomobject]@{ Name="$name snapshot"; Succeeded=$false; Error=$_.Exception.Message } }
    }
    $medic = $snapshots['WaaSMedicSvc']
    if ($medic -and $medic.ValuesTouched) {
        # This exercises the changed disabled-to-Manual path, only after proving rollback write access.
        $waaSMedicKeyPath = $medic.Path
        Set-ItemProperty -LiteralPath $waaSMedicKeyPath -Name Start -Type DWord -Value 4 -ErrorAction Stop
        & $medicBody
        if ((Get-ItemProperty -LiteralPath $waaSMedicKeyPath -Name Start).Start -ne 3) { throw 'Production WaaSMedic block did not restore Start=3 despite baseline write capability.' }
        $report.Operations += [pscustomobject]@{Name='WaaSMedic production disabled-to-Manual restore';Succeeded=$true;Error=$null}
    }
    elseif ($medic) {
        # Run its real protected-key no-op or warning path without changing its initial value.
        $waaSMedicKeyPath=$medic.Path; & $medicBody
    }
    # Real registry ACL exercise on disposable synthetic keys, including inherited denies.
    New-Item -Path $syntheticRoot -Force | Out-Null
    foreach ($scenario in @('Explicit','Inherited')) {
        $parentPath=Join-Path $syntheticRoot $scenario
        New-Item -Path $parentPath -Force | Out-Null
        $parentAcl=Get-Acl -LiteralPath $parentPath
        $systemSid=[Security.Principal.SecurityIdentifier]::new('S-1-5-18')
        $otherSid=[Security.Principal.SecurityIdentifier]::new('S-1-5-19')
        $inherit=if($scenario -eq 'Inherited'){[Security.AccessControl.InheritanceFlags]::ContainerInherit}else{[Security.AccessControl.InheritanceFlags]::None}
        $systemRule=[Security.AccessControl.RegistryAccessRule]::new($systemSid,[Security.AccessControl.RegistryRights]::SetValue,$inherit,[Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Deny)
        $otherRule=[Security.AccessControl.RegistryAccessRule]::new($otherSid,[Security.AccessControl.RegistryRights]::SetValue,[Security.AccessControl.InheritanceFlags]::None,[Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Deny)
        $parentAcl.AddAccessRule($systemRule); $parentAcl.AddAccessRule($otherRule)
        Set-Acl -Path $parentPath -AclObject $parentAcl
        $serviceKeyPath=$parentPath
        if($scenario -eq 'Inherited'){ $serviceKeyPath=Join-Path $parentPath 'Child'; New-Item -Path $serviceKeyPath -Force | Out-Null }
        $serviceName="synthetic-$scenario"
        $beforeAcl=Get-Acl -LiteralPath $serviceKeyPath
        & $aclBody
        $afterAcl=Get-Acl -LiteralPath $serviceKeyPath
        $rules=@($afterAcl.GetAccessRules($true,$true,[Security.Principal.SecurityIdentifier]))
        $remainingSystem=@($rules | Where-Object {$_.AccessControlType -eq 'Deny' -and $_.IdentityReference.Value -eq 'S-1-5-18'})
        if($scenario -eq 'Explicit' -and $remainingSystem.Count -ne 0){throw 'Explicit SYSTEM deny was not removed.'}
        if($scenario -eq 'Inherited' -and $remainingSystem.Count -eq 0){throw 'Inherited SYSTEM deny unexpectedly changed.'}
        $expectedAcl=[Security.AccessControl.RegistrySecurity]::new(); $expectedAcl.SetSecurityDescriptorSddlForm($beforeAcl.Sddl)
        if($scenario -eq 'Explicit'){foreach($rule in @($expectedAcl.GetAccessRules($true,$false,[Security.Principal.SecurityIdentifier]) | Where-Object {$_.AccessControlType -eq 'Deny' -and $_.IdentityReference.Value -eq 'S-1-5-18'})){ $expectedAcl.RemoveAccessRule($rule)|Out-Null }}
        if($afterAcl.Sddl -ne $expectedAcl.Sddl){throw 'Production ACL removal changed an unrelated ACE.'}
        $report.Synthetic += [pscustomobject]@{Scenario=$scenario;Before=$beforeAcl.Sddl;After=$afterAcl.Sddl;Passed=$true}
    }
    if($snapshots['UsoSvc'] -and $snapshots['UsoSvc'].ServiceTouched){[void](Invoke-Probe 'UsoSvc actual start' {Start-Service -Name UsoSvc -ErrorAction Stop})}
}
finally {
    foreach($name in $services){
        $snapshot=$snapshots[$name]
        if(-not $snapshot){continue}
        try {
            if($snapshot.ServiceTouched){Set-Service -Name $name -StartupType $snapshot.StartupType -ErrorAction Stop}
            if($snapshot.ValuesTouched -or $snapshot.ServiceTouched){
                Set-ItemProperty -LiteralPath $snapshot.Path -Name Start -Type DWord -Value $snapshot.Start -ErrorAction Stop
                if($snapshot.DelayedExists){Set-ItemProperty -LiteralPath $snapshot.Path -Name DelayedAutoStart -Type DWord -Value $snapshot.Delayed -ErrorAction Stop}else{Remove-ItemProperty -LiteralPath $snapshot.Path -Name DelayedAutoStart -ErrorAction SilentlyContinue}
            }
            if($name -eq 'UsoSvc' -and $snapshot.ServiceTouched -and $snapshot.Status -eq 'Stopped' -and (Get-Service $name).Status -ne 'Stopped'){Stop-Service -Name $name -Force -ErrorAction Stop}
            if($snapshot.AclTouched){Set-Acl -Path $snapshot.Path -AclObject $snapshot.Acl -ErrorAction Stop}
            $finalAcl=Get-Acl -LiteralPath $snapshot.Path
            $finalStart=(Get-ItemProperty -LiteralPath $snapshot.Path -Name Start).Start
            if($finalAcl.Sddl -ne $snapshot.Sddl -or $finalStart -ne $snapshot.Start){throw 'Original service key state was not restored.'}
            $report.Cleanup += [pscustomobject]@{Name=$name;Restored=$true;Error=$null}
        }catch{$cleanupFailed=$true;$report.Cleanup += [pscustomobject]@{Name=$name;Restored=$false;Error=$_.Exception.Message}}
    }
    if(Test-Path -LiteralPath $syntheticRoot){Remove-Item -LiteralPath $syntheticRoot -Recurse -Force}
    $report.ProductionLog=@($script:productionLog.ToArray())
    $outputPath=Join-Path $env:RUNNER_TEMP 'winutil-pr5233-capability.json'
    $report | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $outputPath -Encoding UTF8
    Get-Content -LiteralPath $outputPath
    if($cleanupFailed){throw 'Capability test cleanup failed; inspect report.'}
}
