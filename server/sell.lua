-- Property selling server logic
-- Uses Framework Bridge for multi-framework support

-- Sell property back to city (50% of original price)
RegisterNetEvent('haus-manager:server:sellToCity', function(propertyId)
    local src = source
    local Player = FrameworkServer.GetPlayer(src)
    
    if not Player then return end
    
    local property = GetPropertyById(propertyId)
    if not property then
        TriggerClientEvent('QBCore:Notify', src, "Immobilie nicht gefunden!", 'error')
        return
    end
    
    -- Verify ownership
    local playerIdentifier = FrameworkServer.GetPlayerIdentifier(Player)
    if property.owner_identifier ~= playerIdentifier then
        TriggerClientEvent('QBCore:Notify', src, "Sie sind nicht der Eigentümer dieser Immobilie!", 'error')
        return
    end
    
    -- Calculate sell price (50% of original price)
    local sellPrice = math.floor(property.price * 0.5)
    
    -- Remove all keys for this property - AWAIT this
    MySQL.query.await('DELETE FROM haus_keys WHERE property_id = ?', {propertyId})
    
    -- Remove all vehicles from garage - AWAIT this
    MySQL.query.await('DELETE FROM haus_garage_vehicles WHERE property_id = ?', {propertyId})
    
    -- Clear safe storage - AWAIT this
    MySQL.query.await('DELETE FROM haus_safe_storage WHERE property_id = ?', {propertyId})
    
    -- Reset property ownership - AWAIT this
    MySQL.query.await([[
        UPDATE haus_properties 
        SET owner_identifier = NULL,
            owned = 0,
            is_rented = 0,
            rent_end_date = NULL,
            rent_period = NULL,
            current_owner_count = 0
        WHERE property_id = ?
    ]], {propertyId})
    
    -- Give money to player
    FrameworkServer.AddMoney(Player, 'bank', sellPrice, "property-sale-to-city")
    
    -- Notify player
    TriggerClientEvent('QBCore:Notify', src, 
        string.format("Immobilie für $%s an die Stadt verkauft!", FormatMoney(sellPrice)), 
        'success')
    
    -- Kick seller out of property if they're inside
    TriggerClientEvent('haus-manager:client:exitProperty', src)
    
    -- Wait a moment for database operations to fully complete
    Wait(100)
    
    -- Get updated keys for seller
    local sellerKeys = GetPlayerKeys(FrameworkServer.GetPlayerIdentifier(Player))
    
    print(string.format("^2[Haus-Manager Sell]^7 City Sale - Seller keys after sale: %d", #sellerKeys))
    
    -- Update seller's keys directly
    TriggerClientEvent('haus-manager:client:updateKeys', src, sellerKeys)
    
    -- Update all clients with new property data
    local allProps = GetAllProperties()
    print(string.format("^2[Haus-Manager Sell]^7 Broadcasting %d properties to all clients", #allProps))
    TriggerClientEvent('haus-manager:client:updateProperties', -1, allProps)
    
    -- Log sale
    print(string.format("^2[Haus-Manager]^7 %s sold property %s to city for $%d", 
        FrameworkServer.GetPlayerIdentifier(Player), propertyId, sellPrice))
end)

-- Sell property to another player
RegisterNetEvent('haus-manager:server:sellToPlayer', function(propertyId, targetId, price)
    local src = source
    local Player = FrameworkServer.GetPlayer(src)
    local Target = FrameworkServer.GetPlayer(targetId)
    
    if not Player or not Target then 
        if Player then
            TriggerClientEvent('QBCore:Notify', src, "Zielspieler nicht gefunden!", 'error')
        end
        return 
    end
    
    local property = GetPropertyById(propertyId)
    if not property then
        TriggerClientEvent('QBCore:Notify', src, "Immobilie nicht gefunden!", 'error')
        return
    end
    
    -- Verify ownership
    if property.owner_identifier ~= FrameworkServer.GetPlayerIdentifier(Player) then
        TriggerClientEvent('QBCore:Notify', src, "Sie sind nicht der Eigentümer dieser Immobilie!", 'error')
        return
    end
    
    -- Validate price
    if price < 0 or price > 99999999 then
        TriggerClientEvent('QBCore:Notify', src, "Ungültiger Preis!", 'error')
        return
    end
    
    -- Check if target has enough money
    if FrameworkServer.GetPlayerMoney(Target, "bank") < price then
        TriggerClientEvent('QBCore:Notify', src, "Der Käufer hat nicht genug Geld!", 'error')
        TriggerClientEvent('QBCore:Notify', targetId, "Sie haben nicht genug Geld für diese Immobilie!", 'error')
        return
    end
    
    -- Remove money from target
    FrameworkServer.RemoveMoney(Target, 'bank', price, "property-purchase-from-player")
    
    -- Give money to seller
    FrameworkServer.AddMoney(Player, 'bank', price, "property-sale-to-player")
    
    -- Remove all old keys (except we'll give the new owner a key) - AWAIT this
    MySQL.query.await('DELETE FROM haus_keys WHERE property_id = ?', {propertyId})
    
    -- Transfer ownership
    SetPropertyOwner(propertyId, FrameworkServer.GetPlayerIdentifier(Target), false, nil, nil)
    
    -- Give key to new owner
    local keySuccess = GivePropertyKey(propertyId, FrameworkServer.GetPlayerIdentifier(Target), FrameworkServer.GetPlayerIdentifier(Target))
    
    if not keySuccess then
        print("^1[Haus-Manager Sell ERROR]^7 Failed to give key to buyer!")
    end
    
    -- Notify both players
    TriggerClientEvent('QBCore:Notify', src, 
        string.format("Immobilie '%s' für $%s verkauft!", property.property_name, FormatMoney(price)), 
        'success')
    
    TriggerClientEvent('QBCore:Notify', targetId, 
        string.format("Sie haben '%s' für $%s gekauft!", property.property_name, FormatMoney(price)), 
        'success')
    
    -- Kick seller out of property if they're inside
    TriggerClientEvent('haus-manager:client:exitProperty', src)
    
    -- Wait a moment for database operations to fully complete
    Wait(100)
    
    -- Get updated keys for both parties
    local sellerKeys = GetPlayerKeys(FrameworkServer.GetPlayerIdentifier(Player))
    local buyerKeys = GetPlayerKeys(FrameworkServer.GetPlayerIdentifier(Target))
    
    print(string.format("^2[Haus-Manager Sell]^7 Player Sale - Seller keys: %d, Buyer keys: %d", 
        #sellerKeys, #buyerKeys))
    
    -- Update seller's keys directly (should be empty after deletion)
    TriggerClientEvent('haus-manager:client:updateKeys', src, sellerKeys)
    
    -- Update buyer's keys directly (should include new property)
    TriggerClientEvent('haus-manager:client:updateKeys', targetId, buyerKeys)
    
    -- Update all clients with new property data
    local allProps = GetAllProperties()
    print(string.format("^2[Haus-Manager Sell]^7 Broadcasting %d properties to all clients", #allProps))
    TriggerClientEvent('haus-manager:client:updateProperties', -1, allProps)
    
    -- Log sale
    print(string.format("^2[Haus-Manager]^7 %s sold property %s to %s for $%d", 
        FrameworkServer.GetPlayerIdentifier(Player), propertyId, FrameworkServer.GetPlayerIdentifier(Target), price))
end)

-- Get nearby players callback
CreateThread(function()
    FrameworkServer.WaitForReady()
    
    FrameworkServer.CreateCallback('haus-manager:server:getNearbyPlayers', function(source, cb)
        local src = source
        local Player = FrameworkServer.GetPlayer(src)
        if not Player then 
            cb({})
            return 
        end
        
        local ped = GetPlayerPed(src)
        local coords = GetEntityCoords(ped)
        local players = {}
        
        for _, playerId in ipairs(GetPlayers()) do
            local targetId = tonumber(playerId)
            if targetId ~= src then
                local targetPed = GetPlayerPed(targetId)
                if targetPed ~= 0 then
                    local targetCoords = GetEntityCoords(targetPed)
                    local distance = #(coords - targetCoords)
                    
                    -- Within 10 meters
                    if distance <= 10.0 then
                        local TargetPlayer = FrameworkServer.GetPlayer(targetId)
                        if TargetPlayer then
                            table.insert(players, {
                                id = targetId,
                                name = FrameworkServer.GetPlayerName(TargetPlayer),
                                citizenid = FrameworkServer.GetPlayerIdentifier(TargetPlayer)
                            })
                        end
                    end
                end
            end
        end
        
        cb(players)
    end)
end)

-- Helper function to format money
function FormatMoney(amount)
    local formatted = tostring(amount)
    local k
    while true do  
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if (k == 0) then
            break
        end
    end
    return "$" .. formatted
end
