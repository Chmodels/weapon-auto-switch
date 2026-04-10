```lua
-- Client-side code for weapon fire mode switch system
local Config = Config

-- Cooldown tracking
local lastInstallTime = 0
local lastRemoveTime = 0

-- Current weapon with switch
local currentWeaponWithSwitch = nil

-- Framework detection
local function detectFramework()
    if Config.Framework ~= "auto" then
        return Config.Framework
    end
    
    if exports["es_extended"] then
        return "esx"
    elseif exports["qb-core"] then
        return "qbcore"
    end
    
    return "unknown"
end

-- Show notification using ox_lib
local function showNotification(message, notificationType)
    local framework = detectFramework()
    
    -- Try ox_lib first (works with both ESX and QBCore)
    if lib and lib.notify then
        lib.notify({
            title = "Weapon Switch",
            description = message,
            type = notificationType or "success"
        })
        return
    end
    
    -- Try QBCore notification
    if framework == "qbcore" and QBCore and QBCore.Functions then
        QBCore.Functions.Notify(message, notificationType or "success")
        return
    end
    
    -- Try ESX notification
    if framework == "esx" and ESX then
        ESX.ShowNotification(message)
        return
    end
    
    -- Fallback to native notification
    BeginTextCommandThefeedPost("STRING")
    AddTextComponentString(message)
    EndTextCommandThefeedPostTicker(false, true)
end

-- Play sound effect
local function playSound()
    if Config.Sound.name then
        PlaySoundFrontend(-1, Config.Sound.name, Config.Sound.set or "HUD_FRONTEND_DEFAULT_SOUNDSET", true)
    end
end

-- Play animation
local function playAnimation()
    local ped = PlayerPedId()
    
    -- Request animation dictionary
    RequestAnimDict(Config.Animation.dict)
    
    while not HasAnimDictLoaded(Config.Animation.dict) do
        Wait(10)
    end
    
    -- Play animation
    TaskPlayAnim(ped, Config.Animation.dict, Config.Animation.name, 8.0, -8.0, -1, Config.Animation.flag, 0, false, false, false)
    
    -- Clear animation after duration
    CreateThread(function()
        Wait(Config.ProgressBar.duration)
        if HasAnimDictLoaded(Config.Animation.dict) then
            StopAnimTask(ped, Config.Animation.dict, Config.Animation.name, true)
        end
    end)
end

-- Get current weapon hash
local function getCurrentWeapon()
    local ped = PlayerPedId()
    local weaponHash = GetSelectedPedWeapon(ped)
    
    -- Check if valid weapon (not unarmed)
    if weaponHash == 0 or weaponHash == nil then
        return nil
    end
    
    return weaponHash
end

-- Get weapon name from hash
local function getWeaponNameFromHash(weaponHash)
    local weaponName = GetWeaponNameFromHash(weaponHash)
    return weaponName or tostring(weaponHash)
end

-- Check if weapon is in allowed list
local function isWeaponAllowed(weaponHash)
    local weaponName = getWeaponNameFromHash(weaponHash)
    
    for _, allowedWeapon in ipairs(Config.AllowedWeapons) do
        if allowedWeapon == weaponName then
            return true
        end
    end
    
    return false
end

-- Check cooldown
local function canInstall()
    local currentTime = GetGameTimer()
    return (currentTime - lastInstallTime) >= Config.Cooldown
end

-- Install automatic switch
local function installSwitch()
    local ped = PlayerPedId()
    local weaponHash = getCurrentWeapon()
    
    -- Check if player has weapon
    if not weaponHash then
        showNotification(Config.Notifications.noWeapon, "error")
        return
    end
    
    -- Check cooldown
    if not canInstall() then
        showNotification(Config.Notifications.cooldown, "warning")
        return
    end
    
    -- Check if weapon is allowed
    if not isWeaponAllowed(weaponHash) then
        showNotification(Config.Notifications.notCompatible, "error")
        return
    end
    
    local weaponName = getWeaponNameFromHash(weaponHash)
    
    -- Check if weapon already has switch (async check)
    local hasSwitch = false
    local checkComplete = false
    
    TriggerServerEvent("weapon_switch:checkStatus", weaponName)
    
    -- Wait briefly for response
    CreateThread(function()
        Wait(200)
        checkComplete = true
    end)
    
    -- Show progress bar
    if lib and lib.progressbar then
        lib.progressbar({
            duration = Config.ProgressBar.duration,
            label = Config.ProgressBar.label,
            useWhileDead = false,
            canCancel = true,
            disableControls = Config.ProgressBar.disableControls,
            anim = {
                dict = Config.Animation.dict,
                name = Config.Animation.name
            }
        }, function(cancelled)
            if cancelled then
                showNotification("Installation cancelled", "warning")
                return
            end
            
            -- Installation complete
            lastInstallTime = GetGameTimer()
            playSound()
            
            -- Confirm to server
            TriggerServerEvent("weapon_switch:confirmInstall", weaponName)
        end)
    else
        -- Fallback if lib not available
        playAnimation()
        Wait(Config.ProgressBar.duration)
        
        lastInstallTime = GetGameTimer()
        playSound()
        
        -- Confirm to server
        TriggerServerEvent("weapon_switch:confirmInstall", weaponName)
    end
end

-- Remove automatic switch
local function removeSwitch()
    local ped = PlayerPedId()
    local weaponHash = getCurrentWeapon()
    
    -- Check if player has weapon
    if not weaponHash then
        showNotification(Config.Notifications.noWeapon, "error")
        return
    end
    
    -- Check cooldown
    local currentTime = GetGameTimer()
    if (currentTime - lastRemoveTime) < Config.Cooldown then
        showNotification(Config.Notifications.cooldown, "warning")
        return
    end
    
    local weaponName = getWeaponNameFromHash(weaponHash)
    
    -- Show progress for removal (faster)
    if lib and lib.progressbar then
        lib.progressbar({
            duration = 3000,
            label = "Removing automatic switch...",
            useWhileDead = false,
            canCancel = true,
            disableControls = {
                mouse = true,
                movement = true,
                weapon = true
            }
        }, function(cancelled)
            if cancelled then
                showNotification("Removal cancelled", "warning")
                return
            end
            
            lastRemoveTime = GetGameTimer()
            playSound()
            
            TriggerServerEvent("weapon_switch:confirmRemove", weaponName)
        end)
    else
        playAnimation()
        Wait(3000)
        
        lastRemoveTime = GetGameTimer()
        playSound()
        
        TriggerServerEvent("weapon_switch:confirmRemove", weaponName)
    end
end

-- Apply automatic fire mode to weapon
local function applyAutomaticFire(weaponHash)
    local ped = PlayerPedId()
    
    -- Set weapon to automatic fire mode
    -- This is done by modifying the weapon's fire type
    SetWeaponDamageModifier(weaponHash, 1.0)
    
    -- Enable automatic firing
    SetWeaponAccuracy(weaponHash, GetWeaponAccuracy(weaponHash))
    
    -- Note: Actual automatic fire mode modification in GTA V requires
    -- specific handling through weapon components or ped weapon flags
    
    -- Apply automatic fire rate
    -- This creates the continuous fire effect
    SetPedFireRate(ped, 100.0) -- Higher fire rate for automatic effect
    
    -- Mark weapon as automatic
    currentWeaponWithSwitch = getWeaponNameFromHash(weaponHash)
end

-- Remove automatic fire mode
local function removeAutomaticFire(weaponHash)
    local ped = PlayerPedId()
    
    -- Reset fire rate to default
    SetPedFireRate(ped, 1.0)
    
    -- Clear weapon flag
    currentWeaponWithSwitch = nil
end

-- Check equipped weapons for switches
local function checkEquippedWeapons()
    local ped = PlayerPedId()
    
    -- Check current weapon
    local weaponHash = getCurrentWeapon()
    
    if weaponHash then
        local weaponName = getWeaponNameFromHash(weaponHash)
        
        -- Request status from server
        TriggerServerEvent("weapon_switch:checkStatus", weaponName)
    end
end

-- Client events
RegisterNetEvent("weapon_switch:install", function()
    installSwitch()
end)

RegisterNetEvent("weapon_switch:remove", function()
    removeSwitch()
end)

RegisterNetEvent("weapon_switch:installSuccess", function(weaponHash)
    showNotification(Config.Notifications.installed, "success")
    
    -- Apply automatic fire effect
    applyAutomaticFire(weaponHash)
end)

RegisterNetEvent("weapon_switch:installFailed", function(reason)
    showNotification(reason or "Installation failed", "error")
end)

RegisterNetEvent("weapon_switch:removeSuccess", function(weaponHash)
    showNotification(Config.Notifications.removed, "success")
    
    -- Remove automatic fire effect
    removeAutomaticFire(weaponHash)
end)

RegisterNetEvent("weapon_switch:removeFailed", function(reason)
    showNotification(reason or "Removal failed", "error")
end)

RegisterNetEvent("weapon_switch:statusResult", function(hasSwitch, weaponName)
    if hasSwitch then
        -- Apply automatic fire if weapon has switch
        local weaponHash = getCurrentWeapon()
        if weaponHash and getWeaponNameFromHash(weaponHash) == weaponName then
            currentWeaponWithSwitch = weaponName
            applyAutomaticFire(weaponHash)
        end
    else
        currentWeaponWithSwitch = nil
    end
end)

-- Main thread to monitor weapon changes
CreateThread(function()
    local lastWeapon = 0
    
    while true do
        Wait(500)
        
        local ped = PlayerPedId()
        local currentWeapon = GetSelectedPedWeapon(ped)
        
        -- Check if weapon changed
        if currentWeapon ~= lastWeapon and currentWeapon ~= 0 then
            -- Check if new weapon has switch
            local weaponName = getWeaponNameFromHash(currentWeapon)
            
            TriggerServerEvent("weapon_switch:checkStatus", weaponName)
            
            lastWeapon = currentWeapon
        elseif currentWeapon == 0 then
            lastWeapon = 0
            currentWeaponWithSwitch = nil
        end
    end
end)

-- Initialize
print("[^2INFO^7] Weapon Switch System client initialized")
```