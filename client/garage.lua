-- Garage system with interior teleportation
-- Uses Framework Bridge (loaded before this file)
local currentGarage = nil
local inGarageInterior = false
local lastExteriorCoords = nil
local currentPropertyData = nil -- Store property data for fallback
local spawnedGarageVehicles = {} -- Track spawned vehicles for cleanup

-- Helper function: Validate coordinates are valid numbers
local function IsValidCoords(coords)
    if not coords then return false end
    if type(coords) ~= "table" then return false end
    if not coords.x or not coords.y or not coords.z then return false end
    if type(coords.x) ~= "number" or type(coords.y) ~= "number" or type(coords.z) ~= "number" then return false end
    -- Check if coordinates are not NaN or Inf
    if coords.x ~= coords.x or coords.y ~= coords.y or coords.z ~= coords.z then return false end
    if coords.x == math.huge or coords.y == math.huge or coords.z == math.huge then return false end
    if coords.x == -math.huge or coords.y == -math.huge or coords.z == -math.huge then return false end
    return true
end

-- Helper function: Get safe exit coordinates with fallback
local function GetSafeExitCoords()
    -- First try: Use saved player position (lastExteriorCoords)
    if IsValidCoords(lastExteriorCoords) then
        return lastExteriorCoords
    end
    
    -- Second try: Use property garage coordinates as fallback
    if currentPropertyData and currentPropertyData.garage_coords then
        local success, garageCoords = pcall(json.decode, currentPropertyData.garage_coords)
        if success and IsValidCoords(garageCoords) then
            print("[Haus-Manager] FALLBACK: Verwende Garagen-Eingangskoordinaten (lastExteriorCoords ungültig)")
            return garageCoords
        end
    end
    
    -- Third try: Use current player position (emergency fallback)
    local playerPed = PlayerPedId()
    local currentPos = GetEntityCoords(playerPed)
    if IsValidCoords({x = currentPos.x, y = currentPos.y, z = currentPos.z}) then
        print("[Haus-Manager] NOTFALL-FALLBACK: Verwende aktuelle Position")
        return {
            x = currentPos.x,
            y = currentPos.y,
            z = currentPos.z,
            heading = GetEntityHeading(playerPed)
        }
    end
    
    -- Fourth try: Return to world center (absolute emergency)
    print("[Haus-Manager] KRITISCHER FEHLER: Keine gültigen Koordinaten gefunden, teleportiere zu Standardposition")
    return {
        x = 0.0,
        y = 0.0,
        z = 75.0,
        heading = 0.0
    }
end

-- Garage interior configurations (IPL-based garages)
local GarageInteriors = {
    small = {
        coords = vector4(173.2903, -1003.6, -99.6571, 180.0),
        slots = 2,
        parkingSlots = {
            vector4(172.5, -1004.5, -99.0, 180.0),
            vector4(175.5, -1004.5, -99.0, 180.0)
        },
        exitMarker = vector3(173.5, -1000.5, -99.0)
    },
    medium = {
        coords = vector4(197.8153, -1002.293, -99.6571, 180.0),
        slots = 6,
        parkingSlots = {
            vector4(193.5, -1004.0, -99.0, 180.0),
            vector4(196.5, -1004.0, -99.0, 180.0),
            vector4(199.5, -1004.0, -99.0, 180.0),
            vector4(193.5, -1000.5, -99.0, 180.0),
            vector4(196.5, -1000.5, -99.0, 180.0),
            vector4(199.5, -1000.5, -99.0, 180.0)
        },
        exitMarker = vector3(197.5, -997.5, -99.0)
    },
    large = {
        coords = vector4(229.9559, -981.7928, -99.6606, 180.0),
        slots = 16,
        parkingSlots = {
            -- Left column (lengthwise down the garage)
            vector4(227.0, -983.5, -99.0, 180.0),  -- Front-left
            vector4(227.0, -982.0, -99.0, 180.0),
            vector4(227.0, -980.5, -99.0, 180.0),
            vector4(227.0, -979.0, -99.0, 180.0),
            vector4(227.0, -977.5, -99.0, 180.0),
            vector4(227.0, -976.0, -99.0, 180.0),
            vector4(227.0, -974.5, -99.0, 180.0),
            vector4(227.0, -973.0, -99.0, 180.0),  -- Back-left
            
            -- Right column (lengthwise down the garage)
            vector4(233.0, -983.5, -99.0, 180.0),  -- Front-right
            vector4(233.0, -982.0, -99.0, 180.0),
            vector4(233.0, -980.5, -99.0, 180.0),
            vector4(233.0, -979.0, -99.0, 180.0),
            vector4(233.0, -977.5, -99.0, 180.0),
            vector4(233.0, -976.0, -99.0, 180.0),
            vector4(233.0, -974.5, -99.0, 180.0),
            vector4(233.0, -973.0, -99.0, 180.0)   -- Back-right
        },
        exitMarker = vector3(229.5, -975.5, -99.0)
    }
}

