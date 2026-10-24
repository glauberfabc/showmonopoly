import base64
import json
import pathlib
from urllib.parse import urlsplit

har = json.loads(pathlib.Path("I:/Downloads/bet88.ph.har").read_text(encoding="utf-8-sig"))
for entry in har["log"]["entries"]:
    path = urlsplit(entry.get("request", {}).get("url", "")).path
    content = entry.get("response", {}).get("content", {})
    if not any(token in path.lower() for token in ("sound", "audio")):
        continue
    if content.get("mimeType", "").startswith("audio") or path.endswith(".mp3"):
        continue
    text = content.get("text", "")
    if content.get("encoding") == "base64":
        try:
            text = base64.b64decode(text).decode("utf-8")
        except (ValueError, UnicodeDecodeError):
            continue
    try:
        data = json.loads(text)
    except ValueError:
        continue
    print("Audio metadata file:", pathlib.PurePosixPath(path).name)
    if isinstance(data, dict):
        print("Keys:", list(data)[:20])
        for key in ("spritemap", "sprite", "sounds"):
            if key in data:
                result = data[key]
                output = pathlib.Path("assets/audio") / ("hotjackpot-sprites.json" if "hotjackpot" in path else "game-sprites.json")
                output.write_text(json.dumps(result, indent=2), encoding="utf-8")
                print(json.dumps(result)[:9000])
