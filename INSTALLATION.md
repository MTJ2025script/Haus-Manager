# Installation & Setup Guide

## Schritt-für-Schritt Installation

### 1. Voraussetzungen prüfen

Stellen Sie sicher, dass Sie folgende Resources installiert haben:

- ✅ **QB-Core Framework** (neueste Version)
- ✅ **qb-interior** Resource
- ✅ **oxmysql** Resource
- ✅ **qb-menu** Resource
- ✅ **MySQL-Datenbank** (MariaDB oder MySQL 5.7+)

### 2. Download & Installation

#### Option A: Git Clone
```bash
cd /pfad/zu/ihrem/server/resources
git clone https://github.com/MTJ2024/Haus-Manager.git
```

#### Option B: Manueller Download
1. Laden Sie die neueste Version von GitHub herunter
2. Entpacken Sie das Archiv
3. Benennen Sie den Ordner zu `haus-manager` um
4. Kopieren Sie ihn in Ihren `resources` Ordner

### 3. Datenbank einrichten

Die Datenbank-Tabellen werden automatisch beim ersten Start erstellt. Sie müssen nichts manuell importieren.

**Alternativ** können Sie die Tabellen manuell erstellen:

```sql
-- Diese Tabellen werden automatisch erstellt, aber hier zur Referenz:

CREATE TABLE IF NOT EXISTS haus_properties (
    id INT AUTO_INCREMENT PRIMARY KEY,
    property_id VARCHAR(50) UNIQUE NOT NULL,
    property_type VARCHAR(20) NOT NULL,
    property_name VARCHAR(100) NOT NULL,
    coords JSON NOT NULL,
    interior_type VARCHAR(50) NOT NULL,
    price INT NOT NULL DEFAULT 0,
    owner_identifier VARCHAR(50) DEFAULT NULL,
    owned TINYINT(1) NOT NULL DEFAULT 0,
    is_rented TINYINT(1) NOT NULL DEFAULT 0,
    rent_end_date BIGINT DEFAULT NULL,
    rent_period INT DEFAULT NULL,
    marker_visible TINYINT(1) NOT NULL DEFAULT 1,
    marker_radius FLOAT NOT NULL DEFAULT 50.0,
    garage_coords JSON DEFAULT NULL,
    garage_size VARCHAR(20) DEFAULT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS haus_keys (
    id INT AUTO_INCREMENT PRIMARY KEY,
    property_id VARCHAR(50) NOT NULL,
    citizen_id VARCHAR(50) NOT NULL,
    granted_by VARCHAR(50) NOT NULL,
    granted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_property_citizen (property_id, citizen_id),
    FOREIGN KEY (property_id) REFERENCES haus_properties(property_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS haus_garage_vehicles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    property_id VARCHAR(50) NOT NULL,
    plate VARCHAR(20) NOT NULL,
    vehicle_data JSON NOT NULL,
    stored TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (property_id) REFERENCES haus_properties(property_id) ON DELETE CASCADE
);
```

### 4. Server.cfg konfigurieren

Fügen Sie folgende Zeilen zu Ihrer `server.cfg` hinzu:

```cfg
# Dependencies (in dieser Reihenfolge)
ensure qb-core
ensure qb-interior
ensure oxmysql
ensure qb-menu

# Haus-Manager Resource
ensure haus-manager
```

**Wichtig**: Stellen Sie sicher, dass `haus-manager` NACH allen Dependencies geladen wird.

### 5. Konfiguration anpassen

Öffnen Sie `haus-manager/config/config.lua` und passen Sie die Einstellungen an:

```lua
-- Beispiel-Anpassungen:

-- Admin-Berechtigung ändern
Config.AdminGroup = "admin" -- oder "god", "superadmin", etc.

-- Standard-Preise anpassen
Config.DefaultPrices = {
    apartment = 50000,  -- Ihre Preise
    house = 150000,
    office = 250000
}

-- Marker-Einstellungen
Config.Markers.DrawDistance = 50.0  -- Sichtweite anpassen
Config.Markers.Color = { r = 173, g = 255, b = 47 } -- Farbe ändern

-- Debug aktivieren (für Entwicklung)
Config.Debug = false  -- Auf true setzen für Debug-Meldungen
```

