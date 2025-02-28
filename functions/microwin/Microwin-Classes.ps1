class ErroredPackage {
    [string]$PackageName
    [string]$ErrorMessage
    ErroredPackage() { $this.Init(@{} )}
    # Constructor for packages that have errored out
    ErroredPackage([string]$pkgName, [string]$reason) {
        $this.PackageName = $pkgName
        $this.ErrorMessage = $reason
    }
}
