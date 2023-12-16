function ConvertTo-Icon { 
    <#
    
        .DESCRIPTION
        This function will convert PNG to ICO file

        .EXAMPLE
        ConvertTo-Icon -bitmapPath "$env:TEMP\cttlogo.png" -iconPath $iconPath
    #>
    param( [Parameter(Mandatory=$true)] 
        $bitmapPath, 
        $iconPath = "$env:temp\newicon.ico"
    ) 
    
    Add-Type -AssemblyName System.Drawing 
    
    if (Test-Path $bitmapPath) { 
        $b = [System.Drawing.Bitmap]::FromFile($bitmapPath) 
        $icon = [System.Drawing.Icon]::FromHandle($b.GetHicon()) 
        $file = New-Object System.IO.FileStream($iconPath, 'OpenOrCreate') 
        $icon.Save($file) 
        $file.Close() 
        $icon.Dispose() 
        #explorer "/SELECT,$iconpath" 
    } 
    else { Write-Warning "$BitmapPath does not exist" } 
}