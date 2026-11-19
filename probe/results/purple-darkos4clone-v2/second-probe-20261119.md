# Second probe: the purple, 2026-11-19

What the handheld has that nobody had tried. Run over ssh from the laptop while the menu
(EmulationStation) was up, with only the data cable in. Each part says what was done, the raw
readings, and what is still unknown. Everything changed on the unit was put back.

## The recording path

- `arecord -l` lists one capture device: card 0, device 0, `ff070000.i2s-rk817-hifi`.
- The mixer has `Capture MIC Path` (`MIC OFF`, `Main Mic`; it was `MIC OFF`) and `Record` (255 of
  255). It was set to `Main Mic` for each recording and back to `MIC OFF` afterwards.
- `arecord -D hw:0,0 -f S16_LE -c 2` worked at 48,000 Hz and at 44,100 Hz.

| recording | left channel | right channel |
|---|---|---|
| 2 s, nothing playing, 48,000 Hz | all zeros (peak -90 dBFS) | noise at -52.6 dBFS, peaks -34.1 dBFS, offset -551 |
| 3 s, a 1,000 Hz tone played through the menu's sound path, 44,100 Hz | all zeros | noise at -53.8 dBFS; 1,000 Hz at -74.5 dBFS |
| the same with the recording at 48,000 Hz (the menu plays at 44,100) | all zeros | noise at -54.1 dBFS; 1,000 Hz at -102 dBFS, the same as with nothing playing |

- **Reading.** The right channel is a live input with nothing on it. A microphone a few
  centimetres from the speaker would have recorded the tone near full scale; it came in 20 dB
  under the noise, which is leakage inside the board. So: **no microphone on the board.**
- **Still unknown:** whether the headphone jack carries a headset's microphone to this input. The
  device tree names a `Mic Jack` routed to `MIC_IN`. It needs a phone headset plugged in.
- Whether the tone was audible was not checked by anyone.

## The rumble line

- The gamepad (`GO-Super Gamepad`, `/dev/input/event2`) advertises force feedback: rumble, periodic
  effects and gain. The device tree's `rumble-gpio` is GPIO 102.
- A rumble effect uploaded and played with the gain left alone: the pin stayed low.
- With the gain set to full first (`EV_FF`, `FF_GAIN`, 0xFFFF): the pin read high in every one of
  about 2,400 samples through each 1.4 s effect (strong only, weak only, both), and low afterwards.
- **So the line can be driven from a program.** The `input` group has access; `ark` is in it.
- **Still unknown:** whether a motor is fitted. The battery gauge is too slow to show one (below).
  It needs a hand on the unit.

## The two lights

- `/sys/class/leds/led-blue` (GPIO 0, on) and `led-red` (GPIO 17, off), both with trigger `none`.
- Writing 0 or 1 to either `brightness` changed nothing: the values and the pins read the same
  after each of six writes. The firmware's own setup log says `led=unsupported`.
- **So the lights can't be used as they are.**

## The backlight

- `/sys/class/backlight/backlight/brightness`, 0 to 255, was 200. It is PWM at 40 kHz
  (`pwm-0`, period 25,000 ns).
- Battery current with the menu idle, 14 s at each level, the mean of the last 8 readings:

| level | current |
|---|---|
| 255 | 388 mA |
| 200 (as found) | 350 mA |
| 120 | 275 mA |
| 60 | 226 mA |
| 20 | 195 mA |
| 1 | 180 mA |

- **The backlight is more than half of what the idle handheld draws:** 208 mA of 388 at full.
  From the level it was found at, 120 saves 21% and 60 saves 35%.
- Writing the level needs root, which a Ports launcher has.
- **Still unknown:** how it looks when the level follows the music, which needs eyes.

## The clock

- The clock chip (`rk808-rtc`) read 2017-08-06 19:23:47 UTC at this start-up. At a start-up on
  about 2026-11-12 it read 2017-08-05 17:10:40 (`probe-9b4d0e-20260413-165106.txt`). It had gained
  26 hours in a week.
- The system clock read 1794965659 when the true time was 1795105227: 38.8 hours behind. systemd
  had put it back to where the last session ended.
- **So across a power-off the handheld does not know how long it was off.** The clock chip ticks
  while the unit runs (it gained 6 min 51 s in 6 min 56 s of uptime).
- The chip accepts a new time: it was set to the true time (`RTC_SET_TIME` on `/dev/rtc0`), and the
  pair was written to `/roms/ports/gameguy-clock-check.txt`. The next start-up will show whether a
  set clock keeps counting with the power off.

## What the kernel can host over USB

