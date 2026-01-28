-- ████████████████████████████████████████████████████████████████████████████████
-- █─█──██▀▄─██▄─██─▄█─▄▄▄▄███▀▄─██▄─▀█▄─▄██▀▄─██▄─▄▄▀█▄─▄▄─█▄─▄▄▀█
-- █─▄▀███─▀─███─██─██▄▄▄▄─███─▀─███─█▄▀─███─▀─███─▄─▄██─▄█▀██─▄─▄█
-- ▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▄▄▀▄▄▄▄▄▀▀▀▄▄▀▄▄▀▄▄▄▀▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▀▄▄▄▄▄▀▄▄▀▄▄▀
-- 
-- Client-Side Key Management System
-- ████████████████████████████████████████████████████████████████████████████████

-- Uses Framework Bridge (loaded before this file)

-- ═══════════════════════════════════════════════════════════════════════════════
-- SHOW KEY NOTIFICATION (Mini-UI when receiving temporary key)
-- ═══════════════════════════════════════════════════════════════════════════════
RegisterNetEvent('haus-manager:client:showKeyNotification', function(data)
    SendNUIMessage({
        action = 'showKeyNotification',
        propertyName = data.propertyName,
        hours = data.hours,
        grantedBy = data.grantedBy,
        expiresAt = data.expiresAt
    })
    
    -- Play a notification sound
    PlaySoundFrontend(-1, 'CLICK_BACK', 'WEB_NAVIGATION_SOUNDS_PHONE', true)
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- OPEN KEY MANAGEMENT UI
-- ═══════════════════════════════════════════════════════════════════════════════
function OpenKeyManagementUI(property)
    if not property then 
        print('^1[Haus-Manager KeyManager]^7 ERROR: property is nil!')
        return 
    end
    
    print('^2[Haus-Manager KeyManager]^7 Getting keys for property:', property.property_id)
    
    Framework.TriggerCallback('haus-manager:server:getPropertyKeys', function(keys)
        print('^2[Haus-Manager KeyManager]^7 Received keys:', json.encode(keys))
        
        if not keys then
            print('^1[Haus-Manager KeyManager]^7 ERROR: keys is nil!')
            Framework.Notify('Fehler beim Laden der Schlüssel', 'error')
            return
        end
        
        -- Get nearby players for key granting
        print('^2[Haus-Manager KeyManager]^7 Getting nearby players...')
        Framework.TriggerCallback('haus-manager:server:getNearbyPlayers', function(nearbyPlayers)
            print('^2[Haus-Manager KeyManager]^7 Received nearby players:', json.encode(nearbyPlayers))
            
            local messageData = {
                action = 'openKeyManagement',
                property = {
                    id = property.property_id,
                    name = property.property_name,
                    type = property.property_type
                },
                keys = keys,
                nearbyPlayers = nearbyPlayers or {}
            }
            
            print('^2[Haus-Manager KeyManager]^7 Sending NUI message:', json.encode(messageData))
            SendNUIMessage(messageData)
            
            print('^2[Haus-Manager KeyManager]^7 Setting NUI focus to true')
            SetNuiFocus(true, true)
            
            print('^2[Haus-Manager KeyManager]^7 UI should now be visible!')
        end)
    end, property.property_id)
end

-- Export for other scripts
exports('OpenKeyManagementUI', OpenKeyManagementUI)

-- ═══════════════════════════════════════════════════════════════════════════════
-- NUI CALLBACKS
-- ═══════════════════════════════════════════════════════════════════════════════

-- Close Key Management UI
RegisterNUICallback('closeKeyManagement', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Grant Temporary Key
RegisterNUICallback('grantTemporaryKey', function(data, cb)
    TriggerServerEvent('haus-manager:server:grantTemporaryKey', 
        data.propertyId, 
        data.targetId, 
        data.hours)
    
    -- Refresh the UI after a short delay
    Wait(500)
    Framework.TriggerCallback('haus-manager:server:getPropertyKeys', function(keys)
        if keys then
            SendNUIMessage({
                action = 'refreshKeys',
                keys = keys
            })
        end
    end, data.propertyId)
    
    cb('ok')
end)

-- Grant Permanent Key
RegisterNUICallback('grantPermanentKey', function(data, cb)
    TriggerServerEvent('haus-manager:server:grantPermanentKey', 
        data.propertyId, 
        data.targetId)
    
    -- Refresh the UI after a short delay
    Wait(500)
    Framework.TriggerCallback('haus-manager:server:getPropertyKeys', function(keys)
        if keys then
            SendNUIMessage({
                action = 'refreshKeys',
                keys = keys
            })
        end
    end, data.propertyId)
    
    cb('ok')
end)

-- Revoke Key
RegisterNUICallback('revokeKey', function(data, cb)
    TriggerServerEvent('haus-manager:server:revokeKey', 
        data.propertyId, 
        data.citizenId)
    
    -- Refresh the UI after a short delay
    Wait(500)
    Framework.TriggerCallback('haus-manager:server:getPropertyKeys', function(keys)
        if keys then
            SendNUIMessage({
                action = 'refreshKeys',
                keys = keys
            })
        end
    end, data.propertyId)
    
    cb('ok')
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- EVENT HANDLER TO OPEN KEY MANAGEMENT
-- ═══════════════════════════════════════════════════════════════════════════════
RegisterNetEvent('haus-manager:client:openKeyManagement', function(property)
    print('^2[Haus-Manager KeyManager]^7 openKeyManagement event triggered')
    print('^2[Haus-Manager KeyManager]^7 Property data:', json.encode(property))
    if property and property.property_id then
        print('^2[Haus-Manager KeyManager]^7 Opening Key Management UI for property:', property.property_id)
        OpenKeyManagementUI(property)
    else
        print('^1[Haus-Manager KeyManager]^7 ERROR: No valid property data received!')
    end
end)

print('^2[Haus-Manager KeyManager Client] Loaded successfully^7')
