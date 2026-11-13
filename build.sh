#!/usr/bin/env bash
# Build dist/GrainBrick.muxapp: GrainBrick (KNULLI port) repackaged as a muOS application.
#
# Inputs (checksums in SOURCES.sha256):
#   upstream/grainbrick.beta.1.0.1.zip   original GrainBrick release, used unmodified
#   vendor-dl/pygame-2.6.1-cp312-...whl  pygame for CPython 3.12 / aarch64 from PyPI
#
# pygame's bundled SDL2, SDL2_image, SDL2_mixer and SDL2_ttf are swapped for the muOS
# system copies (patchelf --replace-needed), because muOS displays through its own
# patched SDL2 build. Bundled libraries nothing references afterwards are dropped.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
# -I: don't import modules from the script or working directory while reading untrusted archives
PY=(uv run --no-project --quiet python -I)
# Pinned so the relinked modules, and with them the .muxapp, stay byte-for-byte reproducible
PATCHELF=(uvx --quiet --from patchelf==0.15.2.0 patchelf)

UPSTREAM_ZIP="$HERE/upstream/grainbrick.beta.1.0.1.zip"
WHEEL="$HERE/vendor-dl/pygame-2.6.1-cp312-cp312-manylinux_2_17_aarch64.manylinux2014_aarch64.whl"
UPSTREAM_DIR="grainbrick beta 1.0.1"
WORK="$HERE/work"
PKG="$WORK/GrainBrick"
OUT="$HERE/dist/GrainBrick.muxapp"

echo "== verify inputs"
(cd "$HERE" && sha256sum -c --quiet SOURCES.sha256)

echo "== extract"
rm -rf "$WORK"
mkdir -p "$WORK/upstream" "$PKG/pylib" "$HERE/dist"
"${PY[@]}" -c 'import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' "$UPSTREAM_ZIP" "$WORK/upstream"
"${PY[@]}" -c 'import sys, zipfile; zipfile.ZipFile(sys.argv[1]).extractall(sys.argv[2])' "$WHEEL" "$PKG/pylib"
(cd "$WORK/upstream/$UPSTREAM_DIR" && sha256sum -c --quiet SHA256SUMS.txt)
mv "$WORK/upstream/$UPSTREAM_DIR" "$PKG/grainbrick"

echo "== relink pygame against muOS system SDL2"
LIBS="$PKG/pylib/pygame.libs"
needed() { "${PATCHELF[@]}" --print-needed "$1"; }
declare -A SYSTEM_SONAME=(
	[libSDL2-2]="libSDL2-2.0.so.0"
	[libSDL2_image-2]="libSDL2_image-2.0.so.0"
	[libSDL2_mixer-2]="libSDL2_mixer-2.0.so.0"
	[libSDL2_ttf-2]="libSDL2_ttf-2.0.so.0"
)
mapfile -t MODULES < <(find "$PKG/pylib/pygame" -name '*.so')
for PREFIX in "${!SYSTEM_SONAME[@]}"; do
	BUNDLED=$(cd "$LIBS" && ls "$PREFIX"-*.so* 2>/dev/null | grep -E "^${PREFIX}-[0-9a-f]{8}\." | head -n 1)
	[ -n "$BUNDLED" ] || { echo "missing bundled $PREFIX"; exit 1; }
	for MOD in "${MODULES[@]}"; do
		if needed "$MOD" | grep -qxF "$BUNDLED"; then
			"${PATCHELF[@]}" --replace-needed "$BUNDLED" "${SYSTEM_SONAME[$PREFIX]}" "$MOD"
		fi
	done
	rm -f "$LIBS/$BUNDLED"
	echo "   $BUNDLED -> ${SYSTEM_SONAME[$PREFIX]}"
done

echo "== drop bundled libraries nothing references any more"
declare -A KEEP=()
QUEUE=("${MODULES[@]}")
while [ "${#QUEUE[@]}" -gt 0 ]; do
	F="${QUEUE[0]}"
	QUEUE=("${QUEUE[@]:1}")
	while read -r DEP; do
		if [ -f "$LIBS/$DEP" ] && [ -z "${KEEP[$DEP]:-}" ]; then
			KEEP[$DEP]=1
			QUEUE+=("$LIBS/$DEP")
		fi
	done < <(needed "$F")
done
for L in "$LIBS"/*; do
	N=$(basename "$L")
	[ -n "${KEEP[$N]:-}" ] || { rm -f "$L"; echo "   removed $N"; }
done
echo "   kept: ${!KEEP[*]}"

echo "== check nothing still points at a removed bundled library"
for F in "${MODULES[@]}" "$LIBS"/*; do
	while read -r DEP; do
		case "$DEP" in
		*-[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f].*)
			[ -f "$LIBS/$DEP" ] || { echo "dangling $DEP in $F"; exit 1; } ;;
		esac
	done < <(needed "$F")
done

echo "== muOS launcher, name and icon"
install -m 755 "$HERE/src/mux_launch.sh" "$PKG/mux_launch.sh"
install -m 644 "$HERE/src/mux_lang.ini" "$PKG/mux_lang.ini"
install -D -m 644 "$HERE/src/glyph/grainbrick.svg" "$PKG/glyph/grainbrick.svg"
install -m 644 "$HERE/README.md" "$PKG/README_muOS.md"

echo "== pack"
"${PY[@]}" "$HERE/tools/pack.py" "$WORK" GrainBrick "$OUT"
(cd "$HERE/dist" && sha256sum GrainBrick.muxapp > GrainBrick.muxapp.sha256)
echo "== done: $OUT"
