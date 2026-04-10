```lua
fx_version 'cerulean'
game 'gta5'

author 'SwisserAI'
description 'Generated with SwisserAI - https://ai.swisser.dev'
version '1.0.0'

-- Dependencies
dependency 'ox_lib'
dependency 'ox_inventory'

-- Shared scripts
shared_script 'config.lua'

-- Framework detection (ESX or QBCore)
shared_scripts {
    '@es_extended/imports.lua',
    '@qb-core/import.lua'
}

-- Items definition for ox_inventory
items 'items.lua'

-- Client scripts
client_script 'client.lua'

-- Server scripts
server_script 'server.lua'

-- Ensure proper loading order
lua54 'yes'