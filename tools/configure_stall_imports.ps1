$ErrorActionPreference = 'Stop'
$taskRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$taskImports = @(rg --files (Join-Path $taskRoot 'assets/stalls') -g '*.import')
if ($taskImports.Count -eq 0) {
    Write-Output 'No imported stall backgrounds yet. Add the final artwork and import in Godot first.'
    exit 0
}
$taskRelativePaths = @($taskImports | ForEach-Object {
    [IO.Path]::GetRelativePath($taskRoot, $_)
    $taskSource = $_.Substring(0, $_.Length - '.import'.Length)
    if (Test-Path -LiteralPath $taskSource -PathType Leaf) { [IO.Path]::GetRelativePath($taskRoot, $taskSource) }
})
& (Join-Path $PSScriptRoot 'backup_design.ps1') -Name stall-background-import-settings -Paths $taskRelativePaths
foreach ($taskImport in $taskImports) {
    $taskText = [IO.File]::ReadAllText($taskImport)
    $taskText = $taskText -replace '(?m)^compress/mode=.*$', 'compress/mode=2'
    $taskText = $taskText -replace '(?m)^mipmaps/generate=.*$', 'mipmaps/generate=false'
    $taskText = $taskText -replace '(?m)^process/size_limit=.*$', 'process/size_limit=2048'
    $taskText = $taskText -replace '(?m)^detect_3d/compress_to=.*$', 'detect_3d/compress_to=0'
    [IO.File]::WriteAllText($taskImport, $taskText, [Text.UTF8Encoding]::new($false))
}
Write-Output "Updated $($taskImports.Count) stall texture imports. Reimport in Godot."
