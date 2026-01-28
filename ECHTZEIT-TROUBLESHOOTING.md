# Echtzeit-Verkauf Troubleshooting Guide

## Problem
Nach Verkauf einer Immobilie funktionieren die Echtzeit-Updates nicht:
- Verkäufer kann immer noch rein
- Käufer muss klingeln
- System erkennt Verkauf nicht

## Debugging Schritte

### Schritt 1: Resource Neustart
```
/restart haus-manager
```

### Schritt 2: F8 Konsole öffnen und bereit halten

### Schritt 3: Verkauf durchführen und Logs prüfen

## Erwartete Log-Ausgaben

### Bei VERKAUF AN STADT:

**Server Console sollte zeigen:**
```
[Haus-Manager Sell] City Sale - Seller keys after sale: 0
[Haus-Manager Sell] Broadcasting 5 properties to all clients
[Haus-Manager] ABC123 sold property property_1 to city for $50000
```

**Client F8 Console sollte zeigen:**
```
[Haus-Manager Client] Properties updated: 5 properties
[Haus-Manager Client] Keys updated: 0 keys received
```

### Bei VERKAUF AN SPIELER:

**Server Console sollte zeigen:**
```
[Haus-Manager Sell] Player Sale - Seller keys: 0, Buyer keys: 1
[Haus-Manager Sell] Broadcasting 5 properties to all clients
[Haus-Manager] ABC123 sold property property_1 to XYZ789 for $75000
```

**Verkäufer F8 Console sollte zeigen:**
```
[Haus-Manager Client] Keys updated: 0 keys received
```

**Käufer F8 Console sollte zeigen:**
```
[Haus-Manager Client] Keys updated: 1 keys received
[Haus-Manager Client] Key 1: Meine Immobilie (property_1)
```

## Was die Logs bedeuten

### ✅ FUNKTIONIERT wenn:
1. Alle oben genannten Logs erscheinen
2. Verkäufer hat 0 keys
3. Käufer hat 1+ keys
4. Properties werden broadcast

### ❌ FUNKTIONIERT NICHT wenn:

#### Keine Logs erscheinen:
**Problem:** Resource lädt nicht oder Events nicht registriert
**Lösung:** 
- Check `manifest.lua` - ist `server/sell.lua` drin?
- Check Server Console beim Start - Fehler?
- Versuche `/ensure haus-manager`

#### "Seller keys after sale" zeigt > 0:
**Problem:** Keys werden nicht aus Datenbank gelöscht
**Lösung:**
- Check Datenbank direkt: `SELECT * FROM haus_keys WHERE property_id = 'XXX'`
- Sollte leer sein nach Verkauf
- Wenn nicht: MySQL Problem oder Berechtigung

#### "Buyer keys" zeigt 0:
**Problem:** Key wird nicht an Käufer gegeben
**Lösung:**
- Check für Error: `[Haus-Manager Sell ERROR] Failed to give key to buyer!`
- Check `max_keys` in Config für property_type
- Check Datenbank: `SELECT * FROM haus_keys WHERE citizen_id = 'XXX'`

#### "Broadcasting X properties" fehlt:
**Problem:** GetAllProperties() schlägt fehl
**Lösung:**
- Check Server Console für MySQL Errors
- Check Datenbank Verbindung
- Versuche `/refreshdb` oder `/ensure oxmysql`

#### Client erhält "Keys updated" nicht:
**Problem:** Event kommt nicht beim Client an
**Lösung:**
- Check ob Spieler wirklich online ist (targetId korrekt?)
- Check FiveM Server Logs für Event Errors
- Versuche `/cl_drawfps 1` um Client Freeze zu prüfen

## Manuelle Datenbank-Prüfung

### Nach Verkauf an Stadt prüfen:
```sql
-- Keys sollten weg sein
SELECT * FROM haus_keys WHERE property_id = 'PROPERTY_ID';
-- Result: Keine Zeilen

-- Property sollte keinen Owner haben
SELECT owner_identifier, owned FROM haus_properties WHERE property_id = 'PROPERTY_ID';
-- Result: owner_identifier = NULL, owned = 0
```

