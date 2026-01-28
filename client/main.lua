-- Main client file
-- Uses Framework Bridge (loaded before this file)
local PlayerData = {}
local properties = {}
local playerKeys = {}
local isInProperty = false
local currentProperty = nil

-- Load necessary IPLs for interiors
-- (No special IPLs needed for standard interiors)

-- Initialize
CreateThread(function()
    -- Wait for Framework Bridge to be ready
    local maxAttempts = 100
    local attempts = 0
    while not Framework.Object and attempts < maxAttempts do
        Wait(50)
        attempts = attempts + 1
    end
    
    if not Framework.Object then
        print("^1[Haus-Manager Client]^7 ERROR: Framework not loaded after 5 seconds!")
        return
    end
    
    print("^2[Haus-Manager Client]^7 Framework loaded, initializing...")
    
    -- Wait for PlayerData to be available (especially important for ESX)
    local playerDataAttempts = 0
    repeat
        Wait(100)
        PlayerData = Framework.GetPlayerData()
        playerDataAttempts = playerDataAttempts + 1
        
        -- Check if we have identifier (ESX) or citizenid (QB-Core)
        local hasIdentifier = (Framework.Type == 'esx' and PlayerData.identifier) or 
                             (Framework.Type == 'qb-core' and PlayerData.citizenid)
        
        if hasIdentifier then
            print("^2[Haus-Manager Client]^7 PlayerData loaded successfully")
            print("^3[Haus-Manager Client Debug]^7 Identifier: " .. tostring(PlayerData.identifier or PlayerData.citizenid))
            break
        end
    until playerDataAttempts > 50 -- Max 5 seconds wait
    
    if playerDataAttempts > 50 then
        print("^1[Haus-Manager Client]^7 WARNING: PlayerData not loaded after 5 seconds! Owner detection may not work.")
    end
    
    -- Request properties from server
    Framework.TriggerCallback('haus-manager:server:getAllProperties', function(props)
        properties = props or {}
        
        -- Normalize marker_visible to ensure it's a number
        for i, prop in ipairs(properties) do
            if prop.marker_visible ~= nil then
                -- Handle boolean true/false from MySQL TINYINT
                if type(prop.marker_visible) == "boolean" then
                    properties[i].marker_visible = prop.marker_visible and 1 or 0
                else
                    properties[i].marker_visible = tonumber(prop.marker_visible) or 0
                end
            end
            if prop.owned ~= nil then
                if type(prop.owned) == "boolean" then
                    properties[i].owned = prop.owned and 1 or 0
                else
                    properties[i].owned = tonumber(prop.owned) or 0
                end
            end
            if prop.is_rented ~= nil then
                if type(prop.is_rented) == "boolean" then
                    properties[i].is_rented = prop.is_rented and 1 or 0
                else
                    properties[i].is_rented = tonumber(prop.is_rented) or 0
                end
            end
        end
        
        print(string.format("^2[Haus-Manager Client]^7 Loaded %d properties", #properties))
        
        -- Trigger blip refresh after properties are normalized
        print("^3[Haus-Manager Client]^7 Triggering blip refresh after property normalization")
        TriggerEvent('haus-manager:client:refreshBlips')
        
        if Config.Debug then
            for _, prop in ipairs(properties) do
                print(string.format("^3[Haus-Manager Client Debug]^7 Property: %s, marker_visible: %s (type: %s)", 
                    prop.property_name, tostring(prop.marker_visible), type(prop.marker_visible)))
            end
        end
    end)
    
    -- Request player keys
    Framework.TriggerCallback('haus-manager:server:getPlayerKeys', function(keys)
        playerKeys = keys or {}
        print(string.format("^2[Haus-Manager Client]^7 Loaded %d keys", #playerKeys))
    end)
    
    print("^2[Haus-Manager Client]^7 Client initialization complete")
end)

-- Update player data
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    -- CRITICAL: Wait a bit for ESX to fully set PlayerData
    Wait(500)
    
    PlayerData = Framework.GetPlayerData()
    print("^2[Haus-Manager Client]^7 Player loaded event - PlayerData refreshed")
    print("^3[Haus-Manager Client Debug]^7 PlayerData.identifier: " .. tostring(PlayerData.identifier))
    print("^3[Haus-Manager Client Debug]^7 PlayerData.citizenid: " .. tostring(PlayerData.citizenid))
    
    Framework.TriggerCallback('haus-manager:server:getAllProperties', function(props)
        properties = props or {}
        
        -- Normalize marker_visible to ensure it's a number
        for i, prop in ipairs(properties) do
            if prop.marker_visible ~= nil then
                -- Handle boolean true/false from MySQL TINYINT
                if type(prop.marker_visible) == "boolean" then
                    properties[i].marker_visible = prop.marker_visible and 1 or 0
                else
                    properties[i].marker_visible = tonumber(prop.marker_visible) or 0
                end
            end
            if prop.owned ~= nil then
                if type(prop.owned) == "boolean" then
                    properties[i].owned = prop.owned and 1 or 0
                else
                    properties[i].owned = tonumber(prop.owned) or 0
                end
            end
            if prop.is_rented ~= nil then
                if type(prop.is_rented) == "boolean" then
                    properties[i].is_rented = prop.is_rented and 1 or 0
                else
                    properties[i].is_rented = tonumber(prop.is_rented) or 0
                end
            end
        end
        
        print(string.format("^2[Haus-Manager Client]^7 Player loaded - Properties refreshed: %d", #properties))
        
        -- Trigger blip refresh after properties are normalized
        print("^3[Haus-Manager Client]^7 Triggering blip refresh after player load")
        TriggerEvent('haus-manager:client:refreshBlips')
    end)
    
    Framework.TriggerCallback('haus-manager:server:getPlayerKeys', function(keys)
        playerKeys = keys
    end)
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    PlayerData = {}
    properties = {}
    playerKeys = {}
end)

RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    PlayerData = data
end)

-- Update properties from server
RegisterNetEvent('haus-manager:client:updateProperties', function(props)
    properties = props or {}
    
    -- Normalize marker_visible to ensure it's a number
    for i, prop in ipairs(properties) do
        if prop.marker_visible ~= nil then
            -- Handle boolean true/false from MySQL TINYINT
            if type(prop.marker_visible) == "boolean" then
                properties[i].marker_visible = prop.marker_visible and 1 or 0
            else
                properties[i].marker_visible = tonumber(prop.marker_visible) or 0
            end
        end
        if prop.owned ~= nil then
            if type(prop.owned) == "boolean" then
                properties[i].owned = prop.owned and 1 or 0
            else
                properties[i].owned = tonumber(prop.owned) or 0
            end
        end
        if prop.is_rented ~= nil then
            if type(prop.is_rented) == "boolean" then
                properties[i].is_rented = prop.is_rented and 1 or 0
            else
                properties[i].is_rented = tonumber(prop.is_rented) or 0
            end
        end
    end
    
    print(string.format("^2[Haus-Manager Client]^7 Properties updated: %d properties", #properties))
    
    if Config.Debug then
        for _, prop in ipairs(properties) do
            print(string.format("^3[Haus-Manager Client Debug]^7 Updated Property: %s, marker_visible: %s (type: %s)", 
                prop.property_name, tostring(prop.marker_visible), type(prop.marker_visible)))
        end
    end
    
    -- Trigger blip refresh after properties are set
    TriggerEvent('haus-manager:client:refreshBlips')
end)

-- Update player keys
RegisterNetEvent('haus-manager:client:updateKeys', function(keys)
    playerKeys = keys
    print(string.format("^2[Haus-Manager Client]^7 Keys updated: %d keys received", #keys))
    
    if Config.Debug then
        for i, key in ipairs(keys) do
            print(string.format("^3[Haus-Manager Client]^7 Key %d: %s (%s)", 
                i, key.property_name or "Unknown", key.property_id or "Unknown"))
        end
    end
end)

-- Open admin UI
RegisterNetEvent('haus-manager:client:openAdminUI', function()
    print("^3[Haus-Manager Client]^7 openAdminUI event received")
    print("^3[Haus-Manager Client]^7 Properties count: " .. #properties)
    print("^3[Haus-Manager Client]^7 Config exists: " .. tostring(Config ~= nil))
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openAdminUI",
        properties = properties,
        config = Config
    })
    
    print("^2[Haus-Manager Client]^7 NUI message sent for admin UI")
end)

-- Open garage admin UI
RegisterNetEvent('haus-manager:client:openGarageUI', function()
    print("^3[Haus-Manager Client]^7 openGarageUI event received")
    print("^3[Haus-Manager Client]^7 Properties count: " .. #properties)
    print("^3[Haus-Manager Client]^7 Config exists: " .. tostring(Config ~= nil))
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = "openGarageUI",
        properties = properties,
        config = Config
    })
    
    print("^2[Haus-Manager Client]^7 NUI message sent for garage UI")
end)

-- Open property interaction UI
function OpenPropertyUI(property)
    Framework.TriggerCallback('haus-manager:server:getPropertyInfo', function(propertyInfo)
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openPropertyUI",
            property = propertyInfo,
            config = Config
        })
    end, property.property_id)
end

-- Close UI
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Create property (from admin UI)
RegisterNUICallback('createProperty', function(data, cb)
    TriggerServerEvent('haus-manager:server:createProperty', data)
    cb('ok')
end)

-- Update property (from admin UI)
RegisterNUICallback('updateProperty', function(data, cb)
    TriggerServerEvent('haus-manager:server:updateProperty', data.propertyId, data.updates)
    cb('ok')
end)

-- Delete property (from admin UI)
RegisterNUICallback('deleteProperty', function(data, cb)
    TriggerServerEvent('haus-manager:server:deleteProperty', data.propertyId)
    cb('ok')
end)

-- Purchase property
RegisterNUICallback('purchaseProperty', function(data, cb)
    TriggerServerEvent('haus-manager:server:purchaseProperty', data.propertyId)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Rent property
RegisterNUICallback('rentProperty', function(data, cb)
    TriggerServerEvent('haus-manager:server:rentProperty', data.propertyId, data.rentPeriod)
    SetNuiFocus(false, false)
    cb('ok')
end)

-- Get player position for admin UI
RegisterNUICallback('getPlayerPosition', function(data, cb)
    local coords = GetEntityCoords(PlayerPedId())
    local heading = GetEntityHeading(PlayerPedId())
    cb({
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = heading
    })
end)

-- Remove safe prop immediately when admin deletes coordinates
RegisterNUICallback('removeSafeProp', function(data, cb)
    if data.propertyId then
        TriggerEvent('haus-manager:client:removeSafeProp', data.propertyId)
        print(string.format("^3[Haus-Manager]^7 Safe prop removal requested for property: %s", data.propertyId))
    end
    cb('ok')
end)

-- Remove wardrobe marker immediately when admin deletes coordinates
RegisterNUICallback('removeWardrobeProp', function(data, cb)
    if data.propertyId then
        TriggerEvent('haus-manager:client:removeWardrobeProp', data.propertyId)
        print(string.format("^3[Haus-Manager]^7 Wardrobe marker removal requested for property: %s", data.propertyId))
    end
    cb('ok')
end)

-- Enter property
function EnterProperty(property)
    print("^2[Haus-Manager EnterProperty]^7 Entering property: " .. tostring(property.property_name))
    
    local interiorType = property.interior_type
    local interiorConfig = Config.Interiors[interiorType]
    
    if not interiorConfig then
        print("^1[Haus-Manager EnterProperty]^7 Invalid interior type: " .. tostring(interiorType))
        Framework.Notify("Ungültiger Innenraum-Typ!", 'error')
        return
    end
    
    print("^2[Haus-Manager EnterProperty]^7 Interior config found, type: " .. tostring(interiorType))
    
    -- CRITICAL: Store PROPERTY MARKER position for exit (NOT player position!)
    -- This ensures player exits at the SAME location as the property marker
    local propertyCoords = json.decode(property.coords)
    local exteriorCoords = vector3(propertyCoords.x, propertyCoords.y, propertyCoords.z)
    local exteriorHeading = propertyCoords.heading or 0.0
    print("^2[Haus-Manager EnterProperty]^7 Storing MARKER coords for exit: " .. exteriorCoords.x .. ", " .. exteriorCoords.y .. ", " .. exteriorCoords.z)
    
    -- Screen fade for smooth transition
    DoScreenFadeOut(500)
    
    -- Ensure player is not frozen before starting transition
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, false)
    SetPlayerControl(PlayerId(), true, 0)
    
    Wait(500)
    
    -- Teleport player to interior spawn location (ALWAYS execute!)
    if interiorConfig.spawn then
        print("^2[Haus-Manager EnterProperty]^7 Teleporting to: " .. interiorConfig.spawn.x .. ", " .. interiorConfig.spawn.y .. ", " .. interiorConfig.spawn.z)
        
        -- Teleport with all freeze/network options disabled
        SetEntityCoords(ped, interiorConfig.spawn.x, interiorConfig.spawn.y, interiorConfig.spawn.z, false, false, false, true)
        SetEntityHeading(ped, interiorConfig.spawn.heading or 0.0)
        
        -- Force unfreeze after teleport
        Wait(100)
        FreezeEntityPosition(ped, false)
        NetworkSetEntityInvisibleToNetwork(ped, false)
        SetPlayerControl(PlayerId(), true, 0)
        
        print("^2[Haus-Manager EnterProperty]^7 Player teleported to interior successfully and unfrozen")
    else
        print("^1[Haus-Manager EnterProperty]^7 ERROR: No spawn location defined for interior type: " .. tostring(interiorType))
        FreezeEntityPosition(ped, false)  -- Unfreeze on error!
        SetPlayerControl(PlayerId(), true, 0)
        DoScreenFadeIn(500)
        Framework.Notify("Kein Spawn-Punkt für diesen Innenraum definiert!", 'error')
        return
    end
    
    Wait(500)
    DoScreenFadeIn(500)
    
    -- Use QB-Interior if available (optional enhancement for QB-Core)
    if GetResourceState('qb-interior') == 'started' then
        print("^2[Haus-Manager EnterProperty]^7 Using qb-interior enhancement")
        TriggerEvent('qb-interior:client:enter', interiorConfig.shell, property.property_id)
    else
        print("^3[Haus-Manager EnterProperty]^7 qb-interior not available (ESX mode or not installed)")
    end
    
    isInProperty = true
    currentProperty = property
    -- CRITICAL: Store exterior coords and heading for exit
    currentProperty.storedExteriorCoords = vector4(exteriorCoords.x, exteriorCoords.y, exteriorCoords.z, exteriorHeading)
    
    -- CRITICAL FIX: Trigger safe and wardrobe marker creation
    print("^2[Haus-Manager EnterProperty]^7 Setting up interior markers (safe, wardrobe)")
    TriggerEvent('haus-manager:client:setupInteriorMarkers', property)
    
    Framework.Notify(Config.Notifications["entered_property"] or "Property betreten", 'success')
    print("^2[Haus-Manager EnterProperty]^7 Property entered successfully - player is now inside")
end

-- Exit property
function ExitProperty()
    if not isInProperty or not currentProperty then return end
    
    print("^2[Haus-Manager ExitProperty]^7 Exiting property: " .. tostring(currentProperty.property_name))
    
    -- CRITICAL: Clean up safe and wardrobe markers BEFORE exit
    print("^2[Haus-Manager ExitProperty]^7 Cleaning up interior markers")
    TriggerEvent('haus-manager:client:cleanupInteriorMarkers', currentProperty.property_id)
    
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Teleport back to stored exterior coordinates
    local ped = PlayerPedId()
    if currentProperty.storedExteriorCoords then
        local coords = currentProperty.storedExteriorCoords
        print("^2[Haus-Manager ExitProperty]^7 Teleporting to stored exterior: " .. coords.x .. ", " .. coords.y .. ", " .. coords.z)
        SetEntityCoords(ped, coords.x, coords.y, coords.z, false, false, false, true)
        SetEntityHeading(ped, coords.w or 0.0)
    else
        -- Fallback: Use property marker coordinates
        print("^3[Haus-Manager ExitProperty]^7 No stored coords, using property marker position")
        local propertyCoords = json.decode(currentProperty.coords)
        SetEntityCoords(ped, propertyCoords.x, propertyCoords.y, propertyCoords.z, false, false, false, true)
        SetEntityHeading(ped, propertyCoords.heading or 0.0)
    end
    
    -- Use QB-Interior exit if available
    if GetResourceState('qb-interior') == 'started' then
        TriggerEvent('qb-interior:client:exit')
    end
    
    Wait(500)
    DoScreenFadeIn(500)
    
    isInProperty = false
    currentProperty = nil
    
    Framework.Notify(Config.Notifications["exited_property"] or "Property verlassen", 'success')
    print("^2[Haus-Manager ExitProperty]^7 Exit completed successfully")
end

-- Check if player owns or has key to property
function HasAccessToProperty(property)
    -- CRITICAL FIX: Don't call Framework.GetPlayerIdentifier() every time
    -- Use cached PlayerData.identifier or PlayerData.citizenid instead
    local playerIdentifier = nil
    
    if Framework.Type == 'esx' then
        -- ESX uses identifier field
        playerIdentifier = PlayerData.identifier
    elseif Framework.Type == 'qb-core' then
        -- QB-Core uses citizenid field
        playerIdentifier = PlayerData.citizenid
    end
    
    if not playerIdentifier then 
        print("^1[Haus-Manager]^7 ERROR: Could not get player identifier from PlayerData")
        print("^3[Haus-Manager Debug]^7 Framework.Type: " .. tostring(Framework.Type))
        print("^3[Haus-Manager Debug]^7 PlayerData.identifier: " .. tostring(PlayerData.identifier))
        print("^3[Haus-Manager Debug]^7 PlayerData.citizenid: " .. tostring(PlayerData.citizenid))
        return false 
    end
    
    -- Check if owner (compare identifiers)
    if property.owner_identifier == playerIdentifier then
        print("^2[Haus-Manager]^7 Player IS owner - access granted")
        print("^3[Haus-Manager Debug]^7 Matched: " .. tostring(property.owner_identifier) .. " == " .. tostring(playerIdentifier))
        return true
    end
    
    -- Check if has key
    for _, key in ipairs(playerKeys) do
        if key.property_id == property.property_id then
            print("^2[Haus-Manager]^7 Player has key - access granted")
            return true
        end
    end
    
    print("^3[Haus-Manager]^7 Player is NOT owner and has NO key - access denied")
    print("^3[Haus-Manager Debug]^7 property.owner_identifier: " .. tostring(property.owner_identifier))
    print("^3[Haus-Manager Debug]^7 playerIdentifier: " .. tostring(playerIdentifier))
    return false
end

-- Get properties
function GetProperties()
    return properties
end

-- Get player keys
function GetPlayerKeys()
    return playerKeys
end

-- Set properties (for other files to update the properties list)
function SetProperties(props)
    properties = props
end

-- Export functions
exports('GetProperties', GetProperties)
exports('SetProperties', SetProperties)
exports('GetPlayerKeys', GetPlayerKeys)
exports('HasAccessToProperty', HasAccessToProperty)
exports('EnterProperty', EnterProperty)
exports('ExitProperty', ExitProperty)

-- Close menu event handler
RegisterNetEvent('haus-manager:client:closeMenu', function()
    Menu.Close()
end)
