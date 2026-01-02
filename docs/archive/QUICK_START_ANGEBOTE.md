# 🎯 QUICK START - Angebots-Scanner Feature

## ⚡ 3 Schritte zur Verwendung

### 1️⃣ Scanner-Screen zu deiner App hinzufügen

```dart
// In deinem Navigation (z.B. Settings oder Main Menu)
import 'package:shoply/presentation/screens/scanner/brochure_scanner_page.dart';

// Button/Tile hinzufügen:
ListTile(
  leading: Icon(Icons.document_scanner),
  title: Text('Prospekt Scanner'),
  subtitle: Text('PDF-Prospekte scannen für Angebote'),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BrochureScannerPage(),
      ),
    );
  },
)
```

### 2️⃣ Deal-Badge in Einkaufsliste anzeigen

```dart
// In deinem ShoppingList ListView.builder:
import 'package:shoply/data/services/product_matching_service.dart';
import 'package:shoply/presentation/widgets/deals/deal_badge.dart';

// Im FutureBuilder für ein Item:
FutureBuilder<ExtractedDeal?>(
  future: ProductMatchingService.findBestDealForProduct(item.name),
  builder: (context, snapshot) {
    if (snapshot.hasData && snapshot.data != null) {
      return ListTile(
        title: Text(item.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DealBadge(
              deal: snapshot.data!,
              compact: true, // Zeigt: 🏷️ -25%
            ),
            // ... deine anderen trailing widgets
          ],
        ),
        // Optional: onTap um alle Deals zu zeigen
        onTap: () async {
          final deals = await ProductMatchingService.findDealsForProduct(item.name);
          DealsList.show(
            context,
            productName: item.name,
            deals: deals,
          );
        },
      );
    }
    return ListTile(title: Text(item.name));
  },
)
```

### 3️⃣ AI Recommendations mit Angeboten

```dart
// In deinem Recommendations Widget:
import 'package:shoply/data/services/product_matching_service.dart';

FutureBuilder<Map<String, ExtractedDeal>>(
  future: () async {
    // Hole deine häufig gekauften Produkte
    final frequentProducts = await _getFrequentlyBoughtProducts();
    
    // Finde beste Deals
    return await ProductMatchingService.findBestDealsForShoppingList(
      frequentProducts.map((p) => p.name).toList(),
    );
  }(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return CircularProgressIndicator();
    
    final dealsMap = snapshot.data!;
    
    return ListView(
      children: dealsMap.entries.map((entry) {
        final productName = entry.key;
        final deal = entry.value;
        
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red,
              child: Text(
                deal.formattedDiscount,
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            title: Text(productName),
            subtitle: Text(
              '${deal.formattedOriginalPrice} → ${deal.formattedDiscountedPrice} @ ${deal.supermarket}',
            ),
            trailing: Icon(Icons.add_shopping_cart),
            onTap: () {
              // Füge zur Einkaufsliste hinzu
            },
          ),
        );
      }).toList(),
    );
  },
)
```

---

## 🧪 Testen

### 1. Scanner testen
1. Öffne Scanner-Screen
2. Wähle Supermarkt (z.B. "REWE")
3. Wähle ein PDF-Prospekt (z.B. von rewe.de/prospekte heruntergeladen)
4. Warte bis Scan abgeschlossen ist
5. Sieh gefundene Angebote

### 2. Matching testen
```dart
// Im Terminal/Debug Console
final deals = await ProductMatchingService.findDealsForProduct('Milch');
print('Gefunden: ${deals.length} Angebote für Milch');
```

### 3. Statistiken prüfen
```dart
final stats = await DealsDatabaseService.getStatistics();
print('Aktive Angebote: ${stats['totalActiveDeals']}');
```

---

## 🎨 UI-Anpassungen

### Deal-Badge Farben ändern
```dart
// In deal_badge.dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.purple[600]!, Colors.blue[600]!], // Deine Farben
    ),
  ),
)
```

### Compact vs. Full Badge
```dart
// Kompakt (nur Prozent)
DealBadge(deal: myDeal, compact: true)

// Vollständig (Preise + Supermarkt)
DealBadge(deal: myDeal, compact: false)
```

---

## 🛠️ Erweiterte Features

### Batch-Processing für ganze Liste
```dart
Future<void> checkAllItemsForDeals(List<ShoppingItemModel> items) async {
  final productNames = items.map((item) => item.name).toList();
  
  final dealsMap = await ProductMatchingService.findBestDealsForShoppingList(
    productNames,
  );
  
  // Zeige Notification
  final totalSavings = ProductMatchingService.calculateTotalSavings(dealsMap);
  print('💰 Du kannst ${totalSavings.toStringAsFixed(2)}€ sparen!');
}
```

### Automatische Cleanup
```dart
// In main.dart
void main() async {
  // ... deine Initialisierung
  
  // Täglich abgelaufene Angebote löschen
  Timer.periodic(Duration(days: 1), (_) async {
    await DealsDatabaseService.deleteExpiredDeals();
  });
  
  runApp(MyApp());
}
```

---

## 📱 Erste Verwendung

Beim ersten Start:
1. **Sprachdaten werden automatisch heruntergeladen** (~10MB für Deutsch + Englisch)
2. Das dauert beim ersten Mal ~30 Sekunden
3. Danach ist OCR sofort verfügbar

---

## 💡 Tipps

- **PDF-Qualität**: Je höher die Auflösung, desto besser die OCR-Ergebnisse
- **Prospekt-Quellen**: 
  - rewe.de/prospekte
  - lidl.de/prospekte
  - aldi-sued.de/de/angebote/aktuelle-woche.html
- **Matching-Genauigkeit**: Senke `minSimilarity` von 0.6 auf 0.5 für mehr Treffer
- **Performance**: Nutze `FutureBuilder` mit `AutomaticKeepAliveClientMixin` für gecachte Results

---

## 🚀 Das war's!

Du hast jetzt:
- ✅ PDF-Scanner für Prospekte
- ✅ Automatische Angebots-Extraktion
- ✅ Smart Product Matching
- ✅ Deal-Badges in deiner UI
- ✅ AI Recommendations mit Angeboten

**Viel Erfolg! 🎉**

Bei Fragen: Siehe `ANGEBOTS_SCANNER_COMPLETE.md` für detaillierte Dokumentation.