-- Spawn vehicle at parking slot
local function spawnVehicleAtSlot(vehicleData, coords)
    local model = vehicleData.model
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(50)
    end
    
    local vehicle = CreateVehicle(model, coords.x, coords.y, coords.z, coords.w, true, false)
    SetEntityAsMissionEntity(vehicle, true, true)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')
    SetModelAsNoLongerNeeded(model)
    
    Framework.SetVehicleProperties(vehicle, vehicleData)
    
    return vehicle
end

-- Enter garage interior
RegisterNetEvent('haus-manager:client:enterGarage', function(property)
    -- Check if player has access to this property
    Framework.TriggerCallback('haus-manager:server:hasPropertyAccess', function(hasAccess)
        if not hasAccess then
            Framework.Notify("Sie haben keinen Zugang zu dieser Garage!", 'error')
            return
        end
        
        local garageSize = property.garage_size or 'small'
        local garageConfig = GarageInteriors[garageSize]
        
        if not garageConfig then
            Framework.Notify("Garage-Konfiguration nicht gefunden!", 'error')
            return
        end
        
        -- Save exterior coordinates - validate player is near garage entrance
        local playerPed = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(playerPed, false)
        local currentCoords = GetEntityCoords(playerPed)
        
        -- Validate player is actually near the garage entrance before saving coords
        if property.garage_coords then
            local success, garageCoords = pcall(function()
                return type(property.garage_coords) == "string" and json.decode(property.garage_coords) or property.garage_coords
            end)
            
            if success and garageCoords and garageCoords.x then
                local gCoords = vector3(garageCoords.x, garageCoords.y, garageCoords.z)
                local distance = #(currentCoords - gCoords)
                
                if distance <= 10.0 then
                    -- Player is close enough - save their actual position
                    lastExteriorCoords = {
                        x = currentCoords.x,
                        y = currentCoords.y,
                        z = currentCoords.z,
                        heading = GetEntityHeading(playerPed)
                    }
                else
                    -- Player too far - use garage entrance coordinates as fallback
                    lastExteriorCoords = {
                        x = garageCoords.x,
                        y = garageCoords.y,
                        z = garageCoords.z,
                        heading = garageCoords.heading or 0.0
                    }
                end
            else
                -- Invalid garage coords or JSON parse error - use current position
                lastExteriorCoords = {
                    x = currentCoords.x,
                    y = currentCoords.y,
                    z = currentCoords.z,
                    heading = GetEntityHeading(playerPed)
                }
            end
        else
            -- No garage coords defined - use current position
            lastExteriorCoords = {
                x = currentCoords.x,
                y = currentCoords.y,
                z = currentCoords.z,
                heading = GetEntityHeading(playerPed)
            }
        end
        
        -- Save property data for fallback
        currentPropertyData = property
        
        -- If in vehicle, store it
        if vehicle ~= 0 then
            local plate = Framework.GetPlate(vehicle)
            local vehicleProps = Framework.GetVehicleProperties(vehicle)
            TriggerServerEvent('haus-manager:server:storeVehicle', property.property_id, plate, vehicleProps)
            DeleteVehicle(vehicle)
        end
        
        -- Teleport to garage interior
        DoScreenFadeOut(500)
        Wait(500)
        
        SetEntityCoords(playerPed, garageConfig.coords.x, garageConfig.coords.y, garageConfig.coords.z)
        SetEntityHeading(playerPed, garageConfig.coords.w)
        
        Wait(500)
        DoScreenFadeIn(500)
        
        inGarageInterior = true
        currentGarage = {property = property, config = garageConfig}
        
        -- Fetch and spawn all stored vehicles
        Framework.TriggerCallback('haus-manager:server:getGarageVehicles', function(vehicles)
            for i, vehicleEntry in ipairs(vehicles) do
                if i <= #garageConfig.parkingSlots then
                    local vehicleData = json.decode(vehicleEntry.vehicle_data)
                    local parkingCoords = garageConfig.parkingSlots[i]
                    local spawnedVehicle = spawnVehicleAtSlot(vehicleData, parkingCoords)
                    table.insert(spawnedGarageVehicles, spawnedVehicle)
                end
            end
        end, property.property_id)
        
        Framework.Notify("Garage betreten", 'success')
    end, property.property_id)
end)

