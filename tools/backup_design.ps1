param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string[]]$Paths
)

$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$rootPrefix = $projectRoot.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
$backupRoot = Join-Path $projectRoot '.asset_backups'
$safeName = ($Name -replace '[^a-zA-Z0-9_-]', '-').Trim('-')
if (-not $safeName) { throw 'Provide a descriptive backup name.' }

# Resolve and validate the entire batch before creating any backup.
$sources = @($Paths | ForEach-Object {
    $source = [IO.Path]::GetFullPath((Join-Path $projectRoot $_))
    if (-not $source.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Backup source must be inside the project: $_"
    }
    if ($source.StartsWith($backupRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Do not back up the backup directory.'
    }
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Original file does not exist: $_"
    }
    [PSCustomObject]@{ Source = $source; Relative = $source.Substring($rootPrefix.Length) }
})

New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
$ignorePath = Join-Path $backupRoot '.gdignore'
if (-not (Test-Path -LiteralPath $ignorePath)) {
    [IO.File]::WriteAllText($ignorePath, '')
}
$created = Get-Date
$folder = Join-Path $backupRoot ($created.ToString('yyyy-MM-dd_HH-mm-ss-fff') + '_' + $safeName)
if (Test-Path -LiteralPath $folder) { throw "Backup already exists: $folder" }
New-Item -ItemType Directory -Path $folder | Out-Null
$files = @($sources | ForEach-Object {
    $destination = Join-Path $folder $_.Relative
    New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($destination)) -Force | Out-Null
    Copy-Item -LiteralPath $_.Source -Destination $destination
    [PSCustomObject]@{
        path = $_.Relative.Replace('\', '/')
        sha256 = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash
    }
})
[PSCustomObject]@{
    created_at = $created.ToString('o')
    description = $Name
    files = $files
} | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $folder 'manifest.json') -Encoding utf8
Write-Output $folder
