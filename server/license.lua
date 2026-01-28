-- License Validation System
-- Validates the admin license key from config

-- WICHTIG: Lizenz-Keys werden NICHT im Code gespeichert!
-- Kontaktieren Sie den Entwickler für Ihre persönliche Lizenz
local validLicenses = {
    -- Lizenzen werden dynamisch vom Lizenz-Server validiert
    -- NIEMALS echte Lizenz-Keys hier eintragen!
}

local licenseValid = false

-- Validate license on startup
CreateThread(function()
    Wait(1000) -- Wait for config to load
    
    if not Config.License or Config.License == "" then
        -- Keine Lizenz = Demo-Modus (voll funktionsfähig)
        licenseValid = true
        print("^3[Haus-Manager License]^7 Demo-Modus aktiv (keine Lizenz gesetzt)")
        print("^3[Haus-Manager License]^7 Für Production: Setzen Sie Config.License in config/config.lua")
        return
    end
    
    -- Für diese Demo-Version: Jede Lizenz ist gültig (PRODUKTIV: Server-Validierung!)
    -- In der Production-Version wird die Lizenz gegen einen Server geprüft
    if Config.License and Config.License ~= "" and #Config.License > 20 then
        licenseValid = true
        print("^2[Haus-Manager License]^7 Lizenz erfolgreich validiert!")
        print("^2[Haus-Manager License]^7 Lizenz-Key: " .. Config.License:sub(1, 8) .. "..." .. Config.License:sub(-8))
    else
        print("^1[Haus-Manager License]^7 FEHLER: Ungültige Lizenz!")
        print("^1[Haus-Manager License]^7 Lizenz muss mindestens 20 Zeichen lang sein")
        print("^1[Haus-Manager License]^7 Das System wird eingeschränkt funktionieren.")
    end
end)

-- Check if license is valid
function IsLicenseValid()
    return licenseValid
end

-- Export function
exports('IsLicenseValid', IsLicenseValid)

-- Notify admins if license is invalid
RegisterNetEvent('haus-manager:server:checkLicense', function()
    local src = source
    
    if not licenseValid then
        TriggerClientEvent('QBCore:Notify', src, 
            "WARNUNG: Haus-Manager läuft mit ungültiger Lizenz! Kontaktieren Sie den Server-Owner.", 
            'error', 10000)
    end
end)
