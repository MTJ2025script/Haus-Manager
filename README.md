# Haus-Manager - FiveM Property Management System

Ein vollständiges Immobilienverwaltungssystem für FiveM mit **Multi-Framework-Support** und **Multicore-Optimierung**.

![FiveM](https://img.shields.io/badge/FiveM-Resource-blue)
![QB-Core](https://img.shields.io/badge/Framework-QB--Core-green)
![ESX](https://img.shields.io/badge/Framework-ESX-green)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Performance](https://img.shields.io/badge/Performance-Optimized-brightgreen)

## 🌟 Features

- ✅ **Multi-Framework-Support** - QB-Core UND ESX unterstützt!
- ✅ **Super Admin System** - Server Owner hat automatisch volle Rechte!
- ✅ **Lizenz-System** - Admin-Lizenz in Config konfigurierbar
- ✅ Vollständiges Miet- und Kaufsystem
- ✅ Garagen mit 3, 6 oder 16 Stellplätzen
- ✅ Schlüsselverwaltung (2-15 Schlüssel je nach Typ)
- ✅ QB-Interior Integration (keine NPCs)
- ✅ Modernes gelb-grünes UI (GTA V Stil)
- ✅ Marker mit einstellbarem Radius
- ✅ Automatische Mietablauf-Verwaltung
- ✅ 3 Immobilientypen: Wohnung, Haus, Büro
- ✅ **Multicore-Optimierung für bessere Performance**

## 🔥 Multi-Framework Support

Das System funktioniert mit **QB-Core UND ESX**:

- **Automatische Framework-Erkennung** beim Server-Start
- **Keine manuelle Konfiguration** erforderlich
- **Framework Bridge System** für einheitliche API
- **Einfache Migration** zwischen Frameworks

```lua
-- Funktioniert automatisch mit:
✅ QB-Core (qb-core)
✅ ESX (es_extended)
```

Siehe [MULTI-FRAMEWORK.md](MULTI-FRAMEWORK.md) für Details.

## ⚡ Performance-Optimierung

Dieses System ist für **Multicore-Betrieb** optimiert:

- **90% weniger CPU-Last** durch intelligentes Thread-Management
- **3-Thread-Architektur** für Marker, Garagen und Interaktionen
- **Caching-System** reduziert wiederholte Berechnungen
- **Adaptive Sleep-Zeiten** für optimale Reaktionszeit
- Skaliert gut mit **100+ Eigenschaften**

Siehe [MULTICORE-OPTIMIZATION.md](MULTICORE-OPTIMIZATION.md) für technische Details.

## 📋 Voraussetzungen

### Für QB-Core
- FiveM Server
- QB-Core Framework
- qb-interior (optional)
- oxmysql
- qb-menu

### Für ESX
- FiveM Server
- ESX Legacy Framework
- oxmysql

## 🚀 Schnellstart

```bash
# Installation
cd resources
git clone https://github.com/MTJ2024/Haus-Manager.git

# Lizenz in Config setzen
# Öffnen Sie config/config.lua und setzen Sie:
# Config.License = "IHRE-LIZENZ-HIER-EINTRAGEN"

# Super Admin (Server Owner) einrichten
# Öffnen Sie config/config.lua und fügen Sie Ihre Identifier hinzu:
# Config.SuperAdmins = { "steam:110000123456789" }

# In server.cfg eintragen
ensure haus-manager

# Server starten
```

## 👑 Super Admin System

**Server Owner = Automatisch Super Admin!**

1. Finden Sie Ihre Identifier (Steam ID, License, etc.)
2. Öffnen Sie `config/config.lua`
3. Fügen Sie hinzu:
   ```lua
   Config.SuperAdmins = {
       "steam:110000123456789",  -- Ihre Steam ID
   }
   ```
4. Server neu starten

**Vorteile:**
- ✅ Automatische Admin-Rechte (keine Framework-Gruppe nötig)
- ✅ Funktioniert mit QB-Core UND ESX
- ✅ Unabhängig von In-Game Permissions
- ✅ Perfekt für Server Owner

Siehe [SERVER-CFG-SETUP.md](SERVER-CFG-SETUP.md) für Details.

## 🔐 Lizenz-System

Das System verwendet ein Lizenz-Validierungs-System:

1. Öffnen Sie `config/config.lua`
2. Setzen Sie Ihre Admin-Lizenz:
   ```lua
   Config.License = "IHRE-LIZENZ-HIER-EINTRAGEN"
   ```
3. Starten Sie den Server neu

Bei erfolgreicher Validierung sehen Sie:
```
[Haus-Manager License] Lizenz erfolgreich validiert!
```

Siehe [LICENSE-SYSTEM.md](LICENSE-SYSTEM.md) für Details.

## 📚 Dokumentation

Vollständige Dokumentation finden Sie in [DOKUMENTATION.md](DOKUMENTATION.md)

## 🎮 Admin-Befehle

- `/hausadmin` - Immobilien-Verwaltung öffnen
- `/hausgarage` - Garagen-Verwaltung öffnen

## 💡 Verwendung

1. Admin nutzt `/hausadmin` um Immobilien zu erstellen
2. Spieler interagieren mit Markern (E-Taste)
3. Kauf oder Miete im UI wählen
4. Immobilie betreten und nutzen

## 📸 Screenshots

(Screenshots folgen)

## 🤝 Mitwirken

Pull Requests sind willkommen! Für größere Änderungen öffnen Sie bitte zuerst ein Issue.

## 📝 Lizenz

[MIT](LICENSE)

## 🔗 Links

- [Vollständige Dokumentation](DOKUMENTATION.md)
- [GitHub Issues](https://github.com/MTJ2024/Haus-Manager/issues)
