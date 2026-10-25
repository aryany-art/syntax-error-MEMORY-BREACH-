"""Build and publicly share MEMORY BREACH on a Windows PC. Python 3.9+, stdlib only."""
import argparse
import functools
import gzip
import urllib.parse
import http.server
import json
import os
from pathlib import Path
import platform
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import urllib.request
import webbrowser
import zipfile

ROOT = Path(__file__).resolve().parent
PRESETS = '''[preset.0]
name="Public Web"
platform="Web"
runnable=true
export_filter="all_resources"
include_filter="assets/*.json"
exclude_filter="tests/*,*.md,python_runtime/*,assets/memory_breach_theme.wav"
export_path=""
[preset.0.options]
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=true
html/export_icon=true
html/custom_html_shell="res://web/shell.html"
html/canvas_resize_policy=2
html/experimental_virtual_keyboard=true
progressive_web_app/enabled=false

[preset.1]
name="Windows Download"
platform="Windows Desktop"
runnable=true
export_filter="all_resources"
include_filter="assets/*.json"
exclude_filter="tests/*,*.md,python_runtime/*,assets/memory_breach_theme.wav"
export_path=""
[preset.1.options]
binary_format/architecture="x86_64"
binary_format/embed_pck=false
application/modify_resources=false
codesign/enable=false
'''
PAGE = """<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>MEMORY BREACH</title><style>
body{margin:0;min-height:100vh;display:grid;place-items:center;background:#080c18;
color:#e8f5ff;font:18px system-ui}main{max-width:640px;padding:32px}
h1{font-size:clamp(40px,9vw,76px);letter-spacing:-3px;color:#61ffbd}
p{line-height:1.6;color:#aebfd3}a{display:inline-block;padding:16px 22px;margin:8px 10px 8px 0;
background:#61ffbd;border-radius:8px;color:#071523;font-weight:750;text-decoration:none}
.secondary{background:#b7a1ff}small{display:block;margin-top:28px;color:#8195aa}</style>
<main><p>THE HUMAN EXCEPTION</p><h1>MEMORY//BREACH</h1>
<p>Fight the security network. Breach its locks. Recover the memories. Face KAVYA.</p>
<a href="/play/index.html">Play in browser</a>
<a class="secondary" href="/downloads/MEMORY_BREACH_Windows.zip">Download for Windows</a>
<p>Browser: enter numeric hacking answers.<br>
Windows: extract the download, then open MEMORY_BREACH.exe.
Install Python 3 to run Python commands inside the Windows game.</p>
<small>Each player has a separate campaign. On phones, rotate to landscape.</small></main></html>"""

def download(url, target):
    target = Path(target)
    target.parent.mkdir(parents=True, exist_ok=True)
    partial = target.with_suffix(target.suffix + ".part")
    print("Downloading:", target.name, flush=True)
    request = urllib.request.Request(url, headers={"User-Agent": "NULL-VECTOR-Host/1.0"})
    try:
        with urllib.request.urlopen(request, timeout=60) as source, partial.open("wb") as out:
            total = int(source.headers.get("Content-Length", 0))
            done, report = 0, time.monotonic()
            while True:
                block = source.read(1024 * 1024)
                if not block:
                    break
                out.write(block)
                done += len(block)
                if time.monotonic() - report > 4:
                    print("  %.0f MB%s" % (done / 1048576,
                          " / %.0f MB" % (total / 1048576) if total else ""), flush=True)
                    report = time.monotonic()
        if total and done != total:
            raise RuntimeError("Incomplete download; run the launcher again.")
        partial.replace(target)
    finally:
        partial.unlink(missing_ok=True)

def find_godot(given, config):
    candidates = [given, os.environ.get("GODOT_EXE"), config.get("godot")]
    candidates += [shutil.which("godot"), shutil.which("godot4")]
    candidates += [str(p) for p in ROOT.glob("Godot*.exe") if "console" not in p.name.lower()]
    for item in candidates:
        if item and Path(item.strip('"')).is_file():
            return Path(item.strip('"')).resolve()
    print("Select your installed Godot editor .exe (not a project or ZIP).", flush=True)
    try:
        import tkinter
        from tkinter import filedialog
        app = tkinter.Tk()
        app.withdraw()
        chosen = filedialog.askopenfilename(title="Choose Godot editor",
                    filetypes=[("Godot executable", "*.exe")])
        app.destroy()
    except Exception:
        chosen = input("Full path to Godot .exe: ").strip().strip('"')
    if not chosen:
        raise RuntimeError("No Godot editor selected.")
    return Path(chosen).resolve()

