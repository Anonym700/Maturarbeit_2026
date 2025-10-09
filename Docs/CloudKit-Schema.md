# CloudKit Schema Documentation

## 📋 Record Types

Deine App verwendet folgende CloudKit Record Types in der **Private Database** in der **Custom Zone "MainZone"**:

### 1️⃣ Chore Record Type

**Record Type Name:** `Chore`

| Feld | Typ | Erforderlich | Beschreibung |
|------|-----|--------------|--------------|
| `title` | String | ✅ Ja | Titel der Aufgabe |
| `assignedTo` | String | ❌ Nein | UUID des zugewiesenen FamilyMembers (als String) |
| `dueDate` | Date/Time | ❌ Nein | Fälligkeitsdatum |
| `isDone` | Int64 | ✅ Ja | Status (0 = nicht erledigt, 1 = erledigt) |
| `recurrence` | String | ✅ Ja | Wiederholungstyp: "once", "daily", "weekly" |
| `createdAt` | Date/Time | ✅ Ja | Erstellungsdatum |
| `deadline` | Date/Time | ❌ Nein | Countdown-Deadline |

**RecordName:** Die UUID der Chore als String

---

### 2️⃣ FamilyMember Record Type

**Record Type Name:** `FamilyMember`

| Feld | Typ | Erforderlich | Beschreibung |
|------|-----|--------------|--------------|
| `name` | String | ✅ Ja | Name des Familienmitglieds |
| `role` | String | ✅ Ja | Rolle: "parent" oder "child" |

**RecordName:** Die UUID des FamilyMembers als String

---

## 🔧 Manuelle CloudKit Setup-Schritte

### Schritt 1: CloudKit Capabilities in Xcode aktivieren

1. Öffne `Maturarbeit.xcodeproj` in Xcode
2. Wähle das Target **"Maturarbeit"**
3. Gehe zu **"Signing & Capabilities"**
4. Klicke auf **"+ Capability"** und füge hinzu:
   - ✅ **iCloud**
     - Aktiviere **CloudKit**
     - Container: `iCloud.com.christosalexisfantino.MaturarbeitApp`
   - ✅ **Push Notifications** (für CloudKit Subscriptions)
   - ✅ **Background Modes** (optional)
     - Aktiviere **"Remote notifications"**

### Schritt 2: CloudKit Dashboard (Optional)

Die Record Types werden **automatisch erstellt**, wenn du die erste Aufgabe/FamilyMember speicherst!

Falls du trotzdem ins Dashboard möchtest:
1. Gehe zu [CloudKit Dashboard](https://icloud.developer.apple.com/dashboard)
2. Wähle Container: `iCloud.com.christosalexisfantino.MaturarbeitApp`
3. Wähle **"Development"** Environment
4. Unter **"Schema"** kannst du die Record Types sehen (nach dem ersten Speichern)

### Schritt 3: Testen

1. **Wichtig:** Teste auf einem **echten Gerät**, nicht im Simulator
2. Stelle sicher, dass du mit einer **Apple ID** angemeldet bist
3. Die App erstellt beim ersten Start automatisch:
   - Custom Zone "MainZone"
   - 3 Default FamilyMembers (Parent 1, Anna, Max)

---

## 🔄 Default FamilyMembers (Fixed UUIDs)

Die App verwendet **fixe UUIDs** für die Standard-Familienmitglieder:

| Name | Role | UUID |
|------|------|------|
| Parent 1 | parent | `00000000-0000-0000-0000-000000000001` |
| Anna | child | `00000000-0000-0000-0000-000000000002` |
| Max | child | `00000000-0000-0000-0000-000000000003` |

Diese werden beim ersten App-Start in CloudKit gespeichert und bei jedem weiteren Start geladen.

---

## ⚙️ Wie es funktioniert

1. **App-Start:**
   - Lade FamilyMembers aus CloudKit
   - Wenn keine existieren → Erstelle Default-Members und speichere sie in CloudKit

2. **Chores erstellen:**
   - Speichere mit `assignedTo` = UUID des FamilyMembers
   - Die UUID bleibt konsistent über App-Starts hinweg

3. **Synchronisation:**
   - Optimistische UI-Updates für sofortige Reaktion
   - Verify-and-Refresh Logik für zuverlässige CloudKit-Sync

---

## 🚨 Troubleshooting

### Problem: "No members found"
- **Lösung:** Lösche die App und installiere neu → Default-Members werden erstellt

### Problem: "Assignments lost"
- **Lösung:** Dies sollte nicht mehr passieren, da FamilyMembers jetzt in CloudKit gespeichert werden

### Problem: "CloudKit errors"
- Prüfe iCloud-Anmeldung auf dem Gerät
- Prüfe Internetverbindung
- Prüfe Xcode Capabilities (siehe oben)

---

## 📝 Notizen für die Entwicklung

- **Keine manuellen Schema-Änderungen nötig** - CloudKit erstellt die Record Types automatisch
- **Testing:** Immer auf echten Geräten testen, Simulator ist instabil
- **Development vs. Production:** Denk daran, das Schema später nach Production zu promoten

