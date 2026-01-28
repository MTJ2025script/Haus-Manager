# Multi-Framework Support - QB-Core & ESX

## Übersicht

Das Haus-Manager System unterstützt nun **mehrere Frameworks**:
- ✅ **QB-Core** (qb-core)
- ✅ **ESX** (es_extended)

Das System erkennt automatisch, welches Framework aktiv ist, und passt sich entsprechend an.

## Features

### Automatische Framework-Erkennung
- Das System erkennt beim Start automatisch QB-Core oder ESX
- Keine manuelle Konfiguration erforderlich
- Funktioniert mit beiden Frameworks ohne Code-Änderungen

### Framework Bridge System
- **bridge/framework.lua** - Client-seitige Framework-Abstraktion
- **bridge/server_framework.lua** - Server-seitige Framework-Abstraktion
- Einheitliche API für beide Frameworks

### Unterstützte Framework-Funktionen

#### Player Management
- Spieler-Daten abrufen
- Spieler-Identifier (CitizenID/Identifier)
- Geld-Management (hinzufügen/entfernen)
- Permissions/Rechte-System

#### Vehicle Management
- Fahrzeug-Properties abrufen/setzen
- Kennzeichen-Management
- Garage-System

#### Notifications
- Framework-spezifische Benachrichtigungen
- Automatische Typ-Konvertierung

#### Callbacks
- Einheitliche Callback-API
- Kompatibel mit beiden Frameworks

## Installation

### Anforderungen

**Für QB-Core:**
```
- qb-core
- oxmysql
- qb-interior (optional)
```

**Für ESX:**
```
- es_extended
- oxmysql
```

### Setup

1. **Automatische Erkennung (Empfohlen)**
   ```lua
   -- config/config.lua
   Config.Framework = "auto-detect"
   ```
   Das System erkennt automatisch QB-Core oder ESX.

2. **Manuelle Konfiguration (Optional)**
   ```lua
   -- Für QB-Core
   Config.Framework = "qb-core"
   
   -- Für ESX
   Config.Framework = "esx"
   ```

3. **Resource starten**
   ```
   ensure haus-manager
   restart haus-manager
   ```

## Framework Bridge API

### Client-Seite (bridge/framework.lua)

```lua
-- Framework-Typ prüfen
local frameworkType = Framework.GetType() -- 'qb-core' oder 'esx'

-- Spieler-Daten
local playerData = Framework.GetPlayerData()
local identifier = Framework.GetPlayerIdentifier()

-- Notifications
Framework.Notify("Nachricht", "success", 5000)

-- Callbacks
Framework.TriggerCallback('callback-name', function(data)
    print(data)
end, args)

-- Fahrzeuge
local props = Framework.GetVehicleProperties(vehicle)
Framework.SetVehicleProperties(vehicle, props)
local plate = Framework.GetPlate(vehicle)

-- Events
Framework.OnPlayerLoaded(function()
    print("Spieler geladen")
end)

Framework.OnPlayerUnload(function()
    print("Spieler entladen")
end)
```

### Server-Seite (bridge/server_framework.lua)

```lua
-- Spieler von Source
local Player = FrameworkServer.GetPlayer(source)

-- Spieler von CitizenID/Identifier
local Player = FrameworkServer.GetPlayerByCitizenId(citizenid)

-- Geld-Management
local money = FrameworkServer.GetPlayerMoney(Player, 'bank')
FrameworkServer.RemoveMoney(Player, 'bank', 1000, 'Kauf')
FrameworkServer.AddMoney(Player, 'bank', 1000, 'Verkauf')

-- Permissions
local hasPermission = FrameworkServer.HasPermission(source, 'admin')

-- Callbacks
FrameworkServer.CreateCallback('callback-name', function(source, cb, args)
    cb(data)
end)

-- Commands
FrameworkServer.RegisterCommand('hausadmin', 'Öffne Admin Panel', {}, false, function(source)
    -- Command Logic
end, 'admin')
```

## Kompatibilität

### QB-Core Mapping

| QB-Core | Framework Bridge |
|---------|------------------|
| `QBCore.Functions.GetPlayerData()` | `Framework.GetPlayerData()` |
| `QBCore.Functions.Notify()` | `Framework.Notify()` |
| `QBCore.Functions.TriggerCallback()` | `Framework.TriggerCallback()` |
| `QBCore.Functions.GetVehicleProperties()` | `Framework.GetVehicleProperties()` |
| `QBCore.Functions.GetPlayer(source)` | `FrameworkServer.GetPlayer(source)` |

### ESX Mapping

| ESX | Framework Bridge |
|-----|------------------|
| `ESX.GetPlayerData()` | `Framework.GetPlayerData()` |
| `ESX.ShowNotification()` | `Framework.Notify()` |
| `ESX.TriggerServerCallback()` | `Framework.TriggerCallback()` |
| `ESX.Game.GetVehicleProperties()` | `Framework.GetVehicleProperties()` |
| `ESX.GetPlayerFromId(source)` | `FrameworkServer.GetPlayer(source)` |

