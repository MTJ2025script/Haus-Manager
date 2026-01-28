-- Main server file - Property management
-- Uses Framework Bridge for multi-framework support

-- Check if player is Super Admin (License Owner)
local function IsSuperAdmin(source)
    if not source then return false end
    
    -- Get all player identifiers
    local identifiers = GetPlayerIdentifiers(source)
    
    if not identifiers or not Config.SuperAdmins then
        return false
    end
    
    -- Check if any identifier matches Super Admin list
    for _, identifier in ipairs(identifiers) do
        for _, superAdmin in ipairs(Config.SuperAdmins) do
            if identifier == superAdmin then
                if Config.Debug then
                    print(string.format("^2[Haus-Manager]^7 Player %s (%s) is Super Admin", GetPlayerName(source), identifier))
                end
                return true
            end
        end
    end
    
    return false
end

-- Check if player is admin (Super Admin OR Framework Admin)
local function IsAdmin(source)
    -- Super Admins ALWAYS have access
    if IsSuperAdmin(source) then
        if Config.Debug then
            print(string.format("^2[Haus-Manager]^7 Player %s has admin access (Super Admin)", GetPlayerName(source)))
        end
        return true
    end
    
    -- Otherwise check framework permissions
    local hasPermission = FrameworkServer.HasPermission(source, Config.AdminGroup)
    if Config.Debug then
        print(string.format("^2[Haus-Manager]^7 Player %s has admin access: %s (Framework)", GetPlayerName(source), tostring(hasPermission)))
    end
    return hasPermission
end

-- Create new property
RegisterNetEvent('haus-manager:server:createProperty', function(data)
    local src = source
    
    if not IsAdmin(src) then
        local Player = FrameworkServer.GetPlayer(src)
        if Player then
            TriggerClientEvent('QBCore:Notify', src, Config.Notifications["no_permission"], 'error')
        end
        return
    end
    
    local propertyId = CreateProperty(data)
    
    if propertyId then
        TriggerClientEvent('QBCore:Notify', src, "Immobilie erfolgreich erstellt!", 'success')
        TriggerClientEvent('haus-manager:client:updateProperties', -1, GetAllProperties())
    else
        TriggerClientEvent('QBCore:Notify', src, "Fehler beim Erstellen der Immobilie!", 'error')
    end
end)

-- Update property
RegisterNetEvent('haus-manager:server:updateProperty', function(propertyId, data)
    local src = source
    
    if not IsAdmin(src) then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications["no_permission"], 'error')
        return
    end
    
    local success = UpdateProperty(propertyId, data)
    
    if success then
        TriggerClientEvent('QBCore:Notify', src, "Immobilie aktualisiert!", 'success')
        TriggerClientEvent('haus-manager:client:updateProperties', -1, GetAllProperties())
        
        -- If safe or wardrobe coordinates were updated, refresh interior markers for players in this property
        if data.safeCoords or data.wardrobeCoords then
            local updatedProperty = GetPropertyById(propertyId)
            if updatedProperty then
                -- Send update to ALL clients to refresh safe/wardrobe if they're in this property
                TriggerClientEvent('haus-manager:client:refreshInteriorMarkers', -1, propertyId, updatedProperty)
            end
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "Fehler beim Aktualisieren der Immobilie!", 'error')
    end
end)

-- Delete property
RegisterNetEvent('haus-manager:server:deleteProperty', function(propertyId)
    local src = source
    
    if not IsAdmin(src) then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications["no_permission"], 'error')
        return
    end
    
    print("^3[Haus-Manager Server]^7 Deleting property: " .. propertyId)
    
    -- FIRST: Trigger deletion event so clients can remove zones/markers immediately
    TriggerClientEvent('haus-manager:client:propertyDeleted', -1, propertyId)
    
    -- Wait a tiny bit to ensure clients process the deletion
    Wait(50)
    
    -- THEN: Delete from database
    DeleteProperty(propertyId)
    
    -- FINALLY: Send updated property list (without the deleted property)
    local updatedProperties = GetAllProperties()
    TriggerClientEvent('haus-manager:client:updateProperties', -1, updatedProperties)
    
    print("^2[Haus-Manager Server]^7 Property deleted successfully: " .. propertyId)
    TriggerClientEvent('QBCore:Notify', src, "Immobilie erfolgreich gelöscht!", 'success')
end)

