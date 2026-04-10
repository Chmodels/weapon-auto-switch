```lua
local isInstalling = false
local lastUseTime = 0
local currentSwitchState = {}

-- Initialize the client
local function init()
    -- Register usable items with ox_inventory
    registerOxInventoryItems()
    
    -- Monitor weapon changes to apply/remove switch effect
    CreateThread(weaponMonitorThread)
end

-- Register items with ox_inventory
local function registerOxInventoryItems()
    -- The items are registered via server callbacks, but we listen for weapon changes here
end

-- Weapon monitor thread - checks current weapon and applies switch if needed
local function weaponMonitorThread()
    local lastWeapon = 0
    
    while true do
        Wait(500)
        
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)
        
        -- Skip if no weapon or weapon hasn't changed
        if weapon ~= lastWeapon then
            lastWeapon = weapon
            
            -- Check if current weapon has switch installed
            if weapon ~= 0 and currentSwitchState[weapon] then
                applyWeaponSwitch(weapon)
            else
                removeWeaponSwitch(weapon)
            end
        end
    end
end

-- Apply automatic firing pattern to weapon
--- @param weapon number The weapon hash
local function applyWeaponSwitch(weapon)
    local ped = PlayerPedId()
    
    -- Set continuous firing pattern to simulate automatic fire
    -- This makes semi-auto weapons fire continuously while holding trigger
    SetPedFiringPattern(ped, `FIRING_PATTERN_BURST_FIRE`)
    
    -- Store current weapon as switched
    currentSwitchState[weapon] = true
    
    print("[AutoSwitch] Applied automatic fire to weapon:", weapon)
end

-- Remove automatic firing pattern
--- @param weapon number The weapon hash
local function removeWeaponSwitch(weapon)
    local ped = PlayerPedId()
    
    -- Reset to default firing pattern
    SetPedFiringPattern(ped, `FIRING_PATTERN_DEFAULT`)
    
    -- Remove from state
    currentSwitchState[weapon] = nil
    
    print("[AutoSwitch] Removed automatic fire from weapon:", weapon)
end

-- Request to install switch from server
--- @param weaponHash number The weapon hash to install switch on
local function requestInstallSwitch(weaponHash)
    local currentTime = GetGameTimer()
    
    -- Check cooldown
    if currentTime - lastUseTime < Config.Installation.cooldown then
        lib.notify({
            title = "Auto Switch",
            description = Config.Notifications.cooldown,
            type = "error"
        })
        return
    end
    
    -- Check if already installing
    if isInstalling then
        return
    end
    
    isInstalling = true
    lastUseTime = currentTime
    
    -- Play installation animation
    playInstallationAnimation(function()
        -- Request server to process installation
        TriggerServerEvent("autoSwitch:install", weaponHash)
    end)
end

-- Request to remove switch from server
--- @param weaponHash number The weapon hash to remove switch from
local function requestRemoveSwitch(weaponHash)
    local currentTime = GetGameTimer()
    
    -- Check cooldown
    if currentTime - lastUseTime < Config.Installation.cooldown then
        lib.notify({
            title = "Auto Switch",
            description = Config.Notifications.cooldown,
            type = "error"
        })
        return
    end
    
    isInstalling = true
    lastUseTime = currentTime
    
    -- Play removal animation
    playRemovalAnimation(function()
        TriggerServerEvent("autoSwitch:remove", weaponHash)
    end)
end

-- Play installation animation with progress bar
--- @param callback function Function to call when animation completes
local function playInstallationAnimation(callback)
    local ped = PlayerPedId()
    local animDict = Config.Installation.animation.dict
    local animName = Config.Installation.animation.name
    
    -- Request animation dictionary
    RequestAnimDict(animDict)
    
    while not HasAnimDictLoaded(animDict) do
        Wait(0)
    end
    
    -- Play animation
    TaskPlayAnim(ped, animDict, animName, 1.0, -1.0, 0, 1, 1, false, false, false)
    
    -- Show progress bar
    lib.progressBar({
        duration = Config.Installation.duration,
        label = "Installing automatic switch...",
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            scenario = "WORLD_HUMAN_HAMMERING"
        }
    })
    
    -- Clear animation
    ClearPedTasks(ped)
    
    -- Play sound effect
    playSuccessSound()
    
    isInstalling = false
    
    if callback then
        callback()
    end
end

-- Play removal animation with progress bar
--- @param callback function Function to call when animation completes
local function playRemovalAnimation(callback)
    local ped = PlayerPedId()
    
    -- Show progress bar
    lib.progressBar({
        duration = Config.Installation.duration,
        label = "Removing automatic switch...",
        useWhileDead = false,
        canCancel = true,
        disable = {
            car = true,
            move = true,
            combat = true
        },
        anim = {
            scenario = "WORLD_HUMAN_HAMMERING"
        }
    })
    
    -- Play sound effect
    playSuccessSound()
    
    isInstalling = false
    
    if callback then
        callback()
    end
end

-- Play success sound effect
local function playSuccessSound()
    local soundRef = Config.Sound.install.audioRef
    local soundName = Config.Sound.install.audioName
    
    PlaySoundFrontend(-1, soundName, soundRef, true)
end

-- Show notification using ox_lib
--- @param message string The notification message
--- @param type string The notification type (success, error, warning, info)
local function showNotification(message, type)
    lib.notify({
        title = "Auto Switch",
        description = message,
        type = type or "info"
    })
end

-- Sync switch state from server (for when player logs in or weapon changes)
--- @param weaponHash number The weapon hash
--- @param hasSwitch boolean Whether the weapon has switch installed
RegisterNetEvent("autoSwitch:syncState", function(weaponHash, hasSwitch)
    if hasSwitch then
        currentSwitchState[weaponHash] = true
        
        -- Apply immediately if this is the current weapon
        local currentWeapon = GetSelectedPedWeapon(PlayerPedId())
        if currentWeapon == weaponHash then
            applyWeaponSwitch(weaponHash)
        end
    else
        currentSwitchState[weaponHash] = nil
        removeWeaponSwitch(weaponHash)
    end
end)

-- Handle installation success from server
RegisterNetEvent("autoSwitch:installSuccess", function(weaponHash)
    showNotification(Config.Notifications.installed, "success")
    currentSwitchState[weaponHash] = true
    
    -- Apply switch immediately if this is the current weapon
    local currentWeapon = GetSelectedPedWeapon(PlayerPedId())
    if currentWeapon == weaponHash then
        applyWeaponSwitch(weaponHash)
    end
end)

-- Handle removal success from server
RegisterNetEvent("autoSwitch:removeSuccess", function(weaponHash)
    showNotification(Config.Notifications.removed, "success")
    currentSwitchState[weaponHash] = nil
    removeWeaponSwitch(weaponHash)
end)

-- Handle error from server
RegisterNetEvent("autoSwitch:error", function(message)
    showNotification(message, "error")
    isInstalling = false
end)

-- Handle cooldown from server
RegisterNetEvent("autoSwitch:cooldown", function()
    showNotification(Config.Notifications.cooldown, "warning")
    isInstalling = false
end)

-- Initialize when resources start
CreateThread(function()
    -- Wait for framework to be ready
    while true do
        if Config.Framework == "esx" then
            if exports.es_extended and exports.es_extended:getSharedObject() then
                break
            end
        elseif Config.Framework == "qbcore" then
            if exports["qb-core"] and exports["qb-core"]:GetCoreObject() then
                break
            end
        else
            -- Auto-detect
            if exports.es_extended and exports.es_extended:getSharedObject() then
                Config.Framework = "esx"
                break
            elseif exports["qb-core"] and exports["qb-core"]:GetCoreObject() then
                Config.Framework = "qbcore"
                break
            end
        end
        Wait(100)
    end
    
    init()
end)

-- Export functions for external use
exports("requestInstallSwitch", requestInstallSwitch)
exports("requestRemoveSwitch", requestRemoveSwitch)
exports("getSwitchState", function() return currentSwitchState end)
```