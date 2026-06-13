$ErrorActionPreference = "Stop"

$apkDir = Join-Path $PSScriptRoot "apks"
$files = Get-ChildItem -LiteralPath $apkDir -File -Filter "*.apk" | Sort-Object Name
$fromCodePoints = {
    param([int[]]$CodePoints)
    -join ($CodePoints | ForEach-Object { [char]$_ })
}
$pageTitle = "APK " + (& $fromCodePoints @(0x0434, 0x043B, 0x044F)) + " Android TV"
$heading = & $fromCodePoints @(0x041C, 0x043E, 0x0438)
$appCountLabel = & $fromCodePoints @(0x043F, 0x0440, 0x0438, 0x043B, 0x043E, 0x0436, 0x0435, 0x043D, 0x0438, 0x0439)

$items = foreach ($file in $files) {
    $display = [IO.Path]::GetFileNameWithoutExtension($file.Name)
    $href = "apks/" + [Uri]::EscapeDataString($file.Name).Replace("%2F", "/")
    $sizeMb = [Math]::Round($file.Length / 1MB, 1)
    @"
      <a class="app" href="$href" download>
        <span class="name">$([System.Net.WebUtility]::HtmlEncode($display))</span>
        <span class="meta">$sizeMb MB</span>
      </a>
"@
}

$html = @"
<!doctype html>
<html lang="ru">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>$pageTitle</title>
  <style>
    :root { color-scheme: dark; }
    * { box-sizing: border-box; }
    body { margin: 0; min-height: 100vh; font-family: Arial, sans-serif; background: #090b0f; color: #f8f8f8; padding: 32px; }
    header { max-width: 980px; margin: 0 auto 24px; display: flex; align-items: center; justify-content: space-between; gap: 24px; }
    h1 { margin: 0; color: #efc735; font-size: clamp(34px, 6vw, 64px); line-height: 1; }
    .count { color: #d7dde7; font-size: 24px; white-space: nowrap; }
    main { max-width: 980px; margin: 0 auto; display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 16px; }
    .app { min-height: 96px; display: flex; flex-direction: column; justify-content: center; gap: 8px; padding: 20px 22px; border: 2px solid #efc735; border-radius: 8px; background: #171c24; color: #efc735; text-decoration: none; outline: none; }
    .app:focus, .app:hover { background: #252c37; transform: scale(1.02); }
    .name { font-size: 27px; font-weight: 700; overflow-wrap: anywhere; }
    .meta { color: #d7dde7; font-size: 18px; }
  </style>
</head>
<body>
  <header>
    <h1>$heading APK</h1>
    <div class="count">$($files.Count) $appCountLabel</div>
  </header>
  <main>
$($items -join "`n")
  </main>
</body>
</html>
"@

[IO.File]::WriteAllText((Join-Path $PSScriptRoot "index.html"), $html, [Text.UTF8Encoding]::new($false))
Write-Host "Menu updated: $($files.Count) APK files"
