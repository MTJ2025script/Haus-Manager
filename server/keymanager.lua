-- ████████████████████████████████████████████████████████████████████████████████
-- █─█──██▀▄─██▄─██─▄█─▄▄▄▄███▀▄─██▄─▀█▄─▄██▀▄─██▄─▄▄▀█▄─▄▄─█▄─▄▄▀█
-- █─▄▀███─▀─███─██─██▄▄▄▄─███─▀─███─█▄▀─███─▀─███─▄─▄██─▄█▀██─▄─▄█
-- ▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▄▄▀▀▀▄▄▀▄▄▀▄▄▄▀▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▄▄▄▀▄▄▀▄▄▀
-- 
-- Comprehensive Key Management System
-- Handles permanent and temporary keys with automatic expiration
-- ████████████████████████████████████████████████████████████████████████████████

-- Uses Framework Bridge for multi-framework support

-- ═══════════════════════════════════════════════════════════════════════════════
-- GRANT TEMPORARY KEY
-- ═══════════════════════════════════════════════════════════════════════════════
RegisterNetEvent('haus-manager:server:grantTemporaryKey', function(propertyId, targetId, hours)
    local src = source
    local Player = FrameworkServer.GetPlayer(src)
    local Target = FrameworkServer.GetPlayer(targetId)
    
    if not Player or not Target then
        TriggerClientEvent('QBCore:Notify', src, 'Spieler nicht gefunden', 'error')
        return
    end
    
    -- Get property to verify ownership
    local property = GetPropertyById(propertyId)
    if not property then
        TriggerClientEvent('QBCore:Notify', src, 'Immobilie nicht gefunden', 'error')
        return
    end
    
    -- Verify player is owner
    if property.owner_identifier ~= FrameworkServer.GetPlayerIdentifier(Player) then
        TriggerClientEvent('QBCore:Notify', src, 'Sie sind nicht der Eigentümer', 'error')
        return
    end
    
    -- Calculate expiration time in seconds from now
    local expiresAtSeconds = os.time() + (hours * 3600)
    
    -- Grant the temporary key - use FROM_UNIXTIME to convert to MySQL TIMESTAMP
    MySQL.query.await([[
        INSERT INTO haus_keys (property_id, citizen_id, granted_by, key_type, expires_at)
        VALUES (?, ?, ?, 'temporary', FROM_UNIXTIME(?))
        ON DUPLICATE KEY UPDATE 
            key_type = 'temporary',
            expires_at = FROM_UNIXTIME(?),
            granted_at = CURRENT_TIMESTAMP
    ]], {propertyId, FrameworkServer.GetPlayerIdentifier(Target), FrameworkServer.GetPlayerIdentifier(Player), expiresAtSeconds, expiresAtSeconds})
    
    -- Refresh keys for target player
    local targetKeys = GetPlayerKeys(FrameworkServer.GetPlayerIdentifier(Target))
    TriggerClientEvent('haus-manager:client:updateKeys', targetId, targetKeys)
    
    -- Send notification to both players
    TriggerClientEvent('QBCore:Notify', src, 
        'Temporärer Schlüssel vergeben an ' .. Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname .. ' (' .. hours .. 'h)', 
        'success')
    
    -- Send mini-UI notification to target player (expires_at in milliseconds for JS)
    TriggerClientEvent('haus-manager:client:showKeyNotification', targetId, {
        propertyName = property.property_name,
        hours = hours,
        expiresAt = expiresAtSeconds * 1000,  -- Convert to milliseconds for JavaScript
        grantedBy = FrameworkServer.GetPlayerName(Player)
    })
    
    print(string.format('^2[Haus-Manager KeyManager] Temporary key granted: property=%s, holder=%s, hours=%d^7', 
        propertyId, FrameworkServer.GetPlayerIdentifier(Target), hours))
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- GRANT PERMANENT KEY
-- ═══════════════════════════════════════════════════════════════════════════════
RegisterNetEvent('haus-manager:server:grantPermanentKey', function(propertyId, targetId)
    local src = source
    local Player = FrameworkServer.GetPlayer(src)
    local Target = FrameworkServer.GetPlayer(targetId)
    
    if not Player or not Target then
        TriggerClientEvent('QBCore:Notify', src, 'Spieler nicht gefunden', 'error')
        return
    end
    
    -- Get property to verify ownership
    local property = GetPropertyById(propertyId)
    if not property then
        TriggerClientEvent('QBCore:Notify', src, 'Immobilie nicht gefunden', 'error')
        return
    end
    
    -- Verify player is owner
    if property.owner_identifier ~= FrameworkServer.GetPlayerIdentifier(Player) then
        TriggerClientEvent('QBCore:Notify', src, 'Sie sind nicht der Eigentümer', 'error')
        return
    end
    
    -- Grant the permanent key
    MySQL.query.await([[
        INSERT INTO haus_keys (property_id, citizen_id, granted_by, key_type, expires_at)
        VALUES (?, ?, ?, 'permanent', NULL)
        ON DUPLICATE KEY UPDATE 
            key_type = 'permanent',
            expires_at = NULL,
            granted_at = CURRENT_TIMESTAMP
    ]], {propertyId, FrameworkServer.GetPlayerIdentifier(Target), FrameworkServer.GetPlayerIdentifier(Player)})
    
    -- Refresh keys for target player
    local targetKeys = GetPlayerKeys(FrameworkServer.GetPlayerIdentifier(Target))
    TriggerClientEvent('haus-manager:client:updateKeys', targetId, targetKeys)
    
    -- Send notifications
    TriggerClientEvent('QBCore:Notify', src, 
        'Permanenter Schlüssel vergeben an ' .. Target.PlayerData.charinfo.firstname .. ' ' .. Target.PlayerData.charinfo.lastname, 
        'success')
    TriggerClientEvent('QBCore:Notify', targetId, 
        'Sie haben einen permanenten Schlüssel für ' .. property.property_name .. ' erhalten', 
        'success')
    
    print(string.format('^2[Haus-Manager KeyManager] Permanent key granted: property=%s, holder=%s^7', 
        propertyId, FrameworkServer.GetPlayerIdentifier(Target)))
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- REVOKE KEY
-- ═══════════════════════════════════════════════════════════════════════════════
RegisterNetEvent('haus-manager:server:revokeKey', function(propertyId, targetCitizenId)
    local src = source
    local Player = FrameworkServer.GetPlayer(src)
    
    if not Player then return end
    
    -- Get property to verify ownership
    local property = GetPropertyById(propertyId)
    if not property then
        TriggerClientEvent('QBCore:Notify', src, 'Immobilie nicht gefunden', 'error')
        return
    end
    
    -- Verify player is owner
    if property.owner_identifier ~= FrameworkServer.GetPlayerIdentifier(Player) then
        TriggerClientEvent('QBCore:Notify', src, 'Sie sind nicht der Eigentümer', 'error')
        return
    end
    
    -- Don't allow owner to revoke their own key
    if targetCitizenId == FrameworkServer.GetPlayerIdentifier(Player) then
        TriggerClientEvent('QBCore:Notify', src, 'Sie können Ihren eigenen Schlüssel nicht entziehen', 'error')
        return
    end
    
    -- Revoke the key
    local result = MySQL.query.await('DELETE FROM haus_keys WHERE property_id = ? AND citizen_id = ?', 
        {propertyId, targetCitizenId})
    
    if result.affectedRows > 0 then
        -- Find the target player if online and update their keys
        local Target = FrameworkServer.GetPlayerByCitizenId(targetCitizenId)
        if Target then
            local targetKeys = GetPlayerKeys(targetCitizenId)
            local targetSource = FrameworkServer.GetPlayerSource(Target)
            TriggerClientEvent('haus-manager:client:updateKeys', targetSource, targetKeys)
            TriggerClientEvent('QBCore:Notify', targetSource, 
                'Ihr Schlüssel für ' .. property.property_name .. ' wurde entzogen', 
                'error')
            
            -- Kick them out if they're inside
            TriggerClientEvent('haus-manager:client:exitProperty', targetSource, propertyId)
        end
        
        TriggerClientEvent('QBCore:Notify', src, 'Schlüssel erfolgreich entzogen', 'success')
        
        print(string.format('^2[Haus-Manager KeyManager] Key revoked: property=%s, holder=%s^7', 
            propertyId, targetCitizenId))
    else
        TriggerClientEvent('QBCore:Notify', src, 'Schlüssel nicht gefunden', 'error')
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- GET PROPERTY KEYS WITH HOLDER INFORMATION
-- ═══════════════════════════════════════════════════════════════════════════════
CreateThread(function()
    FrameworkServer.WaitForReady()
    
    FrameworkServer.CreateCallback('haus-manager:server:getPropertyKeys', function(source, cb, propertyId)
        local src = source
        local Player = FrameworkServer.GetPlayer(src)
        
        if not Player then 
            cb(nil)
            return 
        end
        
        -- Get property to verify ownership
        local property = GetPropertyById(propertyId)
        if not property or property.owner_identifier ~= FrameworkServer.GetPlayerIdentifier(Player) then
            cb(nil)
            return
        end
        
        -- Get all keys for this property
        -- Try query with new columns first (for migrated databases)
    local success, keys = pcall(function()
        return MySQL.query.await([[
            SELECT 
                k.id,
                k.citizen_id,
                k.granted_by,
                k.key_type,
                k.granted_at,
                k.expires_at,
                CASE 
                    WHEN k.expires_at IS NULL THEN NULL
                    WHEN k.expires_at > NOW() THEN TIMESTAMPDIFF(SECOND, NOW(), k.expires_at)
                    ELSE 0
                END as seconds_remaining
            FROM haus_keys k
            WHERE k.property_id = ?
            AND (k.key_type = 'permanent' OR (k.key_type = 'temporary' AND (k.expires_at IS NULL OR k.expires_at > NOW())))
            ORDER BY k.key_type DESC, k.granted_at DESC
        ]], {propertyId})
    end)
    
    -- If query failed (columns don't exist), fall back to simple query
    if not success then
        print("^3[Haus-Manager KeyManager]^7 Warning: key_type/expires_at columns missing, using fallback query")
        keys = MySQL.query.await([[
            SELECT 
                k.id,
                k.citizen_id,
                k.granted_by,
                k.granted_at
            FROM haus_keys k
            WHERE k.property_id = ?
            ORDER BY k.granted_at DESC
        ]], {propertyId})
    end
    
    if not keys then
        cb({})
        return
    end
    
    -- Enrich with player information
    local enrichedKeys = {}
    for _, key in ipairs(keys) do
        local holderName = 'Unbekannt'
        
        -- ESX vs QB-Core player name query
        if FrameworkServer.Type == 'esx' then
            -- ESX: users table with identifier
            local holderData = MySQL.query.await(
                'SELECT firstname, lastname FROM users WHERE identifier = ?', 
                {key.citizen_id}
            )
            
            if holderData and holderData[1] then
                holderName = (holderData[1].firstname or '') .. ' ' .. (holderData[1].lastname or '')
            end
        else
            -- QB-Core: players table with citizenid
            local holderData = MySQL.query.await(
                'SELECT charinfo FROM players WHERE citizenid = ?', 
                {key.citizen_id}
            )
            
            if holderData and holderData[1] then
                local charinfo = json.decode(holderData[1].charinfo)
                if charinfo then
                    holderName = charinfo.firstname .. ' ' .. charinfo.lastname
                end
            end
        end
        
        table.insert(enrichedKeys, {
            id = key.id,
            citizenId = key.citizen_id,
            holderName = holderName,
            keyType = key.key_type or 'permanent', -- Default to permanent if column doesn't exist
            grantedAt = key.granted_at,
            expiresAt = key.expires_at,
            secondsRemaining = key.seconds_remaining,
            isOwner = (key.citizen_id == property.owner_identifier)
        })
    end
    
    cb(enrichedKeys)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- AUTO-CLEANUP EXPIRED KEYS (Background Job)
-- ═══════════════════════════════════════════════════════════════════════════════
local function CleanupExpiredKeys()
    -- Try cleanup with new columns (for migrated databases)
    local success, expiredKeys = pcall(function()
        return MySQL.query.await([[
            SELECT k.property_id, k.citizen_id, p.property_name
            FROM haus_keys k
            LEFT JOIN haus_properties p ON k.property_id = p.property_id
            WHERE k.key_type = 'temporary' 
            AND k.expires_at IS NOT NULL 
            AND k.expires_at <= NOW()
        ]], {})
    end)
    
    -- If query failed (columns don't exist), skip cleanup
    if not success then
        return
    end
    
    if expiredKeys and #expiredKeys > 0 then
        -- Delete expired keys
        local result = MySQL.query.await([[
            DELETE FROM haus_keys 
            WHERE key_type = 'temporary' 
            AND expires_at IS NOT NULL 
            AND expires_at <= NOW()
        ]], {})
        
        print(string.format('^3[Haus-Manager KeyManager] Cleaned up %d expired temporary keys^7', 
            result.affectedRows or 0))
        
        -- Notify affected players if they're online
        for _, key in ipairs(expiredKeys) do
            local Player = FrameworkServer.GetPlayerByCitizenId(key.citizen_id)
            if Player then
                local playerKeys = GetPlayerKeys(key.citizen_id)
                TriggerClientEvent('haus-manager:client:updateKeys', FrameworkServer.GetPlayerSource(Player), playerKeys)
                TriggerClientEvent('QBCore:Notify', FrameworkServer.GetPlayerSource(Player), 
                    'Ihr temporärer Schlüssel für ' .. (key.property_name or 'Immobilie') .. ' ist abgelaufen', 
                    'error')
                
                -- Kick them out if they're inside
                TriggerClientEvent('haus-manager:client:exitProperty', FrameworkServer.GetPlayerSource(Player), key.property_id)
            end
        end
    end
end

-- Run cleanup every 5 minutes
CreateThread(function()
    while true do
        Wait(300000) -- 5 minutes
        CleanupExpiredKeys()
    end
end)

-- Run cleanup on resource start
CleanupExpiredKeys()

-- ═══════════════════════════════════════════════════════════════════════════════
-- GET CURRENT SERVER TIME (For client HUD)
-- ═══════════════════════════════════════════════════════════════════════════════
    FrameworkServer.CreateCallback('haus-manager:server:getCurrentTime', function(source, cb)
        cb(os.time() * 1000) -- Return current time in milliseconds
    end)
end)

print('^2[Haus-Manager KeyManager] Key Management System loaded successfully^7')
