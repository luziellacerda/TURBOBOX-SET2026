#!/usr/bin/env python3
"""Audit tracked source identity without scanning build caches or rewriting licenses."""

from pathlib import Path
import os
import re
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
LEGACY = re.compile(r'emu' r'elec|emu' r'eelec|\bee' r'roms\b|\bee' r'mount\b|\bee' r'_\w*|\bget_' r'ee' r'_setting\b|\bset_' r'ee' r'_setting\b|\bee' r's\b', re.I)


class IdentityTests(unittest.TestCase):
    def test_tracked_identity_and_symlinks(self):
        paths = subprocess.check_output(
            ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '-z'], cwd=ROOT
        ).decode().split('\0')
        violations = []
        attribution_count = 0
        inspected = 0
        for relative in sorted(set(filter(None, paths))):
            path = ROOT / relative
            if not path.exists() and not path.is_symlink():
                continue  # Staged removal or a rename not yet added to the index.
            inspected += 1
            if LEGACY.search(relative):
                violations.append(f'{relative}: legacy filename')
            if path.is_symlink():
                if LEGACY.search(os.readlink(path)):
                    violations.append(f'{relative}: legacy symlink target')
                continue
            data = path.read_bytes()
            if b'\0' in data:
                continue  # Visual and binary assets require separate inspection.
            for line_number, line in enumerate(data.decode('utf-8', errors='replace').splitlines(), 1):
                if not LEGACY.search(line):
                    continue
                if 'copyright' in line.lower():
                    attribution_count += 1
                    continue
                violations.append(f'{relative}:{line_number}: legacy identity')
        self.assertGreater(inspected, 1000, 'Audit did not inspect the source tree')
        self.assertEqual(violations, [], '\n'.join(violations))
        print(f'Identity audit: {inspected} paths; {attribution_count} original attribution lines preserved.')


if __name__ == '__main__':
    unittest.main()
