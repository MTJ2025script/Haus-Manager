-- Property management server functions
-- Uses Framework Bridge for multi-framework support

-- Get safe items from database
local function GetSafeItems(stashName)
    local result = MySQL.query.await('SELECT items FROM haus_safe_storage WHERE stash_name = ?', {stashName})
    if result and result[1] then
        return json.decode(result[1].items) or {}
    end
    return {}
end

-- Save safe items to database
local function SaveSafeItems(propertyId, ownerIdentifier, stashName, items)
    local itemsJson = json.encode(items)
    MySQL.query([[
        INSERT INTO haus_safe_storage (property_id, owner_identifier, stash_name, items) 
        VALUES (?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE 
            items = VALUES(items),
            updated_at = CURRENT_TIMESTAMP
    ]], {propertyId, ownerIdentifier, stashName, itemsJson})
end

-- Export functions for use by inventory systems
exports('GetSafeItems', GetSafeItems)
exports('SaveSafeItems', SaveSafeItems)

-- Store vehicle in property garage
RegisterNetEvent('haus-manager:server:storeVehicle', function(propertyId, plate, vehicleData)
    local src = source
    local Player = FrameworkServer.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has access to property
    local property = GetPropertyById(propertyId)
    if not property then return end
    
    local hasAccess = property.owner_identifier == FrameworkServer.GetPlayerIdentifier(Player) or 
                     HasPropertyKey(propertyId, FrameworkServer.GetPlayerIdentifier(Player))
    
    if not hasAccess then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications["no_permission"], 'error')
        return
    end
    
    -- Check garage capacity
    local garageSize = property.garage_size
    if not garageSize then
        TriggerClientEvent('QBCore:Notify', src, "Diese Immobilie hat keine Garage!", 'error')
        return
    end
    
    local citizenid = FrameworkServer.GetPlayerIdentifier(Player)
    local maxSlots = Config.GarageSizes[garageSize].slots
    local currentVehicles = MySQL.query.await([[
        SELECT COUNT(*) as count FROM haus_garage_vehicles 
        WHERE property_id = ? AND citizen_id = ?
    ]], {propertyId, citizenid})
    
    if currentVehicles[1].count >= maxSlots then
        TriggerClientEvent('QBCore:Notify', src, "Garage ist voll!", 'error')
        return
    end
    
    -- Store vehicle
    MySQL.insert.await([[
        INSERT INTO haus_garage_vehicles (property_id, citizen_id, plate, vehicle_data, stored)
        VALUES (?, ?, ?, ?, 1)
        ON DUPLICATE KEY UPDATE vehicle_data = ?, stored = 1
    ]], {propertyId, citizenid, plate, json.encode(vehicleData), json.encode(vehicleData)})
    
    TriggerClientEvent('QBCore:Notify', src, "Fahrzeug eingelagert!", 'success')
end)

-- Spawn vehicle from garage
RegisterNetEvent('haus-manager:server:spawnVehicle', function(propertyId, plate)
    local src = source
    local Player = FrameworkServer.GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player has access to property
    local property = GetPropertyById(propertyId)
    if not property then return end
    
    local hasAccess = property.owner_identifier == FrameworkServer.GetPlayerIdentifier(Player) or 
                     HasPropertyKey(propertyId, FrameworkServer.GetPlayerIdentifier(Player))
    
    if not hasAccess then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications["no_permission"], 'error')
        return
    end
    
    -- Get vehicle data
    local result = MySQL.query.await([[
        SELECT * FROM haus_garage_vehicles 
        WHERE property_id = ? AND plate = ? AND stored = 1
    ]], {propertyId, plate})
    
    if not result or #result == 0 then
        TriggerClientEvent('QBCore:Notify', src, "Fahrzeug nicht gefunden!", 'error')
        return
    end
    
    -- Mark as not stored
    MySQL.query.await([[
        UPDATE haus_garage_vehicles SET stored = 0 
        WHERE property_id = ? AND plate = ?
    ]], {propertyId, plate})
    
    -- Spawn vehicle on client
    local vehicleData = json.decode(result[1].vehicle_data)
    TriggerClientEvent('haus-manager:client:spawnVehicle', src, vehicleData, json.decode(property.garage_coords))
end)

-- Get garage vehicles callback
CreateThread(function()
    FrameworkServer.WaitForReady()
    
    FrameworkServer.CreateCallback('haus-manager:server:getGarageVehicles', function(source, cb, propertyId)
        local Player = FrameworkServer.GetPlayer(source)
        if not Player then
            cb({})
            return
        end
        
        local vehicles = MySQL.query.await([[
            SELECT * FROM haus_garage_vehicles WHERE property_id = ?
        ]], {propertyId})
        
        cb(vehicles or {})
    end)
    
    -- Check if player has access to property (for safes/wardrobes/garages)
    FrameworkServer.CreateCallback('haus-manager:server:hasPropertyAccess', function(source, cb, propertyId)
        local Player = FrameworkServer.GetPlayer(source)
        if not Player then
            cb(false)
            return
        end
        
        -- Admins have access to all properties
        if FrameworkServer.HasPermission(source, Config.AdminGroup) then
            cb(true)
            return
        end
        
        local property = GetPropertyById(propertyId)
        if not property then
            cb(false)
            return
        end
        
        -- Owner or keyholder has access
        local hasAccess = property.owner_identifier == FrameworkServer.GetPlayerIdentifier(Player) or 
                         HasPropertyKey(propertyId, FrameworkServer.GetPlayerIdentifier(Player))
        
        cb(hasAccess)
    end)
end)

