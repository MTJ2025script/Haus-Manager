-- DEAKTIVIERT: Alte Interior-Funktionen - main.lua übernimmt jetzt alles
-- Diese Datei ist nur noch für Safe/Wardrobe Marker und den Exit Command
local currentInterior = nil
local insideProperty = false

-- Diese Funktionen werden nicht mehr verwendet - main.lua EnterProperty/ExitProperty sind aktiv
--[[
function EnterInterior(property) ... end
function ExitInterior() ... end  
function CreateInteriorExitMarker(spawnCoords) ... end
]]--

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

-- DEAKTIVIERT: Alte Exit-Marker Funktion - wird jetzt von main.lua gehandhabt
-- Diese Funktion verursachte Crashes (spawnCoords nil) und grüne Marker
-- Das neue System in main.lua verwendet isInProperty und ExitProperty()
--[[
function CreateInteriorExitMarker(spawnCoords)
    CreateThread(function()
        local exitCoords = vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z)
        
        while insideProperty do
            Wait(0)
            
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - exitCoords)
            
            if distance <= 50.0 then
                DrawMarker(
                    1, -- Cylinder
                    exitCoords.x, exitCoords.y, exitCoords.z - 0.95,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    1.2, 1.2, 0.8,
                    100, 255, 100, 180, -- Green color for exit (not red!)
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
]]--

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

-- Export functions for other scripts to use if needed
exports('EnterInterior', EnterInterior)
exports('ExitInterior', ExitInterior)
exports('IsInsideProperty', function() return insideProperty end)
exports('GetCurrentInterior', function() return currentInterior end)
