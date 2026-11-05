"""Create the static website archive consumed by the Ansible app role."""
from pathlib import Path
import tarfile

root = Path(__file__).resolve().parents[1]
with tarfile.open(root / 'site.tar.gz', 'w:gz') as archive:
    for path in sorted((root / 'site').iterdir()):
        if path.is_file():
            info = archive.gettarinfo(str(path), path.name)
            info.mode, info.mtime, info.uid, info.gid = 0o644, 0, 0, 0
            info.uname = info.gname = 'root'
            with path.open('rb') as source:
                archive.addfile(info, source)
