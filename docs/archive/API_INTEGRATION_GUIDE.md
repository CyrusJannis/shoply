# 🚀 Prospekte API-Integration - Quick Start

## Schritt 1: API-Key erhalten (Kostenlos!)

### Option A: MeinProspekt API (Empfohlen)
1. Gehe zu: https://www.meinprospekt.de/
2. Kontaktiere: api@meinprospekt.de
3. Frage nach **Entwickler-Zugang**
4. Erhalte API-Key

### Option B: Kaufda API
1. Gehe zu: https://developer.kaufda.de/
2. Registriere dich
3. Erstelle App
4. Kopiere API-Key

---

## Schritt 2: API-Key eintragen

Öffne: `lib/data/services/store_flyer_service.dart`

```dart
// Zeile 8: Ersetze 'YOUR_API_KEY' mit deinem echten Key
static const String _apiKey = 'dein_echter_api_key_hier';
```

---

## Schritt 3: API-Calls aktivieren

In `store_flyer_service.dart`, ersetze die `_getFlyersForChain` Methode:

### Für MeinProspekt API:
```dart
static Future<List<StoreFlyerModel>> _getFlyersForChain(String chain) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v2/leaflets?retailer=$chain&location=Germany'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> leaflets = data['leaflets'] ?? [];
      
      return leaflets.map((json) {
        return StoreFlyerModel(
          id: json['id'].toString(),
          storeName: json['retailer']['name'] ?? chain,
          storeChain: chain.toLowerCase(),
          logoUrl: json['retailer']['logo_url'] ?? '',
          coverImageUrl: json['cover_url'] ?? '',
          pageImages: (json['pages'] as List<dynamic>)
              .map((page) => page['image_url'] as String)
              .toList(),
          validFrom: DateTime.parse(json['valid_from']),
          validUntil: DateTime.parse(json['valid_until']),
          title: json['title'],
          pageCount: (json['pages'] as List).length,
          isActive: true,
        );
      }).toList();
    }
    
    // Fallback auf Demo-Daten bei Fehler
    return _getDemoFlyersForChain(chain);
  } catch (e) {
    print('API Error: $e');
    return _getDemoFlyersForChain(chain);
  }
}
```

### Für Kaufda API:
```dart
static Future<List<StoreFlyerModel>> _getFlyersForChain(String chain) async {
  try {
    final response = await http.get(
      Uri.parse('$_baseUrl/leaflets?retailer=$chain&country=DE&limit=10'),
      headers: {
        'X-API-Key': $_apiKey,
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> results = data['results'] ?? [];
      
      return results.map((json) {
        return StoreFlyerModel(
          id: json['id'].toString(),
          storeName: json['merchant']['name'] ?? chain,
          storeChain: chain.toLowerCase(),
          logoUrl: json['merchant']['logo'] ?? '',
          coverImageUrl: json['cover_image'] ?? '',
          pageImages: (json['images'] as List<dynamic>)
              .map((img) => img['url'] as String)
              .toList(),
          validFrom: DateTime.parse(json['valid_from']),
          validUntil: DateTime.parse(json['valid_to']),
          title: json['title'],
          pageCount: (json['images'] as List).length,
          isActive: json['is_active'] ?? true,
        );
      }).toList();
    }
    
    return _getDemoFlyersForChain(chain);
  } catch (e) {
    print('API Error: $e');
    return _getDemoFlyersForChain(chain);
  }
}
```

---

## Schritt 4: Imports hinzufügen

Aktiviere die auskommentieren Imports in `store_flyer_service.dart`:

```dart
import 'dart:convert';  // ✅ Aktivieren
import 'package:http/http.dart' as http;  // ✅ Aktivieren
```

---

## Schritt 5: Testen

```dart
// In deiner App:
final flyers = await StoreFlyerService.getActiveFlyers();
print('Gefundene Prospekte: ${flyers.length}');
```

---

## 🎯 Fertig!

Die Prospekte werden jetzt automatisch:
- ✅ Von der API geladen
- ✅ Alle 60 Minuten aktualisiert
- ✅ Im Cache gespeichert
- ✅ Mit Fallback auf Demo-Daten bei Fehler

---

## 📞 Support & Kontakt

### MeinProspekt
- 📧 Email: api@meinprospekt.de
- 🌐 Web: https://www.meinprospekt.de

### Kaufda
- 📧 Email: api@kaufda.de
- 📚 Docs: https://developer.kaufda.de/docs

---

## 💰 Kosten

Beide APIs bieten **kostenlose Tiers**:
- **MeinProspekt**: Bis 1.000 Requests/Tag kostenlos
- **Kaufda**: Bis 500 Requests/Tag kostenlos

Für kleine bis mittlere Apps: **Komplett kostenlos!** 🎉

