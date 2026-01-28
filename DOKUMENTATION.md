# Haus-Manager - FiveM Property Management System

Ein vollständiges Immobilienverwaltungssystem für FiveM QB-Core Server mit Miet- und Kaufoptionen, Garagen-System und Schlüsselverwaltung.

## 🌟 Features

### Systemarchitektur
- ✅ **Kein NPC-System** - Komplett marker-basiert
- ✅ **QB-Interior Integration** - Nutzt natives QB-Interior System (keine eigenen Shells)
- ✅ **Feste Wohnungen** - GTA Online Style - vollständig eingerichtet
- ✅ **Admin-Verwaltung** - Nur Admins können Immobilien erstellen/verwalten
- ✅ **Datenbank-gesteuert** - Alle Daten werden persistent in MySQL gespeichert

### Garagen-System
- 🚗 **Klein**: 3 Stellplätze (für Wohnungen)
- 🚗 **Mittel**: 6 Stellplätze (für Häuser)
- 🚗 **Groß/Hotel**: 16 Stellplätze (für Büros)
- Fahrzeuge sicher ein- und auslagern
- Separate Garagen-Marker

### Schlüsselsystem
- 🔑 **Wohnung**: max. 2 Schlüssel
- 🔑 **Haus**: max. 5 Schlüssel
- 🔑 **Büro**: max. 15 Schlüssel
- Schlüssel an andere Spieler vergeben
- Automatische Rechteverwaltung

### Miet-/Kauf-System
- 💰 **Kauf**: Einmaliger Kauf - dauerhafter Besitz
- 💰 **Miete**: Zeitbasiert (GTA V Spielzeit)
  - 1 Woche (5% des Kaufpreises)
  - 1 Monat (15% des Kaufpreises)
  - 3 Monate (35% des Kaufpreises)
  - 12 Monate (100% des Kaufpreises)
- Automatische Mietablauf-Überprüfung

### Markierungssystem
- 📍 Marker-Sichtbarkeit ein/aus schaltbar
- 📍 Einstellbarer Sichtbarkeitsradius
- 📍 Visueller Radius-Ring im Spiel
- 📍 Interaktive Marker für Kauf/Miete

### UI-Design
- 🎨 Heller, moderner Hintergrund
- 🎨 Gelb-Grün Farbschema (GTA V Gras-Stil)
- 🎨 Separate UIs für Haus- und Garagen-Erstellung
- 🎨 Integriertes Zahlungssystem
- 🎨 Responsive Design

### Immobilientypen
- 🏢 **Büro**: Großzügige Arbeitsbereiche
- 🏠 **Haus**: Komfortable Einfamilienhäuser
- 🏙️ **Wohnung**: Kompakte Stadtwohnungen

## 📋 Voraussetzungen

- FiveM Server
- QB-Core Framework
- qb-interior Resource
- oxmysql (MySQL-Datenbank)
- qb-menu Resource

## 🚀 Installation

1. **Resource herunterladen und extrahieren**
   ```bash
   cd resources
   git clone https://github.com/MTJ2024/Haus-Manager.git
   ```

2. **Datenbank einrichten**
   - Die Tabellen werden automatisch beim ersten Start erstellt
   - Alternativ: SQL-Datei im `sql/` Ordner ausführen (falls vorhanden)

3. **Server.cfg anpassen**
   ```bash
   ensure qb-core
   ensure qb-interior
   ensure oxmysql
   ensure qb-menu
   ensure haus-manager
   ```

4. **Konfiguration anpassen**
   - Öffnen Sie `config/config.lua`
   - Passen Sie Preise, Marker-Einstellungen und andere Parameter an

5. **Server neu starten**

## 🎮 Verwendung

### Admin-Befehle

#### Immobilien erstellen
```
/hausadmin
```
Öffnet die Admin-UI zum Erstellen und Verwalten von Immobilien.

**Schritte:**
1. Immobilientyp auswählen (Wohnung/Haus/Büro)
2. Namen eingeben
3. Innenraum-Typ wählen
4. Preis festlegen
5. Position festlegen (oder "Aktuelle Position verwenden")
6. Marker-Einstellungen konfigurieren
7. "Immobilie erstellen" klicken

#### Garagen hinzufügen
```
/hausgarage
```
Öffnet die Garagen-UI zum Hinzufügen von Garagen zu bestehenden Immobilien.

**Schritte:**
1. Immobilie auswählen
2. Garagengröße wählen (Klein/Mittel/Groß)
3. Garage-Position festlegen
4. "Garage hinzufügen" klicken

### Spieler-Interaktion

#### Immobilie kaufen/mieten
1. Zum Immobilien-Marker gehen (gelb-grüner Zylinder)
2. **[E]** drücken
3. Im UI zwischen Kauf und Miete wählen
4. Für Miete: Zeitraum auswählen
5. Bestätigen

#### Immobilie betreten
1. Als Besitzer oder Schlüsselinhaber zum Marker gehen
2. **[E]** drücken
3. "Immobilie betreten" wählen