Built into the 4.4.189 kernel (`modules.builtin`): `snd-usb-audio`, `snd-usbmidi-lib`,
`snd-rawmidi`, `snd-seq`, `snd-seq-midi`, `usbhid`, `hid-generic`, `joydev`, `uinput`, `cdc-acm`.
There is no `/proc/config.gz`; 583 loadable modules are on the unit, mostly network adapters.

- **So a unit acting as USB host should take a USB microphone or sound interface, a MIDI keyboard,
  and more gamepads.** Nothing was plugged in. Only the black can host so far.

## Other readings

- GPU: `Mali-G31 1 cores r0p0 0x7093`. Rockchip's sheet calls the RK3326's GPU a Mali-G31 MP2; the
  driver counts one core.
- The battery gauge's current reading moves in steps a few seconds apart (387 mA to 524 mA in one
  step with nothing else changing), so it can't time anything shorter than about ten seconds.
- Suspend states offered: `freeze mem disk`. Not tried.
- Tools on the unit: `python3`, `gcc`, `arecord`, `aplay`, `amixer`, `evtest`, `speaker-test`. No
  `hwclock`, `alsactl`, `sox` or `fftest`.
- The gamepad driver: `odroidgo3-joypad`, poll interval 10 ms; sticks scaled by 2 from an ADC range
  of ±1800, with fuzz 32, flat 32 and deadzone 64.

## How many overtones one core renders

`game/bench/modes.zig`: a bank of two-pole resonators, one per overtone, rendered 128 frames at a
time, pinned to core 1, 3,000 buffers timed for each size. "Fit" is how many can be rendered in half
of a 2.67 ms buffer, by the time 99 buffers in 100 came in under.

| clock | how | each overtone-sample | fit in half a buffer |
|---|---|---|---|
| 1248 MHz (pinned at full speed) | one at a time | 12.1 ns | about 840 |
| 1248 MHz | four abreast (NEON) | 3.8 ns | 2,530 to 2,690 |
| 1008 MHz (the purple's clock under sustained load) | one at a time | 15.0 ns | about 680 |
| 1008 MHz | four abreast | 4.7 ns | 2,100 to 2,180 |
| the laptop, for comparison | four abreast | 1.0 ns | 8,400 to 9,200 |

- The slowest buffer was within 20% of the mean in every run: 4,096 overtones took 2.02 ms on
  average and 2.24 ms at worst.
- **The sound is the same to the last bit on the laptop and the purple,** for every size and both
  ways of rendering (for example `67b6cb7ad8b0890b` for 1,024 overtones four abreast on both).
  Multiplies and adds are kept separate, never fused.
- So one core holds about **2,100 sounding overtones** at the throttled clock with half of every
  buffer to spare.

## How many lines a frame holds

`game/src/main.zig --lines`, run through the launcher on the unit's own screen
(`game/results/purple-20261119/`). A made-up land of rolling ground and bell-headed stalks, a
camera circling it, every body's loudness changing every frame; a third of the lines go through the
phosphor. Each line is one instance of a four-cornered strip, placed by the vertex shader. 240
frames for each size. "Drawn" is from the first call to the end of `glFinish`.

| lines | black triangles | drawn | frame |
|---|---|---|---|
| 9,924 | 5,000 | 6.6 ms | 17.09 ms, none late |
| 19,960 | 5,000 | 8.8 ms | 17.09 ms, none late |
| 29,996 | 5,000 | 11.1 ms | 17.09 ms, none late |
| 39,932 | 5,000 | 13.2 ms | 17.09 ms, none late |
| 59,992 | 5,000 | 18.5 ms | 21.6 ms |
| 79,964 | 5,000 | 23.5 ms | 26.6 ms |
| 29,996 | none | 10.7 ms | 17.09 ms, none late |
| 29,996 | 20,000 | 13.3 ms | 17.09 ms, none late |

- About 4.4 ms for the three passes, and 0.22 ms for each thousand lines.
- Black triangles are cheap: 20,000 add 2.2 ms. They are drawn twice, to depth only.
- With six corners to a line instead of four, the same 29,996 lines took 15.5 ms and missed frames.
- So a view holds about **30,000 lines** inside an 11 ms budget.

## Needs a person

1. A phone headset with a microphone in the jack, then a recording: does the game get a voice?
2. A hand on the unit during a rumble effect: is there a motor?
3. Eyes on the screen while the backlight follows a swell: beautiful, or pumping?
4. Ears on the 1,000 Hz tone: how loud is the speaker, and does the jack switch it off?
5. The left stick pushed up, to settle the one log that shows the purple's turned.
6. A power-off and on, to see whether the set clock kept counting.
