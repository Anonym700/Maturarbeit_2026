# iCloud-basiertes Authentifizierungs- und Berechtigungssystem

## 🎯 Übersicht

Die App verwendet jetzt ein automatisches Authentifizierungssystem basierend auf iCloud-Accounts. Jeder Benutzer wird automatisch anhand seines angemeldeten iCloud-Accounts erkannt, und Berechtigungen werden basierend auf der zugewiesenen Rolle (Parent/Child) vergeben.

## 🔑 Hauptfunktionen

### 1. Automatische Benutzer-Erkennung
- Die App erkennt automatisch den angemeldeten iCloud-Account
- Keine manuelle Benutzerwahl mehr notwendig
- Jeder iCloud-Account wird einem FamilyMember-Profil zugeordnet

### 2. Rollenbasierte Berechtigungen

#### **Parent-Berechtigungen:**
- ✅ Tasks erstellen
- ✅ Tasks bearbeiten
- ✅ Tasks löschen
- ✅ Alle Tasks sehen und abarbeiten
- ✅ Familienmitglieder verwalten

#### **Child-Berechtigungen:**
- ✅ Nur zugewiesene Tasks sehen
- ✅ Nur eigene Tasks abarbeiten
- ❌ Keine Tasks erstellen/bearbeiten/löschen
- ❌ Keine Familienmitglieder verwalten

### 3. Registrierungsprozess

Wenn ein Benutzer sich das erste Mal anmeldet, muss er seinen iCloud-Account mit einem FamilyMember-Profil verknüpfen:

**Option 1: Mit bestehendem Profil verknüpfen**
- Zeigt alle FamilyMember an, die noch nicht mit einem iCloud-Account verknüpft sind
- Benutzer wählt sein Profil aus
- iCloud-Account wird automatisch verknüpft

**Option 2: Neues Profil erstellen**
- Benutzer gibt Namen ein
- Wählt Rolle (Parent/Child)
- Neues FamilyMember wird erstellt und automatisch mit iCloud-Account verknüpft

## 🏗️ Technische Implementierung

### CloudKit-Schema Änderungen

**FamilyMember Record Type** wurde erweitert:
```
- name: String (erforderlich)
- role: String (erforderlich) // "parent" oder "child"
- iCloudUserID: String (optional) // NEU: CloudKit User Record ID
```

### Neue Komponenten

#### 1. CloudKitManager
```swift
// Neue Methode zum Abrufen der iCloud User ID
func fetchCurrentUserRecordID() async throws -> CKRecord.ID
```

#### 2. AppState
```swift
// Neue Properties
@Published var currentICloudUserID: String?
@Published var isUserRegistered: Bool

// Neue Permissions
var canCreateChores: Bool
var canEditChores: Bool
var canDeleteChores: Bool
var canManageFamilyMembers: Bool
func canCompleteChore(_ chore: Chore) -> Bool

// Neue Methoden
func linkCurrentUserToMember(_ member: FamilyMember) async
func addFamilyMember(name: String, role: FamilyRole, linkToCurrentUser: Bool = false) async
```

#### 3. FamilyView
- Zeigt aktuellen iCloud-Account Status
- Registrierungsbereich für nicht-registrierte Benutzer
- Zwei Optionen: Verknüpfen oder Neu erstellen
- Nur Parents können neue Mitglieder hinzufügen

#### 4. ChoresView
- Zeigt Registrierungsaufforderung für nicht-registrierte Benutzer
- Children sehen nur ihre zugewiesenen Tasks
- Parents sehen alle Tasks
- Berechtigungen werden durchgehend geprüft

## 🔄 Benutzer-Flow

### Erster Start (Neuer Benutzer)

1. App startet → CloudKit erkennt iCloud-Account
2. Kein verknüpftes FamilyMember gefunden
3. Benutzer wird zur Family-Tab geleitet
4. Registrierungsoptionen werden angezeigt:
   - **Link zu bestehendem Profil** (falls verfügbar)
   - **Neues Profil erstellen**
