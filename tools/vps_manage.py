"""Password is prompted, held in memory, and never saved to project files."""
import argparse
import base64
import getpass
import hashlib
import pathlib
import paramiko

parser = argparse.ArgumentParser()
parser.add_argument("action", choices=["inspect", "inspect-web", "deploy"])
parser.add_argument("--host", required=True)
parser.add_argument("--user", default="root")
parser.add_argument("--replace", action="store_true", help="Atomically replace only the release recorded in the local manifest")
parser.add_argument("--audio-only", action="store_true", help="Preserve published game assets and update only the audio catalog")
args = parser.parse_args()
state = pathlib.Path(__file__).resolve().parent.parent / ".deploy"
state.mkdir(exist_ok=True)
known_hosts = state / "known_hosts"


class TrustNewHost(paramiko.MissingHostKeyPolicy):
    def missing_host_key(self, client, hostname, key):
        fingerprint = base64.b64encode(hashlib.sha256(key.asbytes()).digest()).decode().rstrip("=")
        print("New server host key SHA256:" + fingerprint, flush=True)
        client.get_host_keys().add(hostname, key.get_name(), key)
        client.save_host_keys(str(known_hosts))


client = paramiko.SSHClient()
if known_hosts.exists():
    client.load_host_keys(str(known_hosts))
client.set_missing_host_key_policy(TrustNewHost())
password = getpass.getpass("SSH password (not saved): ")
client.connect(args.host, username=args.user, password=password, timeout=20,
               auth_timeout=20, look_for_keys=False, allow_agent=False)
password = None
try:
    if args.action == "deploy":
        import json
        import time
        build = pathlib.Path(__file__).resolve().parent.parent / "web" / "build"
        allowed = {".html", ".js", ".wasm", ".pck", ".png", ".json", ".mp3", ".ogg", ".wav", ".m4a"}
        files = [p for p in build.iterdir() if p.is_file() and p.suffix in allowed]
        for required in ["index.html", "index.js", "index.wasm", "index.pck"]:
            if not (build / required).is_file():
                raise RuntimeError("Missing build file: " + required)
        target = "/var/www/games/potion-master"
        release = "/var/www/games/potion-master-release-" + time.strftime("%Y%m%d%H%M%S", time.gmtime())
        sftp = client.open_sftp()
        previous_release = None
        try:
            target_stat = sftp.lstat(target)
        except FileNotFoundError:
            pass
        else:
            import stat
            if not args.replace or not stat.S_ISLNK(target_stat.st_mode):
                raise RuntimeError("Destination exists and is not an authorized release symlink")
            saved = json.loads((state / "deployment.json").read_text())
            previous_release = sftp.readlink(target)
            if saved["host"] != args.host or saved["path"] != target or saved["release"] != previous_release:
                raise RuntimeError("Remote release differs from the recorded deployment; inspect first")
        sftp.mkdir(release, mode=0o755)
        import shlex
        manifest = [{"file": p.name, "sha256": hashlib.sha256(p.read_bytes()).hexdigest(), "bytes": p.stat().st_size} for p in sorted(files)]
        previous_hashes = {item["file"]: item["sha256"] for item in saved["files"]} if previous_release else {}
        if args.audio_only:
            if not previous_release:
                raise RuntimeError("Audio-only deployment requires an existing release")
            updates = {item["file"]: item for item in manifest if item["file"].startswith("sound-") or item["file"] in ("sounds.json", "sounds.html")}
            merged = {item["file"]: item for item in saved["files"]}
            merged.update(updates)
            manifest = sorted(merged.values(), key=lambda item: item["file"])
        reusable = [item for item in manifest if previous_hashes.get(item["file"]) == item["sha256"]]
        if reusable:
            command = "cp -- " + " ".join(shlex.quote(previous_release + "/" + item["file"]) for item in reusable) + " " + shlex.quote(release + "/")
            _, copied, errors = client.exec_command(command, timeout=60)
            if copied.channel.recv_exit_status() != 0:
                raise RuntimeError("Unable to reuse previous assets: " + errors.read().decode())
            print("Reused unchanged assets: " + str(len(reusable)), flush=True)
        reusable_names = {item["file"] for item in reusable}
        for item in manifest:
            if item["file"] not in reusable_names:
                sftp.put(str(build / item["file"]), release + "/" + item["file"])
                sftp.chmod(release + "/" + item["file"], 0o644)
                print("Uploaded: " + item["file"], flush=True)
        command = "sha256sum -- " + " ".join(shlex.quote(release + "/" + item["file"]) for item in manifest)
        _, checked, errors = client.exec_command(command, timeout=60)
        hashes = {}
        for line in checked.read().decode().splitlines():
            digest, name = line.split(None, 1)
            hashes[name.strip().rsplit("/", 1)[-1]] = digest
        if checked.channel.recv_exit_status() != 0:
            raise RuntimeError("Remote checksum failed: " + errors.read().decode())
        for item in manifest:
            if hashes.get(item["file"]) != item["sha256"]:
                raise RuntimeError("Remote checksum mismatch: " + item["file"])
        print("Verified all assets: " + str(len(manifest)), flush=True)
        if previous_release:
            if sftp.readlink(target) != previous_release:
                raise RuntimeError("Release changed during upload; refusing replacement")
            staging_link = release + "-activate"
            sftp.symlink(release, staging_link)
            sftp.posix_rename(staging_link, target)
        else:
            sftp.symlink(release, target)
        sftp.close()
        (state / "deployment.json").write_text(json.dumps({"host": args.host, "path": target, "release": release, "previous_release": previous_release, "files": manifest}, indent=2), encoding="utf-8")
        print("Published http://" + args.host + "/games/potion-master/", flush=True)
        raise SystemExit(0)
    command = """uname -sr; cat /etc/os-release | head -n 6; df -h /; command -v nginx || true; command -v caddy || true; command -v apache2 || true; command -v docker || true; ss -ltnp | head -n 18; ls -ld /var/www /srv /opt 2>/dev/null; ls /etc/nginx/sites-enabled 2>/dev/null; ls /etc/nginx/conf.d 2>/dev/null"""
    if args.action == "inspect-web":
        command = """cat /etc/nginx/nginx.conf; cat /etc/nginx/conf.d/2.25.190.121.conf; ls -la /etc/nginx/conf.d/main; ss -ltnp | grep -E ':(80|443|8765|8095) '; ls -la /var/www; nginx -t 2>&1"""
    _, output, errors = client.exec_command(command, timeout=30)
    print(output.read().decode("utf-8", "replace"))
    print(errors.read().decode("utf-8", "replace"))
    raise SystemExit(output.channel.recv_exit_status())
finally:
    client.close()
