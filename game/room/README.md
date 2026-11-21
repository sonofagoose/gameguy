# The room's checkpoints

`checkpoints.txt` is read by `build.sh` and put first in the room's walks (`build/room/promises.txt`),
one a line: an id, the scene, what is new and what to try, and the one question asked on coming back.
A checkpoint is a moment within a stage for Morgan to play what is new and say how it feels; the
room logs his answer as it logs a promise's (`room: ...` lines in the session log). When a
checkpoint has been answered and its answer read, it comes out of the file.
