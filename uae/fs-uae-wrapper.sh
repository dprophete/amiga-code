#!/bin/sh
#-------------------------------------------------------------------------------
# fs-uae-wrapper.sh
#
# Works around an FS-UAE shutdown deadlock.  When an Amiga program calls the UAE
# uaelib ExitEmu trap (see uae/quit.s), uae_quit() tears down the emulation core
# but never signals the fsemu host loop, which stays parked forever in
# g_async_queue_pop waiting for a frame.  The result is a live process behind a
# frozen window.
#
# This wrapper launches the real emulator, watches its log for the line FS-UAE
# prints once the core is gone, waits for the log to fall quiet (so the
# filesystem cache and file streams finish flushing), then reaps the host.
#
# Overridable: FSUAE_REAL_BIN, FSUAE_LOG
#-------------------------------------------------------------------------------
set -u

MARKER="real_main returned"     # emulation core has shut down
POLL=0.05                       # how often to look
QUIET_TICKS=2                   # consecutive quiet polls before we reap
MAX_TICKS=100                   # ...but never wait longer than this

REAL="${FSUAE_REAL_BIN:-}"
if [ -z "$REAL" ]; then
    for d in "$HOME"/.vscode/extensions/prb28.amiga-assembly-*/dist/bin/fs-uae; do
        [ -x "$d/fs-uae-darwin_x64" ] && REAL="$d/fs-uae-darwin_x64"
    done
fi
LOG="${FSUAE_LOG:-$HOME/Documents/FS-UAE/Cache/Logs/fs-uae.log.txt}"

if [ -z "$REAL" ] || [ ! -x "$REAL" ]; then
    echo "fs-uae-wrapper: no fs-uae binary found (set FSUAE_REAL_BIN)" >&2
    exit 127
fi

START=$(date +%s)
REAPED=0
"$REAL" "$@" &
PID=$!

trap 'kill -TERM "$PID" 2>/dev/null' TERM INT HUP

fresh=0
while kill -0 "$PID" 2>/dev/null; do
    sleep "$POLL"
    [ -f "$LOG" ] || continue
    if [ "$fresh" -eq 0 ]; then
        # only trust a log this run has already rewritten
        MT=$(stat -f %m "$LOG" 2>/dev/null) || continue
        [ "$MT" -gt "$START" ] || continue
        fresh=1
    fi
    grep -q "$MARKER" "$LOG" 2>/dev/null || continue

    # Core is gone.  Let it finish writing before we pull the plug: poll until
    # the log has stopped growing, so flushes complete even if they run long.
    prev=-1
    quiet=0
    ticks=0
    while kill -0 "$PID" 2>/dev/null && [ "$ticks" -lt "$MAX_TICKS" ]; do
        size=$(stat -f %z "$LOG" 2>/dev/null || echo -1)
        if [ "$size" = "$prev" ]; then
            quiet=$((quiet + 1))
            [ "$quiet" -ge "$QUIET_TICKS" ] && break
        else
            quiet=0
            prev=$size
        fi
        ticks=$((ticks + 1))
        sleep "$POLL"
    done

    if kill -0 "$PID" 2>/dev/null; then
        # SIGKILL rather than SIGTERM, deliberately.  By now the core has
        # returned and the filesystem cache and file streams are flushed, so a
        # graceful signal buys nothing - and SDL turns SIGTERM into an SDL_QUIT
        # event for the very main loop that is deadlocked, so it is swallowed
        # and we would just wait out the grace period before killing anyway.
        echo "fs-uae-wrapper: emulation core exited, host wedged - terminating" >&2
        kill -KILL "$PID" 2>/dev/null
        REAPED=1
    fi
    break
done

# A reap is a success, not a crash: exit cleanly, and skip the wait so the
# shell does not print a "Killed: 9" job message for a kill we intended.
[ "$REAPED" -eq 1 ] && exit 0

wait "$PID"
exit $?
