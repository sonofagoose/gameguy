#!/usr/bin/env bash
# The card keeps a take through anything (spec/promises/workshop.md, card.takes): kill the game
# hard at a random moment while it plays the first evening and writes its take, start it again,
# and check that it goes on from where it was. Each time:
#   - it goes on from the take that was cut off, opening the take's last dawn if it had one;
#   - the world it goes on with is the same as the take played through from its first step;
#   - it lost under five seconds of the evening (300 steps) before the kill.
# Run with no screen. The number of kills is the first argument (default 100); they run JOBS at a
# time (default 4), each in a folder of its own, so the wait before each kill is shared.
set -uo pipefail
cd "$(dirname "$0")/.."
N=${1:-100}
JOBS=${JOBS:-4}
GAME="$(pwd)/build/gameguy-x86_64"
DIR="$(pwd)/build/killtest"
rm -rf "$DIR"; mkdir -p "$DIR"
export SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy

# One kill, in its own folder; its verdict goes to that folder's verdict file:
#   same|failed  from-dawn(0/1)  steps-lost  [what went wrong]
one_kill() {
  local i=$1
  local here="$DIR/k$i"
  mkdir -p "$here"
  local delay
  delay=$(python3 -I -c "import random; random.seed($i); print(f'{random.uniform(0.3, 7.0):.2f}')")
  ( cd "$here" && exec "$GAME" --scene evening --headless --keep --log run.txt > run.out 2>&1 ) &
  local pid=$!
  sleep "$delay"
  kill -9 "$pid" 2> /dev/null
  wait "$pid" 2> /dev/null
  local last
  last=$(grep -o "^at step [0-9]*" "$here/run.txt" 2> /dev/null | tail -1 | grep -o "[0-9]*$")
  last=${last:-0}
  ( cd "$here" && "$GAME" --scene evening --headless --keep --resume-only --log resume.txt > resume.out 2>&1 )
  local line
  line=$(grep "resumed where you were" "$here/resume.txt" | tail -1)
  if [ -z "$line" ]; then
    # killed before it had written anything: nothing to lose, nothing to go on from
    if [ "$last" -le 60 ]; then echo "same 0 0" > "$here/verdict"; return; fi
    echo "failed 0 0 kill $i after ${delay}s: it did not go on (it had reached step $last)" > "$here/verdict"
    return
  fi
  local step print dawn
  step=$(echo "$line" | grep -o "cut off at step [0-9]*" | grep -o "[0-9]*$")
  print=$(echo "$line" | grep -o "world [0-9a-f]*" | cut -d' ' -f2)
  dawn=$(echo "$line" | grep -o "from its dawn [0-9]*" | grep -o "[0-9]*$")
  ( cd "$here" && "$GAME" --scene evening --headless --check-take keep/takes/evening-00001.take --log check.txt > check.out 2>&1 )
  local check check_step check_print lost from
  check=$(grep -o "the take ends: step [0-9]*, world [0-9a-f]*" "$here/check.txt" | tail -1)
  check_step=$(echo "$check" | grep -o "step [0-9]*" | grep -o "[0-9]*$")
  check_print=$(echo "$check" | grep -o "world [0-9a-f]*" | cut -d' ' -f2)
  lost=$((last - step)); [ "$lost" -lt 0 ] && lost=0
  from=0; [ "${dawn:-0}" -gt 0 ] && from=1
  if [ "$step" = "$check_step" ] && [ "$print" = "$check_print" ] && [ "$lost" -lt 300 ]; then
    echo "same $from $lost" > "$here/verdict"
  else
    echo "failed $from $lost kill $i after ${delay}s: went on at step $step (world $print), the take played through ends at step $check_step (world $check_print); it had reached step $last" > "$here/verdict"
  fi
}

i=1
while [ "$i" -le "$N" ]; do
  one_kill "$i" &
  if [ "$(jobs -rp | wc -l)" -ge "$JOBS" ]; then wait -n; fi
  i=$((i + 1))
done
wait

same=0; from_dawn=0; worst=0; failed=0
for i in $(seq 1 "$N"); do
  read -r verdict from lost rest < "$DIR/k$i/verdict" || { verdict=failed; from=0; lost=0; rest="kill $i left no verdict"; }
  [ "$from" = 1 ] && from_dawn=$((from_dawn + 1))
  [ "$lost" -gt "$worst" ] && worst=$lost
  if [ "$verdict" = same ]; then same=$((same + 1)); else failed=$((failed + 1)); echo "$rest"; fi
done
echo "kills $N, went on the same $same, from a dawn's save $from_dawn, failed $failed, most steps lost $worst"
echo "fact take.kills_survived $same" >&2
echo "fact take.kills_failed $failed" >&2
echo "fact take.kill_most_lost_steps $worst" >&2
