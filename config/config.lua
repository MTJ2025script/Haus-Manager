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
    -- APARTMENTS (Isolierte Interior-Shells - vermeiden Konflikte mit anderen Scripts)
    -- Diese Koordinaten sind INTERIOR-RÄUME, nicht normale Welt-Locations
    ["ModernApartment"] = {
        label = "Moderne Wohnung",
        type = "apartment",
        shell = "ModernHotel",
        spawn = vector4(266.06, -1007.43, -101.01, 0.0), -- Modern Apartment Interior (isoliert)
        safe_coords = vector4(260.0, -1003.0, -99.0, 90.0),
        wardrobe_coords = vector4(263.0, -1000.5, -99.0, 180.0)
    },
    ["ClassicApartment"] = {
        label = "Klassische Wohnung",
        type = "apartment",
        shell = "DelPerroHeights",
        spawn = vector4(151.48, -1007.9, -99.0, 0.0), -- Classic Apartment Interior (isoliert)
        safe_coords = vector4(145.0, -1004.0, -99.0, 90.0),
        wardrobe_coords = vector4(148.0, -1001.0, -99.0, 180.0)
    },
    ["LuxuryApartment"] = {
        label = "Luxus-Wohnung",
        type = "apartment",
        shell = "EclipseTowers",
        spawn = vector4(-773.2, 341.8, 211.4, 180.0), -- Luxury Apartment Interior (isoliert)
        safe_coords = vector4(-778.0, 337.0, 211.4, 90.0),
        wardrobe_coords = vector4(-775.0, 339.0, 211.4, 180.0)
    },
    
    -- HÄUSER (Isolierte Interior-Shells - vermeiden Konflikte mit anderen Scripts)
    ["StandardHouse"] = {
        label = "Standard-Haus",
        type = "house",
        shell = "FranklinHouse",
        spawn = vector4(7.93, 539.5, 176.03, 340.0), -- Standard House Interior (isoliert)
        safe_coords = vector4(12.0, 543.0, 176.03, 270.0),
        wardrobe_coords = vector4(9.0, 541.0, 176.03, 0.0)
    },
    ["ModernHouse"] = {
        label = "Modernes Haus",
        type = "house",
        shell = "MichaelHouse",
        spawn = vector4(-174.35, 497.5, 137.67, 180.0), -- Modern House Interior (isoliert)
        safe_coords = vector4(-169.0, 493.0, 137.67, 270.0),
        wardrobe_coords = vector4(-171.0, 496.0, 137.67, 0.0)
    },
    ["LuxuryHouse"] = {
        label = "Luxus-Haus",
        type = "house",
        shell = "TrevorHouse",
        spawn = vector4(-1150.7, -1520.7, 10.63, 125.0), -- Luxury House Interior (isoliert)
        safe_coords = vector4(-1146.0, -1517.0, 10.63, 270.0),
        wardrobe_coords = vector4(-1148.0, -1519.0, 10.63, 0.0)
    },
    
    -- BÜROS (Isolierte Interior-Shells - vermeiden Konflikte mit anderen Scripts)
    ["SmallOffice"] = {
        label = "Kleines Büro",
        type = "office",
        shell = "OfficeLow",
        spawn = vector4(-1005.0, -481.0, 50.03, 28.0), -- Small Office Interior (isoliert)
        safe_coords = vector4(-1007.5, -474.0, 50.03, 180.0),
        wardrobe_coords = vector4(-1005.0, -476.5, 50.03, 270.0)
    },
    ["MediumOffice"] = {
        label = "Mittleres Büro",
        type = "office",
        shell = "OfficeMid",
        spawn = vector4(-1579.76, -565.11, 108.52, 220.0), -- Medium Office Interior (isoliert)
        safe_coords = vector4(-1575.0, -560.0, 108.52, 180.0),
        wardrobe_coords = vector4(-1577.0, -563.0, 108.52, 270.0)
    },
    ["LargeOffice"] = {
        label = "Großes Büro",
        type = "office",
        shell = "OfficeHigh",
        spawn = vector4(-141.0, -620.0, 168.82, 90.0), -- Large Office Interior (isoliert)
        safe_coords = vector4(-136.89, -631.19, 168.82, 180.0),
        wardrobe_coords = vector4(-139.0, -625.0, 168.82, 270.0)
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
