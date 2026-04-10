```lua
-- Server-side code for weapon fire mode switch system
local Config = Config
local isAutoDetected = false
local detectedFramework = nil

-- Detect framework
local function detectFramework()
    if isAutoDetected then return detectedFramework end
    
    if Config.Framework ~= "auto" then
        detectedFramework = Config.Framework
        return detectedFramework
    end
    
    -- Try to detect ESX
    if exports["es_extended"] and getSharedObject then
        detectedFramework = "esx"
        isAutoDetected = true
        return detectedFramework
    end
    
    -- Try to detect QBCore
    if exports["qb-core"] then
        detectedFramework = "qbcore"
        isAutoDetected = true
        return detectedFramework
    end
    
    detectedFramework = "unknown"
    return detectedFramework
end

-- Get player identifier
local function getPlayerIdentifier(src)
    local framework = detectFramework()
    
    if framework == "esx" then
        local ESX = exports.es_extended:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            return xPlayer.identifier
        end
    elseif framework == "qbcore" then
        local QBCore = exports["qb-core"]:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            return Player.PlayerData.citizenid
        end
    end
    
    -- Fallback to license
    local license = GetPlayerIdentifierByType(src, "license")
    return license or ("unknown:%d"):format(src)
end

-- Check if weapon already has switch (stored in player metadata)
local function hasWeaponSwitch(src, weaponName)
    if not exports.ox_inventory then return false end
    
    local player = exports.ox_inventory:GetInventory(src)
    if not player then return false end
    
    -- Get the stored weapon switches from player metadata
    local switches = player.metadata and player.metadata.weapon_switches
    if not switches then return false end
    
    return switches[weaponName] == true
end

-- Set weapon switch state
local function setWeaponSwitchState(src, weaponName, hasSwitch)
    if not exports.ox_inventory then return false end
    
    -- Get current player inventory
    local player = exports.ox_inventory:GetInventory(src)
    if not player then return false end
    
    -- Initialize or get existing switches
    local switches = player.metadata and player.metadata.weapon_switches or {}
    switches[weaponName] = hasSwitch
    
    -- Update player metadata
    exports.ox_inventory:UpdateMetadata(src, "weapon_switches", switches)
    
    return true
end

-- Check weapon is in allowed list
local function isWeaponAllowed(weaponName)
    for _, allowedWeapon in ipairs(Config.AllowedWeapons) do
        if allowedWeapon == weaponName then
            return true
        end
    end
    
    return false
end

-- Register ox_inventory items
local function registerItems()
    if not exports.ox_inventory then
        print("[^1ERROR^7] ox_inventory not found, cannot register items")
        return
    end
    
    -- Items are registered via ox_inventory's item loader
    -- We just need to make them usable
    print("[^2INFO^7] Weapon switch items ready for use")
end

-- Handle item usage from ox_inventory
local function handleItemUsage(itemName)
    return function(data)
        local src = data.playerId
        
        if itemName == Config.Items.install.name then
            -- Trigger client to install switch
            TriggerClientEvent("weapon_switch:install", src)
        elseif itemName == Config.Items.remove.name then
            -- Trigger client to remove switch
            TriggerClientEvent("weapon_switch:remove", src)
        end
    end
end

-- Register item use callbacks
local function registerItemCallbacks()
    if not exports.ox_inventory then return end
    
    exports.ox_inventory:RegisterUsableItem(Config.Items.install.name, handleItemUsage(Config.Items.install.name))
    exports.ox_inventory:RegisterUsableItem(Config.Items.remove.name, handleItemUsage(Config.Items.remove.name))
    
    print("[^2INFO^7] Weapon switch item callbacks registered")
end

-- Initialize server
CreateThread(function()
    -- Wait for dependencies
    while not exports.ox_inventory do
        Wait(100)
    end
    
    -- Wait a bit more for other resources
    Wait(1000)
    
    registerItems()
    registerItemCallbacks()
    
    print("[^2INFO^7] Weapon Switch System initialized")
end)

-- Server events
RegisterNetEvent("weapon_switch:confirmInstall", function(weaponName)
    local src = source
    
    -- Validate player
    if not src or src <= 0 then return end
    
    -- Check if weapon is allowed
    if not isWeaponAllowed(weaponName) then
        TriggerClientEvent("weapon_switch:installFailed", src, "Weapon not compatible")
        return
    end
    
    -- Check if weapon already has switch
    if hasWeaponSwitch(src, weaponName) then
        TriggerClientEvent("weapon_switch:installFailed", src, "Already installed")
        return
    end
    
    -- Remove item from inventory
    local removed = exports.ox_inventory:RemoveItem(src, Config.Items.install.name, 1)
    
    if removed then
        -- Set weapon switch state
        setWeaponSwitchState(src, weaponName, true)
        
        -- Notify client of success
        TriggerClientEvent("weapon_switch:installSuccess", src, weaponName)
    else
        TriggerClientEvent("weapon_switch:installFailed", src, "Failed to consume item")
    end
end)

RegisterNetEvent("weapon_switch:confirmRemove", function(weaponName)
    local src = source
    
    -- Validate player
    if not src or src <= 0 then return end
    
    -- Check if weapon has switch
    if not hasWeaponSwitch(src, weaponName) then
        TriggerClientEvent("weapon_switch:removeFailed", src, "No switch installed")
        return
    end
    
    -- Remove item from inventory
    local removed = exports.ox_inventory:RemoveItem(src, Config.Items.remove.name, 1)
    
    if removed then
        -- Remove weapon switch state
        setWeaponSwitchState(src, weaponName, false)
        
        -- Notify client of success
        TriggerClientEvent("weapon_switch:removeSuccess", src, weaponName)
    else
        TriggerClientEvent("weapon_switch:removeFailed", src, "Failed to consume item")
    end
end)

-- Check if player has switch on weapon (called from client)
RegisterNetEvent("weapon_switch:checkStatus", function(weaponName)
    local src = source
    local hasSwitch = hasWeaponSwitch(src, weaponName)
    
    TriggerClientEvent("weapon_switch:statusResult", src, hasSwitch, weaponName)
end)

-- Admin command to give weapon switch items
RegisterCommand("giveswitch", function(source, args)
    if source == 0 then
        print("This command must be run by a player")
        return
    end
    
    local itemType = args[1] or "install"
    local amount = tonumber(args[2]) or 1
    
    local itemName = itemType == "remove" and Config.Items.remove.name or Config.Items.install.name
    
    local added = exports.ox_inventory:AddItem(source, itemName, amount)
    
    if added then
        local framework = detectFramework()
        
        if framework == "esx" then
            local ESX = exports.es_extended:getSharedObject()
            local xPlayer = ESX.GetPlayerFromId(source)
            if xPlayer then
                xPlayer.showNotification("Received " .. amount .. "x " .. itemName)
            end
        elseif framework == "qbcore" then
            local QBCore = exports["qb-core"]:GetCoreObject()
            QBCore.Functions.Notify(source, "Received " .. amount .. "x " .. itemName, "success")
        else
            TriggerClientEvent("weapon_switch:notify", source, "Received " .. amount .. "x " .. itemName, "success")
        end
    end
end, true)

-- Notify client event
RegisterNetEvent("weapon_switch:notify", function(message, type)
    -- This is a fallback notification
end)
```