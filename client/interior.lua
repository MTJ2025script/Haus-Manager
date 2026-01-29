-- Interior Marker System für Safe und Garderobe
-- HINWEIS: Enter/Exit Property wird von main.lua gehandhabt!
-- Diese Datei nur noch für Safe/Wardrobe Marker und Exit Command

local interiorObjects = {}
local activeInteriorMarkers = {}

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

-- Event: Setup interior markers (Safe, Wardrobe) - called by main.lua
RegisterNetEvent('haus-manager:client:setupInteriorMarkers', function(property)
    if not property then return end
    
    local propertyId = property.property_id
    print("^2[Haus-Manager Interior]^7 Setting up markers for: " .. propertyId)
    
    -- Clean up existing markers first
    if activeInteriorMarkers[propertyId] then
        print("^3[Haus-Manager Interior]^7 Cleaning up existing markers")
        for _, thread in pairs(activeInteriorMarkers[propertyId]) do
            if thread then
                -- Threads will stop naturally when markers are replaced
            end
        end
    end
    
    activeInteriorMarkers[propertyId] = {}
    
    -- Create Safe Marker
    if property.safe_coords then
        local safeCoords = json.decode(property.safe_coords)
        print("^2[Haus-Manager Interior]^7 Creating safe marker at: " .. safeCoords.x .. ", " .. safeCoords.y .. ", " .. safeCoords.z)
        
        local safeThread = CreateThread(function()
            local safeProp = CreateObject(GetHashKey("p_v_43_safe_s"), safeCoords.x, safeCoords.y, safeCoords.z, false, false, false)
            SetEntityHeading(safeProp, safeCoords.heading or 0.0)
            FreezeEntityPosition(safeProp, true)
            table.insert(interiorObjects, safeProp)
            
            while isInProperty do
                Wait(0)
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - vector3(safeCoords.x, safeCoords.y, safeCoords.z))
                
                if distance < 2.0 then
                    DrawText3D(safeCoords.x, safeCoords.y, safeCoords.z + 0.5, "[~g~E~w~] Tresor öffnen")
                    if IsControlJustReleased(0, 38) then
                        TriggerEvent('haus-manager:client:openStash', property)
                    end
                end
            end
        end)
        
        activeInteriorMarkers[propertyId].safe = safeThread
    end
    
    -- Create Wardrobe Marker
    if property.wardrobe_coords then
        local wardrobeCoords = json.decode(property.wardrobe_coords)
        print("^2[Haus-Manager Interior]^7 Creating wardrobe marker at: " .. wardrobeCoords.x .. ", " .. wardrobeCoords.y .. ", " .. wardrobeCoords.z)
        
        local wardrobeThread = CreateThread(function()
            while isInProperty do
                Wait(0)
                local playerCoords = GetEntityCoords(PlayerPedId())
                local distance = #(playerCoords - vector3(wardrobeCoords.x, wardrobeCoords.y, wardrobeCoords.z))
                
                if distance <= 50.0 then
                    DrawMarker(
                        1, -- Cylinder
                        wardrobeCoords.x, wardrobeCoords.y, wardrobeCoords.z - 0.95,
                        0.0, 0.0, 0.0,
                        0.0, 0.0, 0.0,
                        0.5, 0.5, 0.3,
                        0, 255, 255, 120, -- Cyan for wardrobe
                        false, true, 2, false, nil, nil, false
                    )
                    
                    if distance < 2.0 then
                        DrawText3D(wardrobeCoords.x, wardrobeCoords.y, wardrobeCoords.z + 0.5, "[~g~E~w~] Garderobe öffnen")
                        if IsControlJustReleased(0, 38) then
                            TriggerEvent('haus-manager:client:openWardrobe', property)
                        end
                    end
                end
            end
        end)
        
        activeInteriorMarkers[propertyId].wardrobe = wardrobeThread
    end
end)

-- Event: Cleanup interior markers - called by main.lua before exit
RegisterNetEvent('haus-manager:client:cleanupInteriorMarkers', function(propertyId)
    if activeInteriorMarkers[propertyId] then
        print("^2[Haus-Manager Interior]^7 Cleaning up markers for: " .. propertyId)
        activeInteriorMarkers[propertyId] = nil
    end
    
    -- Delete spawned objects (safe prop)
    for _, obj in ipairs(interiorObjects) do
        if DoesEntityExist(obj) then
            DeleteObject(obj)
        end
    end
    interiorObjects = {}
end)

-- Emergency exit command - IMMER verfügbar!
RegisterCommand('exit', function()
    print("^2[Haus-Manager Exit Command]^7 Emergency exit triggered")
    
    -- Call ExitProperty from main.lua if player is inside
    if isInProperty and currentProperty then
        TriggerEvent('haus-manager:client:exitProperty')
    else
        -- Fallback: Teleport to Pillbox Hospital
        DoScreenFadeOut(500)
        Wait(500)
        
        local exitCoords = vector4(304.27, -600.33, 43.28, 272.249)
        SetEntityCoords(PlayerPedId(), exitCoords.x, exitCoords.y, exitCoords.z, false, false, false, true)
        SetEntityHeading(PlayerPedId(), exitCoords.w)
        
        Wait(500)
        DoScreenFadeIn(500)
        
        Framework.Notify("Notausgang benutzt - Sie wurden teleportiert!", 'success')
    end
end, false)

print("^2[Haus-Manager]^7 Interior marker system loaded (Safe/Wardrobe only)")
