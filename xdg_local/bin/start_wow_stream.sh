#!/bin/bash
set -euo pipefail

# You must run the one-time command first to give the OBS binary the "permission" to be prioritized.
# command: sudo setcap 'cap_sys_nice=eip' /usr/bin/obs

for cmd in obs faugus-launcher sudo renice chrt taskset pgrep; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

# 1. Launch OBS
obs &
OBS_PID=$!
sleep 3

# 2. Prioritize OBS on CCD 1 (Cores 16-31)
# We handle the priority and the core pinning at once
if kill -0 "$OBS_PID" >/dev/null 2>&1; then
  sudo renice -n -10 -p "$OBS_PID"
  sudo chrt -o -p 0 "$OBS_PID"
  sudo taskset -a -cp 16-31 "$OBS_PID"
  echo "OBS optimized on CCD 1."
else
  echo "OBS exited before it could be optimized." >&2
  exit 1
fi

# 3. Launch Faugus GUI
# You can just click 'Play' in the window that pops up
faugus-launcher &

echo "Waiting for World of Warcraft to launch..."

# 4. Watch for the game process
max_attempts=150
attempt=1
while [ "$attempt" -le "$max_attempts" ]; do
  # Pick the newest matching process to avoid stale PIDs from earlier sessions.
  WOW_PID="$(pgrep -n -f 'WoWClassic\.exe' || true)"

  if [ -n "$WOW_PID" ]; then
    sleep 3
    echo "WoW found (PID: $WOW_PID). Pinning to CCD 0 (Cores 0-15)..."
    # We use -a to ensure all sub-threads of the game are also moved
    sudo taskset -a -cp 0-15 "$WOW_PID"
    break
  fi

  attempt=$((attempt + 1))
  sleep 2
done

if [ "$attempt" -gt "$max_attempts" ]; then
  echo "Timed out waiting for World of Warcraft to launch." >&2
  exit 1
fi

echo "Setup complete! Have a great stream."
