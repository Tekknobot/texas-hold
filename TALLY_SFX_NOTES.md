# Texas HOLD 'EM — Scoring sounds

The payout tally now synchronizes short, melodic tick sounds with **each visible numerical change**. It does not emit one sound per rendered frame (which would overwhelm the mix when a large score changes rapidly). Each phase has eight visible number steps; the final TABLE RUN points phase has twelve. Each step uses a short synthesized tick pitched progressively higher. Between phases, a soft landing chime plays; the finish of the tally has a brighter version.

This works with Classic's pot count and TABLE RUN's pot / hand / upgrade / streak / points stages. When a multiplier is 1.00x and the number does not actually change, that phase intentionally plays no counting ticks. Skip Count jumps to the end and plays only the landing sound.

## Tuning

In `scripts/main.gd`:
- `_count_duration()` controls the pacing of each phase.
- `_tally_step_count()` controls the count rhythm (eight increments per normal phase, twelve on the final TABLE RUN score).
- `TALLY_STEP_FRACTION` controls how far into each stage the counting stops before the chime (0.86 = final 14% of the stage is a hold).
- `_tally_tick()` controls the climbing note scale and tick volumes (`-17 dB`, final phase `-15 dB`).
- `_play_tally_sound()` uses a separate six-voice pool, protecting card/chip/win SFX from being stolen.
- `_finish_count()` controls the end-of-tally accent.

Two new, original, self-contained WAVs are included: `audio/tally_tick.wav` and `audio/tally_land.wav`. The game's mechanics, winning-five display and visual styling are unchanged.
