Config = {}

-- Framework-Einstellungen (QB-Core oder ESX werden automatisch erkannt)
Config.Framework = "auto-detect" -- Automatische Erkennung (kann auch manuell auf "qb-core" oder "esx" gesetzt werden)
Config.UseQBInterior = true -- QB-Interior natives verwenden (keine custom shells)

-- Marker-Einstellungen
Config.Markers = {
    Enabled = true, -- Marker-Sichtbarkeit global ein/aus
    Type = 1, -- Marker-Typ (1 = Zylinder)
    Size = { x = 0.8, y = 0.8, z = 0.5 }, -- Kleiner, weniger sichtbar
    Color = { r = 255, g = 255, b = 255 }, -- Weiße Farbe
    Alpha = 100, -- Transparenter
    BobUpAndDown = false,
    FaceCamera = false,
    Rotate = false,
    DrawDistance = 50.0, -- Standard-Sichtweite
    InteractionDistance = 2.5, -- Distanz für Interaktion
    ShowRadius = false, -- Radius-Ring ausblenden für sauberen Look
    RadiusColor = { r = 255, g = 255, b = 255, a = 30 }
}

-- Immobilientypen
Config.PropertyTypes = {
    apartment = {
        label = "Wohnung",
        maxKeys = 2,
        garageSize = "small", -- 3 Parkplätze
        icon = "apartment"
    },
    house = {
        label = "Haus",
        maxKeys = 5,
        garageSize = "medium", -- 6 Parkplätze
        icon = "home"
    },
    office = {
        label = "Büro",
        maxKeys = 15,
        garageSize = "large", -- 16 Parkplätze
        icon = "business"
    }
}

-- Garagen-Größen
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
-- NOTE: Spawn coordinates may need adjustment based on your qb-interior configuration
-- These are example coordinates - verify with your actual interior shells
--
-- WICHTIG: Manche Shells haben fest integrierte grüne Exit-Marker als Teil des IPL/Models!
-- Falls Sie einen grünen Marker sehen der nicht entfernt werden kann, probieren Sie ein anderes Shell.
-- Empfohlene Shells OHNE fest integrierte Marker:
--   - Apartments: "ModernHotel", "DelPerroHeights" 
--   - Häuser: "FranklinHouse", "MichaelHouse"
--   - Büros: "OfficeStandard" (falls verfügbar statt "OfficeLow")
--
Config.Interiors = {
    -- Apartments
    ["ModernApartment"] = {
        label = "Moderne Wohnung",
        type = "apartment",
        shell = "ModernHotel", -- QB-Interior Shell-Name
        spawn = vector4(0.0, 0.0, 0.0, 0.0) -- qb-interior Shell bestimmt die Position
    },
    ["ClassicApartment"] = {
        label = "Klassische Wohnung",
        type = "apartment",
        shell = "DelPerroHeights", -- QB-Interior Shell-Name
        spawn = vector4(0.0, 0.0, 0.0, 0.0) -- qb-interior Shell bestimmt die Position
    },
    ["LuxuryApartment"] = {
        label = "Luxus-Wohnung",
        type = "apartment",
        shell = "EclipseTowers", -- QB-Interior Shell-Name
        spawn = vector4(0.0, 0.0, 0.0, 0.0) -- qb-interior Shell bestimmt die Position
    },
    
    -- Häuser
    ["StandardHouse"] = {
        label = "Standard-Haus",
        type = "house",
        shell = "FranklinHouse", -- QB-Interior Shell-Name
        spawn = vector4(0.0, 0.0, 0.0, 0.0) -- qb-interior Shell bestimmt die Position
    },
    ["ModernHouse"] = {
        label = "Modernes Haus",
        type = "house",
        shell = "MichaelHouse", -- QB-Interior Shell-Name
        spawn = vector4(0.0, 0.0, 0.0, 0.0) -- qb-interior Shell bestimmt die Position
    },
    ["LuxuryHouse"] = {
        label = "Luxus-Haus",
        type = "house",
        shell = "TrevorHouse", -- QB-Interior Shell-Name
        spawn = vector4(0.0, 0.0, 0.0, 0.0) -- qb-interior Shell bestimmt die Position
    },
    
    -- Büros
    ["SmallOffice"] = {
        label = "Kleines Büro",
        type = "office",
        shell = "OfficeLow", -- QB-Interior Shell-Name
        spawn = vector4(0.0, 0.0, 0.0, 0.0) -- qb-interior Shell bestimmt die Position
    },
    ["MediumOffice"] = {
        label = "Mittleres Büro",
        type = "office",
        shell = "OfficeMid", -- QB-Interior Shell-Name
        spawn = vector4(0.0, 0.0, 0.0, 0.0) -- qb-interior Shell bestimmt die Position
    },
    ["LargeOffice"] = {
        label = "Großes Büro",
        type = "office",
        shell = "OfficeHigh", -- QB-Interior Shell-Name
        spawn = vector4(0.0, 0.0, 0.0, 0.0) -- qb-interior Shell bestimmt die Position
    }
}

-- Standard-Immobilienpreise
Config.DefaultPrices = {
    apartment = 50000,
    house = 150000,
    office = 250000
}

-- Admin-Berechtigung (nur Besitzer kann Immobilien setzen)
Config.AdminGroup = "admin" -- QB-Core Berechtigungsgruppe

-- Super-Admins (Server-Besitzer / Lizenzinhaber)
-- Diese Spieler haben IMMER Admin-Rechte, unabhängig von Framework-Gruppen
-- Format: Identifier des Spielers (steam:, license:, discord:, etc.)
Config.SuperAdmins = {
    -- Beispiele:
    -- "steam:110000123456789",
    -- "license:1234567890abcdef1234567890abcdef12345678",
    -- "discord:123456789012345678",
}

-- Lizenz-System
-- WICHTIG: Setzen Sie hier Ihre persönliche Lizenz ein!
-- Diese Datei NICHT auf GitHub hochladen!
Config.License = "" -- Ihre Admin Lizenz-Key hier eintragen

-- Debug-Modus
Config.Debug = false

-- Sprache
Config.Locale = "de" -- Deutsch

-- Benachrichtigungen
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