def godot_version(executable):
    value = subprocess.check_output([str(executable), "--version"],
               text=True, stderr=subprocess.STDOUT, timeout=30).strip()
    match = re.search(r"(4\.\d+(?:\.\d+)?)\.stable", value)
    if not match:
        raise RuntimeError("Use a stable Godot 4 editor. Reported version: " + value)
    return match.group(1)

def ensure_templates(version, cache):
    # Official stable templates are version-matched, never renamed from another release.
    data = Path(os.environ.get("APPDATA", Path.home() / ".local/share"))
    base = data / "Godot/export_templates" if os.name == "nt" else data / "godot/export_templates"
    folder = base / (version + ".stable")
    required = ["web_nothreads_release.zip", "web_nothreads_debug.zip",
                "windows_release_x86_64.exe", "windows_debug_x86_64.exe"]
    if all((folder / name).is_file() for name in required):
        print("Matching Web and Windows templates already installed.")
        return
    print("Installing matching Godot %s templates. First download may be about 1 GB." % version)
    archive = cache / ("Godot_%s_templates.tpz" % version)
    if not archive.exists():
        tag = version + "-stable"
        download("https://github.com/godotengine/godot-builds/releases/download/"
                 + tag + "/Godot_v" + tag + "_export_templates.tpz", archive)
    folder.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive) as z:
        names = {Path(n).name: n for n in z.namelist() if not n.endswith("/")}
        for name in required:
            if name not in names:
                raise RuntimeError("Template layout changed. Install Web and Windows templates "
                    "using Editor > Manage Export Templates, then run again.")
        # Install debug and release files: Godot validates both even for release export.
        for name in required + ["version.txt"]:
            if name in names:
                with z.open(names[name]) as src, (folder / name).open("wb") as dst:
                    shutil.copyfileobj(src, dst)

def command(args, log):
    print("Running:", " ".join(str(x) for x in args), flush=True)
    with log.open("a", encoding="utf-8") as out:
        result = subprocess.run([str(x) for x in args], stdout=out, stderr=subprocess.STDOUT)
    if result.returncode:
        tail = log.read_text(encoding="utf-8", errors="replace")[-5000:]
        raise RuntimeError("Build failed. See " + str(log) + "\n" + tail)

def build(godot, project, output):
    if not (project / "project.godot").exists():
        raise RuntimeError("project.godot is missing from " + str(project))
    # Work in a temporary copy; the user's scenes and export presets are never overwritten.
    with tempfile.TemporaryDirectory(prefix="null_vector_export_") as stage:
        work = Path(stage) / "game"
        shutil.copytree(project, work, ignore=shutil.ignore_patterns(
            ".godot", ".git", "__pycache__", "builds", "web_build", ".hosting", "*.zip", "*.exe"))
        (work / "export_presets.cfg").write_text(PRESETS, encoding="utf-8")
        # Keep original editable WAV in the repository; optimize only the build copy.
        source_music = work / "assets/memory_breach_theme.wav"
        if source_music.exists():
            converted = source_music.with_suffix(".ogg")
            subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y",
                            "-i", str(source_music), "-c:a", "libvorbis", "-q:a", "3",
                            str(converted)], check=True)
            game_script = work / "scripts/game.gd"
            text = game_script.read_text(encoding="utf-8")
            text = text.replace('preload("res://assets/memory_breach_theme.wav")',
                                'preload("res://assets/memory_breach_theme.ogg")')
            text = text.replace("theme.loop_mode=AudioStreamWAV.LOOP_FORWARD\n\ttheme.loop_begin=0\n\ttheme.loop_end=int(round(theme.get_length()*theme.mix_rate))",
                                "theme.loop=true\n\ttheme.loop_offset=0.0")
            game_script.write_text(text, encoding="utf-8")
        patch_runtime(work)
        project_cfg = work / "project.godot"
        content = project_cfg.read_text(encoding="utf-8")
        key = "textures/vram_compression/import_etc2_astc"
        content = re.sub(r"^" + re.escape(key) + r"=.*$", "", content, flags=re.M)
        if "[rendering]" not in content:
            content += "\n[rendering]\n"
        content = content.replace("[rendering]", "[rendering]\n" + key + "=true")
        project_cfg.write_text(content, encoding="utf-8")
        public = output / "public"
        web = public / "play"
        native = output / "windows"
        for folder in (web, native):
            if folder.exists():
                shutil.rmtree(folder)
            folder.mkdir(parents=True)
        log = output / "build.log"
        log.write_text("", encoding="utf-8")
        command([godot, "--headless", "--path", work, "--editor", "--import", "--quit"], log)
        command([godot, "--headless", "--path", work, "--export-release",
                 "Public Web", web / "index.html"], log)
        command([godot, "--headless", "--path", work, "--export-release",
                 "Windows Download", native / "MEMORY_BREACH.exe"], log)
        if not (web / "index.html").exists() or not (native / "MEMORY_BREACH.exe").exists():
            raise RuntimeError("Export did not produce the expected files; inspect build.log.")
        worker = project / "python_runtime/worker.py"
        if worker.exists():
            (native / "python_runtime").mkdir(exist_ok=True)
            shutil.copy2(worker, native / "python_runtime/worker.py")
        (native / "READ_ME.txt").write_text(
            "Extract the whole ZIP before opening MEMORY_BREACH.exe.\n"
            "Keep MEMORY_BREACH.pck and python_runtime beside the executable.\n"
            "The game uses keyboard/mouse. Numeric hacking answers need no Python installation.\n"
            "For actual Python commands, install Python 3 with Add Python to PATH.\n"
            "The terminal runs code with your Windows user permissions; enter trusted code.\n",
            encoding="utf-8")
        downloads = public / "downloads"
        downloads.mkdir(exist_ok=True)
        with zipfile.ZipFile(downloads / "MEMORY_BREACH_Windows.zip", "w", zipfile.ZIP_DEFLATED) as z:
            for f in native.rglob("*"):
                if f.is_file():
                    z.write(f, f.relative_to(native))
        (public / "index.html").write_text(PAGE, encoding="utf-8")
        prepare_compressed_assets(public)
    return public

