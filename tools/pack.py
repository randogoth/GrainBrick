#!/usr/bin/env python3
"""Pack a directory into a muOS archive (.muxapp) and check it against the
same limits muOS applies in SAFE_ARCHIVE (opt/muos/script/var/zip.sh).

usage: pack.py <source_parent_dir> <top_level_name> <output.muxapp>
"""
import os
import stat
import sys
import zipfile

MAX_ENTRIES = 16384
MAX_ENTRY_BYTES = 536870912
MAX_TOTAL_BYTES = 2147483648
MAX_RATIO = 1000


def pack(parent, top, out):
    root = os.path.join(parent, top)
    entries = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames.sort()
        for name in sorted(filenames):
            full = os.path.join(dirpath, name)
            if os.path.islink(full) or not os.path.isfile(full):
                sys.exit(f"pack: refusing non-regular file: {full}")
            entries.append(full)

    tmp = out + ".part"
    with zipfile.ZipFile(tmp, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as z:
        for full in entries:
            arc = os.path.relpath(full, parent).replace(os.sep, "/")
            mode = os.stat(full).st_mode
            perm = 0o755 if mode & stat.S_IXUSR else 0o644
            info = zipfile.ZipInfo(arc, date_time=(2026, 1, 1, 0, 0, 0))
            info.create_system = 3  # Unix, so unzip restores permissions
            info.external_attr = (stat.S_IFREG | perm) << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            with open(full, "rb") as f:
                z.writestr(info, f.read(), compresslevel=9)
    os.replace(tmp, out)
    return check(out)


def check(path):
    problems = []
    total = 0
    with zipfile.ZipFile(path) as z:
        infos = z.infolist()
        for i in infos:
            n = i.filename
            if n.startswith("/") or (len(n) > 1 and n[1] == ":") or "\\" in n or ".." in n.split("/"):
                problems.append(f"unsafe path: {n}")
            ftype = (i.external_attr >> 16) & 0o170000
            if ftype not in (0, stat.S_IFREG, stat.S_IFDIR):
                problems.append(f"link/special file: {n}")
            if i.file_size > MAX_ENTRY_BYTES:
                problems.append(f"entry too large: {n}")
            if i.compress_size == 0 and i.file_size > 0:
                problems.append(f"bad ratio: {n}")
            elif i.compress_size and i.file_size / i.compress_size > MAX_RATIO:
                problems.append(f"ratio > {MAX_RATIO}: {n}")
            total += i.file_size
    if not infos or len(infos) > MAX_ENTRIES:
        problems.append(f"entry count {len(infos)} outside 1..{MAX_ENTRIES}")
    if total > MAX_TOTAL_BYTES:
        problems.append(f"total size {total} > {MAX_TOTAL_BYTES}")
    print(f"pack: {path}: {len(infos)} entries, {total / 1048576:.1f} MiB unpacked, "
          f"{os.path.getsize(path) / 1048576:.1f} MiB packed")
    for p in problems:
        print("pack: FAIL", p)
    return not problems


if __name__ == "__main__":
    if len(sys.argv) != 4:
        sys.exit(__doc__)
    sys.exit(0 if pack(*sys.argv[1:]) else 1)
