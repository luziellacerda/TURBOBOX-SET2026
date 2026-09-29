#!/usr/bin/env python3
"""Host-side checks for renamed runtime contracts; never touch host boot/services."""

import ast
import hashlib
import io
import os
from pathlib import Path
import re
import struct
import subprocess
import tarfile
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
RUNTIME = ROOT / 'packages/sx05re/turborama'
UPDATER = RUNTIME / 'bin/updatecheck.sh'


class UpdateTests(unittest.TestCase):
    def run_function(self, expression, *args):
        return subprocess.run(
            ['bash', '-c', 'source "$1"; shift; ' + expression,
             'test', str(UPDATER), *map(str, args)], capture_output=True, text=True)

    def test_version_order(self):
        for new, old, expected in [
            ('1.1-Genesis', '1.0-Genesis', True),
            ('1.10-Genesis', '1.9-Genesis', True),
            ('1.0-Genesis', '1.0-Genesis', False),
            ('1.0-Genesis', '1.1-Genesis', False),
            ('../../file', '1.0-Genesis', False),
        ]:
            with self.subTest(new=new, old=old):
                self.assertEqual(self.run_function('newer_version "$1" "$2"', new, old).returncode == 0, expected)

    def test_device_filename(self):
        result = self.run_function('update_filename "$1" "$2"', 'Amlogic-ng', '1.0-Genesis')
        self.assertEqual(result.stdout.strip(), 'Turborama-Amlogic-ng.aarch64-1.0-Genesis.tar')
        self.assertNotEqual(self.run_function('update_filename "$1" "$2"', '../../disk', '1.0').returncode, 0)

    def test_download_validation(self):
        with tempfile.TemporaryDirectory(prefix='turborama-update-test-') as tmp:
            archive, checksum = Path(tmp) / 'payload', Path(tmp) / 'checksum'
            image = 'Turborama-Amlogic-ng.aarch64-1.0-Genesis'
            with tarfile.open(archive, 'w') as tar:
                for name in ('SYSTEM', 'KERNEL'):
                    entry = tarfile.TarInfo(f'{image}/target/{name}')
                    entry.size = 4
                    tar.addfile(entry, io.BytesIO(b'test'))
            checksum.write_text(hashlib.sha256(archive.read_bytes()).hexdigest() + '  image.tar\n')
            expression = 'verify_update "$1" "$2" "$3"'
            self.assertEqual(self.run_function(expression, archive, checksum, image).returncode, 0)
            self.assertNotEqual(self.run_function(expression, archive, checksum, image.replace('Amlogic-ng', 'Amlogic-old')).returncode, 0)
            checksum.write_text('0' * 64 + '  image.tar\n')
            self.assertNotEqual(self.run_function(expression, archive, checksum, image).returncode, 0)
            checksum.write_text('')
            self.assertNotEqual(self.run_function(expression, archive, checksum, image).returncode, 0)

    def test_staging_preserves_pending_updates(self):
        with tempfile.TemporaryDirectory(prefix='turborama-stage-test-') as tmp:
            folder = Path(tmp)
            archive, checksum = folder / 'payload', folder / 'checksum'
            image = 'Turborama-Amlogic-ng.aarch64-1.0-Genesis'
            with tarfile.open(archive, 'w') as tar:
                for name in ('SYSTEM', 'KERNEL'):
                    entry = tarfile.TarInfo(f'{image}/target/{name}')
                    entry.size = 4
                    tar.addfile(entry, io.BytesIO(b'test'))
            checksum.write_text(hashlib.sha256(archive.read_bytes()).hexdigest() + '\n')
            expression = 'publish_update "$1" "$2" "$3" "$4"'
            for pending_name in ('previous.tar', 'previous.img.gz', 'previous.img'):
                with self.subTest(pending_name=pending_name):
                    pending = folder / pending_name
                    pending.write_bytes(b'preserve me')
                    self.assertNotEqual(self.run_function(expression, archive, checksum, image, folder).returncode, 0)
                    self.assertEqual(pending.read_bytes(), b'preserve me')
                    self.assertTrue(archive.exists())
                    self.assertFalse((folder / f'{image}.tar').exists())
                    pending.unlink()
            self.assertEqual(self.run_function(expression, archive, checksum, image, folder).returncode, 0)
            self.assertTrue((folder / f'{image}.tar').exists())
            self.assertFalse(archive.exists())

    def test_frontend_update_uses_shared_validator(self):
        wrapper = (RUNTIME / 'bin/batocera/turborama-upgrade').read_text()
        self.assertIn('exec /usr/bin/updatecheck.sh stageupdate', wrapper)
        self.assertNotRegex(wrapper, r'\b(curl|wget)\b')


class SettingsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory(prefix='turborama-settings-test-')
        cls.binary = Path(cls.tmp.name) / 'turborama-settings'
        source = ROOT / 'packages/sx05re/tools/sysutils/turborama-sysutils/sources/turborama-settings.c'
        subprocess.run(['cc', '-O2', str(source), '-o', str(cls.binary)], check=True)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def test_read_write_and_priority(self):
        config = Path(self.tmp.name) / 'turborama.conf'
        config.write_text('turborama_ssh.enabled=1\nglobal.ratio=global\nnes.ratio=platform\nnes["Mario"].ratio=game\n')
        env = {**os.environ, 'TURBORAMA_CONF': str(config)}
        def call(*args):
            return subprocess.run([str(self.binary), '-e', *args], env=env,
                                  check=True, capture_output=True, text=True).stdout.strip()
        self.assertEqual(call('-r', 'turborama_ssh.enabled'), '1')
        self.assertEqual(call('-r', 'ratio', '-p', 'nes', '-m', 'Mario'), 'game')
        self.assertEqual(call('-r', 'ratio', '-p', 'nes', '-m', 'Other'), 'platform')
        self.assertEqual(call('-r', 'ratio', '-p', 'snes'), 'global')
        call('-s', 'turborama_ssh.enabled', '-v', '0')
        self.assertEqual(call('-r', 'turborama_ssh.enabled'), '0')


class JoystickTests(unittest.TestCase):
    def test_python3_keyboard_bytes(self):
        # Load only functions; the daemon body would fork and open real devices.
        tree = ast.parse((RUNTIME / 'bin/joy2key.py').read_text())
        functions = ast.Module(body=[n for n in tree.body if isinstance(n, ast.FunctionDef)], type_ignores=[])
        calls = []
        class Ioctl:
            def ioctl(self, fd, command, value):
                calls.append(value)
        class Termios:
            TIOCSTI = 1
        namespace = dict(struct=struct, event_format='IhBB', JS_EVENT_INIT=0x80,
                         JS_EVENT_BUTTON=1, JS_EVENT_AXIS=2, button_codes=[b'\x1b[A'],
                         fcntl=Ioctl(), termios=Termios(), tty_fd=0)
        exec(compile(functions, 'joy2key.py', 'exec'), namespace)
        self.assertEqual(namespace['get_hex_chars']('0x0a'), b'\n')
        self.assertTrue(namespace['process_event'](struct.pack('IhBB', 0, 1, 1, 0)))
        self.assertEqual(calls, [b'\x1b', b'[', b'A'])


class JavaTests(unittest.TestCase):
    def test_installer_and_launcher_use_same_version_marker(self):
        profile = (RUNTIME / 'profile.d/99-turborama.conf').read_text()
        launcher = (ROOT / 'packages/sx05re/libretro/freej2me/scripts/freej2me.sh').read_text()
        self.assertIn('cat ${JDKDEST}/turborama-version', profile)
        self.assertIn('> "${JDKDEST}/turborama-version"', profile)
        self.assertIn('/storage/roms/bios/jdk/turborama-version', launcher)


class BootTests(unittest.TestCase):
    def test_autostart_does_not_wait_for_dependent_frontend(self):
        unit = (RUNTIME / 'system.d/turborama-autostart.service').read_text()
        self.assertIn('Before=emustation.service', unit)
        script = (RUNTIME / 'bin/turborama_autostart.sh').read_text()
        starts = re.findall(r'^\s*(systemctl[^\n]*start emustation[^\n]*)', script, re.M)
        self.assertTrue(starts)
        self.assertTrue(all('--no-block' in command for command in starts))

    def test_boot_and_rom_labels_agree(self):
        boot = (ROOT / 'projects/Amlogic-ce/devices/Amlogic-ng/bootloader/scripts/Generic_cfgload.src').read_text()
        self.assertIn('boot=LABEL=TURBORAMA disk=LABEL=STORAGE', boot)
        init = (ROOT / 'packages/sysutils/busybox/scripts/init').read_text()
        resize = (ROOT / 'packages/sysutils/busybox/scripts/fs-resize').read_text()
        self.assertIn('LABEL=TURBOROMS', init)
        self.assertIn('mkfs.vfat -n TURBOROMS', resize)
        self.assertEqual(os.readlink(RUNTIME / 'bin/scripts/setup/user-scripts'),
                         '/storage/.config/turborama/scripts')


if __name__ == '__main__':
    unittest.main()
