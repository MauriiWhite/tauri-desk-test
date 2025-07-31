param(
    [Parameter(Position=0)]
    [string]$Version
)

if (-not $Version) {
    $Version = Read-Host "Introduce la nueva versión (p.ej. 1.2.3)"
    if (-not $Version) {
        Write-Error "No se ha proporcionado ninguna versión. Abortando."
        exit 1
    }
}

$pkgPath = "package.json"
if (-not (Test-Path $pkgPath)) {
    Write-Error "No se encontró $pkgPath"
    exit 1
}
$pkgJson = Get-Content $pkgPath -Raw | ConvertFrom-Json
$pkgJson.version = $Version
$pkgJson | ConvertTo-Json -Depth 10 | Set-Content $pkgPath
Write-Host "⇒ package.json → version: $Version"


$cargoPath = "src-tauri\Cargo.toml"
if (-not (Test-Path $cargoPath)) {
    Write-Error "No se encontró $cargoPath"
    exit 1
}
(Get-Content $cargoPath) |
    ForEach-Object {
        if ($_ -match '^version\s*=\s*".*"$') {
            "version = `"$Version`""
        } else {
            $_
        }
    } | Set-Content $cargoPath
Write-Host "⇒ Cargo.toml  → version: $Version"

$tauriPath = "src-tauri/tauri.conf.json"
if (-not (Test-Path $tauriPath)) {
    Write-Error "No se encontró $tauriPath"
    exit 1
}
$tauriJson = Get-Content $tauriPath -Raw | ConvertFrom-Json

if ($tauriJson.PSObject.Properties.Match('version')) {
    $tauriJson.version = $Version
} else {
    Write-Warning "No se encontró 'version' en la raíz de $tauriPath. Agregando el campo."
    $tauriJson | Add-Member -MemberType NoteProperty -Name version -Value $Version
}

$tauriJson | ConvertTo-Json -Depth 10 | Set-Content $tauriPath
Write-Host "⇒ tauri.conf.json → version: $Version"

Write-Host "`n✅ Todas las versiones han sido actualizadas a $Version."
