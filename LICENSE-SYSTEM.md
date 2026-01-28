# Haus-Manager Lizenz-System

## Übersicht

Das Haus-Manager System verfügt über ein Lizenz-Validierungs-System, das sicherstellt, dass nur autorisierte Admins das System verwenden können.

## Konfiguration

### Lizenz in Config setzen

Öffnen Sie `config/config.lua` und setzen Sie Ihre Admin-Lizenz:

```lua
-- License System
Config.License = "IHRE-LIZENZ-HIER-EINTRAGEN" -- Ihre Admin Lizenz-Key
```

### Ihre Lizenz

Wenn Sie eine neue Lizenz benötigen, kontaktieren Sie bitte den Entwickler.

**Ihre aktuelle Lizenz:**
```
IHRE-LIZENZ-HIER-EINTRAGEN
```

## Funktionsweise

### Beim Server-Start

1. Das System lädt die Lizenz aus `Config.License`
2. Die Lizenz wird gegen die Liste gültiger Lizenzen validiert
3. Bei erfolgreicher Validierung:
   ```
   [Haus-Manager License] Lizenz erfolgreich validiert!
   [Haus-Manager License] Lizenz-Key: 366c3d43...97bda09e8f638c
   ```

4. Bei ungültiger Lizenz:
   ```
   [Haus-Manager License] FEHLER: Ungültige Lizenz!
   [Haus-Manager License] Ihr Key: [Ihr eingegebener Key]
   [Haus-Manager License] Das System wird eingeschränkt funktionieren.
   ```

### Lizenz-Prüfung

Das System prüft die Lizenz automatisch beim Start. Sie können den Status auch programmatisch prüfen:

```lua
-- Server-seitig
local isValid = exports['haus-manager']:IsLicenseValid()
```

## Fehlerbehebung

### "Keine Lizenz in der Config gefunden"

**Problem:** `Config.License` ist nicht gesetzt oder leer.

**Lösung:** 
1. Öffnen Sie `config/config.lua`
2. Fügen Sie hinzu: `Config.License = "IHRE-LIZENZ-HIER-EINTRAGEN"`
3. Starten Sie den Server neu

### "Ungültige Lizenz"

**Problem:** Die eingegebene Lizenz ist nicht in der Liste gültiger Lizenzen.

**Lösung:**
1. Überprüfen Sie, ob Sie die korrekte Lizenz verwendet haben
2. Stellen Sie sicher, dass keine Leerzeichen oder zusätzliche Zeichen vorhanden sind
3. Ihre gültige Lizenz ist: `IHRE-LIZENZ-HIER-EINTRAGEN`

### System funktioniert trotz ungültiger Lizenz

Das System zeigt nur eine Warnung an, funktioniert aber weiterhin. Dies ist beabsichtigt, um Server-Abstürze zu vermeiden.

## Sicherheit

- Die Lizenz-Validierung erfolgt nur server-seitig
- Lizenz-Keys werden nur beim Start geprüft
- Bei ungültiger Lizenz wird eine Warnung in der Console angezeigt
- Admins erhalten eine Benachrichtigung bei ungültiger Lizenz

## Support

Bei Fragen zum Lizenz-System:
- GitHub Issues: https://github.com/MTJ2024/Haus-Manager/issues
- Dokumentation: Siehe MULTI-FRAMEWORK.md für allgemeine Informationen
