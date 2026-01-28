-- Blip management system
-- Uses Framework Bridge (loaded before this file)
local propertyBlips = {}

-- Blip configuration (can be moved to Config if needed)
local BlipConfig = {
    Sprite = 40, -- House icon
    Display = 4,
    Scale = 0.8,
    Colors = {
        Available = 2,    -- Green - Property available for purchase/rent
        Owned = 3,        -- Blue - Owned by player
        OwnedByOthers = 5, -- Yellow - Owned by someone else
        Rented = 47       -- Orange - Rented property
    }
}

-- Create blip for a property
local function CreatePropertyBlip(property)
    if Config.Debug then
        print(string.format("^3[Haus-Manager Blips]^7 Creating blip for property '%s'", property.property_name))
    end
    
    local coords = json.decode(property.coords)
    if not coords or not coords.x or not coords.y or not coords.z then
        if Config.Debug then
            print(string.format("^1[Haus-Manager Blips Error]^7 Invalid coords for property '%s': %s", 
                property.property_name, tostring(property.coords)))
        end
        return nil
    end
    
    if Config.Debug then
        print(string.format("^3[Haus-Manager Blips]^7 Coords: x=%.2f, y=%.2f, z=%.2f", coords.x, coords.y, coords.z))
    end
    
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    
    if not blip or blip == 0 then
        if Config.Debug then
            print(string.format("^1[Haus-Manager Blips Error]^7 AddBlipForCoord failed for property '%s'", property.property_name))
        end
        return nil
    end
    
    if Config.Debug then
        print(string.format("^3[Haus-Manager Blips]^7 Blip created with handle: %d", blip))
    end
    
    SetBlipSprite(blip, BlipConfig.Sprite)
    SetBlipDisplay(blip, BlipConfig.Display)
    SetBlipScale(blip, BlipConfig.Scale)
    SetBlipAsShortRange(blip, true)
    
    -- Determine blip color based on property status
    local color = BlipConfig.Colors.Available
    local playerCitizenId = Framework.GetPlayerData().citizenid
    
    if property.owned == 1 or tonumber(property.owned) == 1 then
        if property.owner_identifier == playerCitizenId then
            color = BlipConfig.Colors.Owned
        else
            color = BlipConfig.Colors.OwnedByOthers
        end
    end
    
    if property.is_rented == 1 or tonumber(property.is_rented) == 1 then
        color = BlipConfig.Colors.Rented
    end
    
    SetBlipColour(blip, color)
    
    -- Set blip name
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(property.property_name)
    EndTextCommandSetBlipName(blip)
    
    if Config.Debug then
        print(string.format("^2[Haus-Manager Blips]^7 Blip configured for '%s' (color: %d, sprite: %d, scale: %.2f)", 
            property.property_name, color, BlipConfig.Sprite, BlipConfig.Scale))
    end
    
    return blip
end

-- Remove all property blips
local function RemoveAllBlips()
    for _, blip in pairs(propertyBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    propertyBlips = {}
end

-- Refresh all blips
local function RefreshBlips()
    if Config.Debug then
        print("^3[Haus-Manager Blips]^7 RefreshBlips() called")
    end
    
    RemoveAllBlips()
    
    -- Get properties - check if function exists first
    if not GetProperties then
        if Config.Debug then
            print("^1[Haus-Manager Blips Error]^7 GetProperties function not available yet!")
        end
        return
    end
    
    local properties = GetProperties()
    
    if Config.Debug then
        print(string.format("^3[Haus-Manager Blips]^7 Got %d properties from GetProperties()", properties and #properties or 0))
    end
    
    if not properties or #properties == 0 then 
        if Config.Debug then
            print("^3[Haus-Manager Blips]^7 No properties to create blips for")
        end
        return 
    end
    
    local blipCount = 0
    
    for _, property in ipairs(properties) do
        -- Only create blip if marker is visible
        local markerVisible = property.marker_visible
        if type(markerVisible) == "boolean" then
            markerVisible = markerVisible and 1 or 0
        else
            markerVisible = tonumber(markerVisible) or 0
        end
        
        if Config.Debug then
            print(string.format("^3[Haus-Manager Blips]^7 Property '%s': marker_visible=%s (type: %s, normalized: %d)", 
                property.property_name, tostring(property.marker_visible), type(property.marker_visible), markerVisible))
        end
        
        if markerVisible == 1 then
            local blip = CreatePropertyBlip(property)
            if blip and blip ~= 0 then
                propertyBlips[property.property_id] = blip
                blipCount = blipCount + 1
                if Config.Debug then
                    print(string.format("^2[Haus-Manager Blips]^7 Created blip #%d for '%s' (blip handle: %d)", 
                        blipCount, property.property_name, blip))
                end
            else
                if Config.Debug then
                    print(string.format("^1[Haus-Manager Blips Error]^7 Failed to create blip for '%s'", property.property_name))
                end
            end
        else
            if Config.Debug then
                print(string.format("^1[Haus-Manager Blips]^7 Skipping blip for '%s' - marker not visible (value: %d)", 
                    property.property_name, markerVisible))
            end
        end
    end
    
    if Config.Debug then
        print(string.format("^2[Haus-Manager Blips]^7 Created %d blips from %d properties", blipCount, #properties))
    end
end

-- Update blips when properties change
RegisterNetEvent('haus-manager:client:updateProperties', function(properties)
    Wait(1000) -- Wait for properties to be set in main.lua
    RefreshBlips()
end)

-- Manual refresh event
RegisterNetEvent('haus-manager:client:refreshBlips', function()
    Wait(500) -- Small wait to ensure properties are set
    RefreshBlips()
end)

-- Player loaded
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000) -- Wait for properties to load
    RefreshBlips()
end)

-- Player unload
RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    RemoveAllBlips()
end)

-- Resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        RemoveAllBlips()
    end
end)

-- Toggle blips command
RegisterCommand('toggleblips', function()
    if #propertyBlips > 0 then
        RemoveAllBlips()
        Framework.Notify("Immobilien-Blips ausgeblendet", 'primary')
    else
        RefreshBlips()
        Framework.Notify("Immobilien-Blips eingeblendet", 'primary')
    end
end)

-- Export
exports('RefreshBlips', RefreshBlips)

-- Initial blip creation on resource start
CreateThread(function()
    -- Wait for main.lua to load and properties to be available
    local attempts = 0
    while not GetProperties and attempts < 50 do
        Wait(100)
        attempts = attempts + 1
    end
    
    if not GetProperties then
        if Config.Debug then
            print("^1[Haus-Manager Blips Error]^7 GetProperties function never became available!")
        end
        return
    end
    
    -- Wait additional time for properties to actually load
    Wait(2000)
    
    if Config.Debug then
        print("^3[Haus-Manager Blips]^7 Blips system initialized, creating initial blips...")
    end
    RefreshBlips()
end)
