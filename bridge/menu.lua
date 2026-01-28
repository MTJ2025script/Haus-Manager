-- Menu Bridge System
-- Provides unified menu API for QB-Core and ESX

Menu = {}
Menu.Type = nil
Menu.IsReady = false

-- Initialize menu system immediately (synchronous)
function Menu.Initialize()
    -- Detect menu system with error handling
    if GetResourceState('qb-menu') == 'started' then
        local success = pcall(function()
            local test = exports['qb-menu']
            if test and test.openMenu then
                Menu.Type = 'qb-menu'
                Menu.IsReady = true
                print("^2[Haus-Manager Menu Bridge]^7 QB-Menu erkannt")
            end
        end)
        if success and Menu.IsReady then return end
    end
    
    if GetResourceState('esx_context') == 'started' then
        local success = pcall(function()
            local test = exports['esx_context']
            if test and test.Open then
                Menu.Type = 'esx_context'
                Menu.IsReady = true
                print("^2[Haus-Manager Menu Bridge]^7 ESX Context erkannt")
            end
        end)
        if success and Menu.IsReady then return end
    end
    
    if GetResourceState('esx_menu_default') == 'started' then
        local success = pcall(function()
            local test = exports['esx_menu_default']
            if test then
                Menu.Type = 'esx_menu_default'
                Menu.IsReady = true
                print("^2[Haus-Manager Menu Bridge]^7 ESX Menu Default erkannt")
            end
        end)
        if success and Menu.IsReady then return end
    end
    
    -- Fallback auf NUI
    Menu.Type = 'nui'
    Menu.IsReady = true
    print("^3[Haus-Manager Menu Bridge]^7 Kein Menu-System gefunden, verwende NUI Fallback")
end

-- Initialize immediately when file loads
CreateThread(function()
    Wait(100) -- Minimal wait for resources to start (reduziert von 500ms)
    Menu.Initialize()
end)

-- Wait for menu system to be ready
function Menu.WaitForReady()
    while not Menu.IsReady do
        Wait(100)
    end
end

