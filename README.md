# Auto Loot Roller

Auto Loot Roller is a World of Warcraft 3.3.5a addon that can automatically choose Pass, Need, or Greed for group loot rolls by item quality.

## Features

- Configurable from `Esc > Interface > AddOns > Auto Loot Roller`.
- Per-quality behavior for green, blue, purple, and orange items.
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

`Default Prompt` leaves Blizzard's normal loot roll prompt unchanged.

If `Need` is selected but unavailable, the addon rolls Greed if possible, otherwise Pass.

If `Greed` is selected but unavailable, the addon rolls Pass.

## Install

1. Copy this repository folder to `World of Warcraft\Interface\AddOns\AutoLootRoller`.
2. Restart the client or type `/reload ui` after logging in.
3. Configure it from `Esc > Interface > AddOns > Auto Loot Roller`.

## Slash Commands

- `/alr` opens the options panel.
- `/alr on` enables automatic rolling.
- `/alr off` disables automatic rolling.
