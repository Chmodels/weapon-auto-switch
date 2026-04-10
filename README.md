# 🔫 Weapon Auto Switch - FiveM

Advanced FiveM script that allows players to convert semi-automatic weapons into fully automatic using a usable item.

Built with **ox_inventory** and **ox_lib**, compatible with **ESX** and **QBCore** frameworks.

---

## ✨ Features

- Usable item: `switch_auto`
- Converts semi-auto weapons into automatic
- Weapon validation system (configurable)
- Attachment-style system (no duplicate installs)
- Metadata support (ox_inventory)
- Progress bar and animation (ox_lib)
- Sound effects and notifications
- Cooldown system to prevent abuse
- Optimized performance (no heavy loops)

---

## 📦 Requirements

- ox_inventory
- ox_lib
- ESX or QBCore

---

## ⚙️ Installation

1. Download or clone this repository
2. Place the folder in your `resources` directory
3. Add this to your `server.cfg`:

```cfg
ensure weapon-auto-switch
