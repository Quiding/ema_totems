# EMA Totems

A Gemini-generated plugin for **EMA (Ebony's MultiBoxing Assistant)** [https://www.curseforge.com/wow/addons/ema](https://www.curseforge.com/wow/addons/ema). This addon provides unified totem bars for Shaman teams where you can change the actual totems, track timers, and bind a custom totem sequence to cast your chosen totems.

**Note:** This addon requires your team to be in the same guild and utilize **guild communications** for synchronization.

![totembar1](https://github.com/user-attachments/assets/68b88642-8df9-4ea5-87b2-bf26ba13f303) ![totembar2](https://github.com/user-attachments/assets/c9d3d5bf-6e3d-4f6c-ac91-ef4b638c924b)

## Key Features

*   **Unified Shaman Monitoring:** Manage and view all your Shamans' totems in one compact, synchronized interface.
*   **Custom Totem Type Sequences:** Customize the drop order (e.g., Air, Fire, Earth, Water) for each Shaman individually.
*   **Direct Keybinding:** Assign your "Cast Totem Sequence" key directly in the settings menu—no XML errors or game menu navigation required.
*   **"Only Timers" Mode:** A passive monitor that grays out interactive elements and persistently shows the last totem cast in each slot.
*   **Spam-safe Macros:** Optional `/castsequence reset=3 ..., null` logic allowing you to spam your totem key without accidentally restarting the sequence prematurely.
*   **ElvUI/OmniCC Integration:** Option to disable internal timer text to let global addons handle the styled countdowns.
*   **Combat-Log Tracking:** Uses high-speed `SPELL_SUMMON` events for near-instant timer updates across all clients.

## Installation

1.  Download the repository.
2.  Save the folder as **"EMA_Totems"** in your `Interface\AddOns` directory.
3.  Ensure **EMA** is installed and enabled.

## Usage

*   Open the EMA configuration menu and navigate to **Class > Totems**.
*   Select a Shaman from the **Totem Type Sequence** list to edit their specific order.
*   Right-click any totem slot on the bar to select a specific totem.
*   Use the **Set Cast Totem Sequence Keybind** button to assign your shortcut.
