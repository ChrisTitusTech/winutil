function Invoke-WPFUpdateHistoryToggle {
    if ($sync["WPFShowUpdateHistory"].Content -eq "Show History") {
        $sync["WPFShowUpdateHistory"].Content = "Show available Updates"
        $sync["HistoryGrid"].Visibility = "Visible"
        $sync["UpdatesGrid"].Visibility = "Collapsed"
    } else {
        $sync["WPFShowUpdateHistory"].Content = "Show History"
        $sync["HistoryGrid"].Visibility = "Collapsed"
        $sync["UpdatesGrid"].Visibility = "Visible"
    }
}
