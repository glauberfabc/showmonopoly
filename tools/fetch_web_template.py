"""Fetch only the web templates from the official Godot 3.6 release archive."""
import io
import pathlib
import urllib.request
import zipfile

URL = "https://github.com/godotengine/godot/releases/download/3.6-stable/Godot_v3.6-stable_export_templates.tpz"


class RemoteZip(io.RawIOBase):
    def __init__(self, url):
        request = urllib.request.Request(url, headers={"Range": "bytes=0-0"})
        with urllib.request.urlopen(request, timeout=90) as response:
            if response.status != 206:
                raise RuntimeError("Official asset server did not support ranged download")
            self.url = response.url
            self.size = int(response.headers["Content-Range"].split("/")[-1])
            response.read()
        self.position = 0

    def seekable(self):
        return True

    def readable(self):
        return True

    def tell(self):
        return self.position

    def seek(self, offset, whence=0):
        self.position = offset if whence == 0 else self.position + offset if whence == 1 else self.size + offset
        return self.position

    def read(self, size=-1):
        if size < 0:
            size = self.size - self.position
        size = min(size, self.size - self.position)
        if size <= 0:
            return b""
        end = self.position + size - 1
        request = urllib.request.Request(self.url, headers={"Range": f"bytes={self.position}-{end}"})
        with urllib.request.urlopen(request, timeout=90) as response:
            if response.status != 206:
                raise RuntimeError("Ranged request was not honored")
            data = response.read()
        self.position += len(data)
        return data


destination = pathlib.Path(__file__).resolve().parent / "web_templates"
destination.mkdir(exist_ok=True)
(destination / ".gdignore").touch()
with zipfile.ZipFile(RemoteZip(URL)) as archive:
    names = [name for name in archive.namelist() if "webassembly" in name or "html5" in name]
    print("Available web templates:", names, flush=True)
    for name in names:
        base = pathlib.PurePosixPath(name).name
        if base in ("webassembly_release.zip", "webassembly_debug.zip"):
            path = destination / base
            path.write_bytes(archive.read(name))
            print("Downloaded", path, path.stat().st_size, "bytes", flush=True)
