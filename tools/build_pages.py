"""Build the Godot source into a GitHub Pages site with a Windows download."""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import hosting_build as host

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    cache = Path(os.environ.get("RUNNER_TEMP", str(root / ".build-cache"))) / "memory-breach-tools"
    cache.mkdir(parents=True, exist_ok=True)
    godot = Path(shutil.which(args.godot) or args.godot).resolve()
    version = host.godot_version(godot)
    host.ensure_templates(version, cache)
    output = root / "_release"
    output.mkdir(exist_ok=True)
    public = host.build(godot, root / "MEMORY_BREACH", output)
    # Project Pages sites live under /repository-name/, so links must be relative.
    index = public / "index.html"
    text = index.read_text(encoding="utf-8")
    text = text.replace('href="/play/', 'href="play/')
    text = text.replace('href="/downloads/', 'href="downloads/')
    index.write_text(text, encoding="utf-8")
    (public / ".nojekyll").write_text("", encoding="utf-8")
    # New filenames prevent a previous game pack being reused from browser/CDN cache.
    play=public / "play"
    pack=play / "index.pck"
    revision=hashlib.sha256(pack.read_bytes()).hexdigest()[:12]
    name="memory-breach-"+revision+".pck"
    pack.rename(play / name)
    for html in play.glob("*.html"):
        text=html.read_text(encoding="utf-8").replace("index.pck",name)
        text=text.replace('src="python_bridge.js"', 'src="python_bridge.js?v='+revision+'"')
        text=text.replace('src="index.js"', 'src="index.js?v='+revision+'"')
        html.write_text(text,encoding="utf-8")
    # Pages manages HTTP compression; precompressed siblings need custom headers.
    for file in public.rglob("*.gz"):
        file.unlink()
    print("GitHub Pages artifact:", public)

if __name__ == "__main__":
    main()
