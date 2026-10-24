# Family Dinner

A deck-building card game of passive aggression. Survive four courses against Aunt Linda, Cousin Brad, Uncle Gary and Grandma by trading insults across the dinner table.

**Play in your browser:** https://alen127.github.io/family-dinner/

## How to play

- You get 3 **Spite** per turn and draw 5 cards.
- **Insults** (red) break their composure. **Deflect** (blue) blocks theirs. **Schemes** (green) set up Flustered (target takes 50% more) and Smug (+damage on your insults).
- The box at the top right shows what the relative will do next.
- Click a card or press 1-9 to play it. Space ends your turn.

## Source

The Godot 4.7 project is in [`godot/`](godot/). Cards and relatives are plain data in `godot/data.gd`; game flow and drawing are in `godot/game.gd`.

Open it in the editor with `godot --path godot -e`. To rebuild the web version at the repo root (needs the Godot web export templates):

```bash
godot --headless --path godot --export-release Web ../index.html
```
