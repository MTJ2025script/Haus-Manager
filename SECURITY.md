# Sicherheitshinweise für Haus-Manager

## ⚠️ WICHTIG: Sensible Daten

### Was NIEMALS auf GitHub hochladen!

**NIEMALS diese Dateien/Daten öffentlich teilen:**

1. **config/config.lua** - Enthält Ihre Lizenz und Super-Admin IDs
2. **Lizenz-Keys** - Ihre persönliche Lizenz NIEMALS zeigen
3. **Steam IDs** - Ihre oder andere Spieler-Identifiers
4. **Discord IDs** - Persönliche Identifiers
5. **Datenbank-Credentials** - Falls in Config gespeichert

### .gitignore

Die Datei `.gitignore` verhindert automatisch das Hochladen von:
- `config/config.lua` (Ihre persönliche Config)

**Verwenden Sie stattdessen:**
- `config/config.example.lua` (Beispiel ohne echte Daten)

## 🔒 Sicherheitsmaßnahmen

### 1. Lizenz schützen

**FALSCH:**
```lua
-- ❌ Lizenz im Code oder auf GitHub
Config.License = "echt-lizenz-hier"  -- NIEMALS!
```

**RICHTIG:**
```lua
-- ✅ Nur auf Ihrem Server
Config.License = "Ihre-Lizenz-Hier"  -- Nur lokal!
```

### 2. Super Admins schützen

**FALSCH:**
```lua
-- ❌ Echte Steam IDs auf GitHub
Config.SuperAdmins = {
    "steam:110000123456789",  -- NIEMALS!
}
```

**RICHTIG:**
```lua
-- ✅ Beispiele ohne echte Daten
Config.SuperAdmins = {
    -- "steam:YOUR_STEAM_ID_HERE",
    -- "license:YOUR_LICENSE_HERE",
}
```

### 3. Installation auf dem Server

**Schritt 1: Repository klonen**
```bash
cd resources
git clone https://github.com/MTJ2024/Haus-Manager.git
cd Haus-Manager
```

**Schritt 2: Config einrichten**
```bash
# Kopieren Sie die Beispiel-Config
cp config/config.example.lua config/config.lua

# Bearbeiten Sie config/config.lua (NICHT config.example.lua!)
nano config/config.lua
```

**Schritt 3: Lizenz und Super Admins eintragen**
```lua
-- In config/config.lua (NUR auf Ihrem Server!)
Config.License = "IHRE-ECHTE-LIZENZ"
Config.SuperAdmins = {
    "steam:IHRE-ECHTE-STEAM-ID",
}
```

**Schritt 4: NIEMALS committen!**
```bash
# Überprüfen Sie, dass config.lua NICHT committed wird:
git status

# Sollte NICHT "config/config.lua" zeigen!
# Wenn doch: .gitignore ist fehlerhaft!
```

## 🚨 Falls Lizenz kompromittiert

**Wenn Sie versehentlich Ihre Lizenz veröffentlicht haben:**

1. **Sofort GitHub History bereinigen**
   ```bash
   git filter-branch --force --index-filter \
   'git rm --cached --ignore-unmatch config/config.lua' \
   --prune-empty --tag-name-filter cat -- --all
   
   git push origin --force --all
   ```

2. **Neue Lizenz anfordern**
   - Kontaktieren Sie den Entwickler
   - Alte Lizenz wird ungültig gemacht
   - Neue Lizenz wird ausgestellt

3. **Überprüfen Sie .gitignore**
   - Stellen Sie sicher, dass `config/config.lua` in `.gitignore` ist

## ✅ Best Practices

### DO ✅

- ✅ Verwenden Sie `config/config.example.lua` für GitHub
- ✅ Fügen Sie `config/config.lua` zu `.gitignore` hinzu
- ✅ Speichern Sie Lizenz nur auf Ihrem Server
- ✅ Verwenden Sie Steam IDs (sicherste Option)
- ✅ Dokumentieren Sie ohne echte Daten

### DON'T ❌

- ❌ Lizenz-Keys auf GitHub
- ❌ Echte Steam/Discord IDs in Beispielen
- ❌ config/config.lua committen
- ❌ Lizenz in Commit-Messages
- ❌ Screenshots mit Lizenz-Daten
- ❌ Lizenz in Issue-Beschreibungen

## 📋 Checkliste vor GitHub Push

Bevor Sie Code auf GitHub pushen:

- [ ] Keine echte Lizenz im Code?
- [ ] Keine echten Steam/Discord IDs?
- [ ] config/config.lua in .gitignore?
- [ ] Nur config.example.lua wird committed?
- [ ] Keine sensiblen Daten in Commit-Messages?
- [ ] git status prüfen

## 🔐 Empfohlene Sicherheitsstufen

### Stufe 1: Basis (Minimum)
- Lizenz in config/config.lua
- config/config.lua in .gitignore
- Nur config.example.lua auf GitHub

### Stufe 2: Erweitert (Empfohlen)
- Stufe 1 +
- Lizenz in separater Datei (z.B. `license.key`)
- license.key in .gitignore
- Umgebungsvariablen für Lizenz

### Stufe 3: Maximal (Hochsicher)
- Stufe 2 +
- Verschlüsselte Lizenz-Datei
- Lizenz-Server-Validierung
- 2FA für Repository-Zugriff

## 📞 Support

Bei Sicherheitsfragen oder kompromittierten Lizenzen:
- GitHub Issues: https://github.com/MTJ2024/Haus-Manager/issues
- **PRIVAT** kontaktieren (NICHT öffentlich!)

---

**Denken Sie daran: Einmal auf GitHub = für immer im Internet!**

Selbst gelöschte Commits bleiben in der Git-History. Schützen Sie Ihre Lizenz!
