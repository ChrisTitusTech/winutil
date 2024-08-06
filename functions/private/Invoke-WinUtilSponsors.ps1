Function Invoke-WinUtilSponsors {
    <#
    .SYNOPSIS
        Lists Sponsors from ChrisTitusTech
    .DESCRIPTION
        Lists Sponsors from ChrisTitusTech
    .EXAMPLE
        Invoke-WinUtilSponsors
    .NOTES
        This function is used to list sponsors from ChrisTitusTech
    #>
    try {
        # Define the URL and headers
        $url = "https://github.com/sponsors/ChrisTitusTech"
        $headers = @{
            "User-Agent" = "Chrome/58.0.3029.110"
        }

        # Fetch the webpage content
        try {
            $html = Invoke-RestMethod -Uri $url -Headers $headers
        } catch {
            Write-Output $_.Exception.Message
            exit
        }

        # Use regex to extract the content between "Current sponsors" and "Past sponsors"
        $currentSponsorsPattern = '(?s)(?<=Current sponsors).*?(?=Past sponsors)'
        $currentSponsorsHtml = [regex]::Match($html, $currentSponsorsPattern).Value

        # Use regex to extract the sponsor usernames from the alt attributes in the "Current Sponsors" section
        $sponsorPattern = '(?<=alt="@)[^"]+'
        $sponsors = [regex]::Matches($currentSponsorsHtml, $sponsorPattern) | ForEach-Object { $_.Value }

        # Exclude "ChrisTitusTech" from the sponsors
        $sponsors = $sponsors | Where-Object { $_ -ne "ChrisTitusTech" }

        # Return the sponsors
        return $sponsors
    } catch {
        Write-Error "An error occurred while fetching or processing the sponsors: $_"
        return $null
    }
}
