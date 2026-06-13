$ErrorActionPreference = "Stop"

& "$PSScriptRoot\generate-catalog.ps1"
& "$PSScriptRoot\update-menu.ps1"
Push-Location $PSScriptRoot
try {
    git add .
    git commit -m "Update APK menu"
    git push
} finally {
    Pop-Location
}
