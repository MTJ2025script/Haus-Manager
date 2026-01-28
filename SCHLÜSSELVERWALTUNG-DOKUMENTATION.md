# 🔑 Schlüsselverwaltungssystem - Dokumentation

## Übersicht

Das Haus-Manager Schlüsselverwaltungssystem bietet Immobilieneigentümern vollständige Kontrolle über den Zugang zu ihren Immobilien. Das System unterstützt sowohl permanente als auch temporäre Schlüssel mit automatischem Ablauf.

---

## Features

### ✅ Permanente Schlüssel
- **Laufen nie ab**
- Perfekt für vertrauenswürdige Mitbewohner
- Können jederzeit manuell entzogen werden

### ⏱️ Temporäre Schlüssel
- **Automatischer Ablauf** nach festgelegter Zeit
- Einstellbar von 1 Stunde bis 7 Tage (168 Stunden)
- Automatische Benachrichtigung beim Empfang
- Visuelle Countdown-Anzeige
- Automatische Entfernung bei Ablauf

### 🎨 Benutzerfreundliche Oberfläche
- Professionelles Design im Haus-Manager Stil
- Live-Anzeige aller vergebenen Schlüssel
- Echtzeit-Countdown für temporäre Schlüssel
- Farbcodierte Warnungen bei Ablauf
- Ein-Klick Schlüssel-Entzug

### 📱 Mini-UI Benachrichtigung
- Schöne Benachrichtigung beim Erhalt eines temporären Schlüssels
- Zeigt an:
  - Immobilienname
  - Vergeben von (Person)
  - Gültigkeitsdauer
  - Ablaufdatum/-zeit
- Automatisches Ausblenden nach 5 Sekunden

---

## Verwendung

### Als Eigentümer

#### Schlüsselverwaltung öffnen

1. Gehen Sie zum Eingang Ihrer Immobilie
2. Drücken Sie **E** zum Interagieren
3. Wählen Sie **"🔑 Schlüsselverwaltung"**

#### Permanenten Schlüssel vergeben

1. Öffnen Sie die Schlüsselverwaltung
2. Wählen Sie einen Spieler aus der Dropdown-Liste (max. 10m Entfernung)
3. Klicken Sie auf **"∞ Permanent vergeben"**
4. Der Spieler erhält sofort dauerhaften Zugang

#### Temporären Schlüssel vergeben

1. Öffnen Sie die Schlüsselverwaltung
2. Wählen Sie einen Spieler aus der Dropdown-Liste
3. Stellen Sie die Dauer in Stunden ein (1-168)
   - **Empfohlene Dauern:**
     - 1 Stunde = Kurzer Besuch
     - 12 Stunden = Halbtägiger Zugang
     - 24 Stunden = Täglicher Zugang
     - 168 Stunden = Wöchentlicher Zugang
4. Klicken Sie auf **"⏱️ Temporär vergeben"**
5. Der Spieler erhält eine schöne Benachrichtigung

#### Schlüssel entziehen

1. Öffnen Sie die Schlüsselverwaltung
2. Suchen Sie den Schlüssel in der Liste
3. Klicken Sie auf **"❌ Entziehen"**
4. Der Zugang wird sofort entzogen
5. Der Spieler wird aus der Immobilie geworfen (falls drinnen)

### Als Schlüsselinhaber

#### Temporären Schlüssel empfangen

Wenn Sie einen temporären Schlüssel erhalten, sehen Sie:

- **Mini-UI Benachrichtigung** (oben rechts)
- Zeigt Immobilienname und Gültigkeitsdauer
- Verschwindet automatisch nach 5 Sekunden

#### Zugang zur Immobilie

- Gehen Sie zum Immobilieneingang
- Drücken Sie **E**
- Wählen Sie **"Betreten"**
- Sie werden zur Immobilie teleportiert (nur mit gültigem Schlüssel!)

#### Ablauf des Schlüssels

Wenn Ihr temporärer Schlüssel abläuft:

- ❌ **Benachrichtigung**: "Ihr temporärer Schlüssel für [Immobilie] ist abgelaufen"
- 🚪 **Automatischer Rauswurf** aus der Immobilie (falls drinnen)
- 🔒 **Kein Zugang mehr** zur Immobilie

---

## UI-Komponenten

### Hauptpanel - Schlüsselverwaltung

