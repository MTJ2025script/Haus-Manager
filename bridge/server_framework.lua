-- Server Framework Bridge - Unterstützt QB-Core und ESX
-- Ermöglicht die Verwendung des Haus-Manager Systems mit verschiedenen Frameworks (Server-seitig)

FrameworkServer = {}
FrameworkServer.Type = nil
FrameworkServer.Object = nil

-- Konstanten
local MAX_FRAMEWORK_DETECTION_ATTEMPTS = 50
local FRAMEWORK_DETECTION_INTERVAL = 100

-- Admin Groups (konfig urierbar)
local ADMIN_GROUPS = {
    'admin',
    'superadmin',
    'mod'
}

-- Framework Detection
local function DetectFramework()
    if GetResourceState('qb-core') == 'started' then
        FrameworkServer.Type = 'qb-core'
        FrameworkServer.Object = exports['qb-core']:GetCoreObject()
        print("^2[Haus-Manager Server Bridge]^7 QB-Core Framework erkannt")
        return true
    elseif GetResourceState('es_extended') == 'started' then
        FrameworkServer.Type = 'esx'
        FrameworkServer.Object = exports['es_extended']:getSharedObject()
        print("^2[Haus-Manager Server Bridge]^7 ESX Framework erkannt")
        return true
    else
        print("^1[Haus-Manager Server Bridge]^7 FEHLER: Kein unterstütztes Framework gefunden!")
        return false
    end
end

-- Initialize Framework (synchron beim Start)
local function InitializeFramework()
    local attempts = 0
    
    while not DetectFramework() and attempts < MAX_FRAMEWORK_DETECTION_ATTEMPTS do
        attempts = attempts + 1
        Wait(FRAMEWORK_DETECTION_INTERVAL)
    end
    
    if FrameworkServer.Type then
        print(string.format("^2[Haus-Manager Server Bridge]^7 Framework %s erfolgreich geladen", FrameworkServer.Type))
        print("^2[Haus-Manager Server Bridge]^7 FrameworkServer.Object initialized:", FrameworkServer.Object ~= nil)
        return true
    else
        print("^1[Haus-Manager Server Bridge]^7 WARNUNG: Framework konnte nicht geladen werden!")
        return false
    end
end

-- Synchrone Initialisierung
CreateThread(function()
    InitializeFramework()
end)

-- Wait for Framework to be ready (für andere Scripts)
function FrameworkServer.WaitForReady()
    while not FrameworkServer.Object do
        Wait(100)
    end
    return true
end

-- Check if Framework is ready
function FrameworkServer.IsReady()
    return FrameworkServer.Object ~= nil
end


-- Validate Source
local function IsValidSource(source)
    return source and type(source) == 'number' and source > 0
end

-- Get Player from Source
function FrameworkServer.GetPlayer(source)
    if not IsValidSource(source) then
        print("^1[Haus-Manager Server Bridge]^7 Ungültige Source: " .. tostring(source))
        return nil
    end
    
    if not FrameworkServer.Type or not FrameworkServer.Object then
        print("^1[Haus-Manager Server Bridge]^7 Framework nicht initialisiert!")
        return nil
    end
    
    if FrameworkServer.Type == 'qb-core' then
        return FrameworkServer.Object.Functions.GetPlayer(source)
    elseif FrameworkServer.Type == 'esx' then
        return FrameworkServer.Object.GetPlayerFromId(source)
    end
    return nil
end

-- Get Player by CitizenID/Identifier
function FrameworkServer.GetPlayerByCitizenId(citizenid)
    if FrameworkServer.Type == 'qb-core' then
        return FrameworkServer.Object.Functions.GetPlayerByCitizenId(citizenid)
    elseif FrameworkServer.Type == 'esx' then
        return FrameworkServer.Object.GetPlayerFromIdentifier(citizenid)
    end
    return nil
end

-- Get Player Identifier
function FrameworkServer.GetPlayerIdentifier(Player)
    if not Player then return nil end
    
    if FrameworkServer.Type == 'qb-core' then
        return Player.PlayerData.citizenid
    elseif FrameworkServer.Type == 'esx' then
        return Player.identifier
    end
    return nil
end

-- Get Player Money
function FrameworkServer.GetPlayerMoney(Player, account)
    if not Player then return 0 end
    
    account = account or 'bank'
    
    if FrameworkServer.Type == 'qb-core' then
        return Player.PlayerData.money[account] or 0
    elseif FrameworkServer.Type == 'esx' then
        local acc = account == 'bank' and 'bank' or 'money'
        return Player.getAccount(acc).money or 0
    end
    return 0
end

-- Remove Money from Player
function FrameworkServer.RemoveMoney(Player, account, amount, reason)
    if not Player then return false end
    
    account = account or 'bank'
    reason = reason or 'haus-manager'
    
    if FrameworkServer.Type == 'qb-core' then
        return Player.Functions.RemoveMoney(account, amount, reason)
    elseif FrameworkServer.Type == 'esx' then
        local acc = account == 'bank' and 'bank' or 'money'
        Player.removeAccountMoney(acc, amount)
        return true
    end
    return false
