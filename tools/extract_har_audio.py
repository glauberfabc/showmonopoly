"""Extract embedded audio bodies only. Never export HAR headers or cookies."""
import base64
import hashlib
import io
import json
import pathlib
import re
import sys
from urllib.parse import unquote, urlsplit
import mutagen

source = pathlib.Path(sys.argv[1])
target = pathlib.Path(__file__).resolve().parent.parent / "assets" / "audio"
target.mkdir(parents=True, exist_ok=True)
har = json.loads(source.read_text(encoding="utf-8-sig"))
records, seen = [], set()
for entry in har.get("log", {}).get("entries", []):
    content = entry.get("response", {}).get("content", {})
    url = urlsplit(entry.get("request", {}).get("url", ""))
    name = pathlib.PurePosixPath(unquote(url.path)).name
    mime = content.get("mimeType", "").split(";")[0]
    if not (mime.startswith("audio/") or re.search(r"\.(mp3|ogg|wav|m4a|aac|flac|webm)$", name, re.I)):
        continue
    text = content.get("text")
    record = {"source_host": url.hostname, "source_name": name, "mime": mime}
    if not text or content.get("encoding") != "base64":
        record["status"] = "body_unavailable"
        records.append(record)
        continue
    data = base64.b64decode(text, validate=True)
    digest = hashlib.sha256(data).hexdigest()
    if digest in seen:
        continue
    seen.add(digest)
    extension = pathlib.PurePosixPath(name).suffix.lower()
    if data.startswith(b"OggS"):
        extension = ".ogg"
    elif data.startswith(b"RIFF"):
        extension = ".wav"
    elif data.startswith(b"ID3") or data[:2] in (b"\xff\xfb", b"\xff\xf3", b"\xff\xf2"):
        extension = ".mp3"
    if extension not in (".ogg", ".wav", ".mp3", ".m4a", ".aac", ".flac", ".webm"):
        extension = ".bin"
    stem = re.sub(r"[^A-Za-z0-9_-]", "_", pathlib.PurePosixPath(name).stem)[:70] or "audio"
    filename = stem + "_" + digest[:8] + extension
    (target / filename).write_bytes(data)
    audio = mutagen.File(io.BytesIO(data))
    record.update(status="extracted", file=filename, bytes=len(data), sha256=digest,
                  duration_seconds=round(audio.info.length, 3) if audio else None)
    records.append(record)
(target / "manifest.json").write_text(json.dumps(records, indent=2, ensure_ascii=False), encoding="utf-8")
for item in records:
    print(json.dumps({k: item.get(k) for k in ("status", "source_name", "file", "bytes", "duration_seconds")}, ensure_ascii=False))
print("Extracted:", sum(r["status"] == "extracted" for r in records))
