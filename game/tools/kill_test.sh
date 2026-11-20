#!/usr/bin/env bash
# The card keeps a take through anything (spec/promises/workshop.md, card.takes): kill the game
# hard at a random moment while it plays the first evening and writes its take, start it again,
# and check that it goes on from where it was. Each time:
#   - it goes on from the take that was cut off, opening the take's last dawn if it had one;
#   - the world it goes on with is the same as the take played through from its first step;
#   - it lost under five seconds of the evening (300 steps) before the kill.
# Run with no screen. The number of kills is the first argument (default 100).
set -uo pipefail
cd "$(dirname "$0")/.."
N=${1:-100}
GAME="$(pwd)/build/gameguy-x86_64"
DIR="$(pwd)/build/killtest"
rm -rf "$DIR"; mkdir -p "$DIR"
export SDL_VIDEODRIVER=offscreen SDL_AUDIODRIVER=dummy
same=0; from_dawn=0; worst=0; failed=0
for i in $(seq 1 "$N"); do
  rm -rf "$DIR/keep" "$DIR"/*.txt "$DIR"/*.out
  delay=$(python3 -I -c "import random; random.seed($i); print(f'{random.uniform(0.3, 7.0):.2f}')")
  ( cd "$DIR" && exec "$GAME" --scene evening --headless --keep --log run.txt > run.out 2>&1 ) &
  pid=$!
  sleep "$delay"
  kill -9 "$pid" 2> /dev/null
  wait "$pid" 2> /dev/null
  last=$(grep -o "^at step [0-9]*" "$DIR/run.txt" | tail -1 | grep -o "[0-9]*$")
  last=${last:-0}
  ( cd "$DIR" && "$GAME" --scene evening --headless --keep --resume-only --log resume.txt > resume.out 2>&1 )
  line=$(grep "resumed where you were" "$DIR/resume.txt" | tail -1)
  if [ -z "$line" ]; then
    # killed before it had written anything: nothing to lose, nothing to go on from
    if [ "$last" -le 60 ]; then same=$((same + 1)); continue; fi
    echo "kill $i after ${delay}s: it did not go on (it had reached step $last)"; failed=$((failed + 1)); continue
  fi
  step=$(echo "$line" | grep -o "cut off at step [0-9]*" | grep -o "[0-9]*$")
  print=$(echo "$line" | grep -o "world [0-9a-f]*" | cut -d' ' -f2)
  dawn=$(echo "$line" | grep -o "from its dawn [0-9]*" | grep -o "[0-9]*$")
  ( cd "$DIR" && "$GAME" --scene evening --headless --check-take keep/takes/evening-00001.take --log check.txt > check.out 2>&1 )
  check=$(grep -o "the take ends: step [0-9]*, world [0-9a-f]*" "$DIR/check.txt" | tail -1)
  check_step=$(echo "$check" | grep -o "step [0-9]*" | grep -o "[0-9]*$")
  check_print=$(echo "$check" | grep -o "world [0-9a-f]*" | cut -d' ' -f2)
  lost=$((last - step)); [ "$lost" -lt 0 ] && lost=0
  [ "$lost" -gt "$worst" ] && worst=$lost
  [ "${dawn:-0}" -gt 0 ] && from_dawn=$((from_dawn + 1))
  if [ "$step" = "$check_step" ] && [ "$print" = "$check_print" ] && [ "$lost" -lt 300 ]; then
    same=$((same + 1))
  else
    echo "kill $i after ${delay}s: went on at step $step (world $print), the take played through ends at step $check_step (world $check_print); it had reached step $last"
    failed=$((failed + 1))
  fi
done
echo "kills $N, went on the same $same, from a dawn's save $from_dawn, failed $failed, most steps lost $worst"
echo "fact take.kills_survived $same" >&2
echo "fact take.kills_failed $failed" >&2
echo "fact take.kill_most_lost_steps $worst" >&2
