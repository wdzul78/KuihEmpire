"""Inspect the testing AAB without building an APK or exposing signing secrets."""
import hashlib
import json
import struct
import zipfile
from pathlib import Path

root = Path(__file__).resolve().parents[1]
out = root / 'release/playstore-0.1.1-testing-2026-10-23'
bundle = out / 'kuih-empire-0.1.1-testing.aab'
with zipfile.ZipFile(bundle) as z:
    names = z.namelist()
    forbidden = [n for n in names if any(s in n.lower() for s in ('.asset_backups/', '/tools/', 'upload-password', '.jks', '.analysis/'))]
    native = {}
    for n in names:
        if n.endswith('.so'):
            b = z.read(n)
            assert b[:4] == b'\x7fELF' and b[4] == 2, n
            offset = struct.unpack_from('<Q', b, 32)[0]
            size, count = struct.unpack_from('<HH', b, 54)
            aligns = [struct.unpack_from('<Q', b, offset+i*size+48)[0] for i in range(count) if struct.unpack_from('<I', b, offset+i*size)[0] == 1]
            native[n] = aligns
    assert not forbidden, forbidden
    assert all(min(v) >= 16384 for v in native.values()), native
    report = dict(file=bundle.name, bytes=bundle.stat().st_size, decimal_MB=round(bundle.stat().st_size/1e6, 2), sha256=hashlib.file_digest(bundle.open('rb'), 'sha256').hexdigest(), zip_crc_ok=z.testzip() is None, forbidden_entries=forbidden, native_load_segment_alignment=native, version='0.1.1', version_code=2, target_sdk=36, journey_test='PASS', android_device_test='NOT RUN', play_console_upload='NOT DONE', rewarded_ads='Provider not connected; button disabled')
    assert report['zip_crc_ok']
report['broad_smoke_test'] = 'INCONCLUSIVE: no final result; stopped stalled harness after tutorial diagnostics'
(out / 'validation-summary.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
print(json.dumps(report, indent=2))
