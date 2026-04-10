```lua
Config <const> = {}

-- Framework configuration (auto-detected)
Config.Framework = "auto" -- "auto", "esx", or "qbcore"

-- Cooldown configuration (in milliseconds)
Config.Cooldown = 5000

-- Animation configuration
Config.Animation = {
    dict = "anim@amb@clubhouse@tutorial@bkr_tut_ig3@",
    name = "machinic_loop_playerone",
    flag = 1
}

-- Sound configuration
Config.Sound = {
    name = "BASE_JUMP_CLOTHES",
    set = "SECURITY_DELIVERED"
}

-- Progress bar configuration
Config.ProgressBar = {
    duration = 5000,
    label = "Installing automatic switch...",
    disableControls = {
        mouse = true,
        movement = true,
        carMovement = true,
        weapon = true
    }
}

-- Allowed weapons for automatic fire mode conversion
-- These weapons support fire rate modification
Config.AllowedWeapons = {
    -- Pistols
    "WEAPON_PISTOL",
    "WEAPON_PISTOL_MK2",
    "WEAPON_PISTOL50",
    "WEAPON_REVOLVER",
    "WEAPON_REVOLVER_MK2",
    "WEAPON_SNSPISTOL",
    "WEAPON_SNSPISTOL_MK2",
    "WEAPON_HEAVYPISTOL",
    "WEAPON_VINTAGEPISTOL",
    -- Submachine Guns
    "WEAPON_MICROSMG",
    "WEAPON_SMG",
    "WEAPON_SMG_MK2",
    "WEAPON_ASSAULTSMG",
    "WEAPON_MINISMG",
    -- Rifles
    "WEAPON_ASSAULTRIFLE",
    "WEAPON_ASSAULTRIFLE_MK2",
    "WEAPON_CARBINERIFLE",
    "WEAPON_CARBINERIFLE_MK2",
    "WEAPON_SPECIALCARBINE",
    "WEAPON_SPECIALCARBINE_MK2",
    "WEAPON_ADVANCEDRIFLE",
    -- Shotguns
    "WEAPON_PUMPSHOTGUN",
    "WEAPON_PUMPSHOTGUN_MK2",
    "WEAPON_BULLPUPSHOTGUN",
    "WEAPON_ASSAULTSHOTGUN",
    -- Light Machine Guns
    "WEAPON_MG",
    "WEAPON_COMBATMG",
    "WEAPON_COMBATMG_MK2",
    "WEAPON_GUSENBERG",
    -- Snipers
    "WEAPON_HEAVYSNIPER",
    "WEAPON_HEAVYSNIPER_MK2",
    "WEAPON_MARKSMANRIFLE",
    "WEAPON_MARKSMANRIFLE_MK2"
}

-- Item configuration
Config.Items = {
    install = {
        name = "switch_auto",
        label = "Automatic Switch",
        description = "Converts a semi-automatic weapon to automatic fire mode.",
        image = "switch_auto.png",
        stack = true,
        close = true,
        usetime = 5000,
        interactive = true
    },
    remove = {
        name = "remove_switch",
        label = "Remove Switch",
        description = "Removes the automatic switch from a weapon.",
        image = "remove_switch.png",
        stack = true,
        close = true,
        usetime = 3000,
        interactive = true
    }
}

-- Notification messages
Config.Notifications = {
    installed = "Automatic switch installed",
    alreadyInstalled = "This weapon already has an automatic switch",
    notCompatible = "This weapon is not compatible",
    noWeapon = "You need to be holding a weapon",
    removed = "Automatic switch removed",
    cooldown = "Please wait before installing another switch",
    notEquipped = "No automatic switch found on this weapon"
}
```