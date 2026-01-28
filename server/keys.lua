-- Key management system
-- Uses Framework Bridge for multi-framework support

-- Get keys for a property
function GetPropertyKeys(propertyId)
    -- Try query with new columns first (for migrated databases)
    local success, result = pcall(function()
        return MySQL.query.await([[
            SELECT * FROM haus_keys 
            WHERE property_id = ? 
            AND (key_type = 'permanent' OR (key_type = 'temporary' AND (expires_at IS NULL OR expires_at > NOW())))
        ]], {propertyId})
    end)
    
    -- If query failed (columns don't exist), fall back to simple query
    if not success then
        print("^3[Haus-Manager Keys]^7 Warning: key_type/expires_at columns missing, using fallback query")
        result = MySQL.query.await([[
            SELECT * FROM haus_keys 
            WHERE property_id = ?
        ]], {propertyId})
    end
    
    return result or {}
end

-- Check if player has key
function HasPropertyKey(propertyId, citizenId)
    -- Try query with new columns first (for migrated databases)
    local success, result = pcall(function()
        return MySQL.query.await([[
            SELECT COUNT(*) as count FROM haus_keys 
            WHERE property_id = ? AND citizen_id = ?
            AND (key_type = 'permanent' OR (key_type = 'temporary' AND (expires_at IS NULL OR expires_at > NOW())))
        ]], {propertyId, citizenId})
    end)
    
    -- If query failed (columns don't exist), fall back to simple query
    if not success then
        print("^3[Haus-Manager Keys]^7 Warning: key_type/expires_at columns missing, using fallback query")
        result = MySQL.query.await([[
            SELECT COUNT(*) as count FROM haus_keys 
            WHERE property_id = ? AND citizen_id = ?
        ]], {propertyId, citizenId})
    end
    
    return result and result[1] and result[1].count > 0
end

-- Give key to player
function GivePropertyKey(propertyId, citizenId, grantedBy)
    print(string.format("^3[Haus-Manager]^7 GivePropertyKey called: propertyId=%s, citizenId=%s, grantedBy=%s", 
        tostring(propertyId), tostring(citizenId), tostring(grantedBy)))
    
    -- Check if property exists
    local property = GetPropertyById(propertyId)
    if not property then
        print("^1[Haus-Manager]^7 GivePropertyKey: Property not found!")
        return false, "property_not_found"
    end
    
    -- Get max keys for property type
    local propertyType = property.property_type
    local typeConfig = Config.PropertyTypes[propertyType]
    local maxKeys = typeConfig and typeConfig.maxKeys or 5
    
    -- Check current key count
    local keys = GetPropertyKeys(propertyId)
    if #keys >= maxKeys then
        print("^1[Haus-Manager]^7 GivePropertyKey: Max keys reached!")
        return false, "max_keys_reached"
    end
    
    -- Check if player already has key
    if HasPropertyKey(propertyId, citizenId) then
        print("^1[Haus-Manager]^7 GivePropertyKey: Player already has key!")
        return false, "already_has_key"
    end
    
    -- Give key - INSERT into database
    print("^2[Haus-Manager]^7 Inserting key into database...")
    local insertResult = MySQL.insert.await([[
        INSERT INTO haus_keys (property_id, citizen_id, granted_by)
        VALUES (?, ?, ?)
    ]], {propertyId, citizenId, grantedBy})
    
    if insertResult then
        print(string.format("^2[Haus-Manager]^7 Key successfully inserted! Insert ID: %s", tostring(insertResult)))
        return true
    else
        print("^1[Haus-Manager]^7 Failed to insert key into database!")
        return false, "database_error"
    end
end

-- Remove key from player
function RemovePropertyKey(propertyId, citizenId)
    MySQL.query.await([[
        DELETE FROM haus_keys WHERE property_id = ? AND citizen_id = ?
    ]], {propertyId, citizenId})
    
    return true
end

-- Get all keys for a player
function GetPlayerKeys(citizenId)
    -- Try query with new columns first (for migrated databases)
    local success, result = pcall(function()
        return MySQL.query.await([[
            SELECT k.*, p.property_name, p.property_type, p.coords
            FROM haus_keys k
            JOIN haus_properties p ON k.property_id = p.property_id
            WHERE k.citizen_id = ?
            AND (k.key_type = 'permanent' OR (k.key_type = 'temporary' AND (k.expires_at IS NULL OR k.expires_at > NOW())))
        ]], {citizenId})
    end)
    
    -- If query failed (columns don't exist), fall back to simple query
    if not success then
        print("^3[Haus-Manager Keys]^7 Warning: key_type/expires_at columns missing, using fallback query")
        result = MySQL.query.await([[
            SELECT k.*, p.property_name, p.property_type, p.coords
            FROM haus_keys k
            JOIN haus_properties p ON k.property_id = p.property_id
            WHERE k.citizen_id = ?
        ]], {citizenId})
    end
    
    return result or {}
end

-- NOTE: Old giveKey and removeKey events have been removed
-- Use the new key management system in server/keymanager.lua:
-- - grantTemporaryKey: for temporary keys with expiration
-- - grantPermanentKey: for permanent keys
-- - revokeKey: to revoke any key (temporary or permanent)

-- Get player keys callback
CreateThread(function()
    FrameworkServer.WaitForReady()
    
    FrameworkServer.CreateCallback('haus-manager:server:getPlayerKeys', function(source, cb)
        local Player = FrameworkServer.GetPlayer(source)
        if not Player then
            cb({})
            return
        end
        
        local keys = GetPlayerKeys(FrameworkServer.GetPlayerIdentifier(Player))
        cb(keys)
    end)
    
    -- Check if player has key callback
    FrameworkServer.CreateCallback('haus-manager:server:hasKey', function(source, cb, propertyId)
        local Player = FrameworkServer.GetPlayer(source)
        if not Player then
            cb(false)
            return
        end
        
        cb(HasPropertyKey(propertyId, FrameworkServer.GetPlayerIdentifier(Player)))
    end)
end)

-- Export functions
exports('GetPropertyKeys', GetPropertyKeys)
exports('HasPropertyKey', HasPropertyKey)
exports('GivePropertyKey', GivePropertyKey)
exports('RemovePropertyKey', RemovePropertyKey)
exports('GetPlayerKeys', GetPlayerKeys)

-- Doorbell system
RegisterNetEvent('haus-manager:server:ringDoorbell', function(data)
    local src = source
    local Player = FrameworkServer.GetPlayer(src)
    
    if not Player then return end
    
    local propertyId = data.propertyId
    local property = GetPropertyById(propertyId)
    
    if not property or not property.owner_identifier then
        TriggerClientEvent('QBCore:Notify', src, "Niemand ist zu Hause!", 'error')
        return
    end
    
    -- Find owner online
    local ownerPlayer = FrameworkServer.GetPlayerByCitizenId(property.owner_identifier)
    
    if not ownerPlayer then
        TriggerClientEvent('QBCore:Notify', src, "Niemand ist zu Hause!", 'error')
        return
    end
    
    -- Notify visitor
    TriggerClientEvent('QBCore:Notify', src, "Sie haben geklingelt!", 'success')
    
    -- Notify owner with doorbell alert
    TriggerClientEvent('haus-manager:client:doorbellRang', FrameworkServer.GetPlayerSource(ownerPlayer), {
        propertyName = property.property_name,
        propertyId = property.property_id,
        visitorName = FrameworkServer.GetPlayerName(Player),
        visitorId = src
    })
end)

-- Handle doorbell response (owner invites visitor)
RegisterNetEvent('haus-manager:server:inviteVisitor', function(data)
    local src = source
    local Player = FrameworkServer.GetPlayer(src)
    local visitorId = data.visitorId
    local propertyId = data.propertyId
    
    if not Player then return end
    
    -- Verify owner
    local property = GetPropertyById(propertyId)
    if not property or property.owner_identifier ~= Player.PlayerData.citizenid then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications["no_permission"], 'error')
        return
    end
    
    -- Grant temporary access to visitor
    TriggerClientEvent('haus-manager:client:grantedEntry', visitorId, property)
    TriggerClientEvent('QBCore:Notify', visitorId, 
        string.format("Sie wurden zu %s eingelassen!", property.property_name), 'success')
    TriggerClientEvent('QBCore:Notify', src, "Besucher wurde eingelassen!", 'success')
end)
