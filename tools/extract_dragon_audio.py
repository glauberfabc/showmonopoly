"""Extract only embedded audio and cue names, never HAR request data."""
import base64
import hashlib
import json
import pathlib
from urllib.parse import urlsplit
from mutagen import File

ROOT = pathlib.Path(__file__).resolve().parent.parent
HAR = pathlib.Path('I:/Clone jogos/dragon som melhor de todos.har')

def extract(out):
    entries = json.loads(HAR.read_text(encoding='utf-8-sig'))['log']['entries']
    assets = {}
    configs = []
    for entry in entries:
        name = pathlib.PurePosixPath(urlsplit(entry['request']['url']).path).name
        content = entry['response'].get('content', {})
        if content.get('mimeType', '').startswith('audio/') and content.get('encoding') == 'base64':
            assets[name] = base64.b64decode(content['text'])
        if name == 'config_desktop.json' and content.get('text'):
            configs.append(json.loads(content['text']))
    banks = []
    def walk(node):
        if isinstance(node, dict):
            if 'soundBufferId' in node and 'sounds' in node and 'files' in node:
                banks.append(node)
            for value in node.values():
                walk(value)
        elif isinstance(node, list):
            for value in node:
                walk(value)
    for config in configs:
        walk(config)
    items, seen = [], set()
    for bank in banks:
        name = next((pathlib.PurePosixPath(f['url']).name for f in bank['files'].values()
                     if pathlib.PurePosixPath(f['url']).name in assets), None)
        if name is None:
            raise ValueError('Missing embedded audio bank: ' + bank['soundBufferId'])
        data = assets[name]
        filename = 'sound-' + hashlib.sha256(data).hexdigest()[:16] + pathlib.Path(name).suffix
        target = out / filename
        target.write_bytes(data)
        info = File(target).info
        for label, cue in bank['sounds'].items():
            if label == 'empty' or (filename, label) in seen:
                continue
            seen.add((filename, label))
            start, end = cue['start'] / info.sample_rate, cue['end'] / info.sample_rate
            if not 0 <= start < end <= info.length + 0.05:
                raise ValueError('Invalid audio interval: ' + label)
            group = 'Dragon · ' + ('interface' if bank['soundBufferId'] == 'common_sounds'
                                   else 'músicas' if 'Theme' in label or 'Music' in label else 'efeitos')
            items.append(dict(group=group, name=label, file=filename, start=start, end=end, duration=end-start))
    if not items:
        raise ValueError('No audio extracted')
    return items

if __name__ == '__main__':
    out = ROOT / 'web/build'
    catalog = out / 'sounds.json'
    items = [item for item in json.loads(catalog.read_text(encoding='utf-8'))
             if not item['group'].startswith('Dragon · ')]
    dragon = extract(out)
    catalog.write_text(json.dumps(items + dragon, ensure_ascii=False), encoding='utf-8')
    print(json.dumps({'added': len(dragon), 'total': len(items + dragon),
                      'files': len({item['file'] for item in dragon})}))
