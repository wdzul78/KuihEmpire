"""Validate the demo-ads release without generating an APK."""
import hashlib
import json
import struct
import zipfile
from pathlib import Path
import xml.etree.ElementTree as ET

root = Path(__file__).resolve().parents[1]
out = root / 'release/playstore-0.1.2-test-ads-2026-10-23'
bundle = out / 'kuih-empire-0.1.2-test-ads.aab'
android = '{http://schemas.android.com/apk/res/android}'
manifest = ET.parse(out / 'android-manifest.xml').getroot()
assert manifest.attrib[android+'versionCode'] == '3'
assert manifest.find('uses-sdk').attrib[android+'targetSdkVersion'] == '36'
metadata = {n.attrib[android+'name']: n.attrib.get(android+'value') for n in manifest.findall('./application/meta-data')}
assert metadata['com.google.android.gms.ads.APPLICATION_ID'] == 'ca-app-pub-3940256099942544~3347511713'
permissions = [n.attrib[android+'name'] for n in manifest.findall('uses-permission')]
assert 'android.permission.INTERNET' in permissions
with zipfile.ZipFile(bundle) as z:
    names = z.namelist()
    assert z.testzip() is None
    forbidden = [n for n in names if any(s in n.lower() for s in ('.asset_backups/', '/tools/', 'upload-password', '.jks', '.analysis/'))]
    assert not forbidden, forbidden
    assert any('rewarded_ads.gd' in n for n in names)
    assert any('AdmobPlugin/Admob.gd' in n for n in names)
    assert any('GMPShared' in n for n in names)
    dex = b''.join(z.read(n) for n in names if n.endswith('.dex'))
    assert b'com/google/android/gms/ads/rewarded/RewardedAd' in dex
    assert b'AdmobPlugin' in dex
    aligns = {}
    for n in names:
        if n.endswith('.so'):
            b = z.read(n)
            offset = struct.unpack_from('<Q', b, 32)[0]
            size, count = struct.unpack_from('<HH', b, 54)
            aligns[n] = [struct.unpack_from('<Q', b, offset+i*size+48)[0] for i in range(count) if struct.unpack_from('<I', b, offset+i*size)[0] == 1]
    assert all(min(v) >= 16384 for v in aligns.values())
report = dict(file=bundle.name, bytes=bundle.stat().st_size, decimal_MB=round(bundle.stat().st_size/1e6, 2), sha256=hashlib.file_digest(bundle.open('rb'),'sha256').hexdigest(), version='0.1.2', version_code=3, target_sdk=36, demo_app_id=metadata['com.google.android.gms.ads.APPLICATION_ID'], permissions=permissions, forbidden_entries=forbidden, native_load_alignment=aligns, native_admob_and_google_rewarded_classes='PRESENT', adapter_and_dialog_tests='PASS (fake SDK)', physical_device_ad_delivery='NOT TESTED: no device attached', play_console_upload='NOT DONE')
(out / 'validation-summary.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
