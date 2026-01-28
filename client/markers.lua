-- Marker system with radius visualization - Optimized for multicore operation
-- Uses Framework Bridge (loaded before this file)
local activeMarkers = {}
local showingMarkers = true
local cachedProperties = {}
local lastPropertyUpdate = 0
local nearbyProperties = {}
local activeTargetZones = {}  -- MOVED UP: Must be defined before propertyDeleted event!
local PROPERTY_CACHE_INTERVAL = 5000 -- Update property cache every 5 seconds
local NEARBY_CHECK_INTERVAL = 500 -- Check nearby properties every 500ms

-- Draw marker with radius ring
local function DrawMarkerWithRadius(coords, markerConfig, radius)
    -- Draw main marker
    DrawMarker(
        markerConfig.Type,
        coords.x, coords.y, coords.z,
        0.0, 0.0, 0.0,
        0.0, 0.0, 0.0,
        markerConfig.Size.x, markerConfig.Size.y, markerConfig.Size.z,
        markerConfig.Color.r, markerConfig.Color.g, markerConfig.Color.b, markerConfig.Alpha,
        markerConfig.BobUpAndDown,
        markerConfig.FaceCamera,
        2,
        markerConfig.Rotate,
        nil, nil,
        false
    )
    
    -- Draw radius ring if enabled
    if markerConfig.ShowRadius then
        DrawMarker(
            28, -- Ring marker
            coords.x, coords.y, coords.z,
            0.0, 0.0, 0.0,
            0.0, 0.0, 0.0,
            radius * 2, radius * 2, 1.0,
            markerConfig.RadiusColor.r, markerConfig.RadiusColor.g, markerConfig.RadiusColor.b, markerConfig.RadiusColor.a,
            false,
            false,
            2,
            false,
            nil, nil,
            false
        )
    end
end

-- Thread 1: Property cache updater (runs independently)
-- Updates the property cache from database every 5 seconds to reduce repeated queries
CreateThread(function()
    -- Wait for Framework to be ready
    while not Framework or not Framework.Object do
        Wait(100)
    end
    print("^3[Haus-Manager Markers]^7 Framework ready, starting property cache updater")
    while true do
        Wait(PROPERTY_CACHE_INTERVAL)
        
        local properties = GetProperties()
        if properties and #properties > 0 then
            cachedProperties = properties
            lastPropertyUpdate = GetGameTimer()
        end
    end
end)

-- Event: Property deleted - remove marker immediately
RegisterNetEvent('haus-manager:client:propertyDeleted', function(propertyId)
    print("^1[Haus-Manager Markers]^7 Property deletion triggered for: " .. propertyId)
    
    -- Remove from cached properties FIRST
    for i, property in ipairs(cachedProperties) do
        if property.property_id == propertyId then
            table.remove(cachedProperties, i)
            print("^2[Haus-Manager Markers]^7 Property removed from cache: " .. propertyId)
            break
        end
    end
    
    -- Remove from nearbyProperties to stop rendering immediately
    for i, property in ipairs(nearbyProperties) do
        if property.property_id == propertyId then
            table.remove(nearbyProperties, i)
            print("^2[Haus-Manager Markers]^7 Property removed from nearby: " .. propertyId)
            break
        end
    end
    
    -- Remove target zone LAST (with safe check and proper error handling)
    local zoneName = "property_" .. propertyId
    if activeTargetZones[zoneName] then
        print("^3[Haus-Manager Markers]^7 Removing target zone: " .. zoneName)
        -- Try to remove zone - if it fails, that's OK
        local success, err = pcall(function()
            if Target and Target.RemoveZone then
                Target.RemoveZone(zoneName)
            end
        end)
        
        -- Always mark as removed in our tracking
        activeTargetZones[zoneName] = nil
        
        if success then
            print("^2[Haus-Manager Markers]^7 Target zone removed successfully: " .. zoneName)
        else
            print("^3[Haus-Manager Markers]^7 Zone removal warning (OK if already gone): " .. tostring(err))
        end
    else
        print("^3[Haus-Manager Markers]^7 Zone already removed or never existed: " .. zoneName)
    end
    
    print("^2[Haus-Manager Markers]^7 Property deletion complete: " .. propertyId)
end)

