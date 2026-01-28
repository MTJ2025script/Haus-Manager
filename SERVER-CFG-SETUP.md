# Server.cfg Setup für Haus-Manager

## Super Admin Konfiguration

Das Haus-Manager System unterstützt **Super Admins** - Spieler, die IMMER Admin-Rechte haben, unabhängig von Framework-Gruppen (QB-Core/ESX).

### 1. Spieler-Identifier herausfinden

Um einen Spieler als Super Admin hinzuzufügen, benötigen Sie dessen Identifier.

**Methode 1: In-Game Console**
```
# Spieler verbindet sich mit dem Server
# In der Server-Console sehen Sie:
[system] Player connecting: Name
[system]   steam:110000123456789
[system]   license:1234567890abcdef1234567890abcdef12345678
[system]   discord:123456789012345678
```

**Methode 2: F8 Console (Client)**
```lua
# Spieler öffnet F8 Console im Spiel und gibt ein:
print(GetPlayerIdentifiers(PlayerId()))
```

**Methode 3: Server Command**
```lua
# In Server Console oder als Admin im Chat:
/identifiers [playerID]
```

### 2. Super Admin in Config eintragen

Öffnen Sie `config/config.lua` und fügen Sie die Identifier hinzu:

```lua
-- Super Admins (Server Owner / License Holder)
Config.SuperAdmins = {
    "steam:110000123456789",                              -- Steam ID
    "license:1234567890abcdef1234567890abcdef12345678",   -- Rockstar License
    "discord:123456789012345678",                         -- Discord ID
}
```

**Wichtig:**
- Verwenden Sie den KOMPLETTEN Identifier inkl. Prefix (steam:, license:, discord:, etc.)
- Ein Spieler kann mehrere Identifier haben - einer reicht
- Steam ID ist am sichersten (nicht änderbar)

### 3. Identifier-Typen

| Typ | Beispiel | Beschreibung |
|-----|----------|--------------|
| `steam:` | `steam:110000123456789` | Steam Account ID (empfohlen) |
| `license:` | `license:abc123...` | Rockstar Social Club License |
| `discord:` | `discord:123456789012345678` | Discord Account ID |
| `fivem:` | `fivem:123456` | FiveM Account ID |
| `ip:` | `ip:127.0.0.1` | IP Adresse (NICHT empfohlen) |

### 4. Server.cfg Konfiguration

**KEINE zusätzliche server.cfg Konfiguration nötig!**

Das System funktioniert automatisch:
1. Identifier in `config/config.lua` eintragen
2. Server neu starten: `restart haus-manager`
3. Fertig!

### 5. Beispiel-Konfiguration

**config/config.lua:**
```lua
-- Super Admins (Server Owner / License Holder)
Config.SuperAdmins = {
    "steam:110000123456789",  -- Server Owner
    "steam:110000987654321",  -- Co-Owner
}

-- License System
Config.License = "IHRE-LIZENZ-HIER-EINTRAGEN"

-- Admin Permission (für normale Admins)
Config.AdminGroup = "admin"
```

### 6. Testen

1. Verbinden Sie sich mit dem Spieler auf den Server
2. Geben Sie `/hausadmin` im Chat ein
3. Wenn Sie Super Admin sind, öffnet sich das Admin-UI

**Debug-Modus aktivieren:**
```lua
Config.Debug = true
```

Dann sehen Sie in der Console:
```
[Haus-Manager] Player [ID] is Super Admin: true
[Haus-Manager] Player [ID] has admin access: true
```

### 7. Unterschied: Super Admin vs Normal Admin

| Feature | Super Admin | Normal Admin |
|---------|-------------|--------------|
| Zugriff | IMMER | Nur mit Framework-Gruppe |
| Konfiguration | config.lua | Framework (QB-Core/ESX) |
| Änderbar | Nur mit File-Zugriff | Im Spiel änderbar |
| Empfohlen für | Server Owner, Co-Owner | Moderatoren, Staff |

### 8. Sicherheit

**Beste Practices:**
- Verwenden Sie Steam ID (am sichersten)
- Geben Sie Super Admin nur vertrauenswürdigen Personen
- Dokumentieren Sie, wer Super Admin ist
- Überprüfen Sie regelmäßig die Liste

**NICHT verwenden:**
- IP-Adressen (können sich ändern)
- Zu viele Super Admins (Sicherheitsrisiko)

### 9. Fehlerbehebung

**"Keine Admin-Rechte trotz Super Admin"**
1. Überprüfen Sie den Identifier - muss EXAKT übereinstimmen
2. Prüfen Sie, ob Config.SuperAdmins gesetzt ist
3. Server neu starten: `restart haus-manager`
4. Debug-Modus aktivieren und Console prüfen

**"Identifier nicht gefunden"**
1. Verbinden Sie sich mit dem Server
2. Schauen Sie in die Server-Console
3. Kopieren Sie den KOMPLETTEN Identifier (inkl. `steam:`, `license:`, etc.)

### 10. Automatisches Setup-Script

Erstellen Sie `get_my_identifiers.lua` im Server-Ordner:

```lua
RegisterCommand('myidentifiers', function(source, args, rawCommand)
    local identifiers = GetPlayerIdentifiers(source)
    
    print("^2=== Identifiers für Spieler " .. GetPlayerName(source) .. " ===^7")
    for _, id in ipairs(identifiers) do
        print("  " .. id)
    end
    
    TriggerClientEvent('chat:addMessage', source, {
        args = {"System", "Deine Identifiers wurden in der Server-Console ausgegeben."}
    })
end, false)
```

Dann im Spiel: `/myidentifiers`

---

## Zusammenfassung

1. **Identifier herausfinden** (Server-Console oder F8)
2. **Config.SuperAdmins in config.lua setzen**
3. **Server neu starten**
4. **Testen mit /hausadmin**

Fertig! Sie sind jetzt Super Admin mit vollen Rechten! 🎉
