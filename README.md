# Forever Session

A World of Warcraft Forever addon for tracking XP, gold, honor, and reputation
per hour. Each tracker has a separate section in one movable panel.

Targets the Forever client with interface version `16001`. Retail and other
Classic clients are not supported.

## Installation

1. Download or clone this repository into a folder named `ForeverSession`.
2. Place the folder in your WoW client's `Interface/AddOns` directory.
3. Check that `Interface/AddOns/ForeverSession/ForeverSession.toc` exists directly
   inside the addon folder, without an extra nested repository folder.
4. Restart WoW and enable **Forever Session** in the AddOns list.

The addon has no runtime dependencies. Python is needed only to run the tests.

## Controls

| Action | Control |
| --- | --- |
| Open options | `/fs`, `/foreversession`, or right-click the panel |
| Move the panel | Left-drag while unlocked |
| Lock position | `/fs lock` |
| Unlock position | `/fs unlock` |
| Restore position | `/fs center` |
| Reset tracking | Hover over the panel, then click **Reset** |
| Detailed tooltip | Hold Alt while hovering |

The Reset menu can restart all trackers or one tracker at a time. Individual
resets preserve the shared session timer. Reset all restarts that timer too.
Position and appearance settings are preserved by tracking resets.

## Trackers

Enable each section independently in the addon options. XP is enabled by default.
Hidden trackers continue recording data. Rates include idle time.

### XP

Tracks XP from kills, quests, rested bonuses, exploration, and other sources.
The bar shows progress through the current level. The next-level estimate uses
remaining XP divided by the average XP rate since login or the last XP reset.
Kills to level uses the most recent creature XP award. It remains blank until a
creature awards XP.

The tooltip shows quest-log reward XP and completed quest XP when those values
are available from the client. Multi-level jumps that cannot be reconstructed
from the API are excluded from the XP total.

### Gold

Tracks net changes in carried money, with native gold, silver, and copper icons.
Purchases, repairs, trades, and mail affect the result. Spending can produce a
negative rate. Gold has no progress bar or milestone estimate.

**Include loot value** adds the vendor value of session loot still in your bags.
Items without a sell price add nothing. Selling an item replaces its estimated
value with actual money. Items removed from carried bags no longer contribute
to the unsold-loot total.

### Honor

Tracks Forever PvP rank points, using faction `2800`, with progress toward the
next rank. A weekly cap suppresses the time estimate. The standard honor-level
API is used as a fallback when available. Missing data displays **Unavailable**.

### Reputation

Tracks the faction selected for watching in the game's Reputation panel. The
bar shows progress between the current and next standing thresholds. Reputation
losses reduce the total and rate. Estimates require a positive rate.

Visible factions are baselined at login or reset. Collapsed or newly discovered
factions start when first observed. Each faction retains its own total and timer
when the watched faction changes. Friendship and paragon reward tracks are not
supported.

## Display options

- Independent tracker visibility, progress bars, milestone estimates, and totals.
- One shared session timer below the tracker sections.
- Panel scale, minimum width, number size, and text outlines.
- Progress-bar height from 1 to 16 UI units; default 2.
- Separate XP, honor, and reputation bar colors. Honor defaults to red and
  reputation to dark green. Each bar uses a horizontal gradient.
- Background and border visibility, colors, and opacity. Both opacities default
  to 50%.
- Gold trim at the top and bottom, with shorter gold dividers between sections.
- Level-up effects: gold pulse, panel glow, and a shimmering level message.
- A level-up preview button under **Debug previews**.

Settings are saved per character. `/reload` preserves tracking totals and timers.
A fresh login starts a new session. **Reset appearance** restores display defaults
without changing tracking data, position, or lock state.

## Upgrading from Forever XP / Hour

The addon folder, TOC file, saved-variable name, and commands have changed. Remove
the old `ForeverXPHour` addon folder when installing `ForeverSession`; do not run
both versions together. The commands are now `/fs` and `/foreversession`.

To retain settings, close WoW and back up the character's
`WTF/Account/<account>/<realm>/<character>/SavedVariables/ForeverXPHour.lua` file.
Copy it to `ForeverSession.lua` in the same directory and change the assignment
name from `ForeverXPHourDB` to `ForeverSessionDB`. The settings structure is
unchanged. Leave an existing `ForeverSession.lua` file intact if you have already
used the renamed addon.

## Development

Runtime files are `ForeverSession.lua` and `Options.lua`, loaded in that order by
`ForeverSession.toc`. The addon uses Blizzard's native fonts, textures, settings
controls, and animation APIs.

Run the Lua 5.1 mock checks with Python:

```sh
python -m pip install -r requirements-dev.txt
python test_addon.py
```

The checks cover tracking calculations, grouped layouts, visibility combinations,
reset isolation, saved settings, reloads, loot valuation, and level-up effects.
They do not validate rendering inside WoW. Check layout, scale changes, coin
icons, tooltips, and animation playback in the target client before releasing.

API references use the Forever branch of the Blizzard UI source mirror:

- [Unit and XP APIs](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua)
- [PvP progression](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/PVPRankFrame.lua)
- [Reputation APIs](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ReputationInfoDocumentation.lua)
- [Pixel sizing](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_SharedXML/PixelUtil.lua)