-- Exit garage interior
RegisterNetEvent('haus-manager:client:exitGarage', function()
    if not inGarageInterior then
        return
    end
    
    local playerPed = PlayerPedId()
    local currentVehicle = GetVehiclePedIsIn(playerPed, false)
    local isInVehicle = currentVehicle ~= 0
    
    -- Delete all spawned vehicles EXCEPT the one player is currently in
    for _, vehicle in ipairs(spawnedGarageVehicles) do
        if DoesEntityExist(vehicle) and vehicle ~= currentVehicle then
            DeleteVehicle(vehicle)
        end
    end
    spawnedGarageVehicles = {}
    
    -- Get safe exit coordinates with fallback
    local exitCoords = GetSafeExitCoords()
    
    -- Validate we got valid coordinates
    if not IsValidCoords(exitCoords) then
        Framework.Notify("FEHLER: Ungültige Exit-Koordinaten! Kontaktieren Sie einen Admin.", 'error')
        print("[Haus-Manager] KRITISCHER FEHLER: GetSafeExitCoords() gab ungültige Koordinaten zurück!")
        return
    end
    
    DoScreenFadeOut(500)
    Wait(500)
    
    -- If player is in a vehicle, teleport the vehicle (player goes with it)
    if isInVehicle then
        -- Use smaller z offset (0.5) for vehicles to prevent floating
        SetEntityCoords(currentVehicle, exitCoords.x, exitCoords.y, exitCoords.z + 0.5)
        SetEntityHeading(currentVehicle, exitCoords.heading or 0.0)
    else
        -- If on foot, use exact z-coordinate
        SetEntityCoords(playerPed, exitCoords.x, exitCoords.y, exitCoords.z)
        SetEntityHeading(playerPed, exitCoords.heading or 0.0)
    end
    
    Wait(500)
    DoScreenFadeIn(500)
    
    inGarageInterior = false
    currentGarage = nil
    lastExteriorCoords = nil
    currentPropertyData = nil
    
    Framework.Notify("Garage verlassen", 'success')
end)

