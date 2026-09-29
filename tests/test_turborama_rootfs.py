import importlib.util
import gzip
import os
from pathlib import Path
import struct
import tempfile
import unittest

MODULE = Path(__file__).resolve().parents[1] / 'tools/audit-turborama-rootfs.py'
SPEC = importlib.util.spec_from_file_location('rootfs_audit', MODULE)
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)


class RootfsTests(unittest.TestCase):
    def test_identity_distinguishes_build_paths_from_runtime_paths(self):
        legacy = b'Emu' b'ELEC'
        with tempfile.TemporaryDirectory(prefix='turborama-identity-test-') as tmp:
            root = Path(tmp)
            build_root = b'/build/' + legacy
            (root / 'binary').write_bytes(b'\x7fELF\0' + build_root + b'/src/test.cpp\0')
            (root / 'license').write_bytes(b'# Copyright Original ' + legacy + b' team\n')
            errors, metadata, attributions = AUDIT.audit_identity(root, Path(os.fsdecode(build_root)))
            self.assertEqual(errors, [])
            self.assertEqual((metadata, attributions), (1, 1))
            (root / 'binary').write_bytes(build_root + b'/src/test.cpp\0/' + legacy.lower() + b'/configs/test.cfg\0')
            errors, _, _ = AUDIT.audit_identity(root, Path(os.fsdecode(build_root)))
            self.assertEqual(len(errors), 1)
            self.assertIn('Legacy payload content: /binary', errors[0])
            (root / 'binary').write_bytes(build_root + b'-runtime/configs\0')
            errors, _, _ = AUDIT.audit_identity(root, Path(os.fsdecode(build_root)))
            self.assertEqual(len(errors), 1, 'A similarly named directory is not the actual build root')

    def test_identity_checks_symlink_targets_without_following_them(self):
        with tempfile.TemporaryDirectory(prefix='turborama-identity-test-') as tmp:
            root = Path(tmp)
            (root / 'link').symlink_to('/' + 'emu' + 'elec/configs')
            errors, _, _ = AUDIT.audit_identity(root)
            self.assertEqual(errors, ['Legacy symlink target: /link'])

    def test_absolute_and_relative_links_stay_in_image(self):
        with tempfile.TemporaryDirectory(prefix='turborama-rootfs-test-') as tmp:
            root = Path(tmp)
            (root / 'usr/lib').mkdir(parents=True)
            (root / 'lib').symlink_to('/usr/lib')
            (root / 'usr/lib/loader').symlink_to('../../bin/loader-real')
            self.assertEqual(AUDIT.image_path(root, '/lib/loader'), root / 'bin/loader-real')
            self.assertEqual(AUDIT.image_path(root, '/../../etc/os-release'), root / 'etc/os-release')

    def test_loop_is_rejected(self):
        with tempfile.TemporaryDirectory(prefix='turborama-rootfs-test-') as tmp:
            root = Path(tmp)
            (root / 'a').symlink_to('/b')
            (root / 'b').symlink_to('/a')
            with self.assertRaises(ValueError):
                AUDIT.image_path(root, '/a')

    def test_empty_root_is_not_accepted_as_a_valid_image(self):
        with tempfile.TemporaryDirectory(prefix='turborama-rootfs-test-') as tmp:
            self.assertGreater(len(AUDIT.audit(Path(tmp))), 10)

    def test_compressed_partition_labels(self):
        disk = bytearray(4096)
        disk[510:512] = b'\x55\xaa'
        struct.pack_into('<I', disk, 454, 1)
        struct.pack_into('<I', disk, 470, 4)
        disk[512 + 54:512 + 62] = b'FAT16   '
        disk[512 + 43:512 + 54] = b'TURBORAMA  '
        disk[3072 + 56:3072 + 58] = b'\x53\xef'
        disk[3072 + 120:3072 + 127] = b'STORAGE'
        with tempfile.TemporaryDirectory(prefix='turborama-disk-test-') as tmp:
            path = Path(tmp) / 'image.img.gz'
            with gzip.open(path, 'wb') as stream:
                stream.write(disk)
            self.assertEqual(AUDIT.audit_disk(path), [])
            disk[512 + 43:512 + 54] = b'WRONG      '
            with gzip.open(path, 'wb') as stream:
                stream.write(disk)
            self.assertIn('Boot partition is not labeled TURBORAMA', AUDIT.audit_disk(path))

    def test_truncated_disk_is_rejected(self):
        with tempfile.TemporaryDirectory(prefix='turborama-disk-test-') as tmp:
            path = Path(tmp) / 'image.img'
            path.write_bytes(b'incomplete')
            self.assertEqual(AUDIT.audit_disk(path), ['Invalid MBR signature'])


if __name__ == '__main__':
    unittest.main()
