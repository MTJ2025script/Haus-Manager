# 🔐 Identifier-Based Security System

## Das Problem mit Namen in FiveM

### ❌ Namen sind UNSICHER
FiveM/TxAdmin vergibt unterschiedliche Namen abhängig von der Auth-Methode:

**Beispiel - Ein Spieler, mehrere Namen:**
```
Steam Auth    → ghostdream008
CFX Auth      → coco81
FiveM Name    → lucifer
License Auth  → Player_12345
```

**Warum das problematisch ist:**
- Namen ändern sich je nach Auth-Methode
- Namen können von Spielern geändert werden
- Namen sind NICHT eindeutig
- **Security-Checks mit Namen = UNSICHER!**

---

## ✅ Identifier sind SICHER

### Was ist ein Identifier?

Der **identifier** ist eine **unveränderliche, eindeutige** ID die FiveM jedem Spieler zuweist:

```lua
-- ESX Beispiel:
identifier = "char:366c3d437a682115ababea671897bda09e8f638c"

-- QB-Core Beispiel:
citizenid = "ABC12345"
```

### Warum Identifier sicher sind:

✅ **Unveränderlich** - Bleibt IMMER gleich, egal welche Auth-Methode
✅ **Eindeutig** - Jeder Spieler hat einen einzigartigen identifier
✅ **Framework-Standard** - ESX und QB-Core basieren auf identifier/citizenid
✅ **Datenbank-Safe** - Wird in der Datenbank gespeichert als Primary Key

---

## 🛡️ Wie das Haus-Manager System Identifier verwendet

### 1. Property Ownership (Database)

**Tabelle `haus_properties`:**
```sql
CREATE TABLE haus_properties (
    id INT AUTO_INCREMENT PRIMARY KEY,
    property_id VARCHAR(50) UNIQUE NOT NULL,
    owner_identifier VARCHAR(50) DEFAULT NULL,  -- ✅ Identifier, NICHT Name!
    ...
);
```

**Beispiel-Eintrag:**
```sql
INSERT INTO haus_properties (owner_identifier) VALUES ('char:366c3d437a682115ababea671897bda09e8f638c');
```

### 2. Owner-Check (Client)

**client/main.lua - HasAccessToProperty():**
```lua
function HasAccessToProperty(property)
    -- Get player identifier (cached, secure)
    local playerIdentifier = nil
    
    if Framework.Type == 'esx' then
        playerIdentifier = PlayerData.identifier  -- ✅ Identifier!
    elseif Framework.Type == 'qb-core' then
        playerIdentifier = PlayerData.citizenid  -- ✅ Identifier!
    end
    
    -- Security check: Compare identifiers, NOT names!
    if property.owner_identifier == playerIdentifier then
        return true  -- ✅ SICHER!
    end
    
    return false
end
```

### 3. Key Management (Database)

**Tabelle `haus_keys`:**
```sql
CREATE TABLE haus_keys (
    id INT AUTO_INCREMENT PRIMARY KEY,
    property_id VARCHAR(50) NOT NULL,
    citizen_id VARCHAR(50) NOT NULL,  -- ✅ Identifier!
    granted_by VARCHAR(50) NOT NULL,   -- ✅ Identifier!
    ...
);
```

### 4. Admin Checks (Server)

**server/main.lua - IsAdmin():**
```lua
function IsAdmin(src)
    local identifier = FrameworkServer.GetPlayerIdentifier(src)  -- ✅ Identifier!
    
    -- Super Admin check (Config.lua)
    for _, adminIdentifier in ipairs(Config.SuperAdmins) do
        if identifier == adminIdentifier then  -- ✅ Identifier-Vergleich!
            return true
        end
    end
    
    return false
end
```

---

## 📋 Namen werden nur für Anzeige verwendet

Namen werden **ausschließlich für UI/Display** verwendet, **NIEMALS für Security**:

