function Set-CategoryVisibility {
    <#
        .SYNOPSIS
            Used to expand or collapse categories and corresponding apps on the install tab

        .PARAMETER Category
            Can eigther be a specific category name like "Browsers" OR "*" to affect all categories at once

        .PARAMETER overrideState
            "Expand" => expands the corresponding elements
            "Collapse" => collapses the corresponding elements
            N/A => if compactView is active expand, otherwise collapse elements
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$Category,
        [ValidateSet("Expand", "Collapse")]
        [string]$overrideState
    )

    switch ($overrideState) {
        "Expand"    {$state = $true}
        "Collapse"  {$state = $false}
        default     {$state = $sync.CompactView}
    }

    # If all the Categories are affected, update the Checked state of the ToggleButtons.
    # Otherwise, the state is not synced when toggling between the display modes
    if  ($category -eq "*") {
        $items = $sync.ItemsControl.Items | Where-Object {($_.Tag -like "CategoryWrapPanel_*")}
        $sync.ItemsControl.Items | Where-Object {($_.Tag -eq "CategoryToggleButton")} | Foreach-Object { $_.Visibility = [Windows.Visibility]::Visible; $_.IsChecked = $state }

    } else {
        $items = $sync.ItemsControl.Items | Where-Object {($_.Tag -eq "CategoryWrapPanel_$Category")}
    }

    $elementVisibility = if ($state -eq $true) {[Windows.Visibility]::Visible} else {[Windows.Visibility]::Collapsed}
    $items | ForEach-Object {
        $_.Visibility = $elementVisibility
        }
    $items.Children | ForEach-Object {
        $_.Visibility = $elementVisibility
    }
}
