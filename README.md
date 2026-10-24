# Family Dinner

A deck-building card game of passive aggression. Survive four courses against Aunt Linda, Cousin Brad, Uncle Gary and Grandma by trading insults across the dinner table.

**Play in your browser (phone or desktop):** https://alen127.github.io/family-dinner/

## How to play

- You get 3 **Spite** per turn and draw 5 cards.
- **Insults** (red) wear down their composure. **Deflects** (blue) soak up theirs. **Schemes** (green) make them Flustered (they take 50% more) or you Smug (your insults hit harder).
- The bubble under the relative shows what they'll do next.
- Tap a card to read it, tap it again to say it. On a keyboard, 1-9 plays a card and Space ends your turn.

## Code

Plain HTML, CSS and JavaScript with no build step.

- `game.js`: the rules, all cards and all relatives. Card and move effects are plain data, so adding an insult or a relative is one entry.
- `ui.js`: rendering, input and animations.
- `style.css`: layout for phones (portrait and landscape) and desktop.
- `test/bot.mjs`: plays 2,000 runs with a simple bot and checks for broken game states. Run it with `node test/bot.mjs`.

To run it locally, serve the folder with any static server, for example `python3 -m http.server`, and open http://localhost:8000.

The first version was made in Godot; it's in the git history.
