# 🏷️ Angebots-Scanner Feature - Vollständige Implementierung

## ✅ Was wurde implementiert?

### 1. **OCR & PDF Scanning** (Tesseract)
- ✅ Automatischer Download deutscher + englischer Sprachdaten
- ✅ PDF zu Bild Konvertierung (300 DPI)
- ✅ Text-Extraktion mit Tesseract OCR
- ✅ Progress-Tracking während des Scans

**Files:**
- `lib/data/services/tesseract_setup.dart`
- `lib/data/services/ocr_service.dart`

### 2. **Deal Extraktion** (Smart Parsing)
- ✅ Automatische Preis-Erkennung (€, EUR, verschiedene Formate)
- ✅ Produktnamen-Extraktion mit Keyword-Matching
- ✅ Rabatt-Berechnung
- ✅ Kategorie-Erkennung (Milchprodukte, Fleisch, Getränke, etc.)
- ✅ Marken-Erkennung
- ✅ Mengenangaben-Extraktion (kg, g, L, ml)
- ✅ Duplikat-Filterung

**Files:**
- `lib/data/services/deal_extractor_service.dart`
- `lib/data/models/extracted_deal_model.dart`

### 3. **Datenbank** (SQLite)
- ✅ Deals-Tabelle mit Indizes für Performance
- ✅ Scanned PDFs Tracking (verhindert doppeltes Scannen)
- ✅ CRUD Operations für Angebote
- ✅ Filtern nach: Supermarkt, Kategorie, Produkt
- ✅ Top-Deals & Statistiken
- ✅ Automatisches Löschen abgelaufener Angebote

**Files:**
- `lib/data/services/deals_database_service.dart`

### 4. **Produkt-Matching** (Fuzzy String Matching)
- ✅ String-Similarity Algorithmus (Levenshtein)
- ✅ Keyword-basiertes Matching
- ✅ Batch-Processing für ganze Einkaufslisten
- ✅ Beste-Deal-Finder pro Produkt
- ✅ Kategorisierung von Shopping-Listen
- ✅ Verwandte Produkte finden

**Files:**
- `lib/data/services/product_matching_service.dart`
- `lib/data/models/shopping_item_with_deal.dart`

### 5. **UI Components**
- ✅ BrochureScannerPage (PDF Upload & Scan)
- ✅ Deal Badge Widget (kompakt & ausführlich)
- ✅ Deal Indicator (Orange Badge mit Count)
- ✅ Deals List Bottom Sheet
- ✅ Progress Tracking & Status Messages

**Files:**
- `lib/presentation/screens/scanner/brochure_scanner_page.dart`
- `lib/presentation/widgets/deals/deal_badge.dart`

---

## 🚀 Wie verwende ich es?

### **Schritt 1: PDF Prospekt scannen**

```dart
// Im Scanner Screen
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const BrochureScannerPage(),
  ),
);
```

1. Supermarkt auswählen (Lidl, REWE, Aldi, etc.)
2. "PDF Prospekt scannen" Button drücken
3. PDF Datei auswählen
4. Warten bis Scan abgeschlossen ist
5. Angebote werden automatisch in Datenbank gespeichert

### **Schritt 2: Angebote für Produkt anzeigen**

```dart
import 'package:shoply/data/services/product_matching_service.dart';
import 'package:shoply/presentation/widgets/deals/deal_badge.dart';

// Finde Deals für ein Produkt
final deals = await ProductMatchingService.findDealsForProduct('Milch');

// Zeige Deal Badge
if (deals.isNotEmpty) {
  DealBadge(deal: deals.first, compact: true)
}

// Oder zeige Deal Indicator mit Count
DealIndicator(
  dealCount: deals.length,
  onTap: () {
    DealsList.show(
      context,
      productName: 'Milch',
      deals: deals,
    );
  },
)
```

### **Schritt 3: Integration in Einkaufsliste**

