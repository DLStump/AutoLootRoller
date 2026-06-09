# Auto Loot Roller

Auto Loot Roller is a World of Warcraft 3.3.5a addon that can automatically choose Pass, Need, or Greed for group loot rolls by item quality.

## Features

- Configurable from `Esc > Interface > AddOns > Auto Loot Roller`.
- Per-quality behavior for green, blue, purple, and orange items.
- Need List for item links that should always roll Need before quality rules.
- Supports `Default Prompt`, `Pass`, `Need`, and `Greed`.
- Hides Blizzard roll prompts only when the addon auto-rolls.
- Automatically accepts bind-on-pickup roll confirmations only for rolls initiated by the addon.
- Saves settings between game sessions.

## Defaults

- Enabled
- Greens: Default Prompt
- Blues: Default Prompt
- Purples: Default Prompt
- Oranges: Default Prompt

## Roll Behavior

Items in the Need List are matched by item ID from pasted client item links. A matched item rolls Need before the quality dropdown rules are checked.

`Default Prompt` leaves Blizzard's normal loot roll prompt unchanged.

If `Need` is selected but unavailable, the addon rolls Greed if possible, otherwise Pass.

If `Greed` is selected but unavailable, the addon rolls Pass.

## Install

1. Copy this repository folder to `World of Warcraft\<_your_wow_3.3.5_flavor_>\Interface\AddOns\AutoLootRoller`.
2. Restart the client or type `/reload ui` after logging in.
3. Configure it from `Esc > Interface > AddOns > Auto Loot Roller`.

## Need List

Paste client item links into the Need List box, one item per line. Shift-clicking an item while the Need List box has focus should insert the client item link.

The list is saved with your addon settings.

## Slash Commands

- `/alr` opens the options panel.
- `/alr on` enables automatic rolling.
- `/alr off` disables automatic rolling.
