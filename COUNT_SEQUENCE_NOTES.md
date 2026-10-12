# Texas HOLD 'EM - Card-safe UI and animated payout tally

## What changed

The table is now for cards, chips, and the winning-five reveal. Labels that could be obscured have been removed or relocated. Cards now arrive with short, local dealing motions rather than crossing UI labels from the far side of the felt. The pot has been moved to the right of the CPU cards; small-blind/bet labels are placed near the left seat plates; betting-street names remain visible in the sidebar. The old pop-up result panel at the lower left was removed because it could sit on top of the player's cards. All win/loss information now displays in the right-hand match panel.

## Animated tally after every hand

After each completed hand, the sidebar runs a paced, eased count-up with chip sounds and sparks. It blocks progression until the result is tallied or skipped. The specific sequence depends on the mode:

- **Classic:** count the pot, then display who collects the chips (or split pot).
- **Table Run, winning hand:** count pot -> multiply by the made hand (fold wins use 0.65x) -> multiply by activated upgrades -> multiply by streak -> count up the final points into the run total. Visual progress bars mark each step; the names of the scoring upgrades that triggered are shown in the upgrade step.
- **Table Run, lost or tied hand:** pot settles and the tally lands on 0 points.

Click **SKIP COUNT** or press **Enter/Space** once to complete the tally. Press **Enter/Space** again or click the Next Hand / Choose Upgrade / Check Stage button to advance. This prevents one keypress from inadvertently skipping the reveal and advancing the hand at once.

At the upgrade checkpoint, the three choice cards reveal in a short staggered animation with the existing gold particles and selection sound. Their hit targets activate after they settle.

## Where to adjust the timing

In `scripts/main.gd`, edit `_count_duration()` for individual scoring stages. Change the pacing of the perk-card entrance in `scripts/screen_overlay.gd` under `_draw_draft()`.

This does **not** change Hold'em odds, poker rules, card sprites, stack accounting, CPU strategy, scores, or the selected upgrade pool. No additional external files are required.
