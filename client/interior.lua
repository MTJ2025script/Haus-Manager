-- Interior system using QB-Interior natives
-- Uses Framework Bridge (loaded before this file)
local currentInterior = nil
local insideProperty = false

-- Enter interior (using qb-interior)
function EnterInterior(property)
    local interiorType = property.interior_type
    local interiorConfig = Config.Interiors[interiorType]
    
    if not interiorConfig then
        Framework.Notify("Ungültiger Innenraum!", 'error')
        return
    end
    
    -- Store current exterior position
    local exteriorCoords = GetEntityCoords(PlayerPedId())
    
    -- Use QB-Interior to load the shell
    -- This is a placeholder - actual implementation depends on qb-interior structure
    -- Typically you would call something like:
    -- exports['qb-interior']:CreateApartmentShell(interiorConfig.shell, function(interiorId)
    --     -- Teleport player to interior spawn point
    -- end)
    
    -- For now, we'll implement a basic version
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Set interior ID for this property
    currentInterior = {
        propertyId = property.property_id,
        exteriorCoords = exteriorCoords,
        interiorType = interiorType
    }
    
    -- Parse property coordinates
    local coords = json.decode(property.coords)
    
    -- Use QB-Interior approach: Teleport to a unique interior dimension based on property ID
    -- Each interior type has specific coordinates where the shell is loaded
    -- We offset the coordinates to create unique instances
    local propertyOffset = property.property_id and tonumber(string.match(property.property_id, "%d+")) or 0
    
    -- Interior spawn coordinates (proper interior positions based on type)
    -- Using researched coordinates that spawn player inside with proper door access
    local interiorSpawn
    if interiorConfig.type == "apartment" then
        -- Apartment interior with proper spawn point near door
        interiorSpawn = vector4(-782.4077 + (propertyOffset * 0.01), 318.4500, 217.6737, 355.4485)
    elseif interiorConfig.type == "house" then
        -- House interior spawn point
        interiorSpawn = vector4(-174.35 + (propertyOffset * 0.01), 497.5, 137.65, 180.0)
    elseif interiorConfig.type == "office" then
        -- Office interior spawn point
        interiorSpawn = vector4(-141.0 + (propertyOffset * 0.01), -620.0, 168.82, 90.0)
    else
        -- Default to apartment coordinates
        interiorSpawn = vector4(-782.4077, 318.4500, 217.6737, 355.4485)
    end
    
    SetEntityCoords(PlayerPedId(), interiorSpawn.x, interiorSpawn.y, interiorSpawn.z, false, false, false, true)
    SetEntityHeading(PlayerPedId(), interiorSpawn.w)
    
    -- Create interior objects/furniture (simplified)
    CreateInteriorFurniture(property.property_id, interiorConfig)
    
    Wait(500)
    DoScreenFadeIn(500)
    
    insideProperty = true
    
    Framework.Notify(Config.Notifications["entered_property"], 'success')
    
    -- Create exit marker
    CreateInteriorExitMarker(interiorSpawn)
    
    -- Trigger safe and wardrobe marker creation
    TriggerEvent('haus-manager:client:setupInteriorMarkers', property)
end

-- Exit interior
function ExitInterior()
    if not currentInterior then
        Framework.Notify("Sie sind nicht in einer Immobilie!", 'error')
        return
    end
    
    -- Clean up safe and wardrobe markers
    TriggerEvent('haus-manager:client:cleanupInteriorMarkers', currentInterior.propertyId)
    
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Teleport back to exterior
    SetEntityCoords(PlayerPedId(), 
        currentInterior.exteriorCoords.x,
        currentInterior.exteriorCoords.y,
        currentInterior.exteriorCoords.z
    )
    
    -- Clean up interior
    DeleteInteriorFurniture()
    
    currentInterior = nil
    insideProperty = false
    
    Wait(500)
    DoScreenFadeIn(500)
    
    Framework.Notify(Config.Notifications["exited_property"], 'success')
end

