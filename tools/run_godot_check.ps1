param(
    [Parameter(Mandatory=$true)][string]$Scene,
    [switch]$Visual,
    [switch]$VerboseLog,
    [string]$Resolution = '540x960'
)
$ErrorActionPreference = 'Stop'
$taskProjectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$taskRuntimeRoot = Join-Path $taskProjectRoot '.analysis/godot-test-runtime'
New-Item -ItemType Directory -Force -Path $taskRuntimeRoot | Out-Null
$taskProcessInfo = [Diagnostics.ProcessStartInfo]::new()
$taskProcessInfo.FileName = 'F:/WDzul78/Documents/Godot/Godot_v4.7.2-stable_win64_console.exe'
$taskProcessInfo.UseShellExecute = $false
$taskProcessInfo.CreateNoWindow = $true
$taskProcessInfo.RedirectStandardOutput = $true
$taskProcessInfo.RedirectStandardError = $true
$taskProcessInfo.WorkingDirectory = $taskProjectRoot
$taskProcessInfo.Environment['APPDATA'] = $taskRuntimeRoot
$taskProcessInfo.Environment['LOCALAPPDATA'] = $taskRuntimeRoot
if (-not $Visual) { $taskProcessInfo.ArgumentList.Add('--headless') }
$taskProcessInfo.ArgumentList.Add('--fixed-fps')
$taskProcessInfo.ArgumentList.Add('60')
$taskProcessInfo.ArgumentList.Add('--path')
$taskProcessInfo.ArgumentList.Add($taskProjectRoot)
$taskProcessInfo.ArgumentList.Add('--resolution')
$taskProcessInfo.ArgumentList.Add($Resolution)
$taskProcessInfo.ArgumentList.Add($Scene)
if ($VerboseLog) { $taskProcessInfo.ArgumentList.Add('--verbose') }
$taskProcess = [Diagnostics.Process]::Start($taskProcessInfo)
$taskOutput = $taskProcess.StandardOutput.ReadToEndAsync()
$taskErrors = $taskProcess.StandardError.ReadToEndAsync()
$taskTimedOut = -not $taskProcess.WaitForExit(45000)
if ($taskTimedOut) { $taskProcess.Kill(); $taskProcess.WaitForExit() }
$taskStdout = $taskOutput.GetAwaiter().GetResult()
Write-Output ($taskStdout -split "`r?`n")
$taskStderr = $taskErrors.GetAwaiter().GetResult()
Write-Output ($taskStderr -split "`r?`n")
if ($taskTimedOut) { throw 'Godot check exceeded 45 seconds.' }
if ($taskStderr -match '(?m)^SCRIPT ERROR:') { throw 'Godot reported a script error.' }
exit $taskProcess.ExitCode