-- Open Menu (converts QB-Menu format to appropriate system)
function Menu.Open(menuData)
    print("^2[Haus-Manager Menu]^7 Menu.Open called, waiting for ready...")
    Menu.WaitForReady()
    print("^2[Haus-Manager Menu]^7 Menu system ready, Type: " .. tostring(Menu.Type))
    
    if Menu.Type == 'qb-menu' then
        print("^2[Haus-Manager Menu]^7 Opening QB-Menu...")
        -- QB-Menu format (already correct)
        exports['qb-menu']:openMenu(menuData)
        print("^2[Haus-Manager Menu]^7 QB-Menu opened successfully")
        
    elseif Menu.Type == 'esx_context' then
        print("^2[Haus-Manager Menu]^7 Opening ESX Context menu...")
        -- Convert to ESX Context format
        local elements = {}
        
        for _, item in ipairs(menuData) do
            if not item.isMenuHeader then
                table.insert(elements, {
                    title = item.header or item.txt,
                    description = item.txt,
                    event = item.params and item.params.event,
                    args = item.params and item.params.args,
                    server = item.params and item.params.isServer or false
                })
            end
        end
        
        print("^2[Haus-Manager Menu]^7 Calling esx_context:Open with " .. #elements .. " elements")
        exports['esx_context']:Open('center', elements)
        print("^2[Haus-Manager Menu]^7 ESX Context menu opened successfully")
        
    elseif Menu.Type == 'esx_menu_default' then
        -- ESX Menu Default doesn't support custom events in elements
        -- We need to handle this differently - trigger events directly without using ESX's event system
        local elements = {}
        local eventMap = {} -- Map value to event data
        
        for i, item in ipairs(menuData) do
            if not item.isMenuHeader then
                local uniqueValue = 'option_' .. i
                table.insert(elements, {
                    label = item.header or item.txt,
                    value = uniqueValue
                })
                
                -- Store event data in map
                if item.params and item.params.event then
                    eventMap[uniqueValue] = {
                        event = item.params.event,
                        args = item.params.args,
                        isServer = item.params.isServer or false
                    }
                end
            end
        end
        
        print("^3[Haus-Manager Menu]^7 Opening ESX menu with " .. #elements .. " options")
        print("^3[Haus-Manager Menu Debug]^7 ESX object exists: " .. tostring(ESX ~= nil))
        print("^3[Haus-Manager Menu Debug]^7 ESX.UI exists: " .. tostring(ESX and ESX.UI ~= nil))
        print("^3[Haus-Manager Menu Debug]^7 ESX.UI.Menu exists: " .. tostring(ESX and ESX.UI and ESX.UI.Menu ~= nil))
        print("^3[Haus-Manager Menu Debug]^7 ESX.UI.Menu.Open exists: " .. tostring(ESX and ESX.UI and ESX.UI.Menu and ESX.UI.Menu.Open ~= nil))
        print("^3[Haus-Manager Menu Debug]^7 Resource name: " .. GetCurrentResourceName())
        print("^3[Haus-Manager Menu Debug]^7 Title: " .. tostring(menuData[1] and menuData[1].header or 'Menu'))
        print("^3[Haus-Manager Menu Debug]^7 Elements count: " .. #elements)
        
        for i, elem in ipairs(elements) do
            print("^3[Haus-Manager Menu Debug]^7 Element " .. i .. ": label=" .. tostring(elem.label) .. ", value=" .. tostring(elem.value))
        end
        
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'property_menu', {
            title = menuData[1] and menuData[1].header or 'Menu',
            align = 'top-left',
            elements = elements
        }, function(data, menu)
            print("^2[Haus-Manager Menu]^7 ESX menu callback triggered!")
            print("^3[Haus-Manager Menu Debug]^7 Selected value: " .. tostring(data.current.value))
            
            local selectedValue = data.current.value
            local eventData = eventMap[selectedValue]
            
            if eventData then
                print("^2[Haus-Manager Menu]^7 Event found: " .. eventData.event)
                print("^3[Haus-Manager Menu Debug]^7 Event args type: " .. type(eventData.args))
                print("^3[Haus-Manager Menu Debug]^7 Is server event: " .. tostring(eventData.isServer))
                
                if eventData.isServer then
                    print("^2[Haus-Manager Menu]^7 Triggering server event...")
                    TriggerServerEvent(eventData.event, eventData.args)
                else
                    print("^2[Haus-Manager Menu]^7 Triggering client event...")
                    TriggerEvent(eventData.event, eventData.args)
                end
            else
                print("^1[Haus-Manager Menu ERROR]^7 No event mapped for value: " .. tostring(selectedValue))
            end
            
            menu.close()
        end, function(data, menu)
            print("^3[Haus-Manager Menu]^7 Menu cancelled")
            menu.close()
        end)
        
        print("^2[Haus-Manager Menu]^7 ESX Menu Default opened successfully")
        
    else
        print("^2[Haus-Manager Menu]^7 Opening NUI fallback menu...")
        -- NUI Fallback - use built-in NUI system
        SendNUIMessage({
            action = "openMenu",
            data = menuData
        })
        SetNuiFocus(true, true)
    end
end

-- Close Menu
function Menu.Close()
    if Menu.Type == 'qb-menu' then
        TriggerEvent('qb-menu:client:closeMenu')
    elseif Menu.Type == 'esx_context' then
        exports['esx_context']:Close()
    elseif Menu.Type == 'esx_menu_default' then
        ESX.UI.Menu.CloseAll()
    else
        SendNUIMessage({
            action = "closeMenu"
        })
        SetNuiFocus(false, false)
    end
end

-- Register NUI Callback for fallback menu
RegisterNUICallback('menuAction', function(data, cb)
    if data.event then
        if data.isServer then
            TriggerServerEvent(data.event, data.args)
        else
            TriggerEvent(data.event, data.args)
        end
    end
    Menu.Close()
    cb('ok')
end)

RegisterNUICallback('closeMenu', function(data, cb)
    Menu.Close()
    cb('ok')
end)