### ✅ Erlaubte Name-Verwendung:

**1. Display in UI:**
```lua
-- Zeige Owner-Namen in UI (nur Anzeige!)
local ownerName = exports['haus-manager']:GetOwnerName(property.owner_identifier)
print("Property gehört: " .. ownerName)  -- ✅ Nur Display!
```

**2. Nearby Players Liste:**
```lua
-- Zeige Spieler-Namen in Schlüsselverwaltung
nearbyPlayers = {
    { id = "char:366c3d43...", name = "coco81" },  -- Name nur für Anzeige!
    { id = "char:789abc...", name = "lucifer" }
}
```

**3. Logs/Debug:**
```lua
print("Player " .. GetPlayerName(source) .. " hat Property gekauft")  -- ✅ Nur Logging!
```

### ❌ Verbotene Name-Verwendung:

**NIEMALS Namen für Security verwenden:**
```lua
-- ❌ FALSCH - UNSICHER!
if property.owner_name == GetPlayerName(source) then
    return true
end

-- ❌ FALSCH - UNSICHER!
if adminName == "coco81" then
    return true
end
```

---

## 🔍 Identifier-Typen in FiveM

### ESX Legacy:
```lua
-- Character-basierter Identifier
identifier = "char:366c3d437a682115ababea671897bda09e8f638c"

-- Oder Steam-basiert (ältere Versionen):
identifier = "steam:110000xxxxxxxxx"
```

### QB-Core:
```lua
-- Citizen ID (kürzer, alphanumerisch)
citizenid = "ABC12345"
```

### Wie man den Identifier erhält:

**ESX:**
```lua
local playerData = ESX.GetPlayerData()
local identifier = playerData.identifier
```

**QB-Core:**
```lua
local playerData = QBCore.Functions.GetPlayerData()
local citizenid = playerData.citizenid
```

---

## ✅ Zusammenfassung

### Was das Haus-Manager System NIEMALS tut:
❌ Namen für Owner-Checks verwenden
❌ Namen für Admin-Checks verwenden
❌ Namen für Key-Access verwenden
❌ Namen in Security-relevanten Vergleichen verwenden

### Was das Haus-Manager System IMMER tut:
✅ Identifier für Owner-Checks verwenden
✅ Identifier für Admin-Checks verwenden
✅ Identifier für Key-Access verwenden
✅ Identifier in der Datenbank speichern
✅ Namen nur für UI/Display/Logs verwenden

---

## 🚀 Resultat

**Das System ist 100% sicher, egal welchen Namen TxAdmin vergibt!**

- Ein Spieler kann "ghostdream008", "coco81" oder "lucifer" heißen
- Sein identifier bleibt IMMER "char:366c3d437a682115ababea671897bda09e8f638c"
- Das System erkennt ihn IMMER korrekt als Owner
- **Security ist garantiert!**

---

## 📝 Best Practices für Entwickler

Wenn du das Script erweiterst:

1. **Verwende IMMER identifier für Security-Checks**
2. **Verwende Namen nur für Display**
3. **Speichere identifier in der Datenbank, nicht Namen**
4. **Vergleiche identifier, nicht Namen**
5. **Teste mit verschiedenen Auth-Methoden (Steam, CFX, License)**

**Beispiel - Property kaufen:**
```lua
-- ✅ RICHTIG:
MySQL.execute('UPDATE haus_properties SET owner_identifier = ? WHERE property_id = ?', {
    playerIdentifier,  -- ✅ Identifier!
    propertyId
})

-- ❌ FALSCH:
MySQL.execute('UPDATE haus_properties SET owner_name = ? WHERE property_id = ?', {
    playerName,  -- ❌ Name - UNSICHER!
    propertyId
})
```

---

**Dokumentiert:** 2026-01-27
**Author:** Haus-Manager Development Team
**Framework:** ESX Legacy & QB-Core
**Security Level:** 🔒 HIGH
