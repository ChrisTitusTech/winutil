function Initialize-AppStackPanel {
    <#
        .SYNOPSIS
            Clears the given WPF Grid and creates a [Windows.Controls.Border] containing a [Windows.Controls.StackPanel]
            Used to as part of the Install Tab UI generation
        .PARAMETER TargetGridName
            The WPF Grid name 
        .OUTPUTS
            Returns the created [Windows.Controls.StackPanel] element
    #>
    param(
        [Parameter(Mandatory)]
        [string]$TargetGridName
    )
    $targetGrid = $sync.Form.FindName($TargetGridName)       
    $null = $targetGrid.Children.Clear()

    $Border = New-Object Windows.Controls.Border
    $Border.VerticalAlignment = "Stretch"
    $Border.SetResourceReference([Windows.Controls.Control]::StyleProperty, "BorderStyle")
    $StackPanel = New-Object Windows.Controls.StackPanel
    $Border.Child = $StackPanel
    $null = $targetGrid.Children.Add($Border)

    return $StackPanel
}