# Projekt-Übersicht: Haus-Manager

## 📊 Statistiken

- **Gesamtzeilen Code**: ~3,100+ Zeilen
  - Lua (Server/Client): ~1,916 Zeilen
  - HTML/CSS/JS (UI): ~1,200 Zeilen
- **Dateien**: 24 Dateien
- **Sprachen**: Lua, HTML, CSS, JavaScript, SQL
- **Framework**: QB-Core für FiveM

## 🗂️ Dateistruktur

```
haus-manager/
├── 📄 fxmanifest.lua           # FiveM Resource Manifest
├── 📄 README.md                # Projekt-Readme
├── 📄 DOKUMENTATION.md         # Vollständige Dokumentation (DE)
├── 📄 INSTALLATION.md          # Installations-Anleitung
├── 📄 CHANGELOG.md             # Versionshistorie
├── 📄 LICENSE                  # MIT Lizenz
├── 📄 .gitignore              # Git Ignore Datei
│
├── 📁 config/
│   └── config.lua              # Zentrale Konfigurationsdatei
│
├── 📁 server/                  # Server-seitige Scripts
│   ├── main.lua               # Haupt-Server-Logik & Admin-Befehle
│   ├── database.lua           # Datenbank-Schema & Funktionen
│   ├── property.lua           # Immobilien-Verwaltung
│   ├── keys.lua               # Schlüsselsystem
│   └── rent.lua               # Miet-/Kauf-System
│
├── 📁 client/                  # Client-seitige Scripts
│   ├── main.lua               # Haupt-Client-Logik
│   ├── markers.lua            # Marker-System mit Radius
│   ├── garage.lua             # Garagen-Funktionalität
│   └── interior.lua           # QB-Interior Integration
│
└── 📁 html/                    # UI System
    ├── index.html             # Haupt-HTML-Datei
    ├── 📁 css/
    │   ├── style.css          # Haupt-Styles
    │   ├── admin.css          # Admin-UI Styles
    │   └── property.css       # Property-UI Styles
    └── 📁 js/
        ├── main.js            # Haupt-JavaScript
        ├── admin.js           # Admin-UI Logik
        └── property.js        # Property-UI Logik
```

## 🔧 Kern-Komponenten

### Server-Side (Lua)

#### 1. Database System (`server/database.lua`)
- **Automatische Tabelleninitialisierung**
  - `haus_properties` - Immobilien-Daten
  - `haus_keys` - Schlüssel-Zuweisungen
  - `haus_garage_vehicles` - Garagen-Fahrzeuge
- **CRUD-Operationen**
  - Erstellen, Lesen, Aktualisieren, Löschen von Immobilien
- **Exports für andere Resources**

#### 2. Property Management (`server/property.lua`)
- Fahrzeug-Ein- und Auslagerung
- Garagen-Kapazitätsverwaltung
- Zugriffskontrolle

#### 3. Key System (`server/keys.lua`)
- Typen-basierte Schlüssel-Limits
  - Wohnung: max. 2 Schlüssel
  - Haus: max. 5 Schlüssel
  - Büro: max. 15 Schlüssel
- Schlüssel-Vergabe an Spieler
- Zugriffs-Validierung

#### 4. Rent & Purchase System (`server/rent.lua`)
- Kauf-Abwicklung (einmalig)
- Miet-Abwicklung mit Zeiträumen
  - 1 Woche (5% des Kaufpreises)
  - 1 Monat (15%)
  - 3 Monate (35%)
  - 12 Monate (100%)
- Automatische Mietablauf-Überprüfung (alle 30 Min)
- Spieler-Benachrichtigungen

#### 5. Main Server (`server/main.lua`)
- Admin-Berechtigungsprüfung
- Event-Handlers
- QB-Core Commands
  - `/hausadmin` - Immobilien-Verwaltung
  - `/hausgarage` - Garagen-Verwaltung
  - `/hausdebug` - Debug-Informationen

### Client-Side (Lua)

#### 1. Main Client (`client/main.lua`)
- QB-Core Integration
- Property-Datenverwaltung
- NUI Callbacks
- Export-Funktionen

#### 2. Marker System (`client/markers.lua`)
- **Marker-Rendering**
  - Konfigurierbarer Radius
  - Sichtbarkeits-Steuerung
  - Radius-Ring-Visualisierung
- **Interaktions-System**
  - E-Taste für Interaktion
  - Kontext-basierte Menüs
  - Schlüssel-Verwaltung
- **3D-Text-Anzeige**

#### 3. Garage System (`client/garage.lua`)
- Garagen-Menüs
- Fahrzeug-Ein-/Auslagerung
- Garagen-Marker mit gelber Farbe
- Kapazitätsanzeige

#### 4. Interior System (`client/interior.lua`)
- QB-Interior Integration
- Betreten/Verlassen von Immobilien
- Screen-Fade-Effekte
- Exit-Marker im Innenraum

### UI System (HTML/CSS/JS)

#### 1. HTML Structure (`html/index.html`)
- **Admin-UI** - Immobilien-Erstellung
- **Garagen-UI** - Garagen-Verwaltung
- **Property-UI** - Kauf/Miet-Interface

#### 2. Styling (`html/css/*.css`)
- **GTA V Gelb-Grün Theme**
  - Primary: #ADFF2F (Yellow-Green)
  - Secondary: #FFD700 (Gold)
- **Moderne, helle Optik**
- **Responsive Design**
- **Animationen & Transitions**