-- Event: Properties updated - refresh cached properties immediately after purchase/changes
RegisterNetEvent('haus-manager:client:updateProperties', function(updatedProperties)
    -- Update cached properties so interactions use fresh data
    cachedProperties = updatedProperties or {}
    
    -- Force immediate refresh of nearby properties
    lastPropertyUpdate = 0
    
    print(string.format("^2[Haus-Manager Markers]^7 Cached properties updated: %d properties", #cachedProperties))
    
    if Config.Debug then
        for _, prop in ipairs(cachedProperties) do
            print(string.format("^3[Haus-Manager Markers Debug]^7 Cached property: %s, owned: %s, owner: %s", 
                prop.property_name, tostring(prop.owned), tostring(prop.owner_identifier)))
        end
    end
end)

-- Thread 2: Property Target Zone Manager
-- Creates and manages target zones for properties
-- Updates zones when properties change
-- NOTE: activeTargetZones is now defined at the top of the file!

CreateThread(function()
    while true do
        Wait(NEARBY_CHECK_INTERVAL)
        
        if not cachedProperties or #cachedProperties == 0 then
            -- Remove all zones if no properties
            for zoneName, _ in pairs(activeTargetZones) do
                Target.RemoveZone(zoneName)
                activeTargetZones[zoneName] = nil
            end
            goto continue
        end
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local tempNearby = {}
        local currentZones = {}
        
        -- Process all visible properties
        for _, property in ipairs(cachedProperties) do
            local markerVisible = tonumber(property.marker_visible) or 0
            
            if markerVisible == 1 then
                local coords = json.decode(property.coords)
                local propertyCoords = vector3(coords.x, coords.y, coords.z)
                local distance = #(playerCoords - propertyCoords)
                local markerRadius = property.marker_radius or Config.Markers.DrawDistance
                local zoneName = "property_" .. property.property_id
                
                -- Check if within range for target zones (larger range than visual markers)
                if distance <= (markerRadius * 1.5) then
                    currentZones[zoneName] = true
                    
                    -- Add zone if it doesn't exist
                    if not activeTargetZones[zoneName] then
                        AddPropertyTargetZone(property, propertyCoords, zoneName)
                        activeTargetZones[zoneName] = true
                    end
                end
                
                -- Only include in nearbyProperties if within visual range
                if distance <= markerRadius then
                    table.insert(tempNearby, {
                        property = property,
                        coords = propertyCoords,
                        distance = distance,
                        markerRadius = markerRadius
                    })
                end
            end
        end
        
        -- Remove zones for properties that are out of range
        for zoneName, _ in pairs(activeTargetZones) do
            if not currentZones[zoneName] then
                Target.RemoveZone(zoneName)
                activeTargetZones[zoneName] = nil
            end
        end
        
        nearbyProperties = tempNearby
        
        ::continue::
    end
end)

-- Add target zone for a property
function AddPropertyTargetZone(property, coords, zoneName)
    local interactionDist = Config.Markers.InteractionDistance or 2.5
    
    print("^3[Haus-Manager Target]^7 Adding zone: " .. zoneName .. " for property: " .. property.property_name)
    
    Target.AddBoxZone(zoneName, coords, interactionDist * 2, interactionDist * 2, {
        name = zoneName,
        heading = 0.0,
        debugPoly = false,
        minZ = coords.z - 1.0,
        maxZ = coords.z + 2.0
    }, {
        {
            type = "client",
            label = property.property_name,
            icon = "fas fa-home",
            action = function()
                print("^2[Haus-Manager Target]^7 Property interaction triggered: " .. property.property_name)
                HandlePropertyInteraction(property)
            end,
            canInteract = function()
                return true
            end
        }
    })
end

-- Thread 3: Visual marker renderer (draws markers only, NO text labels)
-- Target zones handle all interactions now
CreateThread(function()
    while true do
        Wait(0)
        
        if not showingMarkers then
            Wait(1000)
            goto continue
        end
        
        if not nearbyProperties or #nearbyProperties == 0 then
            Wait(500)
            goto continue
        end
        
        local sleep = true
        local playerCoords = GetEntityCoords(PlayerPedId())
        
        for _, data in ipairs(nearbyProperties) do
            local distance = #(playerCoords - data.coords)
            
            -- Draw marker at all distances (as long as in nearbyProperties)
            sleep = false
            DrawMarkerWithRadius(data.coords, Config.Markers, data.markerRadius)
            
            -- NO 3D TEXT HERE - Target system handles interaction prompts now!
            -- This prevents double display (marker + target prompt)
        end
        
        if sleep then
            Wait(500)
        end
        
        ::continue::
    end
end)

-- Handle property interaction
function HandlePropertyInteraction(property)
    print("^3[Haus-Manager]^7 HandlePropertyInteraction called for: " .. property.property_name)
    print("^3[Haus-Manager]^7 Property owned: " .. tostring(property.owned))
    
    -- Check if property is owned
    if property.owned == 0 then
        print("^3[Haus-Manager]^7 Property not owned - opening purchase/rent UI")
        -- Open purchase/rent UI
        OpenPropertyUI(property)
    else
        print("^3[Haus-Manager]^7 Property is owned - checking access")
        -- Check if player has access
        if HasAccessToProperty(property) then
            print("^2[Haus-Manager]^7 Player has access - showing property menu")
            -- Show property menu
            ShowPropertyMenu(property)
        else
            print("^3[Haus-Manager]^7 Player has no access - showing visitor menu")
            -- Show doorbell option for visitors
            ShowVisitorMenu(property)
        end
    end
end

-- Show property menu for owners
function ShowPropertyMenu(property)
    print("^2[Haus-Manager]^7 ShowPropertyMenu called for: " .. property.property_name)
    
    local menu = {
        {
            header = property.property_name,
            isMenuHeader = true
        },
        {
            header = "Immobilie betreten",
            txt = "Betreten Sie die Immobilie",
            params = {
                event = "haus-manager:client:enterProperty",
                args = {
                    property = property
                }
            }
        }
    }
    
    -- Garage has its own SEPARATE marker - removed from this menu
    
    -- CRITICAL FIX: Check owner using same method as HasAccessToProperty
    local playerIdentifier = nil
    if Framework.Type == 'esx' then
        local pd = Framework.GetPlayerData()
        playerIdentifier = pd.identifier
    elseif Framework.Type == 'qb-core' then
        local pd = Framework.GetPlayerData()
        playerIdentifier = pd.citizenid
    end
    
    -- Add key management for owner
    if property.owner_identifier == playerIdentifier then
        print("^3[Haus-Manager]^7 Player is owner (identifier match), adding owner menu options")
        
        -- Key management option (unified UI for temporary and permanent keys)
        table.insert(menu, {
            header = "🔑 Schlüsselverwaltung",
            txt = "Schlüssel vergeben und verwalten",
            params = {
                event = "haus-manager:client:openKeyManagement",
                args = property  -- Pass property directly, not wrapped in object
            }
        })
        print("^3[Haus-Manager]^7 Added '🔑 Schlüsselverwaltung' menu option")
        
        -- Add sell property option for owner
        table.insert(menu, {
            header = "Immobilie verkaufen",
            txt = "An Stadt oder Spieler verkaufen",
            params = {
                event = "haus-manager:client:openSellMenu",
                args = {
                    property = property
                }
            }
        })
        print("^3[Haus-Manager]^7 Added 'Immobilie verkaufen' menu option")
    else
        print("^3[Haus-Manager]^7 Player is not owner (owner: " .. tostring(property.owner_identifier) .. ", player: " .. tostring(playerIdentifier) .. ")")
    end
    
    table.insert(menu, {
        header = "Schließen",
        params = {
            event = "haus-manager:client:closeMenu"
        }
    })
    
    print("^2[Haus-Manager]^7 Opening menu with " .. #menu .. " options")
    Menu.Open(menu)
    print("^2[Haus-Manager]^7 Menu.Open() called successfully")
end

-- Show visitor menu (doorbell)
function ShowVisitorMenu(property)
    print("^2[Haus-Manager]^7 ShowVisitorMenu called for: " .. property.property_name)
    
    local menu = {
        {
            header = property.property_name,
            txt = "Diese Immobilie gehört jemand anderem",
            isMenuHeader = true
        },
        {
            header = "🔔 Klingeln",
            txt = "Benachrichtigen Sie den Eigentümer",
            params = {
                isServer = true,
                event = "haus-manager:server:ringDoorbell",
                args = {
                    propertyId = property.property_id
                }
            }
        },
        {
            header = "Schließen",
            params = {
                event = "haus-manager:client:closeMenu"
            }
        }
    }
    
    print("^2[Haus-Manager]^7 Opening visitor menu with " .. #menu .. " options")
    Menu.Open(menu)
    print("^2[Haus-Manager]^7 Menu.Open() called successfully")
end


-- Enter property event
RegisterNetEvent('haus-manager:client:enterProperty', function(data)
    print("^2[Haus-Manager Events]^7 enterProperty event triggered")
    print("^3[Haus-Manager Events]^7 Data type: " .. type(data))
    
    -- Handle different menu systems passing data differently
    local property = nil
    if type(data) == "table" then
        -- ESX menu passes args directly
        if data.property then
            property = data.property
        -- qb-menu passes the property object itself
        elseif data.property_id then
            property = data
        end
    end
    
    if property and property.property_id then
        print("^2[Haus-Manager Events]^7 Valid property found: " .. tostring(property.property_name))
        EnterProperty(property)
    else
        print("^1[Haus-Manager Events ERROR]^7 Invalid property data received!")
        Framework.Notify("Fehler beim Betreten der Immobilie", 'error')
    end
end)

-- Close menu event
RegisterNetEvent('haus-manager:client:closeMenu', function()
    print("^3[Haus-Manager Events]^7 Close menu event triggered")
    Menu.Close()
end)

-- Open sell menu event
RegisterNetEvent('haus-manager:client:openSellMenu', function(data)
    print("^2[Haus-Manager Events]^7 openSellMenu event triggered")
    
    local property = nil
    if type(data) == "table" then
        if data.property then
            property = data.property
        elseif data.property_id then
            property = data
        end
    end
    
    if property and property.property_id then
        SetNuiFocus(true, true)
        SendNUIMessage({
            action = "openSellUI",
            property = property
        })
    else
        print("^1[Haus-Manager Events ERROR]^7 Invalid property data for sell menu!")
    end
end)

-- Draw 3D text
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

-- Toggle markers
RegisterCommand('togglemarkers', function()
    showingMarkers = not showingMarkers
    Framework.Notify(showingMarkers and "Marker aktiviert" or "Marker deaktiviert", 'primary')
end)

-- Doorbell rang notification (for property owner)
RegisterNetEvent('haus-manager:client:doorbellRang', function(data)
    -- Play doorbell sound
    PlaySoundFrontend(-1, "CHECKPOINT_PERFECT", "HUD_MINI_GAME_SOUNDSET", true)
    
    -- Show notification menu to owner
    local menu = {
        {
            header = "🔔 Jemand klingelt!",
            txt = data.visitorName .. " steht vor " .. data.propertyName,
            isMenuHeader = true
        },
        {
            header = "✅ Einlassen",
            txt = "Besucher Zugang gewähren",
            params = {
                isServer = true,
                event = "haus-manager:server:inviteVisitor",
                args = {
                    visitorId = data.visitorId,
                    propertyId = data.propertyId
                }
            }
        },
        {
            header = "❌ Ignorieren",
            txt = "Tür bleibt geschlossen",
            params = {
                event = "haus-manager:client:closeMenu"
            }
        }
    }
    
    -- Show notification
    Framework.Notify(data.visitorName .. " klingelt an " .. data.propertyName .. "!", 'primary', 10000)
    
    -- Open menu
    Menu.Open(menu)
end)

-- Visitor granted entry (for visitor)
RegisterNetEvent('haus-manager:client:grantedEntry', function(property)
    -- Allow visitor to enter property temporarily
    EnterProperty(property)
end)

-- Export
exports('HandlePropertyInteraction', HandlePropertyInteraction)
