# Showdown UI clearance fix

- Removed the centered `WINNING FIVE` banner from the table felt. Winner cards lift upward during the gold-highlight animation and previously overlapped that banner.
- The existing exact five-card identification, gold outlines and dimming of unused cards are unchanged.
- The winner label and five small card faces remain in the separate right-hand match panel, which cannot be overlapped by table card sprites.
- Shortened the payout / TABLE RUN count-up overlay to stop above the winning-five sidebar preview. The preview is now visible while the count-up plays, instead of being covered by the tally panel.
- Moved `SKIP COUNT` to the top-right of the tally panel to free the area directly above the winning-five preview.

The poker rules, upgrade logic, chips, sprites, fonts, sounds and particle effects are unchanged.
