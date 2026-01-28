# Garage Exit Fallback System

## Übersicht

Das Garage-Exit-System verwendet einen mehrstufigen Fallback-Mechanismus, um sicherzustellen, dass Spieler niemals zu ungültigen Koordinaten teleportiert werden.

## Problem

**Ursprünglicher Bug (Zeile 94):**
```lua
lastExteriorCoords = json.decode(property.garage_coords)
```

Dies speicherte die **Garagen-Eingangskoordinaten** statt der **tatsächlichen Spielerposition** beim Betreten der Garage. Dadurch wurden Spieler beim Verlassen der Garage zu den Eingangskoordinaten statt zu ihrer ursprünglichen Position teleportiert, was zu Abstürzen oder Fall unter die Map führen konnte.

## Lösung

### 1. Hauptfix: Speichern der tatsächlichen Spielerposition

```lua
local currentCoords = GetEntityCoords(playerPed)
lastExteriorCoords = {
    x = currentCoords.x,
    y = currentCoords.y,
    z = currentCoords.z,
    heading = GetEntityHeading(playerPed)
}
```

### 2. Koordinatenvalidierung

Die Funktion `IsValidCoords(coords)` prüft:
- ✅ Koordinaten existieren (nicht nil)
- ✅ Koordinaten sind eine Tabelle
- ✅ x, y, z existieren
- ✅ x, y, z sind Zahlen (nicht Strings)
- ✅ Keine NaN-Werte (x ~= x prüft auf NaN)
- ✅ Keine Infinity-Werte (math.huge)

### 3. Vierstufiger Fallback-Mechanismus

Die Funktion `GetSafeExitCoords()` versucht in dieser Reihenfolge:

#### Stufe 1: Gespeicherte Spielerposition (BEVORZUGT)
```lua
if IsValidCoords(lastExteriorCoords) then
    return lastExteriorCoords
end
```
✅ **Normal Fall**: Spieler wird zu Position teleportiert, wo er Garage betreten hat

#### Stufe 2: Garagen-Eingangskoordinaten (FALLBACK)
```lua
if currentPropertyData and currentPropertyData.garage_coords then
    local success, garageCoords = pcall(json.decode, currentPropertyData.garage_coords)
    if success and IsValidCoords(garageCoords) then
        print("[Haus-Manager] FALLBACK: Verwende Garagen-Eingangskoordinaten")
        return garageCoords
    end
end
```
⚠️ **Fallback**: Wenn gespeicherte Position ungültig → Spieler wird zu Garagen-Eingang teleportiert
- Log-Nachricht wird ausgegeben für Debugging

#### Stufe 3: Aktuelle Position in Garage (NOTFALL)
```lua
local playerPed = PlayerPedId()
local currentPos = GetEntityCoords(playerPed)
if IsValidCoords({x = currentPos.x, y = currentPos.y, z = currentPos.z}) then
    print("[Haus-Manager] NOTFALL-FALLBACK: Verwende aktuelle Position")
    return {
        x = currentPos.x,
        y = currentPos.y,
        z = currentPos.z,
        heading = GetEntityHeading(playerPed)
    }
end
```
⚠️ **Notfall**: Wenn alles andere fehlschlägt → Spieler bleibt an aktueller Position (in Garage)
- Besser als Absturz oder ungültige Teleportation

#### Stufe 4: Weltmitte (ABSOLUTER NOTFALL)
```lua
print("[Haus-Manager] KRITISCHER FEHLER: Keine gültigen Koordinaten gefunden")
return {
    x = 0.0,
    y = 0.0,
    z = 75.0,
    heading = 0.0
}
```
🚨 **Absoluter Notfall**: Wenn NICHTS funktioniert → Spieler wird zu sicherer Position in der Luft teleportiert
- Verhindert Fall unter die Map
- Admin-Benachrichtigung nötig

## Verwendung

Das System arbeitet automatisch im Hintergrund. Administratoren sollten auf diese Log-Nachrichten achten:

```
[Haus-Manager] FALLBACK: Verwende Garagen-Eingangskoordinaten (lastExteriorCoords ungültig)
[Haus-Manager] NOTFALL-FALLBACK: Verwende aktuelle Position
[Haus-Manager] KRITISCHER FEHLER: Keine gültigen Koordinaten gefunden, teleportiere zu Standardposition
```

## Fehlerbehebung

Wenn Spieler Probleme beim Verlassen der Garage haben:

1. **Überprüfe Server-Logs** auf Fallback-Nachrichten
2. **Validiere Datenbank**: `garage_coords` in `haus_properties` Tabelle
3. **Teste verschiedene Szenarien**:
   - Zu Fuß betreten/verlassen
   - Mit Fahrzeug betreten/verlassen
   - Mehrfaches Betreten/Verlassen

## Sicherheit

✅ **Garantiert**: Spieler wird IMMER zu einer gültigen Position teleportiert
✅ **Kein Absturz**: Alle Fehler werden abgefangen
✅ **Debugging**: Alle Fallbacks werden geloggt
✅ **Wiederherstellung**: System kann sich von allen Fehlerzuständen erholen

## Code-Dateien

- **Hauptdatei**: `client/garage.lua`
- **Zeilen**: 9-59 (Helper-Funktionen), 144-156 (Speichern), 195-245 (Exit)
