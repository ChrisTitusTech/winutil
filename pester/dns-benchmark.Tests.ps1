BeforeAll {
    . "$PSScriptRoot/../functions/private/Get-WinUtilDNSBenchmark.ps1"
    function Write-WinUtilLog { param($Message, $Level, $Component) }
}

Describe 'Get-WinUtilDNSBenchmark' {
    BeforeEach {
        $script:sync = @{ configs = @{ dns = Get-Content "$PSScriptRoot/../config/dns.json" -Raw | ConvertFrom-Json } }
        $script:probeCompleted = $true
        $script:connectFails = $false
        $script:disposed = 0
        $script:ended = 0
        $script:probed = @()
        Mock Write-WinUtilLog { }
        Mock New-Object {
            $client = [pscustomobject]@{}
            $client | Add-Member ScriptMethod BeginConnect {
                param($Address, $Port, $Callback, $State)
                $script:probed += $Address
                $handle = [pscustomobject]@{}
                $handle | Add-Member ScriptMethod WaitOne { param($Timeout, $ExitContext) return $script:probeCompleted }
                return [pscustomobject]@{ AsyncWaitHandle = $handle }
            }
            $client | Add-Member ScriptMethod EndConnect {
                param($Result)
                $script:ended++
                if ($script:connectFails) { throw 'Connection refused' }
            }
            $client | Add-Member ScriptMethod Dispose { $script:disposed++ }
            return $client
        } -ParameterFilter { $TypeName -eq 'System.Net.Sockets.TcpClient' }
    }

    AfterEach {
        Remove-Variable sync -Scope Script
    }

    It 'only probes explicitly eligible unfiltered providers, including when an unknown provider is added' {
        $script:sync.configs.dns | Add-Member NoteProperty UnknownProvider ([pscustomobject]@{ Primary = '192.0.2.1' })
        $results = @(Get-WinUtilDNSBenchmark)
        $results.Count | Should -Be 2
        $results.Provider | Should -Contain 'Google'
        $results.Provider | Should -Contain 'Cloudflare'
        $script:probed.Count | Should -Be 2
        $script:probed | Should -Contain '8.8.8.8'
        $script:probed | Should -Contain '1.1.1.1'
        @($results | Where-Object LatencyMs -ge 9999).Count | Should -Be 0
        $script:ended | Should -Be 2
        $script:disposed | Should -Be 2
    }

    It 'disposes timed out probes and marks them unavailable' {
        $script:probeCompleted = $false
        $results = @(Get-WinUtilDNSBenchmark)
        @($results | Where-Object LatencyMs -eq 9999).Count | Should -Be 2
        $script:disposed | Should -Be 2
        $script:ended | Should -Be 0
    }

    It 'does not treat EndConnect failures as successful latency measurements' {
        $script:connectFails = $true
        $results = @(Get-WinUtilDNSBenchmark)
        @($results | Where-Object LatencyMs -eq 9999).Count | Should -Be 2
        $script:disposed | Should -Be 2
        $script:ended | Should -Be 2
    }

    It 'returns no results when no providers are eligible' {
        $script:sync.configs.dns.Google.BenchmarkEligible = $false
        $script:sync.configs.dns.Cloudflare.BenchmarkEligible = $false
        @(Get-WinUtilDNSBenchmark).Count | Should -Be 0
        Should -Invoke New-Object -Times 0 -Exactly
    }

    It 'rejects infinite or out-of-range timeouts' {
        { Get-WinUtilDNSBenchmark -TimeoutMs -1 } | Should -Throw
        { Get-WinUtilDNSBenchmark -TimeoutMs 10000 } | Should -Throw
    }
}
