#!/usr/bin/env python3
"""Read-only checks on an extracted Turborama SYSTEM image; never execute its code."""

import argparse
from collections import deque
import gzip
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import struct
import xml.etree.ElementTree as ET
import zlib


LEGACY = re.compile(rb'emu' rb'elec|\bee' rb'mount\b|\bee' rb'roms\b|\bee' rb'version\b|\bee' rb'_utils\b', re.I)


def audit_identity(root, build_root=None):
    """Inspect payload bytes and links, separating build provenance from branding."""
    errors = []
    build_references = 0
    attributions = 0
    prefix = os.fsencode(build_root) if build_root else None
    build_pattern = re.compile(re.escape(prefix) + rb'(?=/|[\x00\s]|$)') if prefix else None
    for directory, dirs, files in os.walk(root, followlinks=False):
        for name in dirs + files:
            path = Path(directory) / name
            relative = str(path.relative_to(root))
            if LEGACY.search(os.fsencode(relative)):
                errors.append(f'Legacy payload path: /{relative}')
            if path.is_symlink():
                if LEGACY.search(os.fsencode(os.readlink(path))):
                    errors.append(f'Legacy symlink target: /{relative}')
                continue
            if not path.is_file():
                continue
            data = path.read_bytes()
            if not LEGACY.search(data):
                continue
            if build_pattern:
                data, count = build_pattern.subn(b'<build-root>', data)
                build_references += count * len(LEGACY.findall(prefix))
            for match in LEGACY.finditer(data):
                start = max(data.rfind(b'\0', 0, match.start()), data.rfind(b'\n', 0, match.start())) + 1
                ends = [end for end in (data.find(b'\0', match.end()), data.find(b'\n', match.end())) if end >= 0]
                end = min(ends) if ends else len(data)
                line = data[start:end]
                if b'copyright' in line.lower():
                    attributions += 1
                    continue
                excerpt = data[max(start, match.start() - 60):min(end, match.end() + 100)]
                errors.append(f'Legacy payload content: /{relative}: {excerpt.decode("utf-8", errors="replace")!r}')
                break  # One actionable diagnostic per file is sufficient.
    return errors, build_references, attributions


def audit_disk(path):
    """Read the labels of the Generic MBR image without mounting or modifying it."""
    errors = []
    opener = gzip.open if path.suffix == '.gz' else open
    with opener(path, 'rb') as stream:
        mbr = stream.read(512)
        if len(mbr) != 512 or mbr[510:512] != b'\x55\xaa':
            return ['Invalid MBR signature']
        if mbr[450] == 0xee:
            return ['GPT is not supported by this Generic MBR label check']
        boot_sector = struct.unpack_from('<I', mbr, 454)[0]
        storage_sector = struct.unpack_from('<I', mbr, 470)[0]
        if not 0 < boot_sector < storage_sector:
            return ['Invalid boot/storage partition offsets']
        stream.seek(boot_sector * 512)
        boot = stream.read(512)
        if len(boot) != 512:
            return ['Truncated FAT boot sector']
        if boot[82:90] == b'FAT32   ':
            label = boot[71:82]
        elif boot[54:62] in (b'FAT16   ', b'FAT12   '):
            label = boot[43:54]
        else:
            return ['Unsupported boot filesystem']
        if label.rstrip() != b'TURBORAMA':
            errors.append('Boot partition is not labeled TURBORAMA')
        stream.seek(storage_sector * 512 + 1024)
        superblock = stream.read(1024)
        if len(superblock) != 1024 or superblock[56:58] != b'\x53\xef':
            errors.append('Missing ext filesystem on STORAGE partition')
        elif superblock[120:136].rstrip(b'\0') != b'STORAGE':
            errors.append('System data partition is not labeled STORAGE')
    return errors


def audit_boot_script(path):
    """Check a generated legacy U-Boot script header and payload without running it."""
    if not path.is_file():
        return [f'Missing boot script: {path.name}']
    data = path.read_bytes()
    if len(data) < 64:
        return [f'Truncated boot script: {path.name}']
    magic, hcrc, _, size, _, _, dcrc, _, _, kind, compression, _ = struct.unpack('>7I4B32s', data[:64])
    if magic != 0x27051956 or kind != 6 or compression != 0:
        return [f'Invalid U-Boot script header: {path.name}']
    header = data[:4] + b'\0' * 4 + data[8:64]
    if hcrc != zlib.crc32(header) or size != len(data) - 64 or dcrc != zlib.crc32(data[64:]):
        return [f'Boot script checksum/size mismatch: {path.name}']
    return []


def image_path(root, absolute):
    """Resolve image symlinks inside the image, never against the host filesystem."""
    parts = deque(PurePosixPath(absolute).parts)
    resolved = []
    links = 0
    while parts:
        part = parts.popleft()
        if part in ('/', '.'):
            continue
        if part == '..':
            if resolved:
                resolved.pop()
            continue
        candidate = root.joinpath(*resolved, part)
        if candidate.is_symlink():
            links += 1
            if links > 40:
                raise ValueError(f'Symlink loop: {absolute}')
            target = PurePosixPath(os.readlink(candidate))
            if target.is_absolute():
                resolved = []
            parts.extendleft(reversed(target.parts))
        else:
            resolved.append(part)
    return root.joinpath(*resolved)


