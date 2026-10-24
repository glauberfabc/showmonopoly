"""Build a public audio-only catalog; never publish HAR headers or URLs."""
import base64, hashlib, json, pathlib, re, shutil, struct
from urllib.parse import urlsplit
from mutagen import File

ROOT = pathlib.Path(__file__).resolve().parent.parent
OUT = ROOT / 'web/build'
OUT.mkdir(exist_ok=True)
items = []

def add(group, name, data, extension, start=0, end=None):
    digest = hashlib.sha256(data).hexdigest()[:16]
    filename = 'sound-' + digest + extension
    target = OUT / filename
    if not target.exists(): target.write_bytes(data)
    duration = File(target).info.length
    items.append(dict(group=group, name=name, file=filename, start=start,
                      end=end or duration, duration=(end or duration)-start))

def crc(data):
    value = 0
    for byte in data:
        value ^= byte << 24
        for _ in range(8):
            value = ((value << 1) ^ (0x04c11db7 if value & 0x80000000 else 0)) & 0xffffffff
    return value

def unpack_ogg(data):
    # Godot binary resource: OggPacketSequence packet_data nested arrays.
    p = data.index(b'OggPacketSequence\0') + len(b'OggPacketSequence\0') + 8
    def u32():
        nonlocal p
        value = struct.unpack_from('<I', data, p)[0]; p += 4
        return value
    assert u32() == 30
    pages = []
    for _ in range(u32()):
        assert u32() == 30
        packets = []
        for _ in range(u32()):
            assert u32() == 31
            size = u32(); packets.append(data[p:p+size]); p += size + (-size % 4)
        pages.append(packets)
    u32()  # granule_positions property index
    assert u32() == 48  # PackedInt64Array
    count = u32()
    granules = struct.unpack_from('<' + 'q'*count, data, p)
    assert count == len(pages)
    result = bytearray()
    for seq, packets in enumerate(pages):
        laces = []
        for packet in packets:
            laces.extend([255] * (len(packet)//255) + [len(packet)%255])
        assert len(laces) <= 255
        flags = (2 if seq == 0 else 0) | (4 if seq == len(pages)-1 else 0)
        page = bytearray(b'OggS' + struct.pack('<BBqIIIB', 0, flags, granules[seq], 1, seq, 0, len(laces)) + bytes(laces) + b''.join(packets))
        struct.pack_into('<I', page, 22, crc(page)); result.extend(page)
    return bytes(result)

def pck_files(data):
    base = struct.unpack_from('<Q', data, 24)[0]
    p = struct.unpack_from('<Q', data, 32)[0]
    count = struct.unpack_from('<I', data, p)[0]; p += 4
    for _ in range(count):
        size = struct.unpack_from('<I', data, p)[0]; p += 4
        name = data[p:p+size].rstrip(b'\0').decode(); p += size
        offset, length = struct.unpack_from('<QQ', data, p); p += 36
        yield name, data[base+offset:base+offset+length]

for prefix, group in [('game', 'Potion Master · jogo'), ('hotjackpot', 'Potion Master · jackpot')]:
    track = next((ROOT/'assets/audio').glob(prefix+'-sounds*.mp3')).read_bytes()
    sprites = json.loads((ROOT/'assets/audio'/f'{prefix}-sprites.json').read_text())
    for name, cue in sprites.items(): add(group, name, track, '.mp3', cue['start'], cue['end'])
for path in (ROOT/'assets/audio').glob('notif*.mp3'):
    add('Interface', path.stem, path.read_bytes(), '.mp3')

for title, har in [('Triple Bonus', pathlib.Path('C:/Users/gladn/Downloads/triple bonus.har')), ('Ace Base', pathlib.Path('I:/Clone jogos/ace base.har'))]:
    seen = set()
    for entry in json.loads(har.read_text(encoding='utf-8-sig'))['log']['entries']:
        name = pathlib.PurePosixPath(urlsplit(entry['request']['url']).path).name
        content = entry['response'].get('content', {})
        if not name.endswith('.pck') or not content.get('text'): continue
        data = base64.b64decode(content['text'])
        group = title + (' \u00b7 bingo' if 'audios_spines' in name else ' \u00b7 slot' if 'big_eye' in name else ' \u00b7 Joker' if 'joker' in name else ' \u00b7 interface')
        for resource, payload in pck_files(data):
            if not resource.endswith('.oggvorbisstr'): continue
            key = (group, hashlib.sha256(payload).hexdigest())
            if key in seen: continue
            seen.add(key)
            label = pathlib.PurePosixPath(resource).name.split('.ogg-')[0]
            add(group, label, unpack_ogg(payload), '.ogg')

# Other audio already extracted in the neighboring game workspaces.
for game, folder in [('Show Ball 3', 'showball-server'), ('Pachinko 3', 'pachinko-server')]:
    for path in (ROOT.parent/'slot'/folder/'public').rglob('*.mp3'):
        add(game, path.stem, path.read_bytes(), '.mp3')

from extract_dragon_audio import extract as extract_dragon
items.extend(extract_dragon(OUT))
from extract_dragon_mais_audio import extract as extract_dragon_mais
items.extend(extract_dragon_mais(OUT))
(OUT/'sounds.json').write_text(json.dumps(items, ensure_ascii=False), encoding='utf-8')
shutil.copyfile(ROOT/'web/sounds.html', OUT/'sounds.html')
print(json.dumps({'sounds': len(items), 'groups': sorted({x['group'] for x in items})}, ensure_ascii=False))
