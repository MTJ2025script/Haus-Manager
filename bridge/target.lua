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
    -- CRITICAL: Check Framework type FIRST to avoid conflicts
    -- QB-Core: Use qb-target only
    -- ESX: Use DrawText mode only (no ox_target/qtarget)
    
    local frameworkType = Framework and Framework.Type or nil
    print("^2[Haus-Manager Target Bridge]^7 Framework detected: " .. tostring(frameworkType))
    
    -- QB-Core: Only check for qb-target
    if frameworkType == 'qb-core' then
        if GetResourceState('qb-target') == 'started' then
            local success = pcall(function()
                local test = exports['qb-target']
                if test and test.AddBoxZone then
                    Target.Type = 'qb-target'
                    print("^2[Haus-Manager Target Bridge]^7 qb-target erkannt (QB-Core)")
                end
            end)
            if success and Target.Type == 'qb-target' then
                return
            end
        end
        
        print("^3[Haus-Manager Target Bridge]^7 QB-Core detected but qb-target not found, using DrawText fallback")
    end
    
    -- ESX: ALWAYS use DrawText mode (ignore ox_target/qtarget to avoid double-target)
    if frameworkType == 'esx' then
        Target.Type = 'drawtext'
        print("^2[Haus-Manager Target Bridge]^7 ESX detected - using DrawText/Prompt mode with icons")
        return
    end
    
    -- Fallback: Try to detect target systems if framework unknown
    if not frameworkType then
        print("^3[Haus-Manager Target Bridge]^7 Framework not detected yet, trying target detection...")
        
        -- Check for qb-target (QB-Core)
        if GetResourceState('qb-target') == 'started' then
            local success = pcall(function()
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
    end
    
    -- Final fallback to DrawText/3D Text
    Target.Type = 'drawtext'
    print("^2[Haus-Manager Target Bridge]^7 Using DrawText/Prompt mode")
end

-- Add box zone (for property markers)
function Target.AddBoxZone(name, coords, length, width, options, targetOptions)
    if Target.Type == 'qb-target' then
        exports['qb-target']:AddBoxZone(name, coords, length, width, options, targetOptions)
        print("^2[Haus-Manager Target]^7 qb-target zone added: " .. name)
    else
        -- DrawText mode - store zone info for proximity checks
        Target.ActiveZones[name] = {
            coords = coords,
            length = length,
            width = width,
            options = targetOptions,
            heading = options.heading or 0.0,
            minZ = options.minZ or (coords.z - 1.0),
            maxZ = options.maxZ or (coords.z + 2.0)
        }
        print("^2[Haus-Manager Target]^7 DrawText zone added: " .. name)
    end
end

-- Remove zone
function Target.RemoveZone(name)
    if Target.Type == 'qb-target' then
        local success = pcall(function()
            exports['qb-target']:RemoveZone(name)
        end)
        if not success then
            print("^3[Haus-Manager Target]^7 Warning: attempted to remove qb-target zone that does not exist (id: " .. name .. ")")
        end
    else
        -- DrawText mode - remove from active zones
        Target.ActiveZones[name] = nil
        print("^2[Haus-Manager Target]^7 DrawText zone removed: " .. name)
    end
end

-- Start DrawText mode thread if needed
function Target.StartDrawTextMode()
    if Target.Type ~= 'drawtext' then return end
    
    CreateThread(function()
        local currentZone = nil
        local showingText = false
        local hasESXTextUI = GetResourceState('esx_textui') == 'started'
        
        print("^2[Haus-Manager Target Bridge]^7 DrawText/Prompt mode started")
        print("^2[Haus-Manager Target Bridge]^7 ESX TextUI available: " .. tostring(hasESXTextUI))
        
        while true do
            local sleep = 500
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local nearestZone = nil
            local nearestDist = 999999.0
            
            -- Find nearest zone
            for name, zone in pairs(Target.ActiveZones) do
                local dist = #(playerCoords - zone.coords)
                local interactionDist = zone.length / 2 + 1.0
                
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
                
                -- Show help text with icon
                if not showingText and nearestZone.zone.options and #nearestZone.zone.options > 0 then
                    local option = nearestZone.zone.options[1]
                    if option.label then
                        -- Get icon from option or use default
                        local icon = option.icon or 'fas fa-home'
                        
                        -- Try esx_textui first (with icon support)
                        if hasESXTextUI then
                            pcall(function()
                                -- ESX TextUI with icon
                                exports['esx_textui']:TextUI('[E] ' .. option.label, 'info')
                            end)
                        end
                        showingText = true
                    end
                end
                
                -- Draw 3D text with icon as fallback (always show)
                if showingText and nearestZone.zone.options and #nearestZone.zone.options > 0 then
                    local option = nearestZone.zone.options[1]
                    if option.label then
                        -- Nice formatted 3D text with icon emoji
                        local icon = option.icon or '🏠'
                        if option.icon == 'fas fa-key' then icon = '🔑'
                        elseif option.icon == 'fas fa-door-open' then icon = '🚪'
                        elseif option.icon == 'fas fa-car' then icon = '🚗'
                        elseif option.icon == 'fas fa-dollar-sign' then icon = '💰'
                        elseif option.icon == 'fas fa-home' then icon = '🏠'
                        end
                        
                        DrawText3D(nearestZone.zone.coords.x, nearestZone.zone.coords.y, nearestZone.zone.coords.z + 1.0, 
                            icon .. ' [~g~E~w~] ' .. option.label)
                    end
                end
                
                -- Check for key press
                if IsControlJustReleased(0, 38) then -- E key
                    print("^2[Haus-Manager Target]^7 E key pressed on zone: " .. nearestZone.name)
                    if nearestZone.zone.options and #nearestZone.zone.options > 0 then
                        for _, option in ipairs(nearestZone.zone.options) do
                            if option.action then
                                print("^2[Haus-Manager Target]^7 Executing action: " .. (option.label or "unknown"))
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

-- Helper function for 3D text (DrawText mode fallback) - Enhanced for ESX
function DrawText3D(x, y, z, text)
    SetTextScale(0.40, 0.40)  -- Slightly larger for better visibility
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 235)  -- Brighter white
    SetTextEntry("STRING")
    SetTextCentre(true)
    SetTextOutline()  -- Add outline for better readability
    AddTextComponentString(text)
    SetDrawOrigin(x, y, z, 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 350
    -- Slightly darker background with more transparency
    DrawRect(0.0, 0.0+0.0125, 0.020+ factor, 0.035, 0, 0, 0, 90)
    ClearDrawOrigin()
end

print("^2[Haus-Manager Target Bridge]^7 Target bridge loaded successfully")
