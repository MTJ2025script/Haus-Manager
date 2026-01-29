-- Framework Bridge - Unterstützt QB-Core und ESX
-- Ermöglicht die Verwendung des Haus-Manager Systems mit verschiedenen Frameworks

Framework = {}
Framework.Type = nil
Framework.Object = nil

-- Konstanten
local MAX_FRAMEWORK_DETECTION_ATTEMPTS = 50
local FRAMEWORK_DETECTION_INTERVAL = 100

-- Notification Type Mapping für ESX
local ESX_NOTIFICATION_TYPES = {
    primary = 'info',
    success = 'success',
    error = 'error',
    info = 'info'
}

-- Framework Detection und Initialisierung
local function DetectFramework()
    -- Verify resources are actually running, not just 'started'
    if GetResourceState('qb-core') == 'started' then
        local success, core = pcall(function()
            return exports['qb-core']:GetCoreObject()
        end)
        if success and core then
            Framework.Type = 'qb-core'
            Framework.Object = core
            print("^2[Haus-Manager Bridge]^7 QB-Core Framework erkannt")
            return true
        end
    end
    
    if GetResourceState('es_extended') == 'started' then
        local success, esx = pcall(function()
            return exports['es_extended']:getSharedObject()
        end)
        if success and esx then
            Framework.Type = 'esx'
            Framework.Object = esx
            print("^2[Haus-Manager Bridge]^7 ESX Framework erkannt")
            return true
        end
    end
    
    return false
end

-- Warte auf Framework-Initialisierung
CreateThread(function()
    local attempts = 0
    local detected = false
    
    -- Schnellerer initialer Check (alle 50ms statt 100ms)
    while not detected and attempts < MAX_FRAMEWORK_DETECTION_ATTEMPTS do
        detected = DetectFramework()
        if not detected then
            attempts = attempts + 1
            Wait(50) -- Schnellere Checks
        end
    end
    
    if Framework.Type then
        print(string.format("^2[Haus-Manager Bridge]^7 Framework %s erfolgreich geladen nach %dms", Framework.Type, attempts * 50))
        
        -- Compatibility layer: Forward ESX events to QB-Core event names (NACH Framework-Detection!)
        if Framework.Type == 'esx' then
            RegisterNetEvent('esx:playerLoaded', function(playerData)
                TriggerEvent('QBCore:Client:OnPlayerLoaded')
            end)
            
            RegisterNetEvent('esx:onPlayerLogout', function()
                TriggerEvent('QBCore:Client:OnPlayerUnload')
            end)
            
            print("^2[Haus-Manager Bridge]^7 ESX event compatibility layer activated")
        end
        
        -- Make Framework globally available
        _G.Framework = Framework
    else
        print("^1[Haus-Manager Bridge]^7 Framework konnte nicht geladen werden!")
    end
end)

-- Get Player Data
function Framework.GetPlayerData()
    if not Framework.Type or not Framework.Object then
        print("^1[Haus-Manager Bridge]^7 Framework nicht initialisiert!")
        return {}
    end
    
    if Framework.Type == 'qb-core' then
        return Framework.Object.Functions.GetPlayerData()
    elseif Framework.Type == 'esx' then
        return Framework.Object.GetPlayerData()
    end
    return {}
end

-- Get Player Identifier
function Framework.GetPlayerIdentifier()
    if not Framework.Type or not Framework.Object then
        print("^1[Haus-Manager Bridge GetPlayerIdentifier]^7 Framework nicht initialisiert!")
        return nil
    end
    
    if Framework.Type == 'qb-core' then
        local PlayerData = Framework.Object.Functions.GetPlayerData()
        if not PlayerData or not PlayerData.citizenid then
            print("^1[Haus-Manager Bridge GetPlayerIdentifier]^7 QB-Core PlayerData.citizenid is nil!")
            return nil
        end
        print("^3[Haus-Manager Bridge GetPlayerIdentifier]^7 QB-Core citizenid: " .. tostring(PlayerData.citizenid))
        return PlayerData.citizenid
    elseif Framework.Type == 'esx' then
        local PlayerData = Framework.Object.GetPlayerData()
        if not PlayerData or not PlayerData.identifier then
            print("^1[Haus-Manager Bridge GetPlayerIdentifier]^7 ESX PlayerData.identifier is nil!")
            print("^3[Haus-Manager Bridge GetPlayerIdentifier Debug]^7 PlayerData: " .. (PlayerData and "exists" or "nil"))
            if PlayerData then
                print("^3[Haus-Manager Bridge GetPlayerIdentifier Debug]^7 PlayerData keys: " .. json.encode(PlayerData))
            end
            return nil
        end
        print("^3[Haus-Manager Bridge GetPlayerIdentifier]^7 ESX identifier: " .. tostring(PlayerData.identifier))
        return PlayerData.identifier
    end
    return nil
