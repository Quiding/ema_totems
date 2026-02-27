# EMA Totems

A Gemini-generated plugin for **EMA (Ebony's MultiBoxing Assistant)** [https://www.curseforge.com/wow/addons/ema](https://www.curseforge.com/wow/addons/ema). This addon provides unified totem bars for Shaman teams where you can change totems, track timers, and bind a custom totem sequence.

Looking for other team-wide tracking? Check out [EMA Cooldowns](https://github.com/Quiding/ema_cooldowns) or [EMA Buffs](https://github.com/Quiding/ema_buffs).

There is a small showcase of this + the other plugins mentioned here: https://www.youtube.com/watch?v=1vsrVzWFRxQ

**Note:** This addon likely requires your team to be in the same guild and utilize **guild communications** for settings synchronization, however, all timers are tracked via the **combat log** for high-precision updates.

**Disclaimer:** These addons are early-stage Gemini-generated prototypes and have not undergone extensive bug testing. Please use with caution and report any issues you find.

![totembar1](https://github.com/user-attachments/assets/68b88642-8df9-4ea5-87b2-bf26ba13f303) ![totembar2](https://github.com/user-attachments/assets/c9d3d5bf-6e3d-4f6c-ac91-ef4b638c924b)

## Key Features

*   **Unified Totem Management:** View and manage all your Shamans' totems in one compact, synchronized interface.
*   **Custom Cast Sequences:** Customize the drop order (e.g., Air, Fire, Earth, Water) for each Shaman individually.
*   **Direct Keybinding:** Assign your "Cast Totem Sequence" key directly in the settings menu for instant team casting.
*   **Persistent Monitoring:** Tracks active totems and remaining durations across your entire team in real-time.
*   **Spam-safe Macros:** Optional logic allowing you to rapidly click your totem key without accidentally restarting your cast sequence.
*   **Global Addon Compatibility:** Built-in options to work seamlessly with OmniCC and ElvUI for timer displays.

## Installation

1.  Download the repository.
2.  Save the folder as **"EMA_Totems"** in your `Interface\AddOns` directory.
3.  Ensure **EMA** is installed and enabled.

## Usage

*   Open the EMA configuration menu and navigate to **Class > Totems**.
*   Select a Shaman from the **Totem Type Sequence** list to edit their specific order.
*   Right-click any totem slot on the bar to select a specific totem.
*   Use the **Set Cast Totem Sequence Keybind** button to assign your shortcut.

## Export example
*  Main Totem settings ( Only Layout, scale and such since everything else is character name based not class )
```^1^T^SbackgroundStyle^SNone^SpresetButtonPosition^SLeftAbove^SbarMargin^N0^SuseSpamMacro^B^SframeBackgroundColourG^N0.1^SframeBorderColourR^N0.5^StimerFontSize^N32^SshowPresets^B^StimerColorB^F7488338831343617^f-54^SborderStyle^SNone^SpresetHandlesOnHover^B^SbarAlpha^N1^SfontSize^N14^StimerColorG^N0^SshowTimers^b^SbarScale^N1.4^SshowIndividualPresetHandles^B^SbarOrder^SRoleAsc^SiconSize^N36^Sglobal^T^t^SfontStyle^SArial~`Narrow^SonlyTimers^b^SframeBorderColourA^N1^SlockBars^B^SframeBackgroundColourB^N0.1^StimerColorR^N1^SshowNames^b^SframeBackgroundColourA^N0.7^SframeBorderColourB^N0.5^SbarLayout^SHorizontal^SiconMargin^N1^SframeBackgroundColourR^N0.1^SshowBars^B^SshowTeamPresetHandle^B^SframeBorderColourG^N0.5^SbreakUpBars^b^t^^```