## Framework-Spezifische Unterschiede

### Player Identifier

**QB-Core:**
```lua
Player.PlayerData.citizenid
```

**ESX:**
```lua
xPlayer.identifier
```

**Framework Bridge:**
```lua
Framework.GetPlayerIdentifier() -- Funktioniert für beide
```

### Money Accounts

**QB-Core:**
- `cash` - Bargeld
- `bank` - Bankgeld

**ESX:**
- `money` - Bargeld
- `bank` - Bankgeld

**Framework Bridge:**
```lua
-- Automatische Konvertierung
FrameworkServer.GetPlayerMoney(Player, 'bank')  -- Funktioniert für beide
FrameworkServer.GetPlayerMoney(Player, 'cash')  -- Wird zu 'money' in ESX
```

### Permissions

**QB-Core:**
```lua
QBCore.Functions.HasPermission(source, 'admin')
```

**ESX:**
```lua
xPlayer.getGroup() == 'admin'
```

**Framework Bridge:**
```lua
FrameworkServer.HasPermission(source, 'admin') -- Funktioniert für beide
```

## Migration

### Von QB-Core-only zu Multi-Framework

**Vorher:**
```lua
local QBCore = exports['qb-core']:GetCoreObject()
local Player = QBCore.Functions.GetPlayer(source)
QBCore.Functions.Notify(source, "Text", 'success')
```

**Nachher:**
```lua
-- Framework Bridge wird automatisch geladen
local Player = FrameworkServer.GetPlayer(source)
FrameworkServer.Notify(source, "Text", 'success')
```

## Troubleshooting

### Framework wird nicht erkannt

**Problem:** Console zeigt "Kein unterstütztes Framework gefunden"

**Lösung:**
1. Überprüfen Sie, dass QB-Core oder ESX läuft:
   ```
   ensure qb-core
   # ODER
   ensure es_extended
   ```

2. Starten Sie Haus-Manager nach dem Framework:
   ```cfg
   # server.cfg
   ensure qb-core
   ensure haus-manager
   ```

### Notifications funktionieren nicht

**Problem:** ESX Benachrichtigungen werden nicht angezeigt

**Lösung:** ESX erfordert möglicherweise ein separates Notification-Script.

**Alternative:**
```lua
-- In bridge/framework.lua anpassen
if Framework.Type == 'esx' then
    -- Verwende esx_notify oder anderes Notification-System
    TriggerEvent('esx:showNotification', message)
end
```

### Permissions funktionieren nicht in ESX

**Problem:** Admin-Commands funktionieren nicht

**Lösung:** Überprüfen Sie die ESX Gruppen-Namen:
```lua
-- ESX verwendet andere Gruppen-Namen
-- admin, superadmin, mod, user, etc.
Config.AdminGroup = "admin" -- Muss mit ESX-Gruppe übereinstimmen
```

## Debug-Modus

Aktivieren Sie Debug-Ausgaben:

```lua
-- config/config.lua
Config.Debug = true
```

**Console-Ausgabe:**
```
[Haus-Manager Bridge] QB-Core Framework erkannt
[Haus-Manager Bridge] Framework qb-core erfolgreich geladen
```

oder

```
[Haus-Manager Bridge] ESX Framework erkannt
[Haus-Manager Bridge] Framework esx erfolgreich geladen
```

## Performance

Die Framework Bridge fügt **keine merkbare Performance-Last** hinzu:
- ✅ Einmalige Framework-Erkennung beim Start
- ✅ Direkte Funktionsaufrufe (keine Overhead)
- ✅ Kompatibel mit Multicore-Optimierungen

## Support

### Getestete Versionen

**QB-Core:**
- ✅ QB-Core 1.x
- ✅ QB-Core 2.x (aktuell)

**ESX:**
- ✅ ESX Legacy 1.8.x
- ✅ ESX Legacy 1.9.x
- ✅ ESX Legacy 1.10.x

### Bekannte Einschränkungen

1. **qb-interior** - Nur mit QB-Core verfügbar
   - ESX-Nutzer müssen alternative Interior-Lösungen verwenden

2. **Inventory-Systeme** - Framework-spezifisch
   - QB: qb-inventory oder ox_inventory
   - ESX: ox_inventory empfohlen

## Zukünftige Erweiterungen

Geplante Framework-Unterstützung:
- [ ] QBox (QB-Core Fork)
- [ ] ND-Core
- [ ] Custom Frameworks

## Zusammenfassung

Das Multi-Framework-System ermöglicht:

✅ **Automatische Erkennung** von QB-Core und ESX
✅ **Einheitliche API** für beide Frameworks
✅ **Keine Code-Duplikation** mehr nötig
✅ **Einfache Migration** zwischen Frameworks
✅ **Bessere Wartbarkeit** durch zentrale Bridge
✅ **Kompatibel mit Multicore-Optimierung**

Das Haus-Manager System ist jetzt ein **universelles Property Management System** für FiveM!