-- Create interior furniture (simplified version)
local interiorObjects = {}

function CreateInteriorFurniture(propertyId, interiorConfig)
    -- This is a simplified version
    -- In a full implementation, you would load specific props based on the shell type
    -- For now, we'll just create a basic setup
    
    local playerCoords = GetEntityCoords(PlayerPedId())
    
    -- Example: Create some basic furniture
    -- In reality, qb-interior would handle this with proper shell models
    
    if Config.Debug then
        print(string.format("^3[Haus-Manager]^7 Loading interior: %s", interiorConfig.label))
    end
end

-- Delete interior furniture
function DeleteInteriorFurniture()
    for _, obj in ipairs(interiorObjects) do
        if DoesEntityExist(obj) then
            DeleteObject(obj)
        end
    end
    interiorObjects = {}
end

-- Create exit marker inside property
function CreateInteriorExitMarker(spawnCoords)
    CreateThread(function()
        -- Place exit marker at door/spawn location (where player entered)
        -- This ensures players can always find the exit
        local exitCoords = vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z)
        
        while insideProperty do
            Wait(0)
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - exitCoords)
            
            if distance <= 50.0 then
                -- Draw exit marker (red for visibility) - ON THE GROUND
                DrawMarker(
                    1, -- Cylinder
                    exitCoords.x, exitCoords.y, exitCoords.z - 0.95, -- Just slightly below spawn point to be ON ground
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    1.2, 1.2, 0.8,
                    255, 0, 0, 180,
                    false, false, 2, false, nil, nil, false
                )
                
                if distance <= 3.0 then
                    DrawText3D(exitCoords.x, exitCoords.y, exitCoords.z + 0.5, "[E] Immobilie verlassen")
                    
                    if IsControlJustReleased(0, 38) then -- E key
                        ExitInterior()
                    end
                end
            else
                Wait(500)
            end
        end
    end)
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

-- Override EnterProperty from main.lua
function EnterProperty(property)
    EnterInterior(property)
end

-- Override ExitProperty from main.lua
function ExitProperty()
    ExitInterior()
end

-- Exit property event (triggered when property is sold)
RegisterNetEvent('haus-manager:client:exitProperty', function()
    if insideProperty or currentInterior then
        ExitInterior()
    end
end)

-- Emergency exit command - ALWAYS WORKS regardless of property state
-- This is a safety measure to get players unstuck from ANY location
RegisterCommand('exit', function()
    DoScreenFadeOut(500)
    Wait(500)
    
    -- Try to use stored exterior coords if available, otherwise use Pillbox
    local exitCoords
    if currentInterior and currentInterior.exteriorCoords then
        exitCoords = currentInterior.exteriorCoords
    else
        -- Fallback to Pillbox Hospital (universal safe spawn)
        exitCoords = vector4(304.27, -600.33, 43.28, 272.249)
    end
    
    -- Teleport player to exit location
    SetEntityCoords(PlayerPedId(), exitCoords.x, exitCoords.y, exitCoords.z, false, false, false, true)
    if exitCoords.w then
        SetEntityHeading(PlayerPedId(), exitCoords.w)
    end
    
    -- Clean up any interior state
    DeleteInteriorFurniture()
    currentInterior = nil
    insideProperty = false
    
    Wait(500)
    DoScreenFadeIn(500)
    
    Framework.Notify("Notausgang benutzt - Sie wurden teleportiert!", 'success')
end, false)

-- Player loaded event - just initialize interior state (NO AUTO-SPAWN)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    -- Just ensure interior state is clean on login
    -- DO NOT auto-spawn - let QBCore/multicharacter handle spawn
    if Config.Debug then
        print("^2[Haus-Manager]^7 Player loaded - interior system initialized")
    end
end)

-- Export functions
exports('EnterInterior', EnterInterior)
exports('ExitInterior', ExitInterior)
exports('IsInsideProperty', function() return insideProperty end)
exports('GetCurrentInterior', function() return currentInterior end)
