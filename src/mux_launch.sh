#!/bin/sh
# HELP: GrainBrick granular sampler
# ICON: grainbrick
# GRID: GrainBrick

# muOS launcher for GrainBrick (upstream targets KNULLI ports).
# Layout inside MUOS/application/GrainBrick:
#   grainbrick/  upstream app folder, unmodified (user samples/projects/recordings live here too)
#   pylib/       pygame 2.6.1, relinked against the muOS system SDL2 libraries

. /opt/muos/script/var/retro.sh

# keep_cursor: don't LD_PRELOAD muOS's libmucursor.so. It wraps SDL_Init/SDL_InitSubSystem
# and finds the real functions with RTLD_NEXT, which fails when SDL is loaded later by
# Python's dlopen (RTLD_LOCAL): every SDL subsystem then fails with an empty error.
SETUP_APP "python3" "keep_cursor"

APP_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$APP_DIR/grainbrick"
LOG="$APP/gb_launch.log"

cd "$APP" || exit 1
mkdir -p "$APP/samples" "$APP/projects" "$APP/recordings" || exit 1

# First run: seed demo content without overwriting user data (same as upstream launcher)
for WAV in "$APP"/demo-samples/*.wav; do
	[ -f "$WAV" ] || continue
	NAME=${WAV##*/}
	if [ ! -e "$APP/samples/$NAME" ] && [ ! -L "$APP/samples/$NAME" ]; then
		cp "$WAV" "$APP/samples/$NAME" || exit 1
	fi
done
if [ -f "$APP/demo-projects/AMBIENT.json" ] && [ ! -e "$APP/projects/AMBIENT.json" ] && [ ! -L "$APP/projects/AMBIENT.json" ]; then
	cp "$APP/demo-projects/AMBIENT.json" "$APP/projects/AMBIENT.json" || exit 1
fi

export GRAINBRICK_ROOT="$APP"
export GRAINBRICK_DISPLAY_FILTER=smooth
export PYTHONUNBUFFERED=1
export PYGAME_HIDE_SUPPORT_PROMPT=1
# pygame must stay outside the app folder (upstream LGPL check), so it lives in ../pylib
export PYTHONPATH="$APP_DIR/pylib${PYTHONPATH:+:$PYTHONPATH}"

printf '\n=== GrainBrick 1.0.1 (muOS package) %s ===\n' "$(date '+%F %T')" >>"$LOG"
/usr/bin/python3 -B "$APP/gb_launch.py" >>"$LOG" 2>&1
RESULT=$?
printf 'GrainBrick exit: %s\n' "$RESULT" >>"$LOG"
exit "$RESULT"
