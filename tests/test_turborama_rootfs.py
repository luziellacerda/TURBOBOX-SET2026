import importlib.util
from pathlib import Path
import tempfile
import unittest

MODULE = Path(__file__).resolve().parents[1] / 'tools/audit-turborama-rootfs.py'
SPEC = importlib.util.spec_from_file_location('rootfs_audit', MODULE)
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)


class RootfsTests(unittest.TestCase):
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


if __name__ == '__main__':
    unittest.main()