#### 3. JavaScript Logic (`html/js/*.js`)
- **NUI Message Handler**
- **Form-Validierung**
- **Dynamic UI Updates**
- **AJAX-Kommunikation mit Client**

## 🎨 Design-Philosophie

### Farbschema (GTA V Stil)
```css
Primary Color:    #ADFF2F (Yellow-Green Grass)
Primary Dark:     #9ACD32
Secondary Color:  #FFD700 (Gold)
Background:       #F5F5F5 (Light)
Text Dark:        #2C2C2C
Success:          #32CD32 (Lime Green)
```

### UI-Prinzipien
1. **Minimalistisch** - Klare, aufgeräumte Interfaces
2. **Intuitiv** - Selbsterklärende Bedienung
3. **Konsistent** - Einheitliches Design
4. **Responsive** - Funktioniert auf allen Auflösungen

## ⚙️ Technische Features

### Datenbank-Design
- **Normalisierte Struktur** - Keine Redundanzen
- **Foreign Keys** - Referenzielle Integrität
- **Indizes** - Optimierte Abfragen
- **JSON-Felder** - Flexible Datenstrukturen (coords, vehicle_data)
- **Timestamps** - Automatische Zeitstempel

### Sicherheit
- ✅ **SQL-Injection-Schutz** - Prepared Statements
- ✅ **Permission Checks** - Admin-Validierung
- ✅ **Client-Server-Validierung** - Doppelte Prüfung
- ✅ **Sichere Schlüssel-Verwaltung** - Zugriffskontrolle

### Performance
- ✅ **Effiziente Marker-Rendering** - Draw-Distance Checks
- ✅ **Optimierte DB-Abfragen** - Indizierte Felder
- ✅ **Client-Side Caching** - Weniger Server-Requests
- ✅ **Threaded Operations** - Keine Blockierungen

### Erweiterbarkeit
- 📦 **Export-Funktionen** - API für andere Resources
- 🔌 **Event-System** - Hooks für Custom-Code
- ⚙️ **Config-File** - Einfache Anpassung
- 🔧 **Modular aufgebaut** - Klare Trennung

## 📋 Feature-Checkliste

### System-Architektur
- ✅ Kein NPC-System (nur Marker)
- ✅ QB-Interior natives (keine eigenen Shells)
- ✅ Feste Wohnungen (GTA Online Stil)
- ✅ Nur Admin-Verwaltung
- ✅ DB-gesteuert

### Garagen-System
- ✅ Klein (3 Slots)
- ✅ Mittel (6 Slots)
- ✅ Groß/Hotel (16 Slots)
- ✅ Fahrzeug-Speicherung
- ✅ Separate Marker

### Schlüsselsystem
- ✅ Wohnung: max. 2 Schlüssel
- ✅ Haus: max. 5 Schlüssel
- ✅ Büro: max. 15 Schlüssel
- ✅ Mehrfach-Schlüssel pro Objekt

### Miet-/Kauf-System
- ✅ Einmaliger Kauf
- ✅ 1 Woche Miete
- ✅ 1 Monat Miete
- ✅ 3 Monate Miete
- ✅ 12 Monate Miete
- ✅ Automatischer Ablauf

### Markierungssystem
- ✅ Ein/Aus schaltbar
- ✅ Radius einstellbar
- ✅ Visueller Radius-Ring
- ✅ Interaktions-UI

### UI-Design
- ✅ Heller Hintergrund
- ✅ Gelb-Grün Farben (GTA V Stil)
- ✅ Moderne Optik
- ✅ Separate UIs (Haus/Garage)
- ✅ Integriertes Zahlungssystem

### Immobilientypen
- ✅ Büro
- ✅ Haus
- ✅ Wohnung

## 🚀 Deployment-Ready

### Was ist enthalten:
1. ✅ **Vollständiger Quellcode** - Alle Lua/HTML/CSS/JS Dateien
2. ✅ **FXManifest** - Korrekte Dependencies
3. ✅ **Konfiguration** - Anpassbare Config-Datei
4. ✅ **Dokumentation** - README, Installation, Vollständige Docs
5. ✅ **Datenbank-Schema** - Auto-Initialisierung
6. ✅ **Lizenz** - MIT License

### Installation:
```bash
1. Resource in 'resources' Ordner kopieren
2. In server.cfg eintragen: ensure haus-manager
3. Server starten
4. Fertig!
```

## 📚 Dokumentation

- **README.md** - Projekt-Übersicht & Quick Start
- **INSTALLATION.md** - Schritt-für-Schritt Anleitung
- **DOKUMENTATION.md** - Vollständige Feature-Dokumentation
- **CHANGELOG.md** - Versionshistorie

## 🎯 Zielgruppe

- FiveM Server-Betreiber
- QB-Core Communities
- Roleplay-Server
- Immobilien-fokussierte Server

## 💡 Besonderheiten

1. **Deutsche Lokalisierung** - Komplett auf Deutsch
2. **GTA V Authentizität** - Originales Design-Feeling
3. **Zero-Configuration** - Funktioniert out-of-the-box
4. **Open Source** - MIT Lizenz, frei anpassbar
5. **Community-Driven** - Offen für Beiträge

## 🔮 Zukunft

Siehe CHANGELOG.md für geplante Features:
- MLO Support
- Möbel-System
- Web-Interface
- Makler-System
- Immobilien-Marktplatz

---

**Status**: ✅ Production Ready
**Version**: 1.0.0
**Letzte Aktualisierung**: 2024-12-27
