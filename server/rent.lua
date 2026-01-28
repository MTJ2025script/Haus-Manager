-- Rent and purchase system
-- Uses Framework Bridge for multi-framework support

-- Calculate rent price
function CalculateRentPrice(propertyPrice, rentPeriodDays)
    for _, period in ipairs(Config.RentPeriods) do
        if period.days == rentPeriodDays then
            return math.floor(propertyPrice * period.multiplier)
        end
    end
    return propertyPrice
end

-- Calculate rent end date (in game time)
function CalculateRentEndDate(rentPeriodDays)
    -- Get current game time
    local currentTime = os.time()
    -- In FiveM, we'll use real time but can be adjusted for game time
    -- For GTA V game time, you might need to track differently
    local endTime = currentTime + (rentPeriodDays * 24 * 60 * 60)
    return endTime
end

-- Check if rent is expired
function IsRentExpired(rentEndDate)
    if not rentEndDate then return false end
    return os.time() >= rentEndDate
end

-- Purchase property
RegisterNetEvent('haus-manager:server:purchaseProperty', function(propertyId)
    local src = source
    local Player = FrameworkServer.GetPlayer(src)
    
    if not Player then return end
    
    local property = GetPropertyById(propertyId)
    if not property then
        TriggerClientEvent('QBCore:Notify', src, "Immobilie nicht gefunden!", 'error')
        return
    end
    
    -- Check if already owned
    if property.owned == 1 then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications["property_already_owned"], 'error')
        return
    end
    
    -- Check if player has enough money
    local price = property.price
    local playerMoney = FrameworkServer.GetPlayerMoney(Player, 'bank')
    if playerMoney < price then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications["not_enough_money"], 'error')
        return
    end
    
    -- Remove money
    FrameworkServer.RemoveMoney(Player, 'bank', price, "property-purchase")
    
    -- Set owner
    local playerIdentifier = FrameworkServer.GetPlayerIdentifier(Player)
    SetPropertyOwner(propertyId, playerIdentifier, false, nil, nil)
    
    -- Give key to owner
    GivePropertyKey(propertyId, playerIdentifier, playerIdentifier)
    
    -- Notify player
    TriggerClientEvent('QBCore:Notify', src, Config.Notifications["property_purchased"], 'success')
    
    -- Update all clients
    TriggerClientEvent('haus-manager:client:updateProperties', -1, GetAllProperties())
    
    -- Log purchase
    if Config.Debug then
        print(string.format("^3[Haus-Manager]^7 %s purchased property %s for $%d", 
            playerIdentifier, propertyId, price))
    end
end)

-- Rent property
RegisterNetEvent('haus-manager:server:rentProperty', function(propertyId, rentPeriodDays)
    local src = source
    local Player = FrameworkServer.GetPlayer(src)
    
    if not Player then return end
    
    local property = GetPropertyById(propertyId)
    if not property then
        TriggerClientEvent('QBCore:Notify', src, "Immobilie nicht gefunden!", 'error')
        return
    end
    
    -- Check if already owned
    if property.owned == 1 then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications["property_already_owned"], 'error')
        return
    end
    
    -- Calculate rent price
    local rentPrice = CalculateRentPrice(property.price, rentPeriodDays)
    
    -- Check if player has enough money
    local playerMoney = FrameworkServer.GetPlayerMoney(Player, 'bank')
    if playerMoney < rentPrice then
        TriggerClientEvent('QBCore:Notify', src, Config.Notifications["not_enough_money"], 'error')
        return
    end
    
    -- Remove money
    FrameworkServer.RemoveMoney(Player, 'bank', rentPrice, "property-rent")
    
    -- Calculate rent end date
    local rentEndDate = CalculateRentEndDate(rentPeriodDays)
    
    -- Set owner
    local playerIdentifier = FrameworkServer.GetPlayerIdentifier(Player)
    SetPropertyOwner(propertyId, playerIdentifier, true, rentEndDate, rentPeriodDays)
    
    -- Give key to owner
    GivePropertyKey(propertyId, playerIdentifier, playerIdentifier)
    
    -- Notify player
    TriggerClientEvent('QBCore:Notify', src, Config.Notifications["property_rented"], 'success')
    
    -- Update all clients
    TriggerClientEvent('haus-manager:client:updateProperties', -1, GetAllProperties())
    
    -- Log rental
    if Config.Debug then
        print(string.format("^3[Haus-Manager]^7 %s rented property %s for $%d (%d days)", 
            playerIdentifier, propertyId, rentPrice, rentPeriodDays))
    end
end)

-- Check rent expiration on player join
RegisterNetEvent('QBCore:Server:PlayerLoaded', function()
    local src = source
    local Player = FrameworkServer.GetPlayer(src)
    
    if not Player then return end
    
    -- Get player properties
    local playerIdentifier = FrameworkServer.GetPlayerIdentifier(Player)
    local properties = GetPropertiesByOwner(playerIdentifier)
    
    for _, property in ipairs(properties) do
        if property.is_rented == 1 and IsRentExpired(property.rent_end_date) then
            -- Remove property ownership
            RemovePropertyOwner(property.property_id)
            
            -- Notify player
            TriggerClientEvent('QBCore:Notify', src, Config.Notifications["rent_expired"], 'error')
            
            if Config.Debug then
                print(string.format("^3[Haus-Manager]^7 Rent expired for property %s owned by %s", 
                    property.property_id, playerIdentifier))
            end
        end
    end
end)

-- Periodic rent check (every 30 minutes)
CreateThread(function()
    while true do
        Wait(30 * 60 * 1000) -- 30 minutes
        
        local properties = GetAllProperties()
        
        for _, property in ipairs(properties) do
            if property.is_rented == 1 and IsRentExpired(property.rent_end_date) then
                -- Remove property ownership
                RemovePropertyOwner(property.property_id)
                
                -- Try to notify player if online
                local Player = FrameworkServer.GetPlayerByCitizenId(property.owner_identifier)
                if Player then
                    local playerSource = FrameworkServer.GetPlayerSource(Player)
                    TriggerClientEvent('QBCore:Notify', playerSource, 
                        Config.Notifications["rent_expired"], 'error')
                end
                
                if Config.Debug then
                    print(string.format("^3[Haus-Manager]^7 Rent expired for property %s", property.property_id))
                end
            end
        end
        
        -- Update all clients
        TriggerClientEvent('haus-manager:client:updateProperties', -1, GetAllProperties())
    end
end)

-- Get property info callback
CreateThread(function()
    FrameworkServer.WaitForReady()
    FrameworkServer.CreateCallback('haus-manager:server:getPropertyInfo', function(source, cb, propertyId)
        local property = GetPropertyById(propertyId)
        cb(property)
    end)
end)

-- Export functions
exports('CalculateRentPrice', CalculateRentPrice)
exports('CalculateRentEndDate', CalculateRentEndDate)
exports('IsRentExpired', IsRentExpired)
