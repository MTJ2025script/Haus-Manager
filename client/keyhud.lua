-- ████████████████████████████████████████████████████████████████████████████████
-- Client-Side Temporary Key HUD Display
-- Shows active temporary keys with live countdown timer
-- ████████████████████████████████████████████████████████████████████████████████

-- Uses Framework Bridge (loaded before this file)
local playerKeys = {}
local hudActive = false

-- ═══════════════════════════════════════════════════════════════════════════════
-- UPDATE KEYS AND REFRESH HUD
-- ═══════════════════════════════════════════════════════════════════════════════
RegisterNetEvent('haus-manager:client:updateKeys', function(keys)
    playerKeys = keys or {}
    RefreshKeyHUD()
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- REFRESH HUD DISPLAY
-- ═══════════════════════════════════════════════════════════════════════════════
function RefreshKeyHUD()
    -- Filter for temporary keys only
    local temporaryKeys = {}
    -- Get current time from system (in milliseconds)
    -- Using QBCore shared function which is server-synced
    Framework.TriggerCallback('haus-manager:server:getCurrentTime', function(currentTime)
        for _, key in ipairs(playerKeys) do
            if key.key_type == 'temporary' and key.expires_at and key.expires_at > currentTime then
                table.insert(temporaryKeys, {
                    propertyId = key.property_id,
                    propertyName = key.property_name or 'Unbekannte Immobilie',
                    expiresAt = key.expires_at
                })
            end
        end
        
        -- Send to NUI
        SendNUIMessage({
            action = 'updateKeyHUD',
            keys = temporaryKeys,
            currentTime = currentTime
        })
        
        -- Manage HUD state
        if #temporaryKeys > 0 and not hudActive then
            hudActive = true
        elseif #temporaryKeys == 0 and hudActive then
            hudActive = false
        end
    end)
end

-- ═══════════════════════════════════════════════════════════════════════════════
-- PERIODIC HUD UPDATE (Every second)
-- ═══════════════════════════════════════════════════════════════════════════════
CreateThread(function()
    while true do
        Wait(1000) -- Update every second
        if hudActive then
            RefreshKeyHUD()
        else
            Wait(4000) -- Check less frequently when HUD is not active
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════════════════════
-- INITIALIZE ON PLAYER LOAD
-- ═══════════════════════════════════════════════════════════════════════════════
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000) -- Wait for keys to load
    RefreshKeyHUD()
end)
