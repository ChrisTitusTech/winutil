Describe "Activity history config" {
    It "disables activity publishing while preserving clipboard history" {
        $configPath = Join-Path $PSScriptRoot "..\config\tweaks.json"
        $tweaks = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        $activityRegistry = @($tweaks.WPFTweaksActivity.registry)

        $activityFeed = @($activityRegistry | Where-Object Name -eq "EnableActivityFeed")
        $activityFeed | Should -HaveCount 1
        $activityFeed[0].Value | Should -Be "1"

        foreach ($policyName in @("PublishUserActivities", "UploadUserActivities")) {
            $policy = @($activityRegistry | Where-Object Name -eq $policyName)
            $policy | Should -HaveCount 1
            $policy[0].Value | Should -Be "0"
        }

        $activityRegistry.Name | Should -Not -Contain "AllowClipboardHistory"
    }
}