-- Open property safe (register and open stash)
RegisterNetEvent('haus-manager:server:openSafe', function(propertyId)
    local src = source
    local Player = FrameworkServer.GetPlayer(src)
    
    if Config.Debug then
        print(string.format("^3[Haus-Manager Safe]^7 Player %s attempting to open safe for property: %s", src, propertyId))
    end
    
    if not Player then
        if Config.Debug then
            print(string.format("^1[Haus-Manager Safe]^7 ERROR: Player object not found for source %s", src))
        end
        return
    end
    
    -- Check if player has access to property
    local property = GetPropertyById(propertyId)
    if not property then
        TriggerClientEvent('QBCore:Notify', src, 'Immobilie nicht gefunden!', 'error')
        if Config.Debug then
            print(string.format("^1[Haus-Manager Safe]^7 ERROR: Property %s not found in database", propertyId))
        end
        return
    end
    
    local hasAccess = property.owner_identifier == FrameworkServer.GetPlayerIdentifier(Player) or 
                     HasPropertyKey(propertyId, FrameworkServer.GetPlayerIdentifier(Player))
    
    if not hasAccess then
        TriggerClientEvent('QBCore:Notify', src, 'Sie haben keinen Zugriff auf diesen Tresor!', 'error')
        if Config.Debug then
            print(string.format("^1[Haus-Manager Safe]^7 ERROR: Player %s (citizenid: %s) has no access to property %s (owner: %s)", 
                src, FrameworkServer.GetPlayerIdentifier(Player), propertyId, property.owner_identifier or "none"))
        end
        return
    end
    
    -- Create UNIQUE stash name per owner (each owner has their own safe storage)
    -- Format: "property_safe_PROPERTYID_OWNERID"
    local ownerCitizenId = property.owner_identifier
    local stashName = string.format("property_safe_%s_%s", propertyId, ownerCitizenId)
    
    if Config.Debug then
        print(string.format("^3[Haus-Manager Safe]^7 Access granted. Stash name: %s", stashName))
    end
    
    -- Ensure safe storage entry exists in database
    MySQL.query([[
        INSERT IGNORE INTO haus_safe_storage (property_id, owner_identifier, stash_name, items) 
        VALUES (?, ?, ?, '[]')
    ]], {propertyId, ownerCitizenId, stashName})
    
    -- Check which inventory system is available
    if GetResourceState('qb-inventory') == 'started' then
        if Config.Debug then
            print(string.format("^3[Haus-Manager Safe]^7 Using QB-Inventory system"))
        end
        
        -- QB-Inventory: Use server-side event to open stash
        -- This is the correct method for QB-Inventory stash handling
        TriggerEvent('qb-inventory:server:OpenInventory', 'stash', stashName, {
            maxweight = 1000000,
            slots = 50,
            label = string.format("Tresor: %s", property.property_name)
        })
        
        -- Open the inventory for the player
        TriggerClientEvent('qb-inventory:client:OpenInventory', src, 'stash', stashName)
        
        TriggerClientEvent('QBCore:Notify', src, 'Tresor geöffnet', 'success')
        if Config.Debug then
            print(string.format("^2[Haus-Manager Safe]^7 Successfully opened QB-Inventory stash '%s' for player %s (owner: %s)", 
                stashName, src, ownerCitizenId))
        end
    elseif GetResourceState('ox_inventory') == 'started' then
        if Config.Debug then
            print(string.format("^3[Haus-Manager Safe]^7 Using OX-Inventory system"))
        end
        
        -- OX-Inventory: Register stash per owner
        exports.ox_inventory:RegisterStash(stashName, string.format("Tresor: %s (Eigentümer)", property.property_name), 50, 1000000, ownerCitizenId)
        
        -- Client will open it
        TriggerClientEvent('haus-manager:client:openOxSafe', src, stashName)
        TriggerClientEvent('QBCore:Notify', src, 'Tresor geöffnet', 'success')
        if Config.Debug then
            print(string.format("^2[Haus-Manager Safe]^7 Successfully opened OX-Inventory stash '%s' for player %s (owner: %s)", 
                stashName, src, ownerCitizenId))
        end
    else
        TriggerClientEvent('QBCore:Notify', src, 'Kein Inventory-System gefunden!', 'error')
        if Config.Debug then
            print(string.format("^1[Haus-Manager Safe]^7 ERROR: No inventory system found (qb-inventory or ox_inventory)"))
        end
    end
end)

