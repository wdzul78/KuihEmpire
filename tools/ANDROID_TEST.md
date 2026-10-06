# Kuih Empire on Android

The Android Test export preset creates a signed debug APK for ARM64 and ARM32
phones. The game uses portrait orientation and the Compatibility renderer.

Build from the project folder:

```powershell
./tools/build_android_test.ps1
```

The APK is saved to `build/android/kuih-empire-test.apk`. Copy it to the phone,
open it in Files, allow that app to install unknown apps, and install Kuih Empire.

For USB testing, enable Developer options and USB debugging, connect the phone,
and accept the computer authorization prompt. Then build, install, and launch:

```powershell
./tools/build_android_test.ps1 -Install
```

Godot's Android Test preset is also Runnable for one-click deployment.
Java SDK and Android SDK paths are configured in the local Godot editor settings.
The matching Android debug and release export templates are installed locally.

`.asset_backups` and local previews are excluded from exports. Tools, design
documents, and build outputs are also excluded. Keep these exclusions when
editing the export preset. Do not copy backups into any build output.

This debug APK is for testing. Publishing to Google Play requires a release
keystore and a separate release AAB configuration.
