function Copy-Files {
    <#

        .DESCRIPTION
        This function will make all modifications to the registry

        .EXAMPLE

        Set-WinUtilRegistry -Name "PublishUserActivities" -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System" -Type "DWord" -Value "0"

    #>
    param (
        [string] $Path,
        [string] $Destination,
        [switch] $Recurse = $false,
        [switch] $Force = $false
    )

    try {

 	$files = Get-ChildItem -Path $path -Recurse:$recurse
	Write-Host "Copy $($files.Count)(s) from $path to $destination"

        foreach($file in $files)
        {
            $status = "Copy files {0} on {1}: {2}" -f $counter, $files.Count, $file.Name
            Write-Progress -Activity "Copy Windows files" -Status $status -PercentComplete ($counter++/$files.count*100)
            $restpath = $file.FullName -Replace $path, ''

            if($file.PSIsContainer -eq $true)
            {
                Write-Debug "Creating $($destination + $restpath)"
                New-Item ($destination+$restpath) -Force:$force -Type Directory -ErrorAction SilentlyContinue
            }
            else
            {
                Write-Debug "Copy from $($file.FullName) to $($destination+$restpath)"
                Copy-Item $file.FullName ($destination+$restpath) -ErrorAction SilentlyContinue -Force:$force
                Set-ItemProperty -Path ($destination+$restpath) -Name IsReadOnly -Value $false
            }
        }
        Write-Progress -Activity "Copy Windows files" -Status "Ready" -Completed
    }
    Catch{
        Write-Warning "Unable to Copy all the files due to unhandled exception"
        Write-Warning $psitem.Exception.StackTrace
    }
}