def patch_runtime(work):
    # The desktop worker must exist on disk, outside the .pck.
    runtime = work / "scripts/python_runtime.gd"
    if not runtime.exists():
        return
    s = runtime.read_text(encoding="utf-8")
    old = 'command.append(ProjectSettings.globalize_path("res://python_runtime/worker.py"))'
    new = ('var worker_path=ProjectSettings.globalize_path("res://python_runtime/worker.py")\n'
           '\t\tif not OS.has_feature("editor"):\n'
           '\t\t\tworker_path=OS.get_executable_path().get_base_dir().path_join("python_runtime/worker.py")\n'
           '\t\tcommand.append(worker_path)')
    s = s.replace(old, new)
    s = s.replace("func submit(code,a,b):", '''func submit(code,a,b):
\tif OS.has_feature("web"):
\t\tfinished.emit({"ok":false,"numeric":null,"output":"Browser mode: enter the numeric answer to breach. Actual Python commands are supported in the Windows download."})
\t\treturn false''')
    runtime.write_text(s, encoding="utf-8")

def prepare_compressed_assets(public):
    for file in Path(public).rglob("*"):
        if file.is_file() and file.suffix in [".wasm", ".pck", ".js", ".css"]:
            compressed = file.with_suffix(file.suffix + ".gz")
            if compressed.exists() and compressed.stat().st_mtime >= file.stat().st_mtime:
                continue
            with file.open("rb") as src, compressed.open("wb") as dst:
                with gzip.GzipFile(filename="", mode="wb", fileobj=dst, compresslevel=6, mtime=0) as zipped:
                    shutil.copyfileobj(src, zipped)

class GameHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map,
                      ".wasm": "application/wasm", ".pck": "application/octet-stream"}
    def guess_type(self, path):
        return super().guess_type(path[:-3] if str(path).endswith(".gz") else path)

    def send_head(self):
        original = self.path
        self._gzip_response = False
        parsed = urllib.parse.urlsplit(original)
        encoding = self.headers.get("Accept-Encoding", "")
        accepts_gzip = False
        for option in encoding.lower().split(","):
            parts = option.strip().split(";")
            if parts[0] == "gzip":
                accepts_gzip = True
                for parameter in parts[1:]:
                    if parameter.strip().startswith("q="):
                        try:
                            accepts_gzip = float(parameter.strip()[2:]) > 0
                        except ValueError:
                            accepts_gzip = False
        if accepts_gzip and parsed.path.endswith((".wasm", ".pck", ".js", ".css")):
            path = Path(self.translate_path(original))
            if path.with_suffix(path.suffix + ".gz").is_file():
                self._gzip_response = True
                self.path = parsed.path + ".gz" + ("?" + parsed.query if parsed.query else "")
        try:
            return super().send_head()
        finally:
            self.path = original

    def copyfile(self, source, outputfile):
        try:
            super().copyfile(source, outputfile)
        except (BrokenPipeError, ConnectionResetError):
            pass  # A visitor closed the page or canceled a download.
    def list_directory(self, path):
        self.send_error(403, "Directory listing disabled")
        return None
    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Vary", "Accept-Encoding")
        if getattr(self, "_gzip_response", False):
            self.send_header("Content-Encoding", "gzip")
        resource = urllib.parse.urlsplit(self.path).path
        self.send_header("Cache-Control", "public, max-age=3600" if resource.endswith((".wasm", ".pck", ".js", ".css", ".gz", ".png", ".zip")) else "no-cache")
        super().end_headers()
    def log_message(self, fmt, *args):
        pass

