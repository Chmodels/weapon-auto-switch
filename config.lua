```lua
Config = {}

-- Framework configuration
Config.Framework = "auto" -- "auto", "esx", or "qbcore"

-- Weapon configuration
Config.AllowedWeapons = {
    "WEAPON_PISTOL",
    "WEAPON_PISTOL_MK2",
    "WEAPON_PISTOL50",
    "WEAPON_REVOLVER",
    "WEAPON_REVOLVER_MK2",
    "WEAPON_SNSPISTOL",
    "WEAPON_SNSPISTOL_MK2",
    "WEAPON_HEAVYPISTOL",
    "WEAPON_VINTAGEPISTOL",
    "WEAPON_MARKSMANPISTOL",
    "WEAPON_APPISTOL",
    "WEAPON_STUNGUN",
    "WEAPON_CERAMICPISTOL",
    "WEAPON_NAVYREVOLVER",
    "WEAPON_DOUBLEACTION",
    "WEAPON_RIFLE",
    "WEAPON_ASSAULTRIFLE",
    "WEAPON_CARBINERIFLE",
    "WEAPON_ADVANCEDRIFLE",
    "WEAPON_SPECIALCARBINE",
    "WEAPON_BULLPUPRIFLE",
    "WEAPON_COMPACTRIFLE",
    "WEAPON_SMG",
    "WEAPON_MICROSMG",
    "WEAPON_MINISMG",
    "WEAPON_SMG_MK2",
    "WEAPON_GUSENBERG"
}

-- Item configuration
Config.Items = {
    install = {
        name = "switch_auto",
        label = "Automatic Switch",
        description = "Converts a semi-automatic weapon to fire automatically",
        image = "switch_auto"
    },
    remove = {
        name = "remove_switch",
        label = "Switch Remover",
        description = "Removes the automatic switch from a weapon",
        image = "remove_switch"
    }
}

-- Installation settings
Config.Installation = {
    duration = 5000, -- 5 seconds in milliseconds
    cooldown = 3000, -- 3 seconds cooldown between uses
    animation = {
        dict = "anim@amb@prop_human_parking_meter@female@idle_a",
        name = "idle_a_female"
    }
}

-- Sound settings
Config.Sound = {
    install = {
        audioName = "BASE_JUMP_PASSED",
        audioRef = "HUD_AWARDS"
    }
}

-- Notification settings
Config.Notifications = {
    notCompatible = "This weapon is not compatible with the automatic switch",
    alreadyInstalled = "This weapon already has an automatic switch installed",
    installed = "Automatic switch installed",
    removed = "Automatic switch removed",
    cooldown = "Please wait before using this item again",
    noWeapon = "You need to be holding a weapon to use this item"
}

-- Metadata key for storing switch state
Config.MetadataKey = "weapon_auto_switch"

-- Database table for persistent storage
Config.Database = {
    table = "player_weapon_switches",
    identifierColumn = "identifier",
    weaponColumn = "weapon",
    switchColumn = "has_switch",
    timestampColumn = "timestamp"
}
```