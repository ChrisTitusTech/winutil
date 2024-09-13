function Invoke-WinUtilGPU {
    $gpuInfo = Get-CimInstance Win32_VideoController

    # GPUs to blacklist from using Demanding Theming
    $lowPowerGPUs = (
        "*NVIDIA GeForce*M*",
        "*NVIDIA GeForce*Laptop*",
        "*NVIDIA GeForce*GT*",
        "*AMD Radeon(TM)*",
        "*Intel(R) HD Graphics*",
        "*UHD*"

    )

    foreach ($gpu in $gpuInfo) {
        foreach ($gpuPattern in $lowPowerGPUs) {
            if ($gpu.Name -like $gpuPattern) {
                return $false
            }
        }
    }
    return $true
}