```
┌─────────────────────────────────────────────────┐
│ 🔑 Schlüsselverwaltung                       ✕ │
│ Villa am See                     🏠 Haus        │
├─────────────────────────────────────────────────┤
│                                                 │
│ 📋 Vergebene Schlüssel                          │
│ ┌─────────────────────────────────────────────┐ │
│ │ 👤 Max Mustermann        👑 Eigentümer      │ │
│ │                          ∞ Permanent        │ │
│ │ Vergeben: 01.01.2026 12:00                  │ │
│ └─────────────────────────────────────────────┘ │
│                                                 │
│ ┌─────────────────────────────────────────────┐ │
│ │ 👤 Anna Schmidt          ⏱️ Temporär        │ │
│ │                                             │ │
│ │ Läuft ab in:  23h 45m                       │ │
│ │ ████████████░░░░░░░  75%                   │ │
│ │                                             │ │
│ │ Vergeben: 01.01.2026 10:15                  │ │
│ │                      [❌ Entziehen]          │ │
│ └─────────────────────────────────────────────┘ │
│                                                 │
│ ➕ Schlüssel vergeben                           │
│ ┌─────────────────────────────────────────────┐ │
│ │ Spieler: [Tom Müller (5m)        ▼]        │ │
│ │                                             │ │
│ │ ⏱️ Temporärer Schlüssel                     │ │
│ │ Schlüssel läuft automatisch ab              │ │
│ │ Dauer: [24] Stunden                         │ │
│ │ [⏱️ Temporär vergeben]                      │ │
│ │                                             │ │
│ │ ∞ Permanenter Schlüssel                     │ │
│ │ Schlüssel läuft nie ab                      │ │
│ │ [∞ Permanent vergeben]                      │ │
│ └─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### Mini-UI Benachrichtigung

```
┌──────────────────────────────────────────┐
│  🔑    🔑 Temporärer Schlüssel erhalten  │
│        Villa am See                      │
│                                          │
│        Vergeben von: Max Mustermann      │
│        Gültig für: 24 Stunden           │
│        Läuft ab: 02.01.2026 10:30       │
│                                          │
│  ████████████████████████████████████   │
└──────────────────────────────────────────┘
```

---

## Technische Details

### Datenbank-Schema

```sql
CREATE TABLE `haus_keys` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `property_id` VARCHAR(50) NOT NULL,
    `citizen_id` VARCHAR(50) NOT NULL,
    `granted_by` VARCHAR(50) NOT NULL,
    `key_type` ENUM('permanent', 'temporary') DEFAULT 'permanent',
    `granted_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `expires_at` TIMESTAMP NULL DEFAULT NULL,
    ...
);
```

### Automatische Bereinigung

- **Intervall**: Alle 5 Minuten
- **Aktion**: Löscht abgelaufene temporäre Schlüssel
- **Benachrichtigung**: Betroffene Online-Spieler werden benachrichtigt
- **Rauswurf**: Spieler in der Immobilie werden rausgeworfen

### Events

**Server → Client:**
- `haus-manager:client:showKeyNotification` - Zeigt Mini-UI Benachrichtigung
- `haus-manager:client:updateKeys` - Aktualisiert Schlüsselliste
- `haus-manager:client:exitProperty` - Wirft Spieler aus Immobilie

**Client → Server:**
- `haus-manager:server:grantTemporaryKey` - Vergibt temporären Schlüssel
- `haus-manager:server:grantPermanentKey` - Vergibt permanenten Schlüssel
- `haus-manager:server:revokeKey` - Entzieht Schlüssel

**Callbacks:**
- `haus-manager:server:getPropertyKeys` - Holt alle Schlüssel für Immobilie

---

## Sicherheitsfeatures

### Validierungen

✅ **Eigentümerprüfung**: Nur Eigentümer können Schlüssel verwalten
✅ **Selbstschutz**: Eigentümer kann eigenen Schlüssel nicht entziehen
✅ **Näheprüfung**: Schlüssel nur an Spieler in 10m Umkreis
✅ **Bereichsprüfung**: Dauer 1-168 Stunden
✅ **Echtzeit-Sync**: Alle Änderungen sofort sichtbar

### Automatische Aktionen

- 🔄 **Key-Refresh**: Bei Vergabe/Entzug automatische Aktualisierung
- 🚪 **Auto-Kick**: Bei Ablauf/Entzug automatischer Rauswurf
- 🧹 **Auto-Cleanup**: Abgelaufene Schlüssel werden automatisch gelöscht
- 📢 **Benachrichtigungen**: Alle Betroffenen werden informiert

---

## Tipps & Best Practices

### Für Eigentümer

