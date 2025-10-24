# iOS Widget Setup Guide

## Übersicht
Die App hat jetzt iOS Widgets! Benutzer können ihre Einkaufsliste direkt auf dem Home Screen sehen.

## Widget Features

### 📱 Drei Größen:
1. **Small Widget** (2×2)
   - Zeigt die ersten 3 Artikel
   - Kompakte Ansicht
   
2. **Medium Widget** (4×2)
   - Zeigt die ersten 5 Artikel
   - Mit Mengenangabe
   - Fortschrittsanzeige
   
3. **Large Widget** (4×4)
   - Zeigt bis zu 8 Artikel
   - "To Buy" und "Completed" Sektionen
   - Vollständige Übersicht

## Setup in Xcode

### Schritt 1: Widget Extension hinzufügen

1. Öffne `ios/Runner.xcworkspace` in Xcode
2. **File** → **New** → **Target**
3. Wähle **Widget Extension**
4. Name: `ShoppingListWidget`
5. Bundle ID: `com.shoply.app.ShoppingListWidget`
6. ✅ **Include Configuration Intent** (für spätere Anpassungen)
7. Klicke **Finish**

### Schritt 2: Dateien ersetzen

1. Lösche die automatisch erstellte `ShoppingListWidget.swift`
2. Füge die vorhandene `ios/ShoppingListWidget/ShoppingListWidget.swift` hinzu
3. Ersetze `Info.plist` mit `ios/ShoppingListWidget/Info.plist`

### Schritt 3: App Group einrichten

**Wichtig:** App und Widget müssen Daten teilen!

1. **Runner Target** auswählen
2. **Signing & Capabilities** → **+ Capability**
3. **App Groups** hinzufügen
4. App Group erstellen: `group.com.shoply.app`

5. **ShoppingListWidget Target** auswählen
6. Gleiche App Group hinzufügen: `group.com.shoply.app`

### Schritt 4: Build Settings

**ShoppingListWidget Target:**
- **iOS Deployment Target**: 14.0 oder höher
- **Swift Language Version**: Swift 5

### Schritt 5: Assets hinzufügen (Optional)

Für ein schöneres Widget-Icon:
1. Füge `WidgetIcon.png` zu Assets hinzu
2. Verwende im Widget: `Image("WidgetIcon")`

## Verwendung im Code

### Widget aktualisieren

```dart
import 'package:shoply/data/services/widget_service.dart';

// Wenn sich die Liste ändert
await WidgetService.updateWidget(
  listName: 'Weekly Shopping',
  items: [
    WidgetItem(
      id: '1',
      name: 'Milk',
      quantity: 2,
      isChecked: false,
    ),
    WidgetItem(
      id: '2',
      name: 'Bread',
      quantity: 1,
      isChecked: false,
    ),
  ],
);
```

### Widget löschen

```dart
await WidgetService.clearWidget();
```

## Integration in die App

### 1. In ListDetailScreen

Füge hinzu, wenn Items sich ändern:

```dart
// Nach dem Hinzufügen/Entfernen/Abhaken eines Items
_updateWidget();

void _updateWidget() async {
  final items = _currentList.items.map((item) => WidgetItem(
    id: item.id,
    name: item.name,
    quantity: item.quantity,
    isChecked: item.isChecked,
  )).toList();
  
  await WidgetService.updateWidget(
    listName: _currentList.name,
    items: items,
  );
}
```

### 2. In ListsScreen

Wenn der Benutzer eine Liste auswählt:

```dart
void _selectList(ShoppingList list) {
  // Liste auswählen
  _selectedList = list;
  
  // Widget aktualisieren
  _updateWidget(list);
}
```

## Widget-Konfiguration (Zukünftig)

Für erweiterte Features:
- Benutzer kann wählen, welche Liste im Widget angezeigt wird
- Verschiedene Themes/Farben
- Tap-Actions (öffnet die App zur Liste)

### Intent Configuration

```swift
struct SelectListIntent: INIntent {
    @Parameter(title: "Shopping List")
    var list: ListEntity?
}
```

## Testen

### Im Simulator:
1. App starten
2. Liste mit Items erstellen
3. Home Button drücken
4. Widget hinzufügen:
   - Lange auf Home Screen drücken
   - **+** Button oben links
   - "Shoply" suchen
   - Widget-Größe wählen
   - **Add Widget**

### Auf echtem Gerät:
- Gleicher Prozess wie Simulator
- Widget aktualisiert sich automatisch alle 15 Minuten
- Oder sofort, wenn die App Daten ändert

## Troubleshooting

### Widget zeigt keine Daten

1. **App Group prüfen:**
   ```swift
   // In beiden Targets muss die gleiche App Group sein:
   group.com.shoply.app
   ```

2. **Signing prüfen:**
   - Beide Targets müssen signiert sein
   - Gleiche Team ID

3. **iOS Version:**
   - Widgets benötigen iOS 14.0+

### Widget aktualisiert sich nicht

```dart
// Force reload im Widget
if #available(iOS 14.0, *) {
  WidgetCenter.shared.reloadAllTimelines()
}
```

## Design Guidelines

### Apple Human Interface Guidelines:
- ✅ Klare, lesbare Schrift
- ✅ Wichtige Infos zuerst
- ✅ Konsistente Farben mit der App
- ✅ Keine interaktiven Elemente (außer Tap zum Öffnen)
- ✅ Schnelles Laden

### Unsere Design-Entscheidungen:
- **Blau** für App-Icon und Akzente
- **Grau** für nicht abgehakte Items
- **Grün** für abgehakte Items
- **SF Symbols** für Icons (Apple Standard)

## Nächste Schritte

1. ✅ Widget Extension in Xcode hinzufügen
2. ✅ App Group konfigurieren
3. ✅ Widget-Updates in ListDetailScreen integrieren
4. ⏳ Widget-Konfiguration (welche Liste anzeigen)
5. ⏳ Deep Links (Widget → App)
6. ⏳ Siri Shortcuts Integration

## Beispiel Screenshots

### Small Widget
```
┌─────────────┐
│ 🛒 Shopping │
│ ─────────── │
│ ○ Milk      │
│ ○ Bread     │
│ ○ Eggs      │
│ +2 more     │
└─────────────┘
```

### Medium Widget
```
┌─────────────────────────────┐
│ 🛒 Weekly Shopping    3/5   │
│ ───────────────────────────  │
│ ○ Milk              ×2      │
│ ○ Bread             ×1      │
│ ○ Eggs              ×12     │
│ ○ Butter            ×1      │
│ ○ Cheese            ×1      │
└─────────────────────────────┘
```

### Large Widget
```
┌─────────────────────────────┐
│ 🛒 Weekly Shopping          │
│                      2/5    │
│                   completed │
│ ───────────────────────────  │
│ TO BUY                      │
│ ○ Milk              ×2      │
│ ○ Bread             ×1      │
│ ○ Eggs              ×12     │
│                             │
│ COMPLETED                   │
│ ✓ Butter                    │
│ ✓ Cheese                    │
└─────────────────────────────┘
```

## Support

Bei Fragen oder Problemen:
- Xcode Console für Logs prüfen
- `print()` Statements in Swift hinzufügen
- Flutter DevTools für Dart-Seite

Viel Erfolg! 🎉
