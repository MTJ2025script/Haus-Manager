-- Safe and Wardrobe interaction system - Optimized for multicore operation
-- Uses Framework Bridge (loaded before this file)
local safeProps = {} -- Track spawned safe props (3D objects)
local wardrobeMarkers = {} -- Track wardrobe markers
local nearbyInteractables = {safes = {}, wardrobes = {}} -- Shared cache for nearby safes and wardrobes
local INTERACTABLE_CHECK_INTERVAL = 500 -- Check every 500ms

-- Initialize safe and wardrobe markers when player enters property
RegisterNetEvent('haus-manager:client:setupInteriorMarkers', function(property)
    if not property then return end
    
    -- Setup Safe prop (3D object) if coordinates exist
    if property.safe_coords and property.safe_coords ~= '' then
        local success, safeData = pcall(json.decode, property.safe_coords)
        if success and safeData and safeData.x then
            CreateSafeProp(property.property_id, safeData)
            if Config.Debug then
                print(string.format("^3[Haus-Manager Safe]^7 Created safe prop for property %s at coords: %.2f, %.2f, %.2f", 
                    property.property_id or "unknown", safeData.x, safeData.y, safeData.z))
            end
        end
    end
    
    -- Setup Wardrobe marker if coordinates exist
    if property.wardrobe_coords and property.wardrobe_coords ~= '' then
        local success, wardrobeData = pcall(json.decode, property.wardrobe_coords)
        if success and wardrobeData and wardrobeData.x then
            CreateWardrobeMarker(property.property_id, wardrobeData)
            if Config.Debug then
                print(string.format("^3[Haus-Manager Wardrobe]^7 Created wardrobe marker for property %s at coords: %.2f, %.2f, %.2f", 
                    property.property_id or "unknown", wardrobeData.x, wardrobeData.y, wardrobeData.z))
            end
        end
    end
end)

-- Clean up markers/props when player exits property
RegisterNetEvent('haus-manager:client:cleanupInteriorMarkers', function(propertyId)
    -- Clean up safe prop
    if safeProps[propertyId] then
        if DoesEntityExist(safeProps[propertyId].entity) then
            DeleteEntity(safeProps[propertyId].entity)
        end
        safeProps[propertyId].active = false
        safeProps[propertyId] = nil
    end
    
    -- Clean up wardrobe marker
    if wardrobeMarkers[propertyId] then
        wardrobeMarkers[propertyId].active = false
        wardrobeMarkers[propertyId] = nil
    end
    if Config.Debug then
        print(string.format("^3[Haus-Manager]^7 Cleaned up safe/wardrobe for property %s", propertyId or "unknown"))
    end
end)

-- QB-Inventory stash handler removed - server handles everything directly

-- Remove safe prop immediately (when admin deletes coordinates)
RegisterNetEvent('haus-manager:client:removeSafeProp', function(propertyId)
    if not propertyId then return end
    
    -- Delete the safe prop entity
    if safeProps[propertyId] then
        if DoesEntityExist(safeProps[propertyId].entity) then
            DeleteEntity(safeProps[propertyId].entity)
        end
        safeProps[propertyId].active = false
        safeProps[propertyId] = nil
        if Config.Debug then
            print(string.format("^2[Haus-Manager Safe]^7 Removed safe prop for property %s", propertyId))
        end
    end
end)

-- Remove wardrobe marker immediately (when admin deletes coordinates)
RegisterNetEvent('haus-manager:client:removeWardrobeProp', function(propertyId)
    if not propertyId then return end
    
    -- Stop the marker interaction
    if wardrobeMarkers[propertyId] then
        wardrobeMarkers[propertyId].active = false
        wardrobeMarkers[propertyId] = nil
        if Config.Debug then
            print(string.format("^2[Haus-Manager Wardrobe]^7 Removed wardrobe marker for property %s", propertyId))
        end
    end
end)