### 6. Server starten

1. Starten Sie Ihren FiveM Server
2. Beobachten Sie die Console auf Fehlermeldungen
3. Sie sollten sehen: `[Haus-Manager] Database tables initialized successfully`

### 7. Erste Schritte im Spiel

1. **Als Admin einloggen**
2. **Befehl eingeben**: `/hausadmin`
3. **Erste Immobilie erstellen**:
   - Typ wählen (z.B. "Wohnung")
   - Namen eingeben
   - Innenraum wählen
   - Preis setzen
   - "Aktuelle Position verwenden" klicken
   - "Immobilie erstellen" klicken

4. **Garage hinzufügen** (optional):
   - `/hausgarage` eingeben
   - Immobilie auswählen
   - Garagengröße wählen
   - Position für Garage festlegen
   - "Garage hinzufügen" klicken

### 8. Testen

1. **Als normaler Spieler**:
   - Zum erstellten Marker gehen
   - **E** drücken
   - Immobilie kaufen oder mieten

2. **Funktionen testen**:
   - ✅ Immobilie betreten
   - ✅ Garage nutzen
   - ✅ Schlüssel vergeben
   - ✅ Marker-Sichtbarkeit mit `/togglemarkers`

## Fehlerbehebung

### Problem: "Resource not found"
**Lösung**: Überprüfen Sie, ob der Ordnername exakt `haus-manager` ist (klein geschrieben, mit Bindestrich).

### Problem: Datenbank-Fehler
**Lösung**: 
1. Prüfen Sie oxmysql-Konfiguration
2. Stellen Sie sicher, dass MySQL läuft
3. Prüfen Sie Zugangsdaten in der server.cfg

### Problem: UI öffnet nicht
**Lösung**:
1. F8 Console öffnen und Fehler prüfen
2. Sicherstellen, dass alle HTML/CSS/JS Dateien vorhanden sind
3. Browser-Cache leeren (im FiveM Client)

### Problem: Marker nicht sichtbar
**Lösung**:
1. `/togglemarkers` eingeben (könnte ausgeschaltet sein)
2. In Config `Config.Markers.Enabled = true` prüfen
3. Immobilie: `marker_visible` muss auf 1 gesetzt sein

### Problem: Keine Berechtigung für Admin-Befehle
**Lösung**:
1. Prüfen Sie `Config.AdminGroup` in config.lua
2. Stellen Sie sicher, dass Ihr QB-Core Rang mit dem übereinstimmt
3. QB-Core permissions.lua überprüfen

## Performance-Optimierung

### Für große Server (100+ Spieler):

1. **Marker-Draw-Distance reduzieren**:
```lua
Config.Markers.DrawDistance = 25.0  -- statt 50.0
```

2. **Miet-Check-Intervall erhöhen**:
In `server/rent.lua` (Zeile ~110):
```lua
Wait(60 * 60 * 1000) -- 60 Minuten statt 30
```

3. **Datenbankabfragen optimieren**:
Indizes sind bereits vorhanden, aber Sie können zusätzliche hinzufügen:
```sql
CREATE INDEX idx_owner ON haus_properties(owner_identifier);
CREATE INDEX idx_owned ON haus_properties(owned);
```

## Aktualisierung

1. Sichern Sie Ihre `config/config.lua`
2. Sichern Sie Ihre Datenbank (SQL Backup)
3. Ersetzen Sie die alten Dateien mit den neuen
4. Übertragen Sie Ihre Config-Änderungen
5. Server neu starten

## Support

Bei Problemen:
1. Server Console Logs prüfen
2. F8 Client Console prüfen
3. GitHub Issues: https://github.com/MTJ2024/Haus-Manager/issues

## Nächste Schritte

- 📚 Lesen Sie die vollständige [DOKUMENTATION.md](DOKUMENTATION.md)
- 🎮 Erkunden Sie alle Features im Spiel
- 🔧 Passen Sie die Konfiguration an Ihre Bedürfnisse an
- 🌟 Geben Sie dem Projekt einen Stern auf GitHub!

---

**Viel Erfolg mit Ihrem Property Management System!** 🏠
