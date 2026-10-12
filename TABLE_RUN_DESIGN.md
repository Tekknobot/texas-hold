# TABLE RUN - design and tuning guide

All new features are OPTIONAL: choose TABLE RUN at the title screen. Classic mode still uses the original poker chips, cards, betting rules and CPU decision-making.

## Core loop

1. Play a real heads-up Texas Hold'em hand against the CPU.
2. A win scores **points** equal to the pot times a base hand multiplier, upgraded multipliers, and win-streak multiplier. These are points and do NOT represent additional chips or prizes.
3. After hands 2, 4, 6 and 8, choose one of three different scoring perks. Perks stack for the rest of the run. No deck manipulation, extra hole cards, changing card values, or hidden CPU handicap.
4. Hit checkpoint scores by hands 3, 6 and 9. Keep the same bankroll. A bankrupt CPU buys back in at 1600 between hands; player bankruptcy ends the run. Best score is saved in `user://texas_hold_run.cfg`.

## How to tune

In `scripts/main.gd`:

- `RUN_LENGTH` is currently 9. The stage division and scoring checkpoints currently assume a nine-hand run, three hands per stage.
- `RUN_TARGETS` sets score goals for stages (450, 1900, 5200). Raising them makes the run harder.
- `RUN_PERKS` lists names and descriptions, and `_run_multiplier()` lists the exact conditions and values.
- `_run_record_hand()` defines the base scores: fold victory 0.65x, high card 1.0x, pair 1.35x, two pair 1.8x, trips 2.4x, straight 3.2x, flush 4.0x, full house 5.5x, quads 9.0x and straight flush 18.0x.
- `_run_record_hand()` gives streaks +0.2x per consecutive win after the first, capped at 2.0x before perk multipliers.
- To protect player expectations, modify scoring only, not the 52-card draw, the `poker_rules.gd` evaluator, CPU equity calculation, or original betting flow.

## Future extensions

- Score-count animation accompanied by tiered sound stingers and floating chip numbers.
- In-run high-score milestones that change the table's brass detail and particles.
- Stages with thematic sets of scoring upgrades or special challenges, without touching the rules.
- A post-run stats screen showing the number of folds, showdowns, best made hand, biggest pot, biggest multiplier, and best streak.
- A daily seeded challenge, as an alternative to fully random runs, after deterministic CPU/card seeding is implemented.

All gameplay uses fictional in-game chips only.
