#!/usr/bin/env python3
"""Read-only checks on an extracted Turborama SYSTEM image; never execute its code."""

import argparse
from collections import deque
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import xml.etree.ElementTree as ET


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
    if initramfs:
        init = image_path(initramfs, '/init')
        require(init.is_file() and 'LABEL=TURBOROMS' in init.read_text(), 'Initramfs has the wrong ROM partition label')
    return errors


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('root', type=Path, help='Extracted Amlogic-ng SYSTEM directory')
    parser.add_argument('--initramfs', type=Path, help='Optional extracted initramfs directory')
    args = parser.parse_args()
    if not args.root.is_dir():
        parser.error('root must be an extracted directory')
    errors = audit(args.root.resolve(), args.initramfs.resolve() if args.initramfs else None)
    for error in errors:
        print('FAIL:', error)
    print(f'Rootfs structural audit: {len(errors)} failure(s). This does not replace a hardware boot test.')
    return bool(errors)


if __name__ == '__main__':
    raise SystemExit(main())
