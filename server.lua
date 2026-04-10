```lua
local switchData = {} -- In-memory storage: [identifier][weaponHash] = true/false
local cooldowns = {} -- Player cooldowns

-- Framework references
local ESX = nil
local QBCore = nil

-- Initialize framework
local function initFramework()
    if Config.Framework == "esx" or Config.Framework == "auto" then
        TriggerEvent("esx:getSharedObject", function(obj)
            ESX = obj
        end)
    end
    
    if Config.Framework == "qbcore" or Config.Framework == "auto" then
        QBCore = exports["qb-core"]:GetCoreObject()
    end
end

-- Get player identifier
--- @param source number The player server ID
--- @return string|nil identifier The player identifier
local function getPlayerIdentifier(source)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.identifier
        end
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.PlayerData.citizenid
        end
    end
    return nil
end

-- Get player source from identifier
--- @param identifier string The player identifier
--- @return number|nil source The player server ID
local function getPlayerSource(identifier)
    if ESX then
        local xPlayers = ESX.GetPlayers()
        for _, src in ipairs(xPlayers) do
            local xPlayer = ESX.GetPlayerFromId(src)
            if xPlayer and xPlayer.identifier == identifier then
                return src
            end
        end
    elseif QBCore then
        local players = QBCore.Functions.GetPlayers()
        for _, src in ipairs(players) do
            local Player = QBCore.Functions.GetPlayer(src)
            if Player and Player.PlayerData.citizenid == identifier then
                return src
            end
        end
    end
    return nil
end

-- Check if player has the item
--- @param source number The player server ID
--- @param itemName string The item name
--- @return boolean hasItem Whether the player has the item
local function hasItem(source, itemName)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            local item = xPlayer.getInventoryItem(itemName)
            return item and item.count > 0
        end
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            return Player.Functions.GetItemByName(itemName) ~= nil
        end
    end
    return false
end

-- Remove item from player
--- @param source number The player server ID
--- @param itemName string The item name
--- @param amount number The amount to remove
local function removeItem(source, itemName, amount)
    amount = amount or 1
    
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer then
            xPlayer.removeInventoryItem(itemName, amount)
        end
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(source)
        if Player then
            Player.Functions.RemoveItem(itemName, amount)
        end
    end
end

-- Check if weapon is in allowed list
--- @param weaponName string The weapon name
--- @return boolean isAllowed Whether the weapon is allowed
local function isWeaponAllowed(weaponName)
    for _, allowedWeapon in ipairs(Config.AllowedWeapons) do
        if allowedWeapon:upper() == weaponName:upper() then
            return true
        end
    end
    return false
end

-- Check if player is on cooldown
--- @param source number The player server ID
--- @return boolean isOnCooldown Whether player is on cooldown
local function isOnCooldown(source)
    local currentTime = os.time()
    if cooldowns[source] and currentTime - cooldowns[source] < 3 then
        return true
    end
    cooldowns[source] = currentTime
    return false
end

-- Check if weapon already has switch installed
--- @param identifier string The player identifier
--- @param weaponHash number The weapon hash
--- @return boolean hasSwitch Whether the weapon has switch installed
local function hasSwitchInstalled(identifier, weaponHash)
    if switchData[identifier] and switchData[identifier][weaponHash] then
        return true
    end
    return false
end

-- Install switch on weapon
--- @param source number The player server ID
--- @param weaponHash number The weapon hash
RegisterNetEvent("autoSwitch:install", function(weaponHash)
    local src = source
    
    -- Validate source
    if not src or src == 0 then
        return
    end
    
    -- Get player identifier
    local identifier = getPlayerIdentifier(src)
    if not identifier then
        TriggerClientEvent("autoSwitch:error", src, "Unable to identify player")
        return
    end
    
    -- Check cooldown
    if isOnCooldown(src) then
        TriggerClientEvent("autoSwitch:cooldown", src)
        return
    end
    
    -- Check if player has the item
    if not hasItem(src, Config.Items.install.name) then
        TriggerClientEvent("autoSwitch:error", src, "You don't have the required item")
        return
    end
    
    -- Get weapon name from hash
    local weaponName = GetWeaponNameFromHash(weaponHash)
    if not weaponName or weaponName == "WEAPON_UNARMED" then
        TriggerClientEvent("autoSwitch:error", src, "Invalid weapon")
        return
    end
    
    -- Check if weapon is allowed
    if not isWeaponAllowed(weaponName) then
        TriggerClientEvent("autoSwitch:error", src, Config.Notifications.notCompatible)
        return
    end
    
    -- Check if switch already installed
    if hasSwitchInstalled(identifier, weaponHash) then
        TriggerClientEvent("autoSwitch:error", src, Config.Notifications.alreadyInstalled)
        return
    end
    
    -- Remove item
    removeItem(src, Config.Items.install.name, 1)
    
    -- Store switch data
    if not switchData[identifier] then
        switchData[identifier] = {}
    end
    switchData[identifier][weaponHash] = true
    
    -- Save to database (async)
    saveSwitchToDatabase(identifier, weaponHash, true)
    
    -- Notify client of success
    TriggerClientEvent("autoSwitch:installSuccess", src, weaponHash)
    
    print("[AutoSwitch] Player " .. identifier .. " installed switch on " .. weaponName)
end)

-- Remove switch from weapon
--- @param source number The player server ID
--- @param weaponHash number The weapon hash
RegisterNetEvent("autoSwitch:remove", function(weaponHash)
    local src = source
    
    -- Validate source
    if not src or src == 0 then
        return
    end
    
    -- Get player identifier
    local identifier = getPlayerIdentifier(src)
    if not identifier then
        TriggerClientEvent("autoSwitch:error", src, "Unable to identify player")
        return
    end
    
    -- Check cooldown
    if isOnCooldown(src) then
        TriggerClientEvent("autoSwitch:cooldown", src)
        return
    end
    
    -- Check if player has the item
    if not hasItem(src, Config.Items.remove.name) then
        TriggerClientEvent("autoSwitch:error", src, "You don't have the required item")
        return
    end
    
    -- Get weapon name from hash
    local weaponName = GetWeaponNameFromHash(weaponHash)
    if not weaponName then
        TriggerClientEvent("autoSwitch:error", src, "Invalid weapon")
        return
    end
    
    -- Check if switch is installed
    if not hasSwitchInstalled(identifier, weaponHash) then
        TriggerClientEvent("autoSwitch:error", src, "This weapon doesn't have a switch installed")
        return
    end
    
    -- Remove item
    removeItem(src, Config.Items.remove.name, 1)
    
    -- Remove switch data
    if switchData[identifier] then
        switchData[identifier][weaponHash] = nil
    end
    
    -- Save to database (async)
    saveSwitchToDatabase(identifier, weaponHash, false)
    
    -- Notify client of success
    TriggerClientEvent("autoSwitch:removeSuccess", src, weaponHash)
    
    print("[AutoSwitch] Player " .. identifier .. " removed switch from " .. weaponName)
end)

-- Save switch data to database
--- @param identifier string The player identifier
--- @param weaponHash number The weapon hash
--- @param hasSwitch boolean Whether the switch is installed
local function saveSwitchToDatabase(identifier, weaponHash, hasSwitch)
    local weaponName = GetWeaponNameFromHash(weaponHash)
    
    -- Use oxmysql if available
    if MySQL then
        if hasSwitch then
            MySQL.insert.await([[
                INSERT INTO `]] .. Config.Database.table .. [[` (]] .. Config.Database.identifierColumn .. [[, ]] .. Config.Database.weaponColumn .. [[, ]] .. Config.Database.switchColumn .. [[, ]] .. Config.Database.timestampColumn .. [[)
                VALUES (?, ?, ?, ?)
                ON DUPLICATE KEY UPDATE ]] .. Config.Database.switchColumn .. [[ = VALUES(]] .. Config.Database.switchColumn .. [[), ]] .. Config.Database.timestampColumn .. [[ = VALUES(]] .. Config.Database.timestampColumn .. [[)
            ]], {identifier, weaponName, 1, os.time()})
        else
            MySQL.update.await([[
                DELETE FROM `]] .. Config.Database.table .. [[`
                WHERE ]] .. Config.Database.identifierColumn .. [[ = ? AND ]] .. Config.Database.weaponColumn .. [[ = ?]]
            , {identifier, weaponName})
        end
    else
        -- Fallback to in-memory only
        print("[AutoSwitch] MySQL not available, using in-memory storage only")
    end
end

-- Load switch data from database for a player
--- @param identifier string The player identifier
local function loadSwitchFromDatabase(identifier)
    if not MySQL then
        return
    end
    
    local results = MySQL.query.await([[
        SELECT ]] .. Config.Database.weaponColumn .. [[, ]] .. Config.Database.switchColumn .. [[
        FROM `]] .. Config.Database.table .. [[`
        WHERE ]] .. Config.Database.identifierColumn .. [[ = ? AND ]] .. Config.Database.switchColumn .. [[ = 1]]
    , {identifier})
    
    if results then
        switchData[identifier] = {}
        for _, row in ipairs(results) do
            local weaponHash = GetHashKey(row[Config.Database.weaponColumn])
            if weaponHash then
                switchData[identifier][weaponHash] = true
            end
        end
    end
end

-- Create database table on resource start
local function createDatabaseTable()
    if not MySQL then
        print("[AutoSwitch] MySQL not available, skipping database setup")
        return
    end
    
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `]] .. Config.Database.table .. [[` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `]] .. Config.Database.identifierColumn .. [[` VARCHAR(50) NOT NULL,
            `]] .. Config.Database.weaponColumn .. [[` VARCHAR(50) NOT NULL,
            `]] .. Config.Database.switchColumn .. [[` TINYINT(1) DEFAULT 0,
            `]] .. Config.Database.timestampColumn .. [[` INT DEFAULT 0,
            UNIQUE KEY `unique_player_weapon` (]] .. Config.Database.identifierColumn .. [[, ]] .. Config.Database.weaponColumn .. [[)
        )
    ]])
    
    print("[AutoSwitch] Database table created/verified")
end

-- Register ox_inventory usable items
local function registerOxInventoryItems()
    -- Register the install item as usable
    exports.ox_inventory:RegisterUsableItem(Config.Items.install.name, function(source)
        local src = source
        local ped = GetPlayerPed(src)
        local weapon = GetSelectedPedWeapon(ped)
        
        if weapon and weapon ~= 0 then
            TriggerClientEvent("autoSwitch:useItem", src, "install", weapon)
        else
            if lib then
                lib.notify(src, {
                    title = "Auto Switch",
                    description = Config.Notifications.noWeapon,
                    type = "error"
                })
            end
        end
    end)
    
    -- Register the remove item as usable
    exports.ox_inventory:RegisterUsableItem(Config.Items.remove.name, function(source)
        local src = source
        local ped = GetPlayerPed(src)
        local weapon = GetSelectedPedWeapon(ped)
        
        if weapon and weapon ~= 0 then
            TriggerClientEvent("autoSwitch:useItem", src, "remove", weapon)
        else
            if lib then
                lib.notify(src, {
                    title = "Auto Switch",
                    description = Config.Notifications.noWeapon,
                    type = "error"
                })
            end
        end
    end)
    
    print("[AutoSwitch] Registered ox_inventory usable items")
end

-- Handle player joining - load their switch data
AddEventHandler("playerJoining", function(source)
    local identifier = getPlayerIdentifier(source)
    if identifier then
        loadSwitchFromDatabase(identifier)
        
        -- Sync data to client
        if switchData[identifier] then
            for weaponHash, hasSwitch in pairs(switchData[identifier]) do
                TriggerClientEvent("autoSwitch:syncState", source, weaponHash, hasSwitch)
            end
        end
    end
end)

-- Initialize on resource start
CreateThread(function()
    -- Wait for framework
    while true do
        if Config.Framework == "esx" then
            TriggerEvent("esx:getSharedObject", function(obj)
                ESX = obj
            end)
            if ESX then break end
        elseif Config.Framework == "qbcore" then
            QBCore = exports["qb-core"]:GetCoreObject()
            if QBCore then break end
        else
            -- Try to detect
            TriggerEvent("esx:getSharedObject", function(obj)
                if obj then
                    ESX = obj
                    Config.Framework = "esx"
                end
            end)
            QBCore = exports["qb-core"]:GetCoreObject()
            if QBCore then
                Config.Framework = "qbcore"
                break
            elseif ESX then
                break
            end
        end
        Wait(100)
    end
    
    -- Create database table
    createDatabaseTable()
    
    -- Register usable items
    if exports.ox_inventory then
        registerOxInventoryItems()
    else
        print("[AutoSwitch] ox_inventory not found, items will not be registered")
    end
    
    print("[AutoSwitch] Resource initialized with framework: " .. Config.Framework)
end)

-- Export functions
exports("hasSwitchInstalled", function(source, weaponHash)
    local identifier = getPlayerIdentifier(source)
    return identifier and hasSwitchInstalled(identifier, weaponHash) or false
end)

exports("getPlayerSwitches", function(source)
    local identifier = getPlayerIdentifier(source)
    return identifier and switchData[identifier] or {}
end)