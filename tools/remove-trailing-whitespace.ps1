# Change into winutil root folder
Set-Location ..\

# Get all files that we remove trailing whitespace (if any are found) from them
$files = Get-ChildItem -Recurse -Exclude ".\.git\", "LICENSE", "*.png", "*.jpg", "*.jpeg", "*.exe" -Attributes !Directory

# Loop over every file, and do a 'Trim' on it to Trim/Remove Trailing Whitespace
# The general idea was Taken from a StackOverFlow Answer, link to it: https://stackoverflow.com/a/61443973
foreach ($file in $files) {
    (Get-Content "$($file.FullName)").TrimEnd() | Set-Content "$($file.FullName)"
}
