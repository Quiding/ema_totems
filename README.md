# EMA Totems

A high-performance Shaman totem management plugin for **EMA (Ebony's MultiBoxing Assistant)**. This addon provides unified totem bars for Shaman teams with instant combat-log tracking and deep customization.

## Key Features

*   **Unified Team Bars:** See and manage all your Shamans' totems in one compact, synchronized interface.
*   **Direct Keybinding:** Set your "Cast Totem Sequence" keybind directly in the addon settings—no XML or game menu navigation required.
*   **"Only Timers" Mode:** A passive monitoring mode that turns the bars into non-interactive status trackers, persistently showing the last totem cast in each slot.
*   **Spam-safe Macros:** Optional `/castsequence reset=3 ..., null` logic allowing you to spam your totem key without accidentally restarting the sequence.
*   **Deep Customization:** Full support for **LibSharedMedia-3.0** (Borders, Backgrounds, Fonts), scaling, alpha transparency, and custom element ordering.
*   **Combat-Log Tracking:** Uses near-instant `SPELL_SUMMON` and `SPELL_CAST_SUCCESS` events for lag-free timer updates across all clients.
*   **ElvUI/OmniCC Integration:** Easily disable internal timer text to let your favorite global timer addons handle the countdowns.

## Installation

1.  Download the repository.
2.  Place the `EMA_Totems` folder into your `Interface\AddOns` directory.
3.  Ensure **EMA** is installed and enabled.

## Usage

*   Open the EMA configuration menu and navigate to **Class > Totems**.
*   Use the **Totem Type Sequence** list to customize the drop order for each Shaman.
*   Right-click any totem slot on the bar to select a specific totem.
*   Assign a keybind using the **Set Cast Totem Sequence Keybind** button.

## Requirements

*   World of Warcraft (Classic/Anniversary)
*   [EMA (Ebony's MultiBoxing Assistant)](https://www.curseforge.com/wow/addons/ema)
