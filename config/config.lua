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
    -- Apartments (ESX-kompatible Koordinaten)
    ["ModernApartment"] = {
        label = "Moderne Wohnung",
        type = "apartment",
        shell = "ModernHotel",
        spawn = vector4(266.06, -1007.43, -101.01, 0.0), -- Funktionierendes Apartment Interior
        safe_coords = vector4(260.0, -1003.0, -99.0, 90.0),
        wardrobe_coords = vector4(263.0, -1000.5, -99.0, 180.0)
    },
    ["ClassicApartment"] = {
        label = "Klassische Wohnung",
        type = "apartment",
        shell = "DelPerroHeights",
        spawn = vector4(265.0, -1007.0, -101.0, 0.0),
        safe_coords = vector4(259.0, -1003.0, -99.0, 90.0),
        wardrobe_coords = vector4(262.0, -1000.0, -99.0, 180.0)
    },
    ["LuxuryApartment"] = {
        label = "Luxus-Wohnung",
        type = "apartment",
        shell = "EclipseTowers",
        spawn = vector4(267.0, -1008.0, -101.0, 0.0),
        safe_coords = vector4(261.0, -1004.0, -99.0, 90.0),
        wardrobe_coords = vector4(264.0, -1001.0, -99.0, 180.0)
    },
    
    -- Häuser (ESX-kompatible Koordinaten)
    ["StandardHouse"] = {
        label = "Standard-Haus",
        type = "house",
        shell = "FranklinHouse",
        spawn = vector4(-174.35, 497.5, 137.65, 180.0), -- Franklin Area Interior
        safe_coords = vector4(-169.0, 493.0, 137.65, 270.0),
        wardrobe_coords = vector4(-171.0, 496.0, 137.65, 0.0)
    },
    ["ModernHouse"] = {
        label = "Modernes Haus",
        type = "house",
        shell = "MichaelHouse",
        spawn = vector4(-175.0, 498.0, 137.5, 180.0),
        safe_coords = vector4(-169.5, 493.5, 137.5, 270.0),
        wardrobe_coords = vector4(-171.5, 496.5, 137.5, 0.0)
    },
    ["LuxuryHouse"] = {
        label = "Luxus-Haus",
        type = "house",
        shell = "TrevorHouse",
        spawn = vector4(-173.0, 496.5, 137.8, 180.0),
        safe_coords = vector4(-168.0, 492.5, 137.8, 270.0),
        wardrobe_coords = vector4(-170.0, 495.5, 137.8, 0.0)
    },
    
    -- Büros (ESX-kompatible Koordinaten)
    ["SmallOffice"] = {
        label = "Kleines Büro",
        type = "office",
        shell = "OfficeLow",
        spawn = vector4(-1003.09, -478.02, 50.03, 90.0), -- Office Building Interior
        safe_coords = vector4(-1007.5, -474.0, 50.03, 180.0),
        wardrobe_coords = vector4(-1005.0, -476.5, 50.03, 270.0)
    },
    ["MediumOffice"] = {
        label = "Mittleres Büro",
        type = "office",
        shell = "OfficeMid",
        spawn = vector4(-1002.5, -477.5, 50.0, 90.0),
        safe_coords = vector4(-1007.0, -473.5, 50.0, 180.0),
        wardrobe_coords = vector4(-1004.5, -476.0, 50.0, 270.0)
    },
    ["LargeOffice"] = {
        label = "Großes Büro",
        type = "office",
        shell = "OfficeHigh",
        spawn = vector4(-1004.0, -479.0, 50.1, 90.0),
        safe_coords = vector4(-1008.0, -475.0, 50.1, 180.0),
        wardrobe_coords = vector4(-1005.5, -477.5, 50.1, 270.0)
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
