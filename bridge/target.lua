-- Target Bridge System - Supports qb-target (QB-Core) and DrawText/3D Text (ESX)
-- Provides unified API for both target-based and proximity-based interactions

Target = {}
Target.Type = nil
Target.ActiveZones = {}

-- Initialize target system immediately
CreateThread(function()
    Wait(100) -- Minimal wait for resources to start
    Target.Initialize()
    
    if Target.Type then
        print(string.format("^2[Haus-Manager Target Bridge]^7 Target system ready, Type: %s", Target.Type))
        _G.Target = Target -- Make globally available immediately
        
        -- Start DrawText mode if applicable
        if Target.Type == 'drawtext' then
            Target.StartDrawTextMode()
        end
    end
end)

-- Initialize target system
function Target.Initialize()
    -- Check for qb-target (QB-Core)
    if GetResourceState('qb-target') == 'started' then
        local success = pcall(function()
            -- Verify export exists
            local test = exports['qb-target']
            if test and test.AddBoxZone then
                Target.Type = 'qb-target'
                print("^2[Haus-Manager Target Bridge]^7 qb-target erkannt")
            end
        end)
        if success and Target.Type == 'qb-target' then
            return
        end
    end
    
    -- Check for ox_target (Modern alternative)
    if GetResourceState('ox_target') == 'started' then
        local success = pcall(function()
            local test = exports['ox_target']
            if test and test.addBoxZone then
                Target.Type = 'ox_target'
                print("^2[Haus-Manager Target Bridge]^7 ox_target erkannt")
            end
        end)
        if success and Target.Type == 'ox_target' then
            return
        end
    end
    
    -- Check for qtarget (Alternative)
    if GetResourceState('qtarget') == 'started' then
        local success = pcall(function()
            local test = exports['qtarget']
            if test and test.AddBoxZone then
                Target.Type = 'qtarget'
                print("^2[Haus-Manager Target Bridge]^7 qtarget erkannt")
            end
        end)
        if success and Target.Type == 'qtarget' then
            return
        end
    end
    
    -- Fallback to DrawText/3D Text (ESX style)
    Target.Type = 'drawtext'
    print("^2[Haus-Manager Target Bridge]^7 DrawText/3D-Text Modus (ESX)")
end

-- Add box zone (for property markers)
function Target.AddBoxZone(name, coords, length, width, options, targetOptions)
    if Target.Type == 'qb-target' then
        exports['qb-target']:AddBoxZone(name, coords, length, width, options, targetOptions)
    elseif Target.Type == 'ox_target' then
        -- ox_target uses different format - convert targetOptions
        local oxOptions = {}
        for i, option in ipairs(targetOptions) do
            table.insert(oxOptions, {
                name = name .. '_' .. i,
                label = option.label,
                icon = option.icon,
                onSelect = option.action,  -- ox_target uses onSelect instead of action
                canInteract = option.canInteract or function() return true end,
                distance = length or 2.5
            })
        end
        
        exports['ox_target']:addBoxZone({
            coords = coords,
            size = vec3(length, width, options.minZ and (options.maxZ - options.minZ) or 2.0),
            rotation = options.heading or 0.0,
            debug = options.debugPoly or false,
            options = oxOptions
        })
        
        print("^2[Haus-Manager Target]^7 ox_target zone added: " .. name)
    elseif Target.Type == 'qtarget' then
        exports['qtarget']:AddBoxZone(name, coords, length, width, options, targetOptions)
    else
        -- DrawText mode - store zone info for proximity checks
        Target.ActiveZones[name] = {
            coords = coords,
            length = length,
            width = width,
            options = targetOptions,
            heading = options.heading or 0.0,
            minZ = options.minZ or (coords.z - 1.0),
            maxZ = options.maxZ or (coords.z + 1.0)
        }
    end
end

-- Remove zone
function Target.RemoveZone(name)
    if Target.Type == 'qb-target' then
        local success = pcall(function()
            exports['qb-target']:RemoveZone(name)
        end)
        if not success then
            print("^3Warning: attempted to remove a zone that does not exist (id: " .. name .. ")^7")
        end
    elseif Target.Type == 'ox_target' then
        pcall(function()
            exports['ox_target']:removeZone(name)
        end)
    elseif Target.Type == 'qtarget' then
        pcall(function()
            exports['qtarget']:RemoveZone(name)
        end)
    else
        Target.ActiveZones[name] = nil
    end
end

-- Start DrawText mode thread if needed
function Target.StartDrawTextMode()
    if Target.Type ~= 'drawtext' then return end
    
    CreateThread(function()
        local currentZone = nil
        local showingText = false
        local hasESXTextUI = GetResourceState('esx_textui') == 'started'
        
        print("^2[Haus-Manager Target Bridge]^7 DrawText thread started, ESX TextUI: " .. tostring(hasESXTextUI))
        
        while true do
            local sleep = 500
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local nearestZone = nil
            local nearestDist = 999999.0
            
            -- Find nearest zone
            for name, zone in pairs(Target.ActiveZones) do
                local dist = #(playerCoords - zone.coords)
                local interactionDist = zone.length / 2 + 1.0 -- Approximation
                
                if dist < interactionDist and dist < nearestDist then
                    nearestDist = dist
                    nearestZone = {name = name, zone = zone, dist = dist}
                end
            end
            
            -- Handle zone interaction
            if nearestZone then
                sleep = 0
                
                if currentZone ~= nearestZone.name then
                    currentZone = nearestZone.name
                    showingText = false
                end
                
                -- Show help text - try different methods
                if not showingText and nearestZone.zone.options and #nearestZone.zone.options > 0 then
                    local option = nearestZone.zone.options[1] -- Use first option
                    if option.label then
                        -- Try esx_textui first
                        if hasESXTextUI then
                            pcall(function()
                                exports['esx_textui']:TextUI('[E] ' .. option.label)
                            end)
                        end
                        showingText = true
                    end
                end
                
                -- Draw 3D text as fallback (always show)
                if showingText and nearestZone.zone.options and #nearestZone.zone.options > 0 then
                    local option = nearestZone.zone.options[1]
                    if option.label then
                        DrawText3D(nearestZone.zone.coords.x, nearestZone.zone.coords.y, nearestZone.zone.coords.z + 1.0, 
                            '[E] ' .. option.label)
                    end
                end
                
                -- Check for key press
                if IsControlJustReleased(0, 38) then -- E key
                    print("^2[Haus-Manager Target]^7 E key pressed on zone: " .. nearestZone.name)
                    if nearestZone.zone.options and #nearestZone.zone.options > 0 then
                        for _, option in ipairs(nearestZone.zone.options) do
                            if option.action then
                                print("^2[Haus-Manager Target]^7 Executing action for: " .. (option.label or "unknown"))
                                option.action()
                                break
                            end
                        end
                    else
                        print("^1[Haus-Manager Target]^7 No options found for zone!")
                    end
                end
            else
                -- Not near any zone
                if showingText then
                    if hasESXTextUI then
                        pcall(function() exports['esx_textui']:HideUI() end)
                    end
                    showingText = false
                end
                currentZone = nil
            end
            
            Wait(sleep)
        end
    end)
end

-- Helper function for 3D text (DrawText mode fallback)
function DrawText3D(x, y, z, text)
    SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry("STRING")
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(x,y,z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0+0.0125, 0.017+ factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

print("^2[Haus-Manager Target Bridge]^7 Target bridge loaded successfully")
