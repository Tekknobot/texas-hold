# Texas HOLD 'EM

A traditional, mouse-first, single-player Texas Hold'em game for Godot 4.6, with an optional roguelike-inspired TABLE RUN scoring mode. Built using the supplied card PNGs and the original Carrom-collection presentation: green felt, walnut/brass trim, cream typography, crisp panels, card flips, chips, sound, and celebratory particles.

## Choose your table

- **CLASSIC:** The original heads-up No Limit Texas Hold'em game against the CPU, with ordinary blinds, stacks, betting, all-ins, showdowns and exact winning-five highlights. Keep playing until one side runs out of chips.
- **TABLE RUN:** An optional nine-hand, three-stage score chase. Real Hold'em betting and hand evaluation are unchanged. Pots won score points; strong showdown hands earn bigger base multipliers, and streaks reward consistency. You need at least 450 points by hand 3, 1900 by hand 6, and 5200 by hand 9 to clear the run. Your chip stack persists through the run; if the house goes broke, it buys in again at $1600. If you go broke or miss a checkpoint, the run ends. There is no real money.

## Scoring

Winning a pot by fold: `pot x 0.65` base. Winning at showdown: `pot x hand factor` (high card 1.0x, pair 1.35x, two pair 1.8x, trips 2.4x, straight 3.2x, flush 4.0x, full house 5.5x, quads 9.0x, straight flush 18.0x). Consecutive wins add a stacking streak multiplier up to 2.0x. Upgrades multiply that score further. Ties and lost hands award zero points. Scoring uses virtual, in-game chips only and does not change the poker rules or CPU's decisions.

After hands 2, 4, 6 and 8, choose **one of three** randomly offered upgrades. The perk pool rewards pairs, straights, flushes, big pots, showdown wins, Aces, private-card use, bluff wins, being an underdog, and consecutive wins. Once selected, perks stay for the entire run and stack multiplicatively. Upgrades affect points only, never card distribution or hand strength.

## Controls

Click the table buttons to choose FOLD / CHECK / CALL / RAISE. Select MIN, HALF POT, POT, or MAX; adjust the proposed raise with `- / +`. F to fold; C, Space, or Enter to call/check; R to raise; arrow keys to adjust your raise; H to open the rules; Space to advance after a hand. When an upgrade is offered, click its card or press 1, 2, or 3.

Blinds start at $25 / $50 and rise every six hands. Starting stacks are $1600. Poker is strictly single-player and offline, suitable for a browser export; there is no gambling with real money.

## Animated hand settlement

After every hand, the match sidebar counts out the pot. TABLE RUN victories additionally count up the hand multiplier, active scoring perks, winning streak and points banked in sequence. Enter/Space or SKIP COUNT completes the reveal without advancing to the next hand; use Next Hand / Choose Upgrade to continue. Upgrade choices animate in with a staggered reveal. See `COUNT_SEQUENCE_NOTES.md` for timing adjustments.

Table labels and result banners have been moved out of the card and animation paths, keeping the table area unobstructed.

## Winning five-card reveal

At showdown, the exact five cards that form the winning poker hand rise with a gold outline; unused cards dim. The sidebar repeats those five face-up. In a split pot, use SHOW HOUSE / SHOW YOU to inspect either side's best combination. No winning-five claim is shown on a fold.

## Files

Open `project.godot` in Godot 4.6 and press F5. The main logic is in `scripts/main.gd`; visual draft and run-complete overlays are in `scripts/screen_overlay.gd`. All original card art, backs, shaders and audio are preserved.