```dart
// In deinem ShoppingList Widget
import 'package:shoply/data/models/shopping_item_with_deal.dart';

Future<List<ShoppingItemWithDeal>> _loadItemsWithDeals() async {
  final items = await _loadShoppingItems(); // Deine existierende Methode
  
  List<ShoppingItemWithDeal> itemsWithDeals = [];
  
  for (final item in items) {
    final deal = await ProductMatchingService.findBestDealForProduct(
      item.name,
      preferredSupermarket: 'REWE', // Optional
    );
    
    final dealCount = await ProductMatchingService.countDealsForProduct(item.name);
    
    itemsWithDeals.add(ShoppingItemWithDeal(
      item: item,
      activeDeal: deal,
      availableDealsCount: dealCount,
    ));
  }
  
  return itemsWithDeals;
}

// In der Liste anzeigen
ListTile(
  title: Text(itemWithDeal.item.name),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (itemWithDeal.hasActiveDeal)
        DealBadge(
          deal: itemWithDeal.activeDeal!,
          compact: true,
        ),
      // Oder
      DealIndicator(
        dealCount: itemWithDeal.availableDealsCount,
        onTap: () async {
          final deals = await ProductMatchingService.findDealsForProduct(
            itemWithDeal.item.name,
          );
          DealsList.show(
            context,
            productName: itemWithDeal.item.name,
            deals: deals,
          );
        },
      ),
    ],
  ),
)
```

### **Schritt 4: AI Recommendations mit Angeboten**

```dart
// In deinem Recommendations Service
import 'package:shoply/data/services/product_matching_service.dart';

Future<List<RecommendationWithDeal>> getRecommendationsWithDeals() async {
  // 1. Hole häufig gekaufte Produkte (deine existierende Logik)
  final frequentProducts = await _getFrequentlyBoughtProducts();
  
  // 2. Finde Angebote für diese Produkte
  final recommendations = <RecommendationWithDeal>[];
  
  for (final product in frequentProducts) {
    final deals = await ProductMatchingService.findDealsForProduct(product.name);
    
    if (deals.isNotEmpty) {
      recommendations.add(RecommendationWithDeal(
        productName: product.name,
        bestDeal: deals.first,
        allDeals: deals,
        purchaseFrequency: product.frequency,
      ));
    }
  }
  
  // Sortiere nach Ersparnis * Häufigkeit
  recommendations.sort((a, b) {
    final scoreA = a.bestDeal.savings * a.purchaseFrequency;
    final scoreB = b.bestDeal.savings * b.purchaseFrequency;
    return scoreB.compareTo(scoreA);
  });
  
  return recommendations;
}

class RecommendationWithDeal {
  final String productName;
  final ExtractedDeal bestDeal;
  final List<ExtractedDeal> allDeals;
  final int purchaseFrequency;
  
  RecommendationWithDeal({
    required this.productName,
    required this.bestDeal,
    required this.allDeals,
    required this.purchaseFrequency,
  });
  
  double get potentialSavings => bestDeal.savings * purchaseFrequency;
}
```

---

## 📊 Database Schema

```sql
CREATE TABLE deals (
  id TEXT PRIMARY KEY,
  supermarket TEXT NOT NULL,
  productName TEXT NOT NULL,
  productBrand TEXT,
  productCategory TEXT,
  originalPrice REAL NOT NULL,
  discountedPrice REAL NOT NULL,
  discountPercentage REAL NOT NULL,
  unit TEXT,
  validFrom TEXT NOT NULL,
  validUntil TEXT NOT NULL,
  imageUrl TEXT,
  scannedAt TEXT NOT NULL,
  isActive INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE scanned_pdfs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  fileName TEXT NOT NULL UNIQUE,
  supermarket TEXT NOT NULL,
  scannedAt TEXT NOT NULL,
  dealCount INTEGER NOT NULL
);

-- Indizes
CREATE INDEX idx_deals_supermarket ON deals(supermarket);
CREATE INDEX idx_deals_category ON deals(productCategory);
CREATE INDEX idx_deals_valid_until ON deals(validUntil);
CREATE INDEX idx_deals_discount ON deals(discountPercentage DESC);
```

---

## 🎨 UI Examples

### Deal Badge (Compact)
```dart
Container(
  child: DealBadge(
    deal: myDeal,
    compact: true, // Zeigt: 🏷️ -25%
  ),
)
```

### Deal Badge (Full)
```dart
Container(
  child: DealBadge(
    deal: myDeal,
    compact: false, // Zeigt: 🏷️ -25%, 2,99€ → 2,24€, @ REWE
  ),
)
```

