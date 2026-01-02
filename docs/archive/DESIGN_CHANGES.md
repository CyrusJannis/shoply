# Design-Änderungen - Home und Listen Screens

## Übersicht
Die Home- und Listen-Screens wurden komplett neu gestaltet, um ein moderneres, benutzerfreundlicheres Design zu bieten. Die Änderungen folgen den bereitgestellten Spezifikationen und Referenzbildern.

## Durchgeführte Änderungen

### 1. Navigation Bar - 5 Items
**Erweitert von 4 auf 5 Items:**
- Home
- Listen
- Rezepte
- **Angebote** (neu hinzugefügt)
- Profil

**Neue Dateien:**
- `lib/presentation/screens/offers/offers_screen.dart` - Neuer Angebote Screen
- `lib/routes/app_router.dart` - Route für `/offers` hinzugefügt

### 2. Home Screen - Komplette Neugestaltung

**Datei:** `lib/presentation/screens/home/home_screen.dart`

#### Header Bereich:
- **Links:** "Hello, [Username]" in fetter Schrift (h2, Bold 700)
- **Darunter:** "Willkommen zu ShoplyAI" in kleinerer Schrift und grauer Farbe
- **Rechts:** Rundes Profilbild-Icon (48x48px), klickbar, navigiert zu `/profile`

#### Listen Sektion:
- **Header:** "Deine Listen" (links) mit "+ Neue Liste" Button (rechts)
- **Listen-Cards:** 
  - Horizontal scrollbar
  - Quadratische, abgerundete Cards (120x140px)
  - **Neon grün (#CCFF00)** als Platzhalter-Hintergrund
  - Zeigt Listenname und Anzahl Items
  - Tappen öffnet die Liste
  - Sanfte Schatten für Tiefe

#### Einkaufshistorie Widget:
- Abgerundete Card mit Schatten
- Header: "Einkaufshistorie" mit "See all" Button rechts
- Inhalt: "Sie waren noch nicht einkaufen" (wenn keine Historie vorhanden)
- Klickbar, navigiert zur Shopping History Screen

### 3. Listen Screen - Mit Hintergrundbild

**Datei:** `lib/presentation/screens/lists/lists_screen.dart`

#### Hintergrundbild:
- Vollbild-Hintergrundbild: `assets/images/app_background.jpg`
- Fallback: Gradient wenn Bild nicht vorhanden
- Obere 120px zeigen das Hintergrundbild

#### Content Overlay:
- Container mit abgerundeten oberen Ecken (32px Radius)
- Beginnt nach 120px, überlagert das Hintergrundbild
- Weißer/Heller Hintergrund für Hauptinhalt
- Sanfte Schatten für Tiefeneffekt

#### Header:
- **Links:** "Meine Listen" (h2, Bold 700)
- **Rechts:** 
  - "Join List" Icon-Button (group_add)
  - "Sort" Icon-Button (sort)
  - Beide mit abgerundeten Hintergrund (12px Radius)

#### Floating Action Button:
- Position: Oben rechts (über dem Hintergrundbild)
- Runder Plus-Button zum Erstellen neuer Listen

#### Listen Layout:
- **Vertikal scrollend** (nicht horizontal)
- Jede Liste als Card mit:
  - **Leicht grüner Hintergrund** (#E8F5E9)
  - Abgerundete Ecken (24px)
  - Icon links (56x56px Container mit gelbem Hintergrund)
  - Listenname und Item-Count
  - Chevron-Icon rechts
  - Sanfte Schatten
  - Ähnlicher Stil wie Tour-Cards aus Referenzbild

#### Funktionen:
- Sort-Menu als Bottom Sheet
- Join List Dialog
- Create List Dialog
- Pull-to-refresh

## Design-Spezifikationen

### Farben:
- **Neon Grün für Listen-Cards:** #CCFF00
- **Leichter grüner Tint für Listen:** #E8F5E9
- **Primärakzent:** #FFC107 (Gelb)
- **Sekundärtext:** #8E8E93 (Grau)
- **Hintergrund:** #F8F9FA (Off-White)

### Border Radius:
- Cards: 24px
- Buttons: 16px
- Bottom Sheet: 32px
- Icon Buttons: 12px
- Floating Action Button: 16px

### Schatten:
- Sanfte Schatten: `BoxShadow(color: Colors.black.withOpacity(0.05-0.1), blurRadius: 8-10)`
- Bottom Navigation: `BoxShadow(blurRadius: 20, offset: Offset(0, -2))`

### Abstände:
- Screen Padding: 24px horizontal, 16px vertikal
- Card Padding: 20px
- Spacing zwischen Elementen: 16-24px
- Liste Card Margin: 16px unten

### Typografie:
- **H2 (Überschriften):** 28px, Semibold (600) oder Bold (700)
- **H3 (Sektionen):** 22px, Semibold (600)
- **H4 (Listen-Titel):** 20px, Semibold (600)
- **Body Medium:** 15px, Regular (400)
- **Body Small:** 13px, Regular (400)
- **Label:** 15px, Medium (500)

## Dateistruktur

```
lib/
├── presentation/
│   └── screens/
│       ├── home/
│       │   └── home_screen.dart (komplett neu gestaltet)
│       ├── lists/
│       │   ├── lists_screen.dart (komplett neu gestaltet)
│       │   ├── lists_screen_old.dart (Backup der alten Version)
│       │   └── list_detail_screen.dart (unverändert)
│       ├── offers/
│       │   └── offers_screen.dart (neu erstellt)
│       └── main_scaffold.dart (5 Navigation Items)
└── routes/
    └── app_router.dart (Offers Route hinzugefügt)
```

## Assets Benötigt

**Wichtig:** Das Hintergrundbild muss hinzugefügt werden:
```
assets/images/app_background.jpg
```

Falls das Bild nicht vorhanden ist, wird ein Gradient als Fallback verwendet.

## Testen

1. **Home Screen:**
   - Überprüfe Begrüßung mit Benutzername
   - Teste Profilbild-Icon Navigation
   - Scrolle horizontal durch Listen
   - Klicke auf "See all" in Einkaufshistorie

2. **Listen Screen:**
   - Überprüfe Hintergrundbild-Darstellung
   - Teste Floating Action Button (oben rechts)
   - Scrolle vertikal durch Listen
   - Teste Sort-Funktion
   - Teste Join List Dialog

3. **Navigation Bar:**
   - Navigiere zu allen 5 Screens
   - Überprüfe Icon-Animationen
   - Teste Blur-Effekt

## Bekannte Einschränkungen

- Hintergrundbild muss manuell zu `assets/images/` hinzugefügt werden
- Shopping History zeigt momentan nur Platzhalter-Text
- Listen-Cards verwenden Neon-Grün als Platzhalter (können später durch Bilder ersetzt werden)

## Zusammenfassung

✅ 5-Item Navigation Bar implementiert
✅ Home Screen mit Begrüßung, Profilbild und horizontalen Listen-Cards
✅ Listen Screen mit Hintergrundbild und vertikalem Layout
✅ Moderne, abgerundete Designelemente
✅ Sanfte Schatten und Blur-Effekte
✅ Konsistente Farbpalette und Typografie
✅ Responsive und benutzerfreundlich