-- Refresh interior markers when property is updated (safe/wardrobe coordinates changed)
RegisterNetEvent('haus-manager:client:refreshInteriorMarkers', function(propertyId, updatedProperty)
    if not propertyId or not updatedProperty then return end
    
    -- Check if player is currently in this property's interior
    local currentInterior = exports['Haus-Manager']:GetCurrentInterior()
    if not currentInterior or currentInterior.propertyId ~= propertyId then
        -- Player is not in this property, skip
        return
    end
    
    if Config.Debug then
        print(string.format("^3[Haus-Manager]^7 Refreshing interior markers for property %s", propertyId))
    end
    
    -- Remove old safe prop
    if safeProps[propertyId] then
        if DoesEntityExist(safeProps[propertyId].entity) then
            DeleteEntity(safeProps[propertyId].entity)
        end
        safeProps[propertyId].active = false
        safeProps[propertyId] = nil
    end
    
    -- Remove old wardrobe marker
    if wardrobeMarkers[propertyId] then
        wardrobeMarkers[propertyId].active = false
        wardrobeMarkers[propertyId] = nil
    end
    
    -- Create new safe prop if coordinates exist
    if updatedProperty.safe_coords and updatedProperty.safe_coords ~= '' then
        local success, safeData = pcall(json.decode, updatedProperty.safe_coords)
        if success and safeData and safeData.x then
            CreateSafeProp(propertyId, safeData)
            if Config.Debug then
                print(string.format("^2[Haus-Manager Safe]^7 Re-created safe prop for property %s at new coords: %.2f, %.2f, %.2f", 
                    propertyId, safeData.x, safeData.y, safeData.z))
            end
        end
    end
    
    -- Create new wardrobe marker if coordinates exist
    if updatedProperty.wardrobe_coords and updatedProperty.wardrobe_coords ~= '' then
        local success, wardrobeData = pcall(json.decode, updatedProperty.wardrobe_coords)
        if success and wardrobeData and wardrobeData.x then
            CreateWardrobeMarker(propertyId, wardrobeData)
            if Config.Debug then
                print(string.format("^2[Haus-Manager Wardrobe]^7 Re-created wardrobe marker for property %s at new coords: %.2f, %.2f, %.2f", 
                    propertyId, wardrobeData.x, wardrobeData.y, wardrobeData.z))
            end
        end
    end
end)

-- Create Safe Prop (3D object - realistic safe model)
function CreateSafeProp(propertyId, coords)
    -- Request safe model
    local safeModel = `p_v_43_safe_s`
    RequestModel(safeModel)
    while not HasModelLoaded(safeModel) do
        Wait(10)
    end
    
    -- Create safe object
    local safeProp = CreateObject(safeModel, coords.x, coords.y, coords.z, false, false, false)
    
    -- Place on ground properly
    PlaceObjectOnGroundProperly(safeProp)
    
    -- Set heading/rotation
    SetEntityHeading(safeProp, coords.heading or 0.0)
    
    -- Freeze position so it can't be moved
    FreezeEntityPosition(safeProp, true)
    
    -- Store safe prop data
    safeProps[propertyId] = {
        entity = safeProp,
        coords = vector3(coords.x, coords.y, coords.z),
        heading = coords.heading or 0.0,
        active = true
    }
    
    if Config.Debug then
        print(string.format("^2[Haus-Manager Safe]^7 Spawned safe prop entity: %s at Vec4(%.2f, %.2f, %.2f, %.2f)", 
            safeProp, coords.x, coords.y, coords.z, coords.heading or 0.0))
    end
    
    -- No individual thread needed - handled by centralized multicore system
end

-- Create Wardrobe marker and interaction (bright cyan marker for visibility)
function CreateWardrobeMarker(propertyId, coords)
    wardrobeMarkers[propertyId] = {
        coords = vector3(coords.x, coords.y, coords.z),
        heading = coords.heading or 0.0,
        active = true
    }
    
    -- No individual thread needed - handled by centralized multicore system
end

-- Open Safe (Inventory/Stash)
function OpenSafe(propertyId)
    if Config.Debug then
        print(string.format("^2[Haus-Manager Safe]^7 Opening safe for property: %s", propertyId))
    end
    
    -- Trigger server event to register and open the stash
    TriggerServerEvent('haus-manager:server:openSafe', propertyId)
end

-- Note: QB-Inventory handler removed - server handles it directly

-- Client-side handler for OX-Inventory safe opening
RegisterNetEvent('haus-manager:client:openOxSafe', function(stashName)
    if GetResourceState('ox_inventory') == 'started' then
        exports.ox_inventory:openInventory('stash', stashName)
        if Config.Debug then
            print(string.format("^2[Haus-Manager Safe]^7 Opened OX-Inventory stash: %s", stashName))
        end
    end
end)

