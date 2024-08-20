function Set-DownloadEngine {
    $CheckBoxes = $sync.GetEnumerator() | Where-Object { $_.Value -is [System.Windows.Controls.CheckBox] }
    
    foreach ($CheckBox in $CheckBoxes) {
        if ($CheckBox.Key.StartsWith("WPFInstall")) {
            Switch ($sync.DownloadEngine) {
                "Winget" {
                    if ($($sync.configs.applications.$($CheckBox.Name).winget) -eq "na"){
                        $CheckBox.Value.Visibility = "Collapsed"
                        $sync."$($CheckBox.Key)Link".Visibility = "Collapsed"

                    }
                    else{
                        $CheckBox.Value.Visibility = "Visible"
                        $sync."$($CheckBox.Key)Link".Visibility = "Visible"
                    }
                }
                "Chocolatey"{
                    if ($($sync.configs.applications.$($CheckBox.Name).chocolatey) -eq "na"){
                        $CheckBox.Value.Visibility = "Collapsed"
                        $sync."$($CheckBox.Key)Link".Visibility = "Collapsed"
                    }
                    else {
                        $CheckBox.Value.Visibility = "Visible"
                        $sync."$($CheckBox.Key)Link".Visibility = "Visible"
                    }
                }
                default{
                    $CheckBox.Value.Visibility = "Visible"
                    $sync."$($CheckBox.Key)Link".Visibility = "Visible"
                }
            }
        }
    }
}