def host(public, cache, output, local_only=False):
    handler = functools.partial(GameHandler, directory=str(public))
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    port = server.server_address[1]
    thread = threading.Thread(target=server.serve_forever, daemon=True)
    thread.start()
    tunnel = None
    try:
        print("Local preview: http://127.0.0.1:%d" % port, flush=True)
        if local_only:
            webbrowser.open("http://127.0.0.1:%d" % port)
            print("Local-only test. Ctrl+C stops.")
            while True:
                time.sleep(0.5)
        binary = cache / ("cloudflared.exe" if os.name == "nt" else "cloudflared")
        if not binary.exists():
            arch = "arm64" if platform.machine().lower() in ("arm64", "aarch64") else "amd64"
            system = "windows" if os.name == "nt" else "linux"
            suffix = ".exe" if os.name == "nt" else ""
            download("https://github.com/cloudflare/cloudflared/releases/latest/download/"
                     + "cloudflared-" + system + "-" + arch + suffix, binary)
            if os.name != "nt":
                binary.chmod(0o700)
        # Isolate Quick Tunnel from any user's named-tunnel configuration.
        config = cache / "quick_tunnel.yml"
        config.write_text("{}\n", encoding="utf-8")
        tunnel = subprocess.Popen([str(binary), "tunnel", "--config", str(config),
                  "--no-autoupdate", "--url", "http://127.0.0.1:%d" % port],
                  stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
                  encoding="utf-8", errors="replace", bufsize=1)
        announced = False
        with (output / "tunnel.log").open("w", encoding="utf-8") as log:
            for line in tunnel.stdout:
                log.write(line)
                log.flush()
                match = re.search(r"https://[a-z0-9-]+\.trycloudflare\.com", line)
                if match and not announced:
                    url = match.group(0)
                    (ROOT / "YOUR_PUBLIC_LINK.txt").write_text(url + "\n", encoding="utf-8")
                    print("\nPUBLIC GAME LINK: " + url + "\n"
                          "Share this link with any laptop or phone.\n"
                          "Keep this PC awake, online, and this window open.\n"
                          "Ctrl+C stops sharing. This temporary link changes after restart.\n",
                          flush=True)
                    webbrowser.open(url)
                    announced = True
                elif not announced:
                    print(line.rstrip(), flush=True)
        raise RuntimeError("Tunnel stopped. See " + str(output / "tunnel.log"))
    finally:
        if tunnel and tunnel.poll() is None:
            tunnel.terminate()
            try:
                tunnel.wait(timeout=5)
            except subprocess.TimeoutExpired:
                tunnel.kill()
                tunnel.wait()
        server.shutdown()
        server.server_close()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", help="Path to installed Godot editor")
    parser.add_argument("--project", type=Path, default=ROOT / "game")
    parser.add_argument("--local-only", action="store_true", help="Test without public sharing")
    parser.add_argument("--rebuild", action="store_true", help="Re-export the edited project")
    parser.add_argument("--skip-build", action="store_true", help="Reuse last successful export")
    args = parser.parse_args()
    cache = Path(os.environ.get("LOCALAPPDATA", str(Path.home() / ".cache"))) / "MEMORY_BREACH_Host"
    cache.mkdir(parents=True, exist_ok=True)
    output = ROOT / ".hosting"
    output.mkdir(exist_ok=True)
    settings = ROOT / "host_settings.json"
    config = json.loads(settings.read_text()) if settings.exists() else {}
    public = output / "public"
    if args.rebuild or (not args.skip_build and not (public / "play/index.html").exists()):
        godot = find_godot(args.godot, config)
        version = godot_version(godot)
        settings.write_text(json.dumps({"godot": str(godot)}, indent=2), encoding="utf-8")
        ensure_templates(version, cache)
        public = build(godot, args.project.resolve(), output)
    if not (public / "play/index.html").exists():
        raise RuntimeError("No exported game found. Run with --rebuild first.")
    prepare_compressed_assets(public)
    host(public, cache, output, args.local_only)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\nHosting stopped.")
    except Exception as error:
        print("\nERROR:", error, file=sys.stderr)
        sys.exit(1)