### Nach Verkauf an Spieler prüfen:
```sql
-- Alte Keys weg, neuer Key da
SELECT * FROM haus_keys WHERE property_id = 'PROPERTY_ID';
-- Result: 1 Zeile mit citizen_id des Käufers

-- Property hat neuen Owner
SELECT owner_identifier, owned FROM haus_properties WHERE property_id = 'PROPERTY_ID';
-- Result: owner_identifier = BUYER_CITIZEN_ID, owned = 1
```

## Häufige Probleme

### 1. "Everything is dead after restart"
**Ursache:** Lua Syntax Fehler oder fehlende Abhängigkeit
**Lösung:** 
- Check Server Console beim `/start haus-manager`
- Suche nach `SCRIPT ERROR` oder `attempt to call`
- Stelle sicher `oxmysql` und `qb-core` laufen

### 2. Verkauf funktioniert, aber Echtzeit nicht
**Ursache:** Events kommen nicht an oder werden ignoriert
**Lösung:**
- Prüfe ob `TriggerClientEvent` wirklich aufgerufen wird (Logs!)
- Prüfe ob Client `RegisterNetEvent` hat für `updateKeys` und `updateProperties`
- Prüfe ob `playerKeys` und `properties` Variables existieren

### 3. Käufer ist Owner aber hat keinen Schlüssel
**Ursache:** `GivePropertyKey` schlägt fehl
**Lösung:**
- Check max_keys Limit
- Check Datenbank Constraints
- Check ob `citizen_id` korrekt ist

### 4. Verkäufer kann immer noch rein
**Ursache:** Keys nicht aktualisiert auf Client
**Lösung:**
- Prüfe ob `updateKeys` Event ankommt
- Prüfe ob `playerKeys = keys` ausgeführt wird
- Restart Client FiveM komplett

## Code-Reihenfolge (Wichtig!)

Bei Verkauf an Spieler läuft folgendes ab:

1. ✅ Geld wird übertragen
2. ✅ `DELETE FROM haus_keys` - ALLE Keys weg (mit .await)
3. ✅ `SetPropertyOwner` - Neuer Owner in DB
4. ✅ `GivePropertyKey` - Neuer Key für Käufer (mit .await in der Funktion)
5. ✅ `Wait(100)` - Warten auf DB Sync
6. ✅ `GetPlayerKeys` - Keys aus DB holen
7. ✅ `TriggerClientEvent updateKeys` - An beide senden
8. ✅ `TriggerClientEvent updateProperties` - An alle senden

Wenn ein Schritt fehlschlägt, brechen die folgenden auch!

## Support

Wenn das Problem weiterhin besteht, bitte folgendes senden:

1. **Server Console** Output nach `/restart haus-manager`
2. **F8 Console** Output bei Verkauf (Verkäufer UND Käufer)
3. **Datenbank Query** Ergebnisse von oben
4. **FiveM Version** und **QBCore Version**
5. **Andere installierte Scripts** die mit Properties arbeiten

## Quick Fix Versuche

### Fix 1: Resource Reihenfolge
In `server.cfg`:
```
ensure oxmysql
ensure qb-core
ensure qb-menu
ensure haus-manager
```

### Fix 2: Cache Clear
```
/restart haus-manager
/refreshdb (wenn verfügbar)
Client: Strg+F5 im Game
```

### Fix 3: Manuelle Key Aktualisierung
Als temporärer Workaround, Spieler können:
```
/logout
/login (oder Character neu wählen)
```
Dies lädt Keys neu vom Server.

## Finale Notiz

Die Logs in Commit `6cc9a5b` sind IMMER aktiv (nicht nur bei Config.Debug).
Wenn Sie KEINE Logs sehen, lädt das Script nicht korrekt!