end

-- Trigger Callback
function Framework.TriggerCallback(name, cb, ...)
    if not Framework.Type or not Framework.Object then
        print("^1[Haus-Manager Bridge]^7 Framework nicht initialisiert!")
        if cb then cb(nil) end
        return
    end
    
    if Framework.Type == 'qb-core' then
        Framework.Object.Functions.TriggerCallback(name, cb, ...)
    elseif Framework.Type == 'esx' then
        Framework.Object.TriggerServerCallback(name, cb, ...)
    end
end

-- Show Notification
function Framework.Notify(message, type, duration)
    duration = duration or 5000
    
    -- Use custom NUI notification system (zentral, schön, mit Icons)
    SendNUIMessage({
        action = 'showNotification',
        message = message,
        type = type or 'info',
        duration = duration
    })
    
    -- Fallback: Also use framework notification for compatibility
    if Framework.Type == 'qb-core' and Framework.Object then
        -- QB-Core notification als Backup
        -- Framework.Object.Functions.Notify(message, type, duration)
    elseif Framework.Type == 'esx' and Framework.Object then
        -- ESX notification als Backup
        -- local notifType = ESX_NOTIFICATION_TYPES[type] or 'info'
        -- Framework.Object.ShowNotification(message, notifType, duration)
    end
end

-- Get Vehicle Properties
function Framework.GetVehicleProperties(vehicle)
    if Framework.Type == 'qb-core' then
        return Framework.Object.Functions.GetVehicleProperties(vehicle)
    elseif Framework.Type == 'esx' then
        return Framework.Object.Game.GetVehicleProperties(vehicle)
    end
    return {}
end

-- Set Vehicle Properties
function Framework.SetVehicleProperties(vehicle, properties)
    if Framework.Type == 'qb-core' then
        Framework.Object.Functions.SetVehicleProperties(vehicle, properties)
    elseif Framework.Type == 'esx' then
        Framework.Object.Game.SetVehicleProperties(vehicle, properties)
    end
end

-- Get Vehicle Plate
function Framework.GetPlate(vehicle)
    if Framework.Type == 'qb-core' then
        return Framework.Object.Functions.GetPlate(vehicle)
    elseif Framework.Type == 'esx' then
        return GetVehicleNumberPlateText(vehicle)
    end
    return ""
end

-- On Player Loaded
function Framework.OnPlayerLoaded(callback)
    if Framework.Type == 'qb-core' then
        RegisterNetEvent('QBCore:Client:OnPlayerLoaded', callback)
    elseif Framework.Type == 'esx' then
        RegisterNetEvent('esx:playerLoaded', callback)
    end
end

-- On Player Unload
function Framework.OnPlayerUnload(callback)
    if Framework.Type == 'qb-core' then
        RegisterNetEvent('QBCore:Client:OnPlayerUnload', callback)
    elseif Framework.Type == 'esx' then
        RegisterNetEvent('esx:onPlayerLogout', callback)
    end
end

-- Get Framework Type
function Framework.GetType()
    return Framework.Type
end

-- Is Framework Ready
function Framework.IsReady()
    return Framework.Type ~= nil and Framework.Object ~= nil
end

-- Vehicle Functions (QB-Core compatible)
function Framework.GetVehicleProperties(vehicle)
    if Framework.Type == 'qb-core' then
        return Framework.Object.Functions.GetVehicleProperties(vehicle)
    elseif Framework.Type == 'esx' then
        -- ESX vehicle properties
        return exports['esx_vehicleshop'] and exports['esx_vehicleshop']:GetVehicleProperties(vehicle) or {}
    end
    return {}
end

function Framework.SetVehicleProperties(vehicle, props)
    if Framework.Type == 'qb-core' then
        Framework.Object.Functions.SetVehicleProperties(vehicle, props)
    elseif Framework.Type == 'esx' then
        -- ESX vehicle properties
        if exports['esx_vehicleshop'] then
            exports['esx_vehicleshop']:SetVehicleProperties(vehicle, props)
        end
    end
end

function Framework.SpawnVehicle(model, callback, coords, isNetwork)
    if Framework.Type == 'qb-core' then
        Framework.Object.Functions.SpawnVehicle(model, callback, coords, isNetwork)
    elseif Framework.Type == 'esx' then
        -- ESX vehicle spawn
        Framework.Object.Game.SpawnVehicle(model, coords, coords.w or 0.0, callback)
    end
end

function Framework.DeleteVehicle(vehicle)
    if Framework.Type == 'qb-core' then
        Framework.Object.Functions.DeleteVehicle(vehicle)
    else
        -- ESX/generic delete
        DeleteEntity(vehicle)
    end
end
