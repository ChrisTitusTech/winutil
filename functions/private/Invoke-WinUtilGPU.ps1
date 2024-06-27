function Invoke-WinUtilGPU {
    $gpuInfo = Get-CimInstance Win32_VideoController

    # GPUs to blacklist from using Demanding Theming
    foreach ($gpu in $gpuInfo) {
        $gpuName = $gpu.Name
        if ($gpuName -like "*NVIDIA GeForce*M*" -OR
            $gpuName -like "*NVIDIA GeForce*Laptop*" -OR
            $gpuName -like "*NVIDIA GeForce*GT*" -OR
            $gpuName -like "*AMD Radeon(TM)*" -OR
            $gpuName -like "*UHD*") {
            return $false
        }
    }

    # GPUs to whitelist on using Demanding Theming
    foreach ($gpu in $gpuInfo) {
        $gpuName = $gpu.Name
        if ($gpuName -like "*NVIDIA*" -OR
            $gpuName -like "*AMD Radeon RX*") {
            return $true
        }
    }
}