-- Get all properties callback
CreateThread(function()
    FrameworkServer.WaitForReady()
    
    FrameworkServer.CreateCallback('haus-manager:server:getAllProperties', function(source, cb)
        cb(GetAllProperties())
    end)
    
    -- Get player properties callback
    FrameworkServer.CreateCallback('haus-manager:server:getPlayerProperties', function(source, cb)
        local Player = FrameworkServer.GetPlayer(source)
        if not Player then
            cb({})
            return
        end
        
        local properties = GetPropertiesByOwner(FrameworkServer.GetPlayerIdentifier(Player))
        cb(properties)
    end)
    
    -- Check if player is admin callback
    FrameworkServer.CreateCallback('haus-manager:server:isAdmin', function(source, cb)
        cb(IsAdmin(source))
    end)
    
    -- Get nearby players callback
    FrameworkServer.CreateCallback('haus-manager:server:getNearbyPlayers', function(source, cb, radius)
        local src = source
        local plyCoords = GetEntityCoords(GetPlayerPed(src))
        local players = {}
        
        for _, playerId in ipairs(GetPlayers()) do
            local targetPed = GetPlayerPed(playerId)
            local targetCoords = GetEntityCoords(targetPed)
            local distance = #(plyCoords - targetCoords)
            
            if playerId ~= tostring(src) and distance <= (radius or 3.0) then
                local Player = FrameworkServer.GetPlayer(tonumber(playerId))
                if Player then
                    table.insert(players, {
                        id = tonumber(playerId),
                        name = FrameworkServer.GetPlayerName(Player),
                        citizenid = FrameworkServer.GetPlayerIdentifier(Player)
                    })
                end
            end
        end
        
        cb(players)
    end)
end)

-- Resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    print("^2[Haus-Manager]^7 Starting Property Management System...")
    
    -- Load all properties and send to all clients
    Wait(1000)
    local properties = GetAllProperties()
    TriggerClientEvent('haus-manager:client:updateProperties', -1, properties)
    
    print(string.format("^2[Haus-Manager]^7 Loaded %d properties", #properties))
end)

-- Player loaded event
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    local properties = GetAllProperties()
    TriggerClientEvent('haus-manager:client:updateProperties', src, properties)
end)

-- Command to open admin UI
FrameworkServer.RegisterCommand('hausadmin', 'Öffne Immobilien-Verwaltung (Nur Admin)', {}, false, function(source)
    local src = source
    
    if not IsAdmin(src) then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications["no_permission"], 'error')
        return
    end
    
    TriggerClientEvent('haus-manager:client:openAdminUI', src)
end, Config.AdminGroup)

print("^2[Haus-Manager Commands]^7 Command /hausadmin registered")

-- Command to open garage UI
FrameworkServer.RegisterCommand('hausgarage', 'Öffne Garagen-Verwaltung (Nur Admin)', {}, false, function(source)
    local src = source
    
    if not IsAdmin(src) then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications["no_permission"], 'error')
        return
    end
    
    TriggerClientEvent('haus-manager:client:openGarageUI', src)
end, Config.AdminGroup)

print("^2[Haus-Manager Commands]^7 Command /hausgarage registered")

-- Debug command
if Config.Debug then
    FrameworkServer.RegisterCommand('hausdebug', 'Show property debug info', {}, false, function(source)
        local src = source
        local properties = GetAllProperties()
        
        print("^3=== Haus-Manager Debug Info ===^7")
        print(string.format("Total properties: %d", #properties))
        
        for _, property in ipairs(properties) do
            print(string.format("- %s (%s) | Owner: %s | Price: $%d", 
                property.property_name,
                property.property_type,
                property.owner_identifier or "None",
                property.price
            ))
        end
        
        TriggerClientEvent('QBCore:Notify', src, "Check server console for debug info", 'primary')
    end, 'admin')
    
    print("^2[Haus-Manager Commands]^7 Command /hausdebug registered (Debug mode enabled)")
end

-- Print command registration summary
print("^2[Haus-Manager]^7 All commands registered successfully!")
print("^2[Haus-Manager]^7 Available commands:")
print("^2[Haus-Manager]^7 - /hausadmin (Admin only)")
print("^2[Haus-Manager]^7 - /hausgarage (Admin only)")
if Config.Debug then
    print("^2[Haus-Manager]^7 - /hausdebug (Debug mode)")
end
