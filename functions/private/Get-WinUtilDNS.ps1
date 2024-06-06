function Get-WinUtilDNS {
    <#

    .SYNOPSIS
        Gets the DNS of all interfaces that are in the "Up" state. It will set the default state of the ComboBox to the DNS provider that is currently set on the interface.

    #>

    Try {
        $Adapters = Get-NetAdapter | Where-Object {$_.Status -eq "Up"}
    
        # Get all DNS providers and their server addresses
        $dnsProviders = $sync.configs.dns.PSObject.Properties | ForEach-Object {
            @{
                Name = $_.Name
                Primary = $_.Value.Primary
                Secondary = $_.Value.Secondary
            }
        }
    
        # Initialize a variable to hold the matched provider
        $matchedProvider = $null
        $global:previousDnsSettings = @()
    
        Foreach ($Adapter in $Adapters) {
            Try {
                # Get the current DNS server addresses
                $currentDnsServers = (Get-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4).ServerAddresses
    
                # Save the current DNS server addresses
                $global:previousDnsSettings += @{
                    AdapterName = $Adapter.Name
                    DnsAddresses = $currentDnsServers
                }
    
                # Check if the current DNS servers match any of the providers
                $matchingProvider = $dnsProviders | Where-Object {
                    $currentDnsServers -contains $_.Primary -and $currentDnsServers -contains $_.Secondary
                }
    
                if ($matchingProvider) {
                    # If this is the first match, set the matchedProvider
                    if (-not $matchedProvider) {
                        $matchedProvider = $matchingProvider.Name
                    } elseif ($matchedProvider -ne $matchingProvider.Name) {
                        # If there is a mismatch in providers, set to Custom
                        $matchedProvider = "Custom"
                        break
                    }
                } else {
                    # If no match is found, set to Custom
                    $matchedProvider = "Custom"
                    break
                }
            } Catch {
                Write-Warning "Failed to process adapter: $($Adapter.Name)"
                Write-Warning $_.Exception.Message
                Write-Warning $_.Exception.StackTrace
            }
        }
    
        # Set the text of $sync["WPFchangedns"] to the result text
        $sync["WPFchangedns"].text = if ($matchedProvider) { $matchedProvider } else { "Custom" }
    }
    Catch {
        Write-Warning "Unable to get DNS Provider due to an unhandled exception"
        Write-Warning $_.Exception.Message
        Write-Warning $_.Exception.StackTrace
    }
}
