"""Проверяет реальные shell-команды извлечения версии из release workflow."""

import subprocess
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]


class ReleaseVersionTest(unittest.TestCase):
    def test_workflows_extract_version_without_build_number(self):
        for workflow in ("release-validate.yml", "release-rustore.yml"):
            source = (ROOT / ".github/workflows" / workflow).read_text()
            command = next(
                line.strip()
                for line in source.splitlines()
                if line.strip().startswith('pubspec_version=')
            )
            for version, expected in (("1.2.0+8", "1.2.0"), ("1.2.3+123", "1.2.3")):
                with self.subTest(workflow=workflow, version=version):
                    with tempfile.TemporaryDirectory() as directory:
                        Path(directory, "pubspec.yaml").write_text(
                            f"name: lampada\nversion: {version}\n"
                        )
                        result = subprocess.run(
                            ["bash", "-c", command + '\nprintf "%s" "$pubspec_version"'],
                            cwd=directory,
                            check=True,
                            capture_output=True,
                            text=True,
                        )
                        self.assertEqual(result.stdout, expected)


if __name__ == "__main__":
    unittest.main()
