"""Compare saved HTML parameters with the original local S5 XML as data only.

No network calls, rendering, camera requests or execution of supplied code.
Run from any directory with the Python standard library.
"""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, parse_qs
import hashlib
import io
import json
import subprocess
import zipfile
import xml.etree.ElementTree as ET

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[1]
REPO = ROOT / "outputs/lumix-s1m2-research-public"
REF = "refs/review/split-pr1"


class Commands(HTMLParser):
    def __init__(self):
        super().__init__()
        self.items = []

    def handle_starttag(self, tag, attrs):
        if tag != "a":
            return
        url = dict(attrs).get("href", "")
        split = urlsplit(url)
        if split.path != "/cam.cgi":
            return
        values = parse_qs(split.query)
        self.items.append({
            "line": self.getpos()[0],
            "parameters": {
                name: values.get(name, [""])[0]
                for name in ("mode", "type", "value", "value2")
            },
        })


def main():
    source = (OUT / "source.txt").read_bytes()
    parser = Commands()
    parser.feed(source.decode("utf-8"))
    # Read an existing local Git object. No fetch or checkout.
    archive = subprocess.run(
        ["git", "show", REF + ":camera_api.zip"],
        cwd=REPO, check=True, capture_output=True,
    ).stdout
    commit = subprocess.run(
        ["git", "rev-parse", REF], cwd=REPO,
        check=True, capture_output=True, text=True,
    ).stdout.strip()
    xml_path = "camera_api/lumix_allmenu.xml"
    with zipfile.ZipFile(io.BytesIO(archive)) as pack:
        xml_data = pack.read(xml_path)
    xml = ET.fromstring(xml_data)
    command_items = [e.attrib for e in xml.iter() if "cmd_mode" in e.attrib]
    quality_items = [a for a in command_items if a.get("cmd_type") == "videoquality"]
    source_quality = [
        item for item in parser.items
        if item["parameters"]["mode"] == "setsetting"
        and item["parameters"]["type"] == "videoquality"
    ]
    comparison = []
    for item in source_quality:
        p = item["parameters"]
        matches = [a for a in quality_items if all(
            a.get("cmd_" + key, "") == p[key]
            for key in ("mode", "type", "value", "value2")
        )]
        comparison.append({**item, "s5_allmenu_matches": matches})
    result = {
        "scope": "offline data comparison, no camera communication or supplied code execution",
        "source": {
            "url": "https://pastebin.com/raw/mHG1T5Ph",
            "bytes": len(source),
            "sha256": hashlib.sha256(source).hexdigest(),
            "author_model_claim": "GX9 FW 1.5, unverified here",
        },
        "menu_source": {
            "local_git_ref": REF, "commit": commit,
            "archive_sha256": hashlib.sha256(archive).hexdigest(),
            "xml_path": xml_path, "bytes": len(xml_data),
            "sha256": hashlib.sha256(xml_data).hexdigest(),
            "model_labels": [
                {"tag": e.tag, "model": e.attrib["model"]}
                for e in xml.iter() if "model" in e.attrib
            ],
            "command_items": len(command_items),
            "videoquality_items": len(quality_items),
            "unique_videoquality_values": len({a.get("cmd_value", "") for a in quality_items}),
        },
        "source_commands_as_data": parser.items,
        "videoquality_comparison": comparison,
        "exact_matches": sum(bool(c["s5_allmenu_matches"]) for c in comparison),
        "comparison_boundary": [
            "A matching S5 menu entry validates its presence in that saved sample only.",
            "An absent entry does not establish absence from the S5 firmware implementation.",
            "Neither matches nor absences prove GX9 effects or S1M2 compatibility.",
        ],
    }
    (OUT / "source_menu_comparison.json").write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + "\n"
    )
    print(json.dumps({
        "source_sha256": result["source"]["sha256"],
        "s5_menu_model": result["menu_source"]["model_labels"],
        "videoquality_count": len(comparison),
        "exact_matches": result["exact_matches"],
        "matched_values": [c["parameters"]["value"] for c in comparison if c["s5_allmenu_matches"]],
    }, ensure_ascii=False))


if __name__ == "__main__":
    main()
