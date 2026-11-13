# GrainBrick for muOS

GrainBrick beta 1.0.1, originally released as a KNULLI port, repackaged as a muOS application (`.muxapp`). Built and checked against MustardOS 2606.0 Andromeda on the TrimUI Brick.

## Install

1. Copy `dist/GrainBrick.muxapp` to the `ARCHIVE` folder on the SD card.
2. On the device, open **Archive Manager**, select `GrainBrick.muxapp` and install.
3. Start **GrainBrick** from **Applications**.

Samples, projects and recordings are stored in `MUOS/application/GrainBrick/grainbrick/` (`samples/`, `projects/`, `recordings/`). Reinstalling the package doesn't touch them. The log is `gb_launch.log` in the same folder.

## What changed compared to the KNULLI port

- **Launcher:** `mux_launch.sh` replaces the KNULLI ports script. It uses muOS paths and sets up the display and controls the way other muOS applications do. The GrainBrick app folder itself is unmodified. It starts the app with muOS's `keep_cursor` option, which skips the `libmucursor.so` preload. That library wraps `SDL_Init`/`SDL_InitSubSystem` and can't find the real functions when Python loads SDL, so the display and controller wouldn't start.
- **pygame:** KNULLI ships pygame as a system package; muOS doesn't. The package includes pygame 2.6.1 (CPython 3.12, aarch64, from PyPI) in `pylib/`, kept outside the app folder as GrainBrick's launcher requires.
- **SDL:** pygame's bundled SDL2, SDL2_image, SDL2_mixer and SDL2_ttf are relinked to the muOS system libraries with `patchelf --replace-needed`, because muOS draws through its own patched SDL2. Bundled libraries that nothing references after that are left out.

muOS provides Python 3.12, which GrainBrick's compiled modules require.

## Build

```sh
./build.sh
```

Needs `uv`, which provides Python and a pinned `patchelf`. The script verifies the inputs against `SOURCES.sha256` and GrainBrick's own `SHA256SUMS.txt`, then writes `dist/GrainBrick.muxapp` and its checksum. Before writing, it checks the archive against the limits muOS's Archive Manager enforces (no links or special files, safe paths, size, entry count and compression ratio). The output is reproducible: rebuilding from the same inputs gives the same checksum.

| Path | Contents |
|---|---|
| `upstream/` | Original GrainBrick release zip |
| `vendor-dl/` | pygame wheel from PyPI |
| `src/` | muOS launcher, name/help text, icon |
| `tools/pack.py` | Archive writer and muOS safety check |
| `work/` | Build output before packing (regenerated each build) |
| `dist/` | Finished `.muxapp` |

## Licences

GrainBrick's notices and licences are in `grainbrick/THIRD_PARTY_NOTICES.md` and `grainbrick/THIRD_PARTY_LICENSES/`. pygame is LGPL-2.1; its licence and metadata are in `pylib/pygame-2.6.1.dist-info/`. pygame stays a separate, replaceable library: swap the `pylib/` folder to use a different build.
