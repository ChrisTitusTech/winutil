param(
    [string]$ConfigDir = "config"
)

$RequiredAppProperties = @("content", "category", "panel", "link")
$RequiredTweakProperties = @("Content", "Description", "category", "panel")

function Test-JsonFile {
    param([string]$FilePath)

    Write-Host "Testing $FilePath..." -NoNewline
    try {
        $content = Get-Content $FilePath -Raw | ConvertFrom-Json -ErrorAction Stop
        Write-Host " [PASS: Syntax]" -ForegroundColor Green
        return $content
    } catch {
        Write-Host " [FAIL: Syntax]" -ForegroundColor Red
        Write-Error "Invalid JSON in $FilePath : $_"
        return $null
    }
}

$script:validationSuccess = $true

Get-ChildItem $ConfigDir -Filter *.json | ForEach-Object {
    $json = Test-JsonFile $_.FullName
    if ($null -eq $json) {
        $script:validationSuccess = $false
        return
    }

    if ($_.Name -eq "applications.json") {
        foreach ($prop in $json.PSObject.Properties) {
            foreach ($req in $RequiredAppProperties) {
                if ($null -eq $prop.Value.$req) {
                    Write-Warning "App '$($prop.Name)' in '$($_.Name)' is missing required property '$req'"
                    $script:validationSuccess = $false
                }
            }
        }
    } elseif ($_.Name -eq "tweaks.json") {
        foreach ($prop in $json.PSObject.Properties) {
            foreach ($req in $RequiredTweakProperties) {
                if ($null -eq $prop.Value.$req) {
                    Write-Warning "Tweak '$($prop.Name)' in '$($_.Name)' is missing required property '$req'"
                    $script:validationSuccess = $false
                }
            }
        }
    }
}

if ($script:validationSuccess) {
    Write-Host "`nAll configurations passed validation!" -ForegroundColor Green
} else {
    Write-Host "`nConfiguration validation failed." -ForegroundColor Red
}
