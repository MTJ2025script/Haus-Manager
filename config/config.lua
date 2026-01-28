Config = {}

-- Framework Settings (QB-Core oder ESX werden automatisch erkannt)
Config.Framework = "auto-detect" -- Automatische Erkennung (kann auch manuell auf "qb-core" oder "esx" gesetzt werden)
Config.UseQBInterior = true -- Use qb-interior natives (no custom shells)

-- Marker Settings
Config.Markers = {
    Enabled = true, -- Toggle marker visibility globally
    Type = 1, -- Marker type (1 = cylinder)
    Size = { x = 0.8, y = 0.8, z = 0.5 }, -- Smaller, less visible
    Color = { r = 255, g = 255, b = 255 }, -- White color
    Alpha = 100, -- More transparent
    BobUpAndDown = false,
    FaceCamera = false,
    Rotate = false,
    DrawDistance = 50.0, -- Default visibility distance
    InteractionDistance = 2.5, -- Distance to interact
    ShowRadius = false, -- Hide radius ring for cleaner look
    RadiusColor = { r = 255, g = 255, b = 255, a = 30 }
}

-- Property Types
Config.PropertyTypes = {
    apartment = {
        label = "Wohnung",
        maxKeys = 2,
        garageSize = "small", -- 3 parking spaces
        icon = "apartment"
    },
    house = {
        label = "Haus",
        maxKeys = 5,
        garageSize = "medium", -- 6 parking spaces
        icon = "home"
    },
    office = {
        label = "Büro",
        maxKeys = 15,
        garageSize = "large", -- 16 parking spaces
        icon = "business"
    }
}

-- Garage Sizes
Config.GarageSizes = {
    small = {
        label = "Klein",
        slots = 3,
        price = 5000
    },
    medium = {
        label = "Mittel",
        slots = 6,
        price = 15000
    },
    large = {
        label = "Groß/Hotel",
        slots = 16,
        price = 50000
    }
}

-- Rent Periods (in GTA V game time)
Config.RentPeriods = {
    {
        label = "1 Woche",
        days = 7,
        multiplier = 0.05 -- 5% of property price
    },
    {
        label = "1 Monat",
        days = 30,
        multiplier = 0.15 -- 15% of property price
    },
    {
        label = "3 Monate",
        days = 90,
        multiplier = 0.35 -- 35% of property price
    },
    {
        label = "12 Monate",
        days = 365,
        multiplier = 1.0 -- 100% of property price (essentially purchase)
    }
}

-- QB-Interior Shells (predefined GTA Online style interiors)
Config.Interiors = {
    -- Apartments
    ["ModernApartment"] = {
        label = "Moderne Wohnung",
        type = "apartment",
        shell = "ModernHotel", -- QB-Interior shell name
        spawn = vector4(0.0, 0.0, 0.0, 0.0) -- Relative spawn point inside
    },
    ["ClassicApartment"] = {
        label = "Klassische Wohnung",
        type = "apartment",
        shell = "DelPerroHeights", -- QB-Interior shell name
        spawn = vector4(0.0, 0.0, 0.0, 0.0)
    },
    ["LuxuryApartment"] = {
        label = "Luxus-Wohnung",
        type = "apartment",
        shell = "EclipseTowers", -- QB-Interior shell name
        spawn = vector4(0.0, 0.0, 0.0, 0.0)
    },
    
    -- Houses
    ["StandardHouse"] = {
        label = "Standard-Haus",
        type = "house",
        shell = "FranklinHouse", -- QB-Interior shell name
        spawn = vector4(0.0, 0.0, 0.0, 0.0)
    },
    ["ModernHouse"] = {
        label = "Modernes Haus",
        type = "house",
        shell = "MichaelHouse", -- QB-Interior shell name
        spawn = vector4(0.0, 0.0, 0.0, 0.0)
    },
    ["LuxuryHouse"] = {
        label = "Luxus-Haus",
        type = "house",
        shell = "TrevorHouse", -- QB-Interior shell name
        spawn = vector4(0.0, 0.0, 0.0, 0.0)
    },
    
    -- Offices
    ["SmallOffice"] = {
        label = "Kleines Büro",
        type = "office",
        shell = "OfficeLow", -- QB-Interior shell name
        spawn = vector4(0.0, 0.0, 0.0, 0.0)
    },
    ["MediumOffice"] = {
        label = "Mittleres Büro",
        type = "office",
        shell = "OfficeMid", -- QB-Interior shell name
        spawn = vector4(0.0, 0.0, 0.0, 0.0)
    },
    ["LargeOffice"] = {
        label = "Großes Büro",
        type = "office",
        shell = "OfficeHigh", -- QB-Interior shell name
        spawn = vector4(0.0, 0.0, 0.0, 0.0)
    }
}

-- Default Property Prices
Config.DefaultPrices = {
    apartment = 50000,
    house = 150000,
    office = 250000
}

-- Admin Permission (only owner can set properties)
Config.AdminGroup = "admin" -- QB-Core permission group

-- Super Admins (Server Owner / License Holder)
-- Diese Spieler haben IMMER Admin-Rechte, unabhängig von Framework-Gruppen
-- Format: Identifier des Spielers (steam:, license:, discord:, etc.)
Config.SuperAdmins = {
    -- Beispiele:
    -- "steam:110000123456789",
    -- "license:1234567890abcdef1234567890abcdef12345678",
    -- "discord:123456789012345678",
}

-- License System
-- WICHTIG: Setzen Sie hier Ihre persönliche Lizenz ein!
-- Diese Datei NICHT auf GitHub hochladen!
Config.License = "" -- Ihre Admin Lizenz-Key hier eintragen

-- Debug Mode
Config.Debug = false

-- Language
Config.Locale = "de" -- German

-- Notifications
Config.Notifications = {
    ["property_purchased"] = "Sie haben die Immobilie erfolgreich gekauft!",
    ["property_rented"] = "Sie haben die Immobilie erfolgreich gemietet!",
    ["not_enough_money"] = "Sie haben nicht genug Geld!",
    ["property_already_owned"] = "Diese Immobilie ist bereits verkauft/vermietet!",
    ["rent_expired"] = "Ihre Miete ist abgelaufen!",
    ["key_given"] = "Schlüssel wurde erfolgreich übergeben!",
    ["max_keys_reached"] = "Maximale Anzahl an Schlüsseln erreicht!",
    ["no_permission"] = "Sie haben keine Berechtigung!",
    ["property_created"] = "Immobilie wurde erfolgreich erstellt!",
    ["garage_created"] = "Garage wurde erfolgreich erstellt!",
    ["property_deleted"] = "Immobilie wurde gelöscht!",
    ["entered_property"] = "Sie haben die Immobilie betreten!",
    ["exited_property"] = "Sie haben die Immobilie verlassen!"
}
