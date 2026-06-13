$ErrorActionPreference = "Stop"

$repo = "Tyranosaur/tv-apk-menu"
$apkDir = Join-Path $PSScriptRoot "apks"
$iconDir = Join-Path $PSScriptRoot "icons"
$descriptionObject = Get-Content -LiteralPath (Join-Path $PSScriptRoot "catalog-descriptions.json") -Raw -Encoding UTF8 | ConvertFrom-Json
$descriptions = @{}
foreach ($property in $descriptionObject.PSObject.Properties) {
    $descriptions[$property.Name] = $property.Value
}
$aapt = "C:\Users\putin\Documents\Codex\2026-05-24\https-kinobase-org-homatics-box-4\.tools\android-sdk\build-tools\35.0.0\aapt.exe"

New-Item -ItemType Directory -Force -Path $iconDir | Out-Null
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Get-Description([string]$name) {
    $lower = $name.ToLowerInvariant()
    foreach ($key in $descriptions.Keys) {
        if ($lower.Contains($key.ToLowerInvariant())) {
            return $descriptions[$key]
        }
    }
    return "Приложение для Android TV."
}

$catalog = foreach ($file in Get-ChildItem -LiteralPath $apkDir -File -Filter "*.apk" | Sort-Object Name) {
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $badging = & $aapt dump badging $file.FullName 2>$null
    $ErrorActionPreference = $oldPreference
    $label = [IO.Path]::GetFileNameWithoutExtension($file.Name)
    $package = ""
    $iconPath = ""

    foreach ($line in $badging) {
        if ($line -match "^package: name='([^']+)'") { $package = $matches[1] }
        if ($line -match "^application-label:'([^']+)'") { $label = $matches[1] }
        if ($line -match "^application-icon-\d+:'([^']+)'") { $iconPath = $matches[1] }
    }

    $safeName = ($file.BaseName -replace '[^A-Za-z0-9._-]', '_') + ".png"
    $iconTarget = Join-Path $iconDir $safeName
    if ($iconPath -and !(Test-Path -LiteralPath $iconTarget)) {
        $zip = [IO.Compression.ZipFile]::OpenRead($file.FullName)
        try {
            $entry = $zip.GetEntry($iconPath)
            if ($entry) {
                [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $iconTarget, $true)
            }
        } finally {
            $zip.Dispose()
        }
    }

    [ordered]@{
        name = $file.Name
        displayName = $label
        description = Get-Description $file.Name
        packageName = $package
        size = $file.Length
        downloadUrl = "https://raw.githubusercontent.com/$repo/main/apks/$([Uri]::EscapeDataString($file.Name))"
        iconUrl = if (Test-Path -LiteralPath $iconTarget) { "https://raw.githubusercontent.com/$repo/main/icons/$([Uri]::EscapeDataString($safeName))" } else { "" }
    }
}

$catalog | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $PSScriptRoot "catalog.json") -Encoding UTF8
Write-Host "Catalog generated: $($catalog.Count) applications"