#### Garage verwenden
1. Zum Garagen-Marker gehen (gelber karierter Zylinder)
2. **[E]** drücken
3. Fahrzeug einlagern oder ausholen

#### Schlüssel verwalten (nur Eigentümer)
1. Am Immobilien-Marker **[E]** drücken
2. "Schlüssel verwalten" wählen
3. Spieler in der Nähe auswählen
4. Schlüssel übergeben

### Zusätzliche Befehle

```
/togglemarkers
```
Schaltet die Sichtbarkeit aller Marker ein/aus (persönliche Einstellung)

```
/hausdebug
```
Zeigt Debug-Informationen im Server-Log (nur für Admins, wenn Debug aktiviert ist)

## ⚙️ Konfiguration

### Wichtige Config-Einstellungen

#### Marker-Einstellungen
```lua
Config.Markers = {
    Enabled = true,              -- Marker global aktivieren/deaktivieren
    DrawDistance = 50.0,         -- Standard-Sichtweite
    InteractionDistance = 2.5,   -- Interaktions-Distanz
    ShowRadius = true,           -- Radius-Ring anzeigen
}
```

#### Immobilientypen
```lua
Config.PropertyTypes = {
    apartment = {
        maxKeys = 2,            -- Max. Schlüssel
        garageSize = "small",   -- Standard-Garagengröße
    },
    -- ...
}
```

#### Mietzeiten
```lua
Config.RentPeriods = {
    {
        label = "1 Woche",
        days = 7,
        multiplier = 0.05  -- 5% des Kaufpreises
    },
    -- ...
}
```

## 🗄️ Datenbank-Struktur

### haus_properties
Speichert alle Immobilien-Informationen
- property_id (eindeutig)
- property_type, property_name
- coords (JSON), interior_type
- price, owner_identifier
- owned, is_rented, rent_end_date
- marker_visible, marker_radius
- garage_coords, garage_size

### haus_keys
Verwaltet Schlüssel-Zuweisungen
- property_id, citizen_id
- granted_by, granted_at

### haus_garage_vehicles
Speichert Garagen-Fahrzeuge
- property_id, plate
- vehicle_data (JSON)
- stored (Eingelagert ja/nein)

## 🔧 Entwicklung & Anpassung

### Neue Innenraum-Typen hinzufügen
Bearbeiten Sie `config/config.lua`:
```lua
Config.Interiors["MeinNeuerTyp"] = {
    label = "Mein Neuer Innenraum",
    type = "apartment",  -- oder "house" oder "office"
    shell = "QB-Interior-Shell-Name",
    spawn = vector4(0.0, 0.0, 0.0, 0.0)
}
```

### UI-Styling anpassen
CSS-Dateien befinden sich in `html/css/`:
- `style.css` - Haupt-Styles
- `admin.css` - Admin-UI
- `property.css` - Kauf/Miet-UI

Farben können über CSS-Variablen angepasst werden:
```css
:root {
    --primary-color: #ADFF2F;  /* Gelb-Grün */
    --secondary-color: #FFD700; /* Gold */
}
```

### Events für andere Resources

#### Server-Events
```lua
-- Immobilie erstellen
TriggerEvent('haus-manager:server:createProperty', propertyData)

-- Schlüssel geben
TriggerEvent('haus-manager:server:giveKey', propertyId, targetPlayerId)
```

#### Client-Events
```lua
-- Immobilie betreten
TriggerEvent('haus-manager:client:enterProperty', {property = propertyData})

-- Garage öffnen
TriggerEvent('haus-manager:client:openGarageMenu', {property = propertyData})
```

#### Exports
```lua
-- Server-seitig
local property = exports['haus-manager']:GetPropertyById(propertyId)
local hasKey = exports['haus-manager']:HasPropertyKey(propertyId, citizenId)

-- Client-seitig
local properties = exports['haus-manager']:GetProperties()
local hasAccess = exports['haus-manager']:HasAccessToProperty(property)
```

## 📝 Lizenz

Dieses Projekt steht unter der MIT-Lizenz. Siehe LICENSE-Datei für Details.

## 🤝 Support & Mitwirken

- **Issues**: Bitte melden Sie Bugs über GitHub Issues
- **Pull Requests**: Beiträge sind willkommen!
- **Dokumentation**: Helfen Sie bei der Verbesserung der Docs

## 📞 Kontakt

- GitHub: https://github.com/MTJ2024/Haus-Manager
- Discord: [Ihr Discord Server Link]

## 🎯 Roadmap

- [ ] MLO-Support (Multi-Level Objects)
- [ ] Möbel-System (Individualisierung)
- [ ] Mitbewohner-System
- [ ] Rechnungssystem für Miete
- [ ] Import/Export von Immobilien
- [ ] Web-Interface für Verwaltung

## 📸 Screenshots

[Screenshots der UI und Features einfügen]

---

**Entwickelt mit ❤️ für die FiveM Community**