-- Open Wardrobe (Saved Outfits Only - NOT full clothing editor)
function OpenWardrobe(propertyId)
    if Config.Debug then
        print(string.format("^2[Haus-Manager Wardrobe]^7 Opening wardrobe for property: %s", propertyId))
    end
    
    -- Check if player has access to this property
    Framework.TriggerCallback('haus-manager:server:hasPropertyAccess', function(hasAccess)
        if not hasAccess then
            TriggerEvent('QBCore:Notify', 'Sie haben keinen Zugriff auf diese Garderobe!', 'error')
            return
        end
        
        -- Open OUTFIT menu (saved outfits only - NOT full clothing editor)
        if GetResourceState('qb-clothing') == 'started' then
            -- QB-Clothing: Open outfit menu (saved outfits only)
            TriggerEvent('qb-clothing:client:openOutfitMenu')
            TriggerEvent('QBCore:Notify', 'Garderobe geöffnet - Gespeicherte Outfits', 'success')
        elseif GetResourceState('illenium-appearance') == 'started' then
            -- Illenium Appearance: Open wardrobe (shows saved outfits)
            exports['illenium-appearance']:openWardrobe()
            TriggerEvent('QBCore:Notify', 'Garderobe geöffnet - Gespeicherte Outfits', 'success')
        elseif GetResourceState('fivem-appearance') == 'started' then
            -- FiveM Appearance: Open clothing menu with saved outfits
            exports['fivem-appearance']:openClothing()
            TriggerEvent('QBCore:Notify', 'Garderobe geöffnet - Gespeicherte Outfits', 'success')
        elseif GetResourceState('qb-shops') == 'started' then
            -- Fallback: QB-Shops clothing menu
            TriggerEvent('qb-shops:client:openOutfitMenu')
            TriggerEvent('QBCore:Notify', 'Garderobe geöffnet - Gespeicherte Outfits', 'success')
        else
            TriggerEvent('QBCore:Notify', 'Kein Kleidungs-System gefunden!', 'error')
        end
    end, propertyId)
end

-- Draw 3D text helper
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.017 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

-- ========== MULTICORE OPTIMIZATION THREADS ==========
-- These centralized threads replace individual per-prop threads for better performance

-- Thread 1: Nearby interactables calculator (runs independently)
-- Calculates nearby interactables (safes and wardrobes) for all properties
CreateThread(function()
    while true do
        Wait(INTERACTABLE_CHECK_INTERVAL)
        
        local playerCoords = GetEntityCoords(PlayerPedId())
        local tempNearby = {safes = {}, wardrobes = {}}
        
        -- Check nearby safes
        for propertyId, safeData in pairs(safeProps) do
            if safeData.active then
                local distance = #(playerCoords - safeData.coords)
                if distance <= 10.0 then
                    tempNearby.safes[propertyId] = {
                        coords = safeData.coords,
                        distance = distance
                    }
                end
            end
        end
        
        -- Check nearby wardrobes
        for propertyId, wardrobeData in pairs(wardrobeMarkers) do
            if wardrobeData.active then
                local distance = #(playerCoords - wardrobeData.coords)
                if distance <= 10.0 then
                    tempNearby.wardrobes[propertyId] = {
                        coords = wardrobeData.coords,
                        distance = distance
                    }
                end
            end
        end
        
        nearbyInteractables = tempNearby
    end
end)

-- Thread 2: Unified safe rendering and interaction (optimized)
-- Renders 3D text and handles interactions for all nearby safes
CreateThread(function()
    while true do
        Wait(0)
        
        if not nearbyInteractables or not nearbyInteractables.safes then
            Wait(500)
            goto continue
        end
        
        local hasNearbySafes = false
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for propertyId, safeData in pairs(nearbyInteractables.safes) do
            hasNearbySafes = true
            local distance = #(playerCoords - safeData.coords)
            
            if distance <= 2.0 then
                -- Draw 3D text above safe
                local groundZ = safeData.coords.z + 0.8
                DrawText3D(safeData.coords.x, safeData.coords.y, groundZ, "[E] Tresor öffnen")
                
                if IsControlJustReleased(0, 38) then -- E key
                    OpenSafe(propertyId)
                end
            end
        end
        
        if not hasNearbySafes then
            Wait(500)
        end
        
        ::continue::
    end
end)

-- Thread 3: Unified wardrobe rendering and interaction (optimized)
-- Renders markers and handles interactions for all nearby wardrobes
CreateThread(function()
    while true do
        Wait(0)
        
        if not nearbyInteractables or not nearbyInteractables.wardrobes then
            Wait(500)
            goto continue
        end
        
        local hasNearbyWardrobes = false
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for propertyId, wardrobeData in pairs(nearbyInteractables.wardrobes) do
            hasNearbyWardrobes = true
            
            -- Draw bright cyan/turquoise wardrobe marker for high visibility
            DrawMarker(
                20, -- Vertical cylinder
                wardrobeData.coords.x, wardrobeData.coords.y, wardrobeData.coords.z,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                0.4, 0.4, 0.5, -- Slightly larger for visibility
                0, 255, 255, 220, -- Bright Cyan/Turquoise - very visible
                false, false, 2, false, nil, nil, false
            )
            
            local distance = #(playerCoords - wardrobeData.coords)
            
            if distance <= 2.0 then
                -- Draw 3D text
                DrawText3D(wardrobeData.coords.x, wardrobeData.coords.y, wardrobeData.coords.z + 0.5, "[E] Garderobe öffnen")
                
                if IsControlJustReleased(0, 38) then -- E key
                    OpenWardrobe(propertyId)
                end
            end
        end
        
        if not hasNearbyWardrobes then
            Wait(500)
        end
        
        ::continue::
    end
end)
