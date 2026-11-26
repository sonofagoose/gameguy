# The room's walks

> **Status, 2026-11-26.** The room is a tool and stays one. Its walks and questions were written for
> the first evening as it was built to the older specification, and each names a retired promise.
> What the game is: `design/the-game.md`.

`walks.txt` is the one list of what the room asks a person to try. Each walk:

- starts from this build's own first evening, kept at a moment of rest. The scripted player
  (`src/bot/walker.zig`) marks each such moment `start:NAME`. The build plays the evening with
  `--walk-starts build/walks` and keeps the world there as `NAME.save`, so a walk is always the game
  as it is today, never a second, hand-made copy of it. The build refuses a walk whose start the
  evening never reached;
- says in plain words what to do, using only words for what is on the screen;
- asks up to four yes-or-no questions, each for a promise in `spec/promises/`. X answers "it didn't
  happen".

A walk leaves the person's own memory alone: no going on from a cut-off take, and no dawns or
ground light kept. Its take is written into `results/walks/` under the walk's name. The room's
first screen names the build it came with (`build.txt`), and so does its log.

The listening clips are cut from the same evening's sound on every build (`tools/clips.py`).
