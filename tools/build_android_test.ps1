param(
    [string]$Godot = 'F:/WDzul78/Documents/Godot/Godot_v4.7.2-stable_win64_console.exe',
    [switch]$Install,
    [string]$Preset = 'Kuih Empire',
    [string]$Package = 'com.kuihempire.kuihempire'
)

$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$apkPath = Join-Path $projectRoot 'build/android/kuih-empire-test.apk'
New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($apkPath)) -Force | Out-Null
& $Godot --headless --path $projectRoot --export-debug $Preset $apkPath
if ($LASTEXITCODE -ne 0) { throw 'Android export failed.' }
Write-Output "APK: $apkPath"

if ($Install) {
    $adbPath = Join-Path $env:LOCALAPPDATA 'Android/Sdk/platform-tools/adb.exe'
    & $adbPath install -r $apkPath
    if ($LASTEXITCODE -ne 0) { throw 'Installation failed. Connect one Android phone and authorize USB debugging.' }
    & $adbPath shell monkey -p $Package -c android.intent.category.LAUNCHER 1
    if ($LASTEXITCODE -ne 0) { throw 'Could not launch Kuih Empire on the phone.' }
}
