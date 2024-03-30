function Invoke-WinUtilGPU {
    $gpuInfo = Get-CimInstance Win32_VideoController
    
    foreach ($gpu in $gpuInfo) {
        $gpuName = $gpu.Name
        if ($gpuName -like "*NVIDIA*") {
            return $true  # NVIDIA GPU found
        }
    }

    foreach ($gpu in $gpuInfo) {
        $gpuName = $gpu.Name
        if ($gpuName -like "*AMD Radeon RX*") {
            return $true # AMD GPU Found 
        }
    }
    foreach ($gpu in $gpuInfo) {
        $gpuName = $gpu.Name
        if ($gpuName -like "*UHD*") {
            return $false # Intel Intergrated GPU Found 
        }
    }
    foreach ($gpu in $gpuInfo) {
        $gpuName = $gpu.Name
        if ($gpuName -like "*AMD Radeon(TM)*") {
            return $false # AMD Intergrated GPU Found 
        }
    }
}