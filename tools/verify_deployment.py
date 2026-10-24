"""Verify public static assets against the authenticated upload manifest."""
import hashlib
import json
import pathlib
import urllib.request
from concurrent.futures import ThreadPoolExecutor

root = pathlib.Path(__file__).resolve().parent.parent
manifest = json.loads((root / ".deploy" / "deployment.json").read_text())
base = "http://" + manifest["host"] + "/games/potion-master/"
def verify(item):
    with urllib.request.urlopen(base + item["file"] + "?verify=" + item["sha256"], timeout=90) as response:
        actual = hashlib.sha256(response.read()).hexdigest()
        result = {"file": item["file"], "status": response.status,
                  "content_type": response.headers.get("Content-Type"),
                  "checksum_matches": actual == item["sha256"]}
    if not result["checksum_matches"]:
        raise RuntimeError("Public asset differs from local build: " + item["file"])
    return result

with ThreadPoolExecutor(max_workers=6) as pool:
    results = list(pool.map(verify, manifest["files"]))
print(json.dumps({"verified_assets": len(results), "all_checksums_match": True}), flush=True)
(root / "tests" / "deployment-verification.json").write_text(
    json.dumps({"url": base, "assets": results}, indent=2), encoding="utf-8")
