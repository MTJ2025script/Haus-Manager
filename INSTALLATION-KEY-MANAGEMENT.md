# 🔑 Installation: Schlüsselverwaltungssystem

## ⚠️ WICHTIG: Nach dem Update

Dieses System wurde in den Commits `512f88b` und `dd3d863` hinzugefügt.

## 🔧 Installations-Schritte

### 1. Resource Stoppen
```
/stop haus-manager
```

### 2. Neueste Version laden
```bash
cd resources/[your-folder]/haus-manager
git pull origin copilot/fix-garage-exit-coordinates
```

### 3. Datenbank aktualisieren

Führen Sie diese SQL-Befehle in Ihrer Datenbank aus:

```sql
-- Spalten für temporäre Schlüssel hinzufügen
ALTER TABLE haus_keys 
ADD COLUMN IF NOT EXISTS key_type VARCHAR(20) DEFAULT 'permanent' 
COMMENT 'permanent or temporary';

ALTER TABLE haus_keys 
ADD COLUMN IF NOT EXISTS expires_at BIGINT DEFAULT NULL 
COMMENT 'Unix timestamp when temporary key expires';

-- Index für schnelles Finden abgelaufener Schlüssel
CREATE INDEX IF NOT EXISTS idx_expires ON haus_keys(expires_at);
```

### 4. Resource neu starten
```
/start haus-manager
```

### 5. Testen

1. Gehen Sie zu einer Immobilie, die Sie besitzen
2. Drücken Sie **E** am Eingang
3. Wählen Sie **"🔑 Schlüsselverwaltung"** aus dem Menü

## ✅ Was Sie sehen sollten

### Im Menü am Eingang:
- ✓ "Immobilie betreten"
- ✓ "Schlüssel verwalten" (alt)
- ✓ **"🔑 Schlüsselverwaltung"** (NEU!)
- ✓ "Immobilie verkaufen"

### In der Schlüsselverwaltungs-UI:
- ✓ Liste ALLER vergebenen Schlüssel
- ✓ Live Countdown-Timer für temporäre Schlüssel
- ✓ Fortschrittsbalken (grün → gelb → rot)
- ✓ Eigentümer-Badge (👑 goldene Krone)
- ✓ "Schlüssel vergeben" Sektion
- ✓ Auswahl zwischen permanent/temporär
- ✓ Ein-Klick "Entziehen" Button

### Mini-Benachrichtigung:
Wenn ein Spieler einen **temporären** Schlüssel erhält, erscheint eine schöne Benachrichtigung:
- ✓ Slide-in Animation von rechts
- ✓ Immobilien-Name
- ✓ Wer hat vergeben
- ✓ Gültigkeitsdauer
- ✓ Ablaufdatum
- ✓ Animierte Fortschrittsleiste
- ✓ Verschwindet automatisch nach 5 Sekunden

## 🐛 Troubleshooting

### Problem: Menüoption wird nicht angezeigt

**Lösung:**
1. Stellen Sie sicher, dass Sie **EIGENTÜMER** der Immobilie sind
2. F8-Konsole öffnen und nach Fehlern suchen
3. Resource neu starten: `/restart haus-manager`
4. Server-Neustart falls nötig

### Problem: UI öffnet sich nicht

**Überprüfen:**
```lua
-- In F8 Konsole sollte erscheinen:
[Haus-Manager KeyManager Client] Loaded successfully
[Haus-Manager KeyManager Server] Loaded successfully
```

**Wenn nicht:**
- Überprüfen Sie `fxmanifest.lua` - sollte enthalten:
  - `client/keymanager.lua`
  - `server/keymanager.lua`
  - `html/js/keymanager.js`
  - `html/css/keymanager.css`

### Problem: Datenbank-Fehler

**Fehler:** "Unknown column 'key_type'"

**Lösung:** SQL-Befehle aus Schritt 3 ausführen

### Problem: Spieler erhalten keine Benachrichtigung

**Überprüfen:**
1. Nur **temporäre** Schlüssel zeigen Benachrichtigung
2. Permanente Schlüssel zeigen keine Benachrichtigung
3. F8-Konsole auf Client-Seite prüfen

## 📚 Weitere Dokumentation

Siehe `SCHLÜSSELVERWALTUNG-DOKUMENTATION.md` für:
- Vollständige Bedienungsanleitung
- UI-Mockups
- Beispiel-Szenarien
- API-Referenz
- FAQ

## ⚡ Quick-Start

**Für Immobilien-Eigentümer:**
1. E drücken am Eingang
2. "🔑 Schlüsselverwaltung" wählen
3. Spieler auswählen (muss in 10m Nähe sein)
4. Typ wählen:
   - **Temporär:** 1-168 Stunden (Standard: 24h)
   - **Permanent:** Läuft nie ab
5. "Vergeben" klicken
6. Zum Entziehen: "Entziehen" Button bei Schlüssel klicken

**Für Schlüssel-Empfänger:**
- Bei temporärem Schlüssel: Schöne Benachrichtigung erscheint
- Bei permanentem Schlüssel: Einfach Zutritt zur Immobilie

## 🎨 UI-Features

- **Live-Timer:** Countdown läuft in Echtzeit (Tage:Stunden:Minuten)
- **Farbcodierung:** 
  - Grün: > 50% Zeit übrig
  - Gelb: 10-50% Zeit übrig
  - Rot: < 10% Zeit übrig (pulsierend wenn < 1 Stunde)
- **Responsive:** Funktioniert auf allen Bildschirmgrößen
- **Animationen:** Smooth Übergänge und Effekte
- **Font Awesome:** Professionelle Icons

## ✨ Systemhintergrund

### Auto-Cleanup
- Läuft alle 5 Minuten
- Entfernt abgelaufene Schlüssel automatisch
- Kickt Spieler aus Immobilie wenn Schlüssel abläuft

### Echtzeit-Updates
- Alle Schlüssel-Änderungen sofort sichtbar
- Betroffene Spieler erhalten sofort Benachrichtigung
- Keine Server-Neustarts nötig

### Sicherheit
- Nur Eigentümer können Schlüssel verwalten
- Eigentümer kann eigenen Schlüssel nicht entziehen
- Alle Aktionen werden geloggt
- Datenbank-Konsistenz gewährleistet