-- Open garage menu (for spawning vehicles inside garage)
RegisterNetEvent('haus-manager:client:openGarageMenu', function(data)
    local property = data.property
    
    Framework.TriggerCallback('haus-manager:server:getGarageVehicles', function(vehicles)
        local garageSize = property.garage_size or 'small'
        local garageConfig = GarageInteriors[garageSize]
        local maxSlots = garageConfig and garageConfig.slots or 2
        
        local menu = {
            {
                header = property.property_name .. " - Garage",
                txt = string.format("Kapazität: %d/%d", #vehicles, maxSlots),
                isMenuHeader = true
            }
        }
        
        -- Add stored vehicles
        for _, vehicle in ipairs(vehicles) do
            local vehicleData = json.decode(vehicle.vehicle_data)
            local status = vehicle.stored == 1 and "Eingelagert" or "Draußen"
            
            table.insert(menu, {
                header = GetDisplayNameFromVehicleModel(vehicleData.model) or "Fahrzeug",
                txt = string.format("Kennzeichen: %s | Status: %s", vehicle.plate, status),
                params = {
                    isServer = true,
                    event = "haus-manager:server:spawnVehicle",
                    args = {
                        property.property_id,
                        vehicle.plate
                    }
                }
            })
        end
        
        table.insert(menu, {
            header = "Schließen",
            params = {
                event = "haus-manager:client:closeMenu"
            }
        })
        
        Menu.Open(menu)
    end, property.property_id)
end)

-- Vehicle options menu
RegisterNetEvent('haus-manager:client:garageVehicleOptions', function(data)
    local property = data.property
    local vehicle = data.vehicle
    
    local menu = {
        {
            header = "Fahrzeug Optionen",
            isMenuHeader = true
        }
    }
    
    if vehicle.stored == 1 then
        table.insert(menu, {
            header = "Fahrzeug ausholen",
            txt = "Holen Sie das Fahrzeug aus der Garage",
            params = {
                isServer = true,
                event = "haus-manager:server:spawnVehicle",
                args = {
                    property.property_id,
                    vehicle.plate
                }
            }
        })
    else
        table.insert(menu, {
            header = "Fahrzeug ist bereits draußen",
            txt = "",
            disabled = true
        })
    end
    
    table.insert(menu, {
        header = "Zurück",
        params = {
            event = "haus-manager:client:openGarageMenu",
            args = {
                property = property
            }
        }
    })
    
    Menu.Open(menu)
end)

-- Store current vehicle
RegisterNetEvent('haus-manager:client:storeCurrentVehicle', function(data)
    local property = data.property
    local playerPed = PlayerPedId()
    
    if not IsPedInAnyVehicle(playerPed, false) then
        Framework.Notify("Sie müssen in einem Fahrzeug sitzen!", 'error')
        return
    end
    
    local vehicle = GetVehiclePedIsIn(playerPed, false)
    local plate = Framework.GetPlate(vehicle)
    local vehicleProps = Framework.GetVehicleProperties(vehicle)
    
    -- Check if near garage
    local garageCoords = json.decode(property.garage_coords)
    local vehicleCoords = GetEntityCoords(vehicle)
    local distance = #(vector3(garageCoords.x, garageCoords.y, garageCoords.z) - vehicleCoords)
    
    if distance > 10.0 then
        Framework.Notify("Sie sind zu weit von der Garage entfernt!", 'error')
        return
    end
    
    -- Store vehicle
    TriggerServerEvent('haus-manager:server:storeVehicle', property.property_id, plate, vehicleProps)
    
    -- Delete vehicle
    Framework.DeleteVehicle(vehicle)
end)

-- Spawn vehicle from garage
RegisterNetEvent('haus-manager:client:spawnVehicle', function(vehicleData, garageCoords)
    local coords = vector4(garageCoords.x, garageCoords.y, garageCoords.z, garageCoords.heading or 0.0)
    
    Framework.SpawnVehicle(vehicleData.model, function(vehicle)
        Framework.SetVehicleProperties(vehicle, vehicleData)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        TriggerEvent("vehiclekeys:client:SetOwner", Framework.GetPlate(vehicle))
        SetVehicleEngineOn(vehicle, true, true)
        Framework.Notify("Fahrzeug ausgeholt!", 'success')
    end, coords, true)
end)

-- Garage system variables for multicore optimization
local cachedGarageProperties = {}
local lastGarageUpdate = 0
local nearbyGarages = {}
local GARAGE_CACHE_INTERVAL = 5000
local GARAGE_CHECK_INTERVAL = 500

-- Create garage marker thread (SEPARATE FROM PROPERTY ENTRANCE) - OPTIMIZED FOR MULTICORE
-- Thread 1: Garage property cache updater
-- Updates garage property cache from database every 5 seconds
CreateThread(function()
    print("^3[Haus-Manager Garage]^7 Garage cache system initializing...")
    Wait(5000) -- Wait for properties to load
    
    while true do
        Wait(GARAGE_CACHE_INTERVAL)
        
        if not GetProperties then
            goto continue
        end
        
        local success, properties = pcall(function()
            return GetProperties()
        end)
        
        if success and properties and #properties > 0 then
            local tempCache = {}
            for _, property in ipairs(properties) do
                -- Only cache properties with valid garages
                if property.garage_coords and property.garage_coords ~= "" and property.garage_coords ~= "null" then
                    local coordSuccess, garageCoords = pcall(function()
                        if type(property.garage_coords) == "string" then
                            return json.decode(property.garage_coords)
                        else
                            return property.garage_coords
                        end
                    end)
                    
                    if coordSuccess and garageCoords and garageCoords.x then
                        table.insert(tempCache, {
                            property = property,
                            coords = vector3(garageCoords.x, garageCoords.y, garageCoords.z)
                        })
                    end
                end
            end
            cachedGarageProperties = tempCache
            lastGarageUpdate = GetGameTimer()
        end
        
        ::continue::
    end
end)

-- Thread 2: Nearby garage calculator
-- Calculates which garages are near player position
CreateThread(function()
    while true do
        Wait(GARAGE_CHECK_INTERVAL)
        
        if not cachedGarageProperties or #cachedGarageProperties == 0 then
            nearbyGarages = {}
            goto continue
        end
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local tempNearby = {}
        
        for _, garageData in ipairs(cachedGarageProperties) do
            local distance = #(playerCoords - garageData.coords)
            
            -- Only include garages within 3 meters
            if distance <= 3.0 then
                table.insert(tempNearby, {
                    property = garageData.property,
                    coords = garageData.coords,
                    distance = distance
                })
            end
        end
        
        nearbyGarages = tempNearby
        
        ::continue::
    end
end)

-- Thread 3: Main garage marker renderer (optimized)
-- Renders garage markers and handles interactions for nearby garages only
CreateThread(function()
    print("^3[Haus-Manager Garage]^7 Garage marker thread started")
    
    while true do
        Wait(0)
        
        if not nearbyGarages or #nearbyGarages == 0 then
            Wait(500)
            goto continue
        end
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local sleep = true
        
        for _, garageData in ipairs(nearbyGarages) do
            sleep = false
            local property = garageData.property
            local gCoords = garageData.coords
            
            -- Recalculate distance for accuracy
            local distance = #(playerCoords - gCoords)
            
            -- Draw SEPARATE garage marker (larger blue/cyan marker to distinguish from property entrance)
            DrawMarker(
                1, -- Cylinder
                gCoords.x, gCoords.y, gCoords.z - 0.5,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                1.5, 1.5, 1.0, -- Larger and more visible
                100, 150, 255, 150, -- Light blue/cyan color to distinguish from property
                false, false, 2, false, nil, nil, false
            )
            
            local playerVehicle = GetVehiclePedIsIn(playerPed, false)
            
            if playerVehicle ~= 0 then
                -- Player is in a vehicle - show ENTER GARAGE option
                DrawText3D(gCoords.x, gCoords.y, gCoords.z + 1.0, "[E] Garage betreten (Fahrzeug einlagern)")
                
                if IsControlJustReleased(0, 38) then -- E key
                    -- Enter garage interior with vehicle
                    TriggerEvent('haus-manager:client:enterGarage', property)
                end
            else
                -- Player is on foot - show ENTER GARAGE option
                DrawText3D(gCoords.x, gCoords.y, gCoords.z + 1.0, "[E] Garage betreten")
                
                if IsControlJustReleased(0, 38) then -- E key
                    -- Enter garage interior
                    TriggerEvent('haus-manager:client:enterGarage', property)
                end
            end
        end
        
        if sleep then
            Wait(500)
        end
        
        ::continue::
    end
end)

-- Garage interior exit marker thread
CreateThread(function()
    while true do
        Wait(0)
        
        if inGarageInterior and currentGarage then
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local exitMarker = currentGarage.config.exitMarker
            
            -- Draw red exit marker
            DrawMarker(
                1, -- Cylinder
                exitMarker.x, exitMarker.y, exitMarker.z - 0.5,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                1.5, 1.5, 1.0,
                255, 50, 50, 200, -- Red color for exit
                false, false, 2, false, nil, nil, false
            )
            
            local distance = #(playerCoords - exitMarker)
            
            if distance <= 2.0 then
                DrawText3D(exitMarker.x, exitMarker.y, exitMarker.z + 1.0, "[E] Garage verlassen")
                
                if IsControlJustReleased(0, 38) then -- E key
                    TriggerEvent('haus-manager:client:exitGarage')
                end
            end
        else
            Wait(1000) -- Sleep when not in garage
        end
    end
end)

-- Auto-exit garage when player enters vehicle and starts driving
CreateThread(function()
    while true do
        Wait(500) -- Check every 500ms
        
        if inGarageInterior and currentGarage then
            local playerPed = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(playerPed, false)
            
            -- Check if player is in a vehicle
            if vehicle ~= 0 then
                -- Check if vehicle is moving (player started driving)
                local speed = GetEntitySpeed(vehicle)
                
                -- If speed is above threshold, auto-exit garage
                if speed > 0.5 then -- ~1.8 km/h threshold (very low to trigger quickly)
                    Framework.Notify("Automatisch aus der Garage gefahren", 'info')
                    TriggerEvent('haus-manager:client:exitGarage')
                    Wait(2000) -- Prevent rapid re-triggering
                end
            end
        else
            Wait(1000) -- Sleep longer when not in garage
        end
    end
end)

-- Draw 3D text helper (if not already defined)
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
