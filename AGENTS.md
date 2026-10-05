# Project working instructions

## Back up designs before changing them

The user requires a separate original copy BEFORE every design edit or asset replacement. This includes generated images, icons, audio assets, and related UI layout/scene files being changed for a design adjustment. Versioned asset directories alone do not replace this backup.

Run `tools/backup_design.ps1` with the affected existing project-relative file paths and a short descriptive name before making changes. It copies originals into `.asset_backups/YYYY-MM-DD_HH-mm-ss-fff_description/`, preserves their project-relative paths, and writes a manifest. Include existing asset files even when switching to a newly generated version, together with the scripts/scenes whose asset references or layout will change. Do not overwrite or delete previous backups.

Example (PowerShell):

```powershell
./tools/backup_design.ps1 -Name tapau-arrows -Paths assets/specials/directional_v3/tapau_horizontal.png,assets/specials/directional_v3/tapau_vertical_blue.png,scripts/art/board_art.gd
```

`.asset_backups/` is deliberately hidden from Godot, contains `.gdignore`, and is ignored by Git. Never reference it from runtime scripts, scenes, resources, or export include filters. Keep it outside every APK/AAB/PCK and game build. If export settings are added or changed, retain this exclusion; do not manually copy this folder to build output.
