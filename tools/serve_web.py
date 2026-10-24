"""Serve only the generated game on loopback; keep running while playing."""
import argparse
import functools
import http.server
import pathlib

parser = argparse.ArgumentParser()
parser.add_argument("--port", type=int, default=8765)
args = parser.parse_args()
root = pathlib.Path(__file__).resolve().parent.parent / "web" / "build"
if not (root / "index.html").is_file():
    raise SystemExit("Export the Godot Web preset before starting this server.")


class GameHandler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm", ".pck": "application/octet-stream"}

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


handler = functools.partial(GameHandler, directory=str(root))
server = http.server.ThreadingHTTPServer(("127.0.0.1", args.port), handler)
print(f"Potion Master ready at http://127.0.0.1:{server.server_port}/", flush=True)
server.serve_forever()
