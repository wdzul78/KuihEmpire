"""Select runtime resources, including formatted/dynamic load paths, without deleting sources."""
from pathlib import Path
import re, json, fnmatch, argparse

parser = argparse.ArgumentParser()
parser.add_argument("--output-dir", default="release/playstore-2026-10-23")
args = parser.parse_args()

ROOT = Path(__file__).resolve().parents[1]
runtime = []
for folder in ("scripts", "scenes", "resources", "data", "shaders", "addons/AdmobPlugin", "addons/GMPShared"):
    runtime += [p for p in (ROOT / folder).rglob("*") if p.is_file() and p.suffix in (".gd", ".tscn", ".tres", ".gdshader", ".json")]
assets = [p for folder in ("assets", "audio") for p in (ROOT / folder).rglob("*") if p.is_file() and p.suffix not in (".import", ".md", ".txt", ".py") and p.name not in ("source.json", "generation.json")]
selected = {p.relative_to(ROOT).as_posix() for p in runtime}
patterns = set()
for p in runtime + [ROOT / "project.godot"]:
    text = p.read_text(encoding="utf-8", errors="replace")
    text = '\n'.join(line for line in text.splitlines() if not line.lstrip().startswith('#'))
    if p.name == 'project.godot':
        text = re.sub(r'\[file_customization\].*?(?=\n\[|\Z)', '', text, flags=re.S)
    for path in re.findall(r'res://[^\s"\'<>\)\]]+', text):
        path = path.removeprefix("res://")
        if path.startswith(("tools/", ".analysis/", "release/", "design/")):
            continue
        path = re.sub(r'%[-.\d]*[sdif]', '*', path)
        if path.endswith('/'):
            path += '*'
        patterns.add(path)
patterns.discard('assets/ui/*/*.png')
patterns.update('assets/ui/' + folder + '/*.png' for folder in ('gameplay_v2','gameplay_v3','gameplay_v4','tutorial_v1','results_v2'))
for p in assets:
    relative = p.relative_to(ROOT).as_posix()
    if any(fnmatch.fnmatch(relative, pattern) for pattern in patterns):
        selected.add(relative)
for required in ("icon.png", "icon.svg"):
    selected.add(required)
json_files = sorted(x for x in selected if x.endswith(".json"))
resource_files = sorted(x for x in selected if not x.endswith(".json"))
preset = ROOT / "export_presets.cfg"
text = preset.read_text(encoding="utf-8")
start = text.index("[preset.1]")
head, release = text[:start], text[start:]
release = release.replace('export_filter="all_resources"', 'export_filter="resources"')
release = re.sub(r'^include_filter=.*$', 'include_filter=' + json.dumps(','.join(json_files)), release, flags=re.M)
release = re.sub(r'^export_files=.*\n?', '', release, flags=re.M)
release = release.replace('export_filter="resources"', 'export_filter="resources"\nexport_files=PackedStringArray(' + ','.join(json.dumps('res://' + x) for x in resource_files) + ')')
preset.write_text(head + release, encoding="utf-8")
kept = [p for p in assets if p.relative_to(ROOT).as_posix() in selected]
excluded = [p for p in assets if p.relative_to(ROOT).as_posix() not in selected]
report = {"selection": "Runtime scripts/scenes/resources and literal or formatted runtime asset paths; existing legacy fallbacks retained when still referenced.", "included_asset_count": len(kept), "excluded_asset_count": len(excluded), "included_source_bytes": sum(p.stat().st_size for p in kept), "excluded_source_bytes": sum(p.stat().st_size for p in excluded), "included": sorted(selected), "excluded_assets": sorted(p.relative_to(ROOT).as_posix() for p in excluded)}
out = (ROOT / args.output_dir).resolve()
if not out.is_relative_to(ROOT / "release"):
    raise ValueError("Asset manifest must stay inside the project release directory")
out.mkdir(parents=True, exist_ok=True)
(out / "asset-manifest.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print({k: v for k, v in report.items() if k not in ("included", "excluded_assets")})