5. Nach Verknüpfung → Automatische Anmeldung
6. Berechtigungen basierend auf Rolle werden aktiviert

### Normaler Start (Registrierter Benutzer)

1. App startet → CloudKit erkennt iCloud-Account
2. FamilyMember wird anhand der iCloudUserID gefunden
3. Automatische Anmeldung
4. UI passt sich an Berechtigungen an

### Familie teilen

1. **Parent erstellt FamilyMember-Profile** für alle Familienmitglieder
   - Gibt Namen ein
   - Wählt Rolle (Parent/Child)
   - OHNE iCloud-Verknüpfung (leer lassen)

2. **Jedes Familienmitglied meldet sich mit eigenem iCloud-Account an**
   - Installiert die App auf eigenem Gerät
   - Meldet sich mit eigener Apple ID an
   - Wählt sein Profil aus der Liste
   - iCloud-Account wird verknüpft

3. **CloudKit synchronisiert alles automatisch**
   - Alle Geräte sehen die gleichen Tasks
   - Jeder Benutzer hat seine eigenen Berechtigungen
   - Änderungen werden in Echtzeit synchronisiert

## 🛡️ Sicherheit

- **Keine Account-Wechsel möglich**: Benutzer sind an ihren iCloud-Account gebunden
- **Rollenbasierte Zugriffskontrolle**: Berechtigungen werden serverseitig geprüft
- **Automatische Validierung**: App prüft Berechtigungen bei jeder Aktion

## 🧪 Testing

### Auf mehreren Geräten testen:

1. **Gerät 1 (Parent)**
   - Mit Parent-Apple-ID anmelden
   - Neues Parent-Profil erstellen oder verknüpfen
   - Tasks erstellen

2. **Gerät 2 (Child)**
   - Mit Child-Apple-ID anmelden
   - Child-Profil verknüpfen
   - Nur zugewiesene Tasks sehen
   - Tasks können nur abgearbeitet werden

### Wichtige Test-Szenarien:

- ✅ Parent kann Tasks erstellen/bearbeiten/löschen
- ✅ Child sieht nur eigene Tasks
- ✅ Child kann nur eigene Tasks abarbeiten
- ✅ Child kann keine Tasks erstellen
- ✅ Nicht-registrierte Benutzer sehen Registrierungsaufforderung
- ✅ Synchronisation zwischen Geräten funktioniert

## 📝 Migration von bestehendem Setup

Wenn du bereits FamilyMembers ohne iCloudUserID hast:

1. Alle bestehenden FamilyMembers bleiben erhalten
2. Beim ersten Start wird der iCloud-Account erkannt
3. Benutzer wählt sein bestehendes Profil aus
4. iCloudUserID wird hinzugefügt
5. Ab jetzt automatische Anmeldung

## 🔧 Troubleshooting

### "Account Not Linked" wird angezeigt
- **Lösung**: Gehe zur Family-Tab und verknüpfe deinen Account

### Keine FamilyMembers zum Verknüpfen verfügbar
- **Lösung**: Erstelle ein neues Profil (oder ein Parent muss erst Profile erstellen)

### Berechtigungen funktionieren nicht
- **Lösung**: Prüfe, ob iCloudUserID korrekt gespeichert wurde
- Lösche App und installiere neu für frischen Start

### Tasks werden nicht angezeigt
- **Child-Benutzer**: Prüfe, ob Tasks dir zugewiesen sind
- **Parent-Benutzer**: Prüfe CloudKit-Verbindung

## 🚀 Vorteile des neuen Systems

1. **Keine versehentlichen Account-Wechsel**: Jedes Gerät ist fix einem Benutzer zugeordnet
2. **Bessere Sicherheit**: Kinder können nicht einfach zum Parent-Account wechseln
3. **Einfachere Verwaltung**: Automatische Erkennung, kein manuelles Switchen
4. **Echte Multi-User Unterstützung**: Jedes Familienmitglied hat sein eigenes Gerät mit eigener Apple ID
5. **CloudKit-native**: Nutzt iCloud-Infrastruktur optimal aus

