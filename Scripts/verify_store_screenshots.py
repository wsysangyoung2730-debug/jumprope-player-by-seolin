"""Validate the exact upload set without third-party dependencies."""
from pathlib import Path
import struct
import subprocess

root = Path(__file__).resolve().parents[1] / "Marketing/AppStore/ko-KR"
for platform, expected in [("macOS", (2880, 1800)), ("iPadOS", (2064, 2752))]:
    files = sorted((root / platform).glob("*.png"))
    assert len(files) == 6, (platform, "six screenshots required")
    for file in files:
        data = file.read_bytes()
        assert data[:8] == b"\x89PNG\r\n\x1a\n"
        width, height, depth, color = struct.unpack(">IIBB", data[16:26])
        assert (width, height) == expected, file
        assert depth == 8 and color == 2, (file, "must be opaque RGB")
        profile = subprocess.check_output(["sips", "-g", "profile", str(file)], text=True)
        assert "sRGB" in profile, (file, profile)
    print(f"{platform}: 6 PNGs, {expected[0]}×{expected[1]}, sRGB, no alpha")
