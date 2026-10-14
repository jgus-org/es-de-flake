"""Check that the box-art theme changes only the intended non-video artwork and display name."""

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

original, variant = map(Path, sys.argv[1:])
theme = ET.parse(variant / "theme.xml")
original_theme = ET.parse(original / "theme.xml")

images = theme.findall(".//image[@name='gameImage']/imageType")
assert len(images) == 1, "Expected one gameImage artwork selection"
assert images[0].text == "cover, screenshot", "Box art must precede the screenshot fallback"
for name in ("withoutVideos", "withoutVideosLegacy"):
    selections = [
        image.text
        for group in theme.findall("variant")
        if name in [item.strip() for item in group.attrib["name"].split(",")]
        for image in group.findall("view[@name='gamelist']/image[@name='gameImage']/imageType")
    ]
    assert selections == ["cover, screenshot"], f"Missing box-art selection for {name}"

images[0].text = "image"
assert ET.tostring(theme.getroot()) == ET.tostring(original_theme.getroot()), "Other theme behavior changed"

capabilities = ET.parse(variant / "capabilities.xml")
names = capabilities.findall("themeName")
assert len(names) == 1 and names[0].text == "Modern (box art)", "Variant needs a distinct display name"
names[0].text = "Modern"
assert ET.tostring(capabilities.getroot()) == ET.tostring(ET.parse(original / "capabilities.xml").getroot()), "Other capabilities changed"
