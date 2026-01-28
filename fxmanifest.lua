fx_version 'cerulean'
game 'gta5'

author 'Haus-Manager Team'
description 'Complete FiveM Property Management System - Multi-Framework Support (QB-Core & ESX)'
version '1.1.0'

shared_scripts {
    'config/config.lua'
}

client_scripts {
    'bridge/framework.lua',  -- Framework bridge (QB-Core & ESX support)
    'bridge/menu.lua',  -- Menu bridge (qb-menu, esx_context, esx_menu_default)
    'bridge/target.lua',  -- Target bridge (qb-target, ox_target, qtarget, or DrawText fallback)
    'client/main.lua',
    'client/markers.lua',
    'client/interior.lua',
    'client/safes.lua',  -- Safe and wardrobe interactions
    'client/garage.lua',
    'client/sell.lua',   -- Property selling
    'client/keymanager.lua',  -- Key management
    'client/keyhud.lua',  -- Temporary key HUD display
    'client/blips.lua'  -- Load last so GetProperties is available
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server_framework.lua',  -- Server framework bridge (QB-Core & ESX support)
    'server/license.lua',  -- License validation system
    'server/main.lua',
    'server/database.lua',
    'server/property.lua',
    'server/keys.lua',
    'server/rent.lua',
    'server/sell.lua',  -- Property selling
    'server/keymanager.lua'  -- Key management
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/css/*.css',
    'html/js/*.js',
    'html/img/*.png',
    'html/img/*.jpg'
}

dependencies {
    'oxmysql'
    -- QB-Core ODER ESX wird automatisch erkannt
    -- Keine spezifischen Framework-Dependencies erforderlich
}

lua54 'yes'
