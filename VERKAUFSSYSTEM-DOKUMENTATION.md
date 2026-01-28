# Immobilien-Verkaufssystem

## Übersicht

Das Verkaufssystem ermöglicht es Eigentümern, ihre Immobilien entweder an die Stadt zurückzuverkaufen oder an andere Spieler auf dem Server zu verkaufen.

## Funktionen

### 1. Verkauf an Stadt

**Vorteile:**
- Schneller Verkauf ohne Käufersuche
- Garantierte Auszahlung
- Sofortige Verfügbarkeit der Immobilie für andere

**Prozess:**
1. Am Immobilieneingang E drücken
2. "Immobilie verkaufen" auswählen
3. "An Stadt verkaufen" wählen
4. Bestätigung der Details
5. Erhält 50% des ursprünglichen Kaufpreises

**Was passiert:**
- Alle Schlüssel werden entfernt
- Alle Fahrzeuge in der Garage werden entfernt
- Safe-Inhalte werden gelöscht
- Immobilie wird als "Zu verkaufen" markiert
- Eigentümer erhält Geld auf Bankkonto

### 2. Verkauf an Spieler

**Vorteile:**
- Freie Preisgestaltung
- Direkter Verkauf an bekannte Spieler
- Kann höheren Preis erzielen

**Voraussetzungen:**
- Käufer muss in 10 Meter Umkreis sein
- Käufer muss genug Geld haben

**Prozess:**
1. Am Immobilieneingang E drücken
2. "Immobilie verkaufen" auswählen
3. "An Spieler verkaufen" wählen
4. Im NUI-Interface:
   - Käufer aus Dropdown auswählen
   - Verkaufspreis eingeben (Vorschlag: 75% vom Original)
   - "Verkauf abschließen" klicken
5. Käufer zahlt, Verkäufer erhält Geld
6. Eigentum wird übertragen

**Was passiert:**
- Alle alten Schlüssel werden entfernt
- Neuer Eigentümer bekommt automatisch einen Schlüssel
- Verkäufer erhält Geld auf Bankkonto
- Käufer zahlt von Bankkonto
- Fahrzeuge und Safe bleiben beim neuen Eigentümer

## Benutzeroberfläche

### Eigentümer-Menü
```
🏠 [Immobilienname]
━━━━━━━━━━━━━━━━━━━━━
▶ Immobilie betreten
▶ Schlüssel verwalten
▶ Immobilie verkaufen ← NEU
▶ Schließen
```

### Verkaufsoptionen
```
🏠 [Immobilienname] verkaufen
━━━━━━━━━━━━━━━━━━━━━━━━━━━━
▶ 🏛️ An Stadt verkaufen
  Erhält: $[50% vom Preis]
  
▶ 👤 An Spieler verkaufen
  Verkaufen an anderen Spieler
  
▶ ❌ Abbrechen
```

### Verkauf an Stadt - Bestätigung
```
⚠️ Bestätigung erforderlich
━━━━━━━━━━━━━━━━━━━━━━━
📋 Verkaufsdetails
  Immobilie: [Name]
  Kaufpreis: $[Original]
  Verkaufspreis: $[50%]
  
▶ ✅ Verkauf bestätigen
▶ ❌ Abbrechen
```

### Verkauf an Spieler - NUI Interface
```
┌─────────────────────────────────────┐
│ 🏠 Immobilie an Spieler verkaufen   │
├─────────────────────────────────────┤
│                                     │
│ Immobiliendetails:                  │
│ ┌─────────────────────────────────┐ │
│ │ Immobilie: [Name]               │ │
│ │ Typ: [Typ]                      │ │
│ │ Urspr. Preis: $[Preis]          │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Käufer auswählen:                   │
│ ┌─────────────────────────────────┐ │
│ │ [Dropdown: Spieler in Nähe]     │ │
│ └─────────────────────────────────┘ │
│                                     │
│ Verkaufspreis ($):                  │
│ ┌─────────────────────────────────┐ │
│ │ [Eingabefeld: Preis]            │ │
│ └─────────────────────────────────┘ │
│ Empfohlen: 50-100% vom Original     │
│                                     │
│ ┌──────────────┐ ┌───────────────┐ │
│ │ 💰 Verkaufen │ │ ❌ Abbrechen  │ │
│ └──────────────┘ └───────────────┘ │
└─────────────────────────────────────┘
```

## Sicherheitsfunktionen

### Validierungen:
✅ Nur Eigentümer kann verkaufen
✅ Käufer muss genug Geld haben
✅ Preis muss gültig sein (0 - 99,999,999)
✅ Käufer muss in der Nähe sein (10m)

### Datenbank-Operationen:
✅ Transaktionale Übertragung
✅ Automatische Schlüsselverwaltung
✅ Safe und Garage werden korrekt behandelt
✅ Alle Clients werden aktualisiert

## Preisgestaltung

### Empfohlene Preise (Verkauf an Spieler):

| Nutzung | Empfohlener Preis |
|---------|------------------|
| Neu | 90-100% |
| Leicht genutzt | 75-90% |
| Viel genutzt | 50-75% |
| Schnellverkauf | 40-50% |

### Fixpreis (Verkauf an Stadt):
- Immer 50% des ursprünglichen Kaufpreises
- Keine Verhandlung möglich
- Sofortige Auszahlung

## Verwendung für Administratoren

### Debugging:
Wenn `Config.Debug = true`, werden alle Verkäufe geloggt:
```
[Haus-Manager] [Citizenid] sold property [PropertyId] to city for $[Amount]
[Haus-Manager] [Seller] sold property [PropertyId] to [Buyer] for $[Amount]
```

### Fehlerbehebung:

**Spieler kann nicht verkaufen:**
1. Überprüfe Eigentum: `SELECT * FROM haus_properties WHERE property_id = '[ID]'`
2. Überprüfe Spieler ist in Nähe der Immobilie
3. Überprüfe Menü funktioniert (`qb-menu` installiert?)

**Verkauf an Spieler funktioniert nicht:**
1. Überprüfe Käufer ist in 10m Umkreis
2. Überprüfe Käufer hat genug Geld
3. Überprüfe NUI-Fokus funktioniert

## Dateien

- **client/sell.lua** - Client-seitige Verkaufslogik
- **server/sell.lua** - Server-seitige Verkaufslogik
- **html/js/sell.js** - JavaScript für Verkaufs-UI
- **html/index.html** - HTML für Verkaufs-UI (integriert)
- **html/css/property.css** - Styling für Verkaufs-UI

## API

### Events

**Client → Server:**
```lua
-- Verkauf an Stadt
TriggerServerEvent('haus-manager:server:sellToCity', propertyId)

-- Verkauf an Spieler
TriggerServerEvent('haus-manager:server:sellToPlayer', propertyId, targetId, price)
```

**Server → Client:**
```lua
-- Öffne Verkaufsmenü
TriggerClientEvent('haus-manager:client:openSellMenu', source, {property = property})
```

### Callbacks

```lua
-- Hole Spieler in der Nähe
QBCore.Functions.TriggerCallback('haus-manager:server:getNearbyPlayers', function(players)
    -- players = {{id, name, citizenid}, ...}
end)
```

## Changelog

### Version 1.1.0 (Aktuell)
- ✅ Verkauf an Stadt hinzugefügt (50% Rückerstattung)
- ✅ Verkauf an Spieler hinzugefügt
- ✅ Professionelles NUI-Interface
- ✅ Automatische Schlüsselverwaltung
- ✅ Datenbankbereinigung bei Stadtverkauf
- ✅ Eigentümerübertragung bei Spielerverkauf