def audit(root, initramfs=None):
    errors = []

    def require(condition, message):
        if not condition:
            errors.append(message)

    def read(absolute):
        path = image_path(root, absolute)
        if not path.is_file():
            errors.append(f'Missing file: {absolute}')
            return ''
        return path.read_text()

    release = dict(re.findall(r'^(\w+)="?([^"\n]*)"?$', read('/etc/os-release'), re.M))
    require(release.get('NAME') == 'Turborama', 'Incorrect OS name')
    require(release.get('ID') == 'turborama', 'Incorrect OS ID')
    require(read('/turborama_arch').strip() == 'Amlogic-ng', 'Wrong device image')
    require(read('/usr/config/TURBORAMA_VERSION').strip().startswith('1.'), 'Missing Turborama version')
    link = root / 'turborama'
    require(link.is_symlink() and os.readlink(link) == '/storage/.config/turborama', 'Wrong /turborama link')

    units = '/usr/lib/systemd/system'
    for template in (root / units.lstrip('/')).glob('*.wants/*@.service'):
        errors.append(f'Empty service template enabled without an instance: {template.relative_to(root)}')
    require(image_path(root, units + '/default.target') == root / (units + '/turborama.target').lstrip('/'),
            'Default target does not select Turborama')
    read(units + '/turborama.target')
    for name in ('turborama-autostart', 'turborama-disable_small_cores', 'emustation', 'retroarch'):
        read(f'{units}/{name}.service')
        wanted = root / f'{units.lstrip("/")}/turborama.target.wants/{name}.service'
        require(wanted.is_symlink() and image_path(root, '/' + str(wanted.relative_to(root))).is_file(),
                f'Service is not enabled: {name}')
    require('Before=emustation.service' in read(units + '/turborama-autostart.service'), 'Missing frontend ordering')
    require('systemctl --no-block start emustation' in read('/usr/bin/turborama_autostart.sh'), 'Autostart can wait on its own dependency')
    graphics = read(units + '/libmali.service')
    ordering = re.search(r'^Before=(.*)$', graphics, re.M)
    require(bool(ordering) and {'turborama-autostart.service', 'emustation.service', 'retroarch.service'} <= set(ordering[1].split()),
            'Mali graphics setup is not ordered before Turborama frontends')
    enabled = units + '/local-fs.target.wants/libmali.service'
    require(image_path(root, enabled).is_file(), 'Mali graphics setup is not enabled')
    read('/usr/sbin/libmali-overlay-setup')
    for directory in ('/usr/lib', '/usr/lib32'):
        for gpu in ('gondul', 'dvalin', 'm450'):
            require(image_path(root, f'{directory}/libMali.{gpu}.so').is_file(),
                    f'Missing graphics driver: {directory}/libMali.{gpu}.so')

    commands = ('turborama-settings', 'turborama_asd', 'emulationstation', 'retroarch', 'retroarch32',
                'turboramaRunEmu.sh', 'turborama-utils', 'emustation-config', 'updatecheck.sh', 'python3')
    for command in commands + ('../sbin/turborama-mount',):
        absolute = '/usr/bin/' + command
        path = image_path(root, absolute)
        if not path.is_file():
            errors.append(f'Missing executable: {absolute}')
            continue
        require(bool(path.stat().st_mode & 0o111), f'Not executable: {absolute}')
        with path.open('rb') as stream:
            magic = stream.read(4)
        if magic == b'\x7fELF':
            info = subprocess.run(['readelf', '-l', str(path)], capture_output=True, text=True, check=True)
            match = re.search(r'Requesting program interpreter: ([^\]]+)', info.stdout)
            if match:
                require(image_path(root, match[1]).is_file(), f'Missing ELF loader for {absolute}: {match[1]}')

    for config in ('turborama/configs/turborama.conf', 'emulationstation/scripts/es_env.sh'):
        read('/usr/config/' + config)
    systems = read('/usr/config/emulationstation/es_systems.cfg')
    if systems:
        try:
            xml = ET.fromstring(systems)
            require(any('turboramaRunEmu.sh' in (entry.text or '') for entry in xml.iter('command')),
                    'Frontend does not invoke the Turborama launcher')
        except ET.ParseError as error:
            errors.append(f'Invalid frontend systems XML: {error}')
    require('publish_update' in read('/usr/bin/updatecheck.sh'), 'Missing shared update verifier')
    require('stageupdate' in read('/usr/bin/batocera/turborama-upgrade'), 'Frontend bypasses shared updater')
    for script in ('Generic_cfgload', 'aml_autoscript'):
        path = image_path(root, '/usr/share/bootloader/' + script)
        errors.extend(audit_boot_script(path))
        if script == 'Generic_cfgload' and path.is_file():
            require(b'boot=LABEL=TURBORAMA disk=LABEL=STORAGE' in path.read_bytes(),
                    'Generated Generic boot script selects incorrect partitions')
    if initramfs:
        init = image_path(initramfs, '/init')
        require(init.is_file() and 'LABEL=TURBOROMS' in init.read_text(), 'Initramfs has the wrong ROM partition label')
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('root', type=Path, help='Extracted Amlogic-ng SYSTEM directory')
    parser.add_argument('--initramfs', type=Path, help='Optional extracted initramfs directory')
    parser.add_argument('--disk', type=Path, help='Optional Generic .img or .img.gz for partition label checks')
    parser.add_argument('--build-root', type=Path, default=Path(__file__).resolve().parents[1],
                        help='Exact source directory to classify embedded build paths as provenance')
    args = parser.parse_args()
    if not args.root.is_dir():
        parser.error('root must be an extracted directory')
    errors = audit(args.root.resolve(), args.initramfs.resolve() if args.initramfs else None)
    identity_errors, build_references, attributions = audit_identity(args.root.resolve(), args.build_root)
    errors.extend(identity_errors)
    print(f'Payload identity: {build_references} build-path references and {attributions} attribution references preserved.')
    if args.disk:
        errors.extend(audit_disk(args.disk))
    for error in errors:
        print('FAIL:', error)
    print(f'Rootfs structural audit: {len(errors)} failure(s). This does not replace a hardware boot test.')
    return bool(errors)


if __name__ == '__main__':
    raise SystemExit(main())