✨ **Temporäre Schlüssel bevorzugen**
- Verwenden Sie temporäre Schlüssel für Gäste
- Vermeiden Sie dauerhafte Zugänge für Besucher

⏰ **Sinnvolle Dauern wählen**
- 1-2 Stunden: Kurzer Besuch
- 12-24 Stunden: Tagesbesuch
- 7 Tage: Wöchentlicher Gast
- Permanent: Nur für vertrauenswürdige Personen

🔍 **Regelmäßig überprüfen**
- Checken Sie die Schlüsselliste regelmäßig
- Entziehen Sie ungenutzte Schlüssel
- Behalten Sie den Überblick

### Für Schlüsselinhaber

⏳ **Ablaufzeit beachten**
- Notieren Sie sich das Ablaufdatum
- Bei Bedarf um Verlängerung bitten
- Rechtzeitig Immobilie verlassen

🔒 **Respektvoller Umgang**
- Nutzen Sie den Zugang nur wie vereinbart
- Respektieren Sie das Eigentum
- Bei Problemen Eigentümer kontaktieren

---

## Troubleshooting

### Problem: "Keine Spieler in der Nähe"

**Lösung:**
- Stellen Sie sicher, dass Spieler maximal 10 Meter entfernt sind
- Bitten Sie den Spieler näherzukommen
- Laden Sie die UI neu (schließen und neu öffnen)

### Problem: Schlüssel wird nicht angezeigt

**Lösung:**
- Script neustarten: `/restart haus-manager`
- Datenbank prüfen: `SELECT * FROM haus_keys WHERE property_id = 'X'`
- Server-Logs checken auf Fehler

### Problem: Mini-UI erscheint nicht

**Lösung:**
- Cache leeren (F5 im Spiel)
- Prüfen ob `keymanager.js` geladen wird
- Browser-Konsole auf JavaScript-Fehler prüfen

### Problem: Automatische Bereinigung funktioniert nicht

**Lösung:**
- Server-Logs checken: `[Haus-Manager KeyManager] Cleaned up X expired...`
- MySQL Zeitzone prüfen
- Script-Neustart

---

## Beispiel-Szenarien

### Szenario 1: Party-Zugang

**Situation:** Sie veranstalten eine Party in Ihrer Villa

1. Öffnen Sie Schlüsselverwaltung
2. Vergeben Sie temporäre Schlüssel (3-4 Stunden) an Gäste
3. Alle können kommen und gehen während der Party
4. Nach Ablauf: Automatische Sperre

### Szenario 2: Mitbewohner

**Situation:** Sie wohnen mit jemandem zusammen

1. Öffnen Sie Schlüsselverwaltung
2. Vergeben Sie permanenten Schlüssel
3. Mitbewohner hat dauerhaften Zugang
4. Bei Auszug: Manuell entziehen

### Szenario 3: Kurzbesuch

**Situation:** Freund soll etwas aus der Wohnung holen

1. Vergeben Sie temporären Schlüssel (1 Stunde)
2. Freund erhält schöne Benachrichtigung
3. Freund kann Wohnung betreten
4. Nach 1 Stunde: Automatischer Ablauf

---

## FAQ

**F: Kann ich Schlüssel nachträglich von temporär auf permanent ändern?**
A: Ja, vergeben Sie einfach einen neuen permanenten Schlüssel. Der temporäre wird überschrieben.

**F: Was passiert wenn der Server neustartet?**
A: Alle Schlüssel bleiben in der Datenbank erhalten. Automatische Bereinigung läuft nach Neustart weiter.

**F: Kann ich sehen wann ein Schlüssel vergeben wurde?**
A: Ja, in der Schlüsselverwaltung wird "Vergeben: DD.MM.YYYY HH:MM" angezeigt.

**F: Gibt es ein Limit für Schlüssel?**
A: Nein, Sie können unbegrenzt viele Schlüssel vergeben.

**F: Kann ein Spieler mehrere Schlüssel für verschiedene Immobilien haben?**
A: Ja, Spieler können beliebig viele Schlüssel für verschiedene Immobilien besitzen.

---

## Support

Bei Problemen oder Fragen:

1. **Logs checken**: Server-Konsole und F8 Client-Konsole
2. **Dokumentation lesen**: Alle Funktionen sind hier beschrieben
3. **Datenbank prüfen**: Manuelle SQL-Abfragen zur Diagnose
4. **Issue erstellen**: Bei Bugs GitHub Issue öffnen

---

**Version:** 1.0.0  
**Letztes Update:** 10.01.2026  
**Autor:** Haus-Manager Team
