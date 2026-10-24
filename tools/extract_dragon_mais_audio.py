"""Import embedded Dragon Mais Legal audio, preserving the encoded audio stream."""
import base64
import hashlib
import json
import pathlib
import subprocess
from urllib.parse import urlsplit
from mutagen import File

ROOT = pathlib.Path(__file__).resolve().parent.parent
HAR = pathlib.Path('I:/Clone jogos/dragon mais legal som.har')

def extract(out):
    work = ROOT / '.deploy/dragon-mais-audio'
    work.mkdir(parents=True, exist_ok=True)
    items, seen = [], set()
    entries = json.loads(HAR.read_text(encoding='utf-8-sig'))['log']['entries']
    for entry in entries:
        name = pathlib.PurePosixPath(urlsplit(entry['request']['url']).path).name
        content = entry['response'].get('content', {})
        if not name.endswith('.webm') or content.get('encoding') != 'base64':
            continue
        data = base64.b64decode(content['text'])
        digest = hashlib.sha256(data).hexdigest()[:16]
        if digest in seen:
            continue
        seen.add(digest)
        source = work / (digest + '.webm')
        source.write_bytes(data)
        probe = subprocess.run(['ffprobe', '-v', 'error', '-show_streams', '-of', 'json', str(source)],
                               capture_output=True, check=True, text=True)
        streams = json.loads(probe.stdout)['streams']
        if not any(s['codec_type'] == 'audio' for s in streams):
            continue
        target = out / ('sound-' + digest + '.ogg')
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(source), '-map', '0:a:0',
                        '-vn', '-map_metadata', '-1', '-c:a', 'copy', str(target)], check=True)
        duration = File(target).info.length
        if duration <= 0:
            raise ValueError('Invalid duration: ' + name)
        label = pathlib.Path(name).stem
        category = 'músicas' if label.startswith('music') or 'ambience' in label else 'efeitos'
        items.append(dict(group='Dragon Mais Legal · ' + category, name=label,
                          file=target.name, start=0, end=duration, duration=duration))
    if not items:
        raise ValueError('No embedded audio found')
    return items

if __name__ == '__main__':
    out = ROOT / 'web/build'
    catalog = out / 'sounds.json'
    items = [i for i in json.loads(catalog.read_text(encoding='utf-8'))
             if not i['group'].startswith('Dragon Mais Legal · ')]
    added = extract(out)
    keys = {(i['file'], i['start'], i['end']) for i in items}
    added = [i for i in added if (i['file'], i['start'], i['end']) not in keys]
    catalog.write_text(json.dumps(items + added, ensure_ascii=False), encoding='utf-8')
    print(json.dumps({'added': len(added), 'total': len(items + added)}))