### Deal Indicator
```dart
DealIndicator(
  dealCount: 3, // Zeigt: 🏷️ 3
  onTap: () {
    // Zeige alle Deals
  },
)
```

---

## 🔧 Maintenance & Optimierung

### **Abgelaufene Angebote löschen**
```dart
// In main.dart oder einem Background Service
Future<void> cleanupExpiredDeals() async {
  final deleted = await DealsDatabaseService.deleteExpiredDeals();
  print('$deleted abgelaufene Angebote gelöscht');
}

// Täglich ausführen
Timer.periodic(Duration(days: 1), (_) => cleanupExpiredDeals());
```

### **Statistiken abrufen**
```dart
final stats = await DealsDatabaseService.getStatistics();
print('Aktive Angebote: ${stats['totalActiveDeals']}');
print('Durchschnittlicher Rabatt: ${stats['averageDiscount']}%');
print('Top Kategorie: ${stats['topCategory']}');
```

### **PDF Scan-Historie**
```dart
final history = await DealsDatabaseService.getScannedPdfHistory();
// Zeigt wann welche PDFs gescannt wurden
```

---

## 🎯 Performance Tipps

1. **Caching**: Deals werden in SQLite gespeichert, keine wiederholten Scans nötig
2. **Indizes**: Alle wichtigen Spalten haben Indizes für schnelle Queries
3. **Batch Processing**: Nutze `findDealsForShoppingList()` statt einzelne Aufrufe
4. **Similarity Threshold**: Erhöhe `minSimilarity` für präzisere, aber weniger Matches
5. **Background Processing**: OCR-Scans können mit `Isolates` im Hintergrund laufen

---

## 📝 TODO / Future Enhancements

- [ ] **Claude AI Integration** für bessere Produkterkennung
- [ ] **Bildvorverarbeitung** (Kontrast, Helligkeit) für bessere OCR-Qualität
- [ ] **Push Notifications** wenn Produkte aus der Liste im Angebot sind
- [ ] **Automatischer Prospekt-Download** von Supermarkt-Webseiten
- [ ] **QR Code Scanner** für schnelleren PDF-Upload
- [ ] **Multi-Language Support** (aktuell nur Deutsch + Englisch)
- [ ] **Custom Training Data** für bessere Prospekt-Erkennung
- [ ] **Cloud Sync** für Angebote zwischen Geräten

---

## 🐛 Troubleshooting

### **OCR erkennt keinen Text**
- Prüfe PDF-Qualität (mindestens 300 DPI empfohlen)
- Stelle sicher, dass Sprachdaten heruntergeladen wurden
- Versuche `psm: "3"` statt `"6"` in OCRService

### **Keine Angebote gefunden**
- Prüfe ob Preise im Format "X,XX €" oder "X.XX€" vorhanden sind
- Mindestens 2 Preise pro Produkt erforderlich (alter + neuer Preis)
- Mindestrabatt: 5%

### **Produkt-Matching findet nichts**
- Senke `minSimilarity` von 0.6 auf 0.5 oder 0.4
- Prüfe Produktnamen auf Tippfehler
- Nutze `searchDeals()` für direkte Textsuche

### **Langsame Performance**
- Nutze `deleteExpiredDeals()` regelmäßig
- Verwende Batch-Methoden statt einzelne Aufrufe
- Erwäge Background Processing mit Isolates

---

## 📦 Dependencies

```yaml
dependencies:
  flutter_tesseract_ocr: ^0.4.25
  pdf_render: ^1.4.0
  file_picker: ^6.1.1
  path_provider: ^2.1.1
  permission_handler: ^11.0.1
  sqflite: ^2.3.0
  string_similarity: ^2.0.0
  uuid: ^4.3.3
  equatable: ^2.0.5
```

---

## 👨‍💻 Code Ownership

Alle Services sind vollständig dokumentiert und production-ready:
- ✅ Error Handling überall
- ✅ Progress Callbacks
- ✅ Logging mit Emojis
- ✅ Type Safety
- ✅ Null Safety
- ✅ Performance Optimiert

**Viel Erfolg mit dem Angebots-Feature! 🚀**