end

-- Add Money to Player
function FrameworkServer.AddMoney(Player, account, amount, reason)
    if not Player then return false end
    
    account = account or 'bank'
    reason = reason or 'haus-manager'
    
    if FrameworkServer.Type == 'qb-core' then
        return Player.Functions.AddMoney(account, amount, reason)
    elseif FrameworkServer.Type == 'esx' then
        local acc = account == 'bank' and 'bank' or 'money'
        Player.addAccountMoney(acc, amount)
        return true
    end
    return false
end

-- Check Permission
function FrameworkServer.HasPermission(source, permission)
    if not IsValidSource(source) then
        return false
    end
    
    if not FrameworkServer.Type or not FrameworkServer.Object then
        return false
    end
    
    if FrameworkServer.Type == 'qb-core' then
        return FrameworkServer.Object.Functions.HasPermission(source, permission)
    elseif FrameworkServer.Type == 'esx' then
        local xPlayer = FrameworkServer.Object.GetPlayerFromId(source)
        if xPlayer then
            local playerGroup = xPlayer.getGroup()
            -- Check if player has exact permission or is in admin groups
            if playerGroup == permission then
                return true
            end
            -- Check against admin groups list
            for _, adminGroup in ipairs(ADMIN_GROUPS) do
                if playerGroup == adminGroup then
                    return true
                end
            end
        end
    end
    return false
end

-- Create Callback
function FrameworkServer.CreateCallback(name, cb)
    if not FrameworkServer.Object then
        print("^1[Haus-Manager Server Bridge]^7 ERROR: CreateCallback called but FrameworkServer.Object is nil for callback:", name)
        return
    end
    
    if FrameworkServer.Type == 'qb-core' then
        if FrameworkServer.Object.Functions and FrameworkServer.Object.Functions.CreateCallback then
            FrameworkServer.Object.Functions.CreateCallback(name, cb)
            print("^2[Haus-Manager Server Bridge]^7 QB-Core Callback registered:", name)
        else
            print("^1[Haus-Manager Server Bridge]^7 ERROR: QB-Core CreateCallback function not available for:", name)
        end
    elseif FrameworkServer.Type == 'esx' then
        if FrameworkServer.Object.RegisterServerCallback then
            FrameworkServer.Object.RegisterServerCallback(name, cb)
            print("^2[Haus-Manager Server Bridge]^7 ESX Callback registered:", name)
        else
            print("^1[Haus-Manager Server Bridge]^7 ERROR: ESX RegisterServerCallback function not available for:", name)
        end
    else
        print("^1[Haus-Manager Server Bridge]^7 ERROR: Unknown framework type for callback:", name)
    end
end

-- Register Command
function FrameworkServer.RegisterCommand(name, help, args, argsrequired, callback, permission)
    if FrameworkServer.Type == 'qb-core' then
        if FrameworkServer.Object and FrameworkServer.Object.Commands then
            FrameworkServer.Object.Commands.Add(name, help, args or {}, argsrequired or false, callback, permission)
        else
            print("^1[Haus-Manager]^7 ERROR: QB-Core Commands not available!")
        end
    elseif FrameworkServer.Type == 'esx' then
        RegisterCommand(name, function(source, args, rawCommand)
            if permission then
                local xPlayer = FrameworkServer.Object.GetPlayerFromId(source)
                if xPlayer and (xPlayer.getGroup() == permission or xPlayer.getGroup() == 'admin' or xPlayer.getGroup() == 'superadmin') then
                    callback(source, args)
                end
            else
                callback(source, args)
            end
        end, false)
    else
        -- Fallback: Use native FiveM RegisterCommand
        print("^3[Haus-Manager]^7 WARNING: Using fallback RegisterCommand for: " .. name)
        RegisterCommand(name, function(source, args, rawCommand)
            callback(source, args)
        end, false)
    end
end

-- Get Player Source
function FrameworkServer.GetPlayerSource(Player)
    if not Player then return nil end
    
    if FrameworkServer.Type == 'qb-core' then
        return Player.PlayerData.source
    elseif FrameworkServer.Type == 'esx' then
        return Player.source
    end
    return nil
end

-- Get Player Name
function FrameworkServer.GetPlayerName(Player)
    if not Player then return "Unknown" end
    
    if FrameworkServer.Type == 'qb-core' then
        local charinfo = Player.PlayerData.charinfo
        if charinfo then
            return charinfo.firstname .. ' ' .. charinfo.lastname
        end
    elseif FrameworkServer.Type == 'esx' then
        return Player.getName() or "Unknown"
    end
    return "Unknown"
end

-- Get Framework Type
function FrameworkServer.GetType()
    return FrameworkServer.Type
end

-- Is Framework Ready
function FrameworkServer.IsReady()
    return FrameworkServer.Type ~= nil and FrameworkServer.Object ~= nil
end
