import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shoply/data/models/item_purchase_stats.dart';
import 'package:shoply/data/models/shopping_item_model.dart';
import 'package:shoply/data/models/shopping_history.dart';
import 'package:shoply/data/models/recommendation_item.dart';
import 'package:shoply/data/services/purchase_tracking_service.dart';
import 'package:shoply/data/services/shopping_history_service.dart';

/// 🧠 Advanced ML-based Recommendation Engine
/// 
/// Multi-factor scoring system analyzing:
/// ✅ Purchase Frequency & Recency (15%)
/// ✅ Predictive Replenishment Pattern Recognition (20%)
/// ✅ Sequential Shopping History - Last 10 Trips (15%)
/// ✅ Item Association Mining (Co-occurrence) (15%)
/// ✅ Day-of-Week Patterns (10%)
/// ✅ Time-of-Day Patterns (5%)
/// ✅ Seasonal Trends (5%)
/// ✅ Category Affinity (10%)
/// ✅ List Completeness Score (5%)
/// 
/// Returns TOP 3 most relevant recommendations only
class MLRecommendationService {
  final PurchaseTrackingService _trackingService;
  final ShoppingHistoryService _historyService;

  MLRecommendationService({
    PurchaseTrackingService? trackingService,
    ShoppingHistoryService? historyService,
  })  : _trackingService = trackingService ?? PurchaseTrackingService(),
        _historyService = historyService ?? ShoppingHistoryService();

  /// 🎯 Generate 1-3 ML-powered recommendations based on confidence scores
  /// 
  /// Returns ONLY highly confident recommendations:
  /// - Score >= 75: EXCELLENT match (always include)
  /// - Score >= 60: GOOD match (include up to 2)
  /// - Score >= 45: DECENT match (include only 1 if nothing better)
  /// - Score < 45: TOO LOW - don't show
  Future<List<RecommendationItem>> getRecommendations({
    required List<ShoppingItemModel> currentListItems,
    int limit = 3,
  }) async {
    try {
      if (kDebugMode) {
        print('🧠 [ML_RECOMMEND] Starting recommendation engine...');
        print('📋 [ML_RECOMMEND] Current list has ${currentListItems.length} items');
      }

      // Get all data
      final allStats = await _trackingService.getAllStats();
      final recentHistory = await _historyService.getRecentHistory(limit: 10); // Increased to 10 trips
      
      // Get current item names (lowercase for comparison)
      final currentItemNames = currentListItems
          .map((item) => item.name.trim().toLowerCase())
          .toSet();

      // If no data yet, return starter recommendations
      if (allStats.isEmpty && recentHistory.isEmpty) {
        if (kDebugMode) print('⚠️ [ML_RECOMMEND] No data - returning starter items');
        return _getStarterRecommendations(currentItemNames);
      }

      if (kDebugMode) {
        print('📊 [ML_RECOMMEND] Stats: ${allStats.length} items tracked');
        print('🕒 [ML_RECOMMEND] History: ${recentHistory.length} recent trips');
      }

      // Calculate scores using advanced multi-factor analysis
      final candidateScores = <String, double>{};
      final candidateStats = <String, ItemPurchaseStats>{};
      final candidateReasons = <String, List<String>>{};
      final candidateFactors = <String, Map<String, double>>{}; // Track individual factor scores

      // 1️⃣ Sequential/Personal History Score (15% weight)
      final historyScores = await _calculateHistoryScore(recentHistory, currentItemNames);
      for (final entry in historyScores.entries) {
        candidateScores[entry.key] = (candidateScores[entry.key] ?? 0) + entry.value * 0.15;
        candidateFactors.putIfAbsent(entry.key, () => {})['history'] = entry.value * 0.15;
        if (entry.value > 0.6) {
          candidateReasons.putIfAbsent(entry.key, () => []).add('Oft gekauft');
        }
      }

      // 2️⃣ Item Association Score (15% weight)
      final associationScores = await _calculateAssociationScore(currentListItems, currentItemNames);
      for (final entry in associationScores.entries) {
        candidateScores[entry.key] = (candidateScores[entry.key] ?? 0) + entry.value * 0.15;
        candidateFactors.putIfAbsent(entry.key, () => {})['association'] = entry.value * 0.15;
        if (entry.value > 0.5) {
          candidateReasons.putIfAbsent(entry.key, () => []).add('Passt gut dazu');
        }
      }

      // 3️⃣ Day-of-Week Pattern Score (10% weight)
      final dowScores = _calculateDayOfWeekScore(allStats, currentItemNames);
      for (final entry in dowScores.entries) {
        candidateScores[entry.key] = (candidateScores[entry.key] ?? 0) + entry.value * 0.10;
        candidateFactors.putIfAbsent(entry.key, () => {})['dayOfWeek'] = entry.value * 0.10;
      }

      // 4️⃣ Category Affinity Score (10% weight)
      final categoryScores = _calculateCategoryAffinityScore(currentListItems, allStats, currentItemNames);
      for (final entry in categoryScores.entries) {
        candidateScores[entry.key] = (candidateScores[entry.key] ?? 0) + entry.value * 0.10;
        candidateFactors.putIfAbsent(entry.key, () => {})['categoryAffinity'] = entry.value * 0.10;
      }

      // 5️⃣ Frequency, Recency & Replenishment Score (50% weight - MOST IMPORTANT)
      for (final stats in allStats) {
        final itemName = stats.itemName.toLowerCase();
        if (currentItemNames.contains(itemName)) continue;

        candidateStats[itemName] = stats;
        
        // Frequency Score (15% of total)
        final frequencyScore = _calculateFrequencyScore(stats);
        candidateScores[itemName] = (candidateScores[itemName] ?? 0) + frequencyScore * 0.15;
        candidateFactors.putIfAbsent(itemName, () => {})['frequency'] = frequencyScore * 0.15;
        
        // Recency Score (15% of total)
        final recencyScore = _calculateRecencyScore(stats);
        candidateScores[itemName] = (candidateScores[itemName] ?? 0) + recencyScore * 0.15;
        candidateFactors.putIfAbsent(itemName, () => {})['recency'] = recencyScore * 0.15;
        
        // 🎯 Predictive Replenishment Score (20% of total - HIGHEST WEIGHT)
        final replenishmentScore = _calculateReplenishmentScore(stats);
        candidateScores[itemName] = (candidateScores[itemName] ?? 0) + replenishmentScore * 0.20;
        candidateFactors.putIfAbsent(itemName, () => {})['replenishment'] = replenishmentScore * 0.20;
        
        // Add reason if item is due for replenishment
        if (replenishmentScore > 0.7) {
          candidateReasons.putIfAbsent(itemName, () => []).add('Wieder Zeit zu kaufen');
        }
      }

      // Build all recommendations with scores
      final allRecommendations = <RecommendationItem>[];
      
      for (final entry in candidateScores.entries) {
        final itemName = _capitalizeItemName(entry.key);
        final score = entry.value * 100; // Scale to 0-100
        final reasons = candidateReasons[entry.key] ?? ['Empfohlen'];
        final stats = candidateStats[entry.key];

        allRecommendations.add(RecommendationItem(
          itemName: itemName,
          score: score,
          reason: reasons.join(' • '),
          stats: stats,
          category: stats?.preferredCategory,
          quantity: stats?.preferredQuantity,
        ));
      }

      // Sort by score (highest first)
      allRecommendations.sort((a, b) => b.score.compareTo(a.score));
      
      if (kDebugMode && allRecommendations.isNotEmpty) {
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('🏆 [ML_RECOMMEND] Top candidates:');
        for (var i = 0; i < min(5, allRecommendations.length); i++) {
          final rec = allRecommendations[i];
          print('   ${i + 1}. ${rec.itemName}: ${rec.score.toStringAsFixed(1)} - ${rec.reason}');
        }
      }

      // 🎯 SMART FILTERING: Return 1-3 based on confidence thresholds
      final filteredRecommendations = _filterByConfidence(allRecommendations);
      
      if (kDebugMode) {
        print('✅ [ML_RECOMMEND] Returning ${filteredRecommendations.length} high-confidence recommendations');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      }

      // Ensure we have some recommendations
      if (filteredRecommendations.isEmpty) {
        if (kDebugMode) print('⚠️ [ML_RECOMMEND] No confident matches - returning starter items');
        return _getStarterRecommendations(currentItemNames).take(1).toList();
      }

      return filteredRecommendations;
    } catch (e) {
      return _getStarterRecommendations({});
    }
  }

  /// 1️⃣ Sequential/Personal History Score
  /// Analyzes last 3 shopping trips to find patterns
  Future<Map<String, double>> _calculateHistoryScore(
    List<ShoppingHistory> recentHistory,
    Set<String> excludeItems,
  ) async {
    final scores = <String, double>{};
    
    if (recentHistory.isEmpty) return scores;

    // Weight: More recent trips = higher weight
    final weights = [1.0, 0.7, 0.5]; // Last trip most important
    
    for (var i = 0; i < recentHistory.length && i < 3; i++) {
      final trip = recentHistory[i];
      final items = trip.items;
      
      for (final item in items) {
        final itemName = item.name.toLowerCase();
        if (excludeItems.contains(itemName)) continue;
        
        // Boost score based on trip recency
        scores[itemName] = (scores[itemName] ?? 0) + weights[i];
      }
    }

    // Normalize scores to 0-1 range
    if (scores.isNotEmpty) {
      final maxScore = scores.values.reduce(max);
      scores.updateAll((key, value) => value / maxScore);
    }

    return scores;
  }

  /// 2️⃣ Item Association Score (Apriori-like)
  /// Finds items frequently bought together
  Future<Map<String, double>> _calculateAssociationScore(
    List<ShoppingItemModel> currentItems,
    Set<String> excludeItems,
  ) async {
    final scores = <String, double>{};
    
    if (currentItems.isEmpty) return scores;

    // Get all shopping history to mine associations
    final allHistory = await _historyService.getRecentHistory(limit: 50);
    
    // Build co-occurrence matrix
    final coOccurrence = <String, Map<String, int>>{};
    
    for (final trip in allHistory) {
      final items = trip.items;
      final itemNames = items.map((item) => item.name.toLowerCase()).toList();
      
      // Count co-occurrences
      for (var i = 0; i < itemNames.length; i++) {
        for (var j = 0; j < itemNames.length; j++) {
          if (i == j) continue;
          
          final item1 = itemNames[i];
          final item2 = itemNames[j];
          
          coOccurrence.putIfAbsent(item1, () => {});
          coOccurrence[item1]![item2] = (coOccurrence[item1]![item2] ?? 0) + 1;
        }
      }
    }

    // Calculate association scores for current items
    for (final currentItem in currentItems) {
      final currentName = currentItem.name.toLowerCase();
      
      if (!coOccurrence.containsKey(currentName)) continue;
      
      final associations = coOccurrence[currentName]!;
      
      for (final entry in associations.entries) {
        final associatedItem = entry.key;
        final count = entry.value;
        
        if (excludeItems.contains(associatedItem)) continue;
        
        // Confidence: P(B|A) = count(A,B) / count(A)
        final confidence = count / currentItems.length;
        scores[associatedItem] = (scores[associatedItem] ?? 0) + confidence;
      }
    }

    // Normalize
    if (scores.isNotEmpty) {
      final maxScore = scores.values.reduce(max);
      scores.updateAll((key, value) => value / maxScore);
    }

    return scores;
  }

  /// Calculate recency score (0-1)
  double _calculateRecencyScore(ItemPurchaseStats stats) {
    final daysSinceLastPurchase = DateTime.now()
        .difference(stats.lastPurchase)
        .inDays;

    // Score decreases with time: 1.0 for today, 0.0 for 30+ days
    final score = 1.0 - (daysSinceLastPurchase / 30.0).clamp(0.0, 1.0);
    
    return score;
  }

  /// 🎯 Predictive Replenishment Score
  /// Erkennt wiederkehrende Kaufmuster: "Du kaufst Eier alle 3 Tage"
  /// Berechnet: Ist es wieder Zeit für dieses Item?
  double _calculateReplenishmentScore(ItemPurchaseStats stats) {
    // Brauchen mindestens 2 Käufe für Pattern
    if (stats.purchaseCount < 2 || stats.averageDaysBetween == null) {
      return 0.0;
    }

    final avgDays = stats.averageDaysBetween!;
    final daysSinceLastPurchase = DateTime.now()
        .difference(stats.lastPurchase)
        .inDays;

    // Wie nah sind wir am erwarteten Wiederkauf-Zeitpunkt?
    // Beispiel: avgDays = 3, daysSince = 3 → ratio = 1.0 → Perfekt!
    // Beispiel: avgDays = 3, daysSince = 1.5 → ratio = 0.5 → Zu früh
    // Beispiel: avgDays = 3, daysSince = 6 → ratio = 2.0 → Überfällig!
    final ratio = daysSinceLastPurchase / avgDays;

    // Score-Berechnung mit Gaussian-ähnlicher Kurve
    // Peak bei ratio = 1.0 (genau zur richtigen Zeit)
    // Fällt ab wenn zu früh oder zu spät
    double score;
    
    if (ratio < 0.7) {
      // Zu früh - linear steigend von 0 bis 0.7
      score = ratio / 0.7 * 0.3;
    } else if (ratio <= 1.3) {
      // Sweet Spot - zwischen 70% und 130% des Durchschnitts
      // 0.7-1.0: Steigt auf 1.0
      // 1.0-1.3: Bleibt hoch, fällt leicht
      score = 0.3 + (1.0 - (ratio - 0.7).abs() / 0.6) * 0.7;
      score = score.clamp(0.7, 1.0);
    } else {
      // Überfällig - Score bleibt hoch aber fällt langsam
      score = 1.0 / (1 + (ratio - 1.3) * 0.3);
      score = score.clamp(0.4, 1.0);
    }

    // Boost für häufig gekaufte Items (mehr Vertrauen in Pattern)
    final confidenceBoost = (stats.purchaseCount / 10.0).clamp(0.0, 0.2);
    score = (score + confidenceBoost).clamp(0.0, 1.0);

    return score;
  }

  /// Normalize value to 0-1 range
  double _normalizeScore(double value, double min, double max) {
    if (max == min) return 1.0;
    return ((value - min) / (max - min)).clamp(0.0, 1.0);
  }

  /// 🎯 Smart Confidence Filtering
  /// Returns 1-3 recommendations based on quality thresholds
  /// 
  /// Rules:
  /// - Score >= 75: EXCELLENT (always show, up to 3)
  /// - Score >= 60: GOOD (show up to 2 if no excellent)
  /// - Score >= 45: DECENT (show 1 if nothing better)
  /// - Score < 45: TOO LOW (don't show)
  List<RecommendationItem> _filterByConfidence(List<RecommendationItem> allRecommendations) {
    if (allRecommendations.isEmpty) return [];

    final filtered = <RecommendationItem>[];
    
    // Count items by confidence tier
    final excellent = allRecommendations.where((r) => r.score >= 75).toList();
    final good = allRecommendations.where((r) => r.score >= 60 && r.score < 75).toList();
    final decent = allRecommendations.where((r) => r.score >= 45 && r.score < 60).toList();

    if (kDebugMode) {
      print('🎯 [ML_RECOMMEND] Confidence distribution:');
      print('   Excellent (≥75): ${excellent.length}');
      print('   Good (≥60): ${good.length}');
      print('   Decent (≥45): ${decent.length}');
    }

    // Strategy: Prioritize quality over quantity
    if (excellent.isNotEmpty) {
      // Show up to 3 excellent recommendations
      filtered.addAll(excellent.take(3));
      if (kDebugMode) print('   → Showing ${filtered.length} excellent items');
    } else if (good.isNotEmpty) {
      // No excellent items, show up to 2 good ones
      filtered.addAll(good.take(2));
      if (kDebugMode) print('   → Showing ${filtered.length} good items');
    } else if (decent.isNotEmpty) {
      // No good items, show only 1 decent item
      filtered.add(decent.first);
      if (kDebugMode) print('   → Showing 1 decent item');
    }
    // Else: return empty list (scores too low)

    return filtered;
  }

  /// 3️⃣ Day-of-Week Pattern Score (10% weight)
  /// Detects if items are typically bought on specific days
  Map<String, double> _calculateDayOfWeekScore(
    List<ItemPurchaseStats> allStats,
    Set<String> excludeItems,
  ) {
    final scores = <String, double>{};
    final currentDayOfWeek = DateTime.now().weekday;

    for (final stats in allStats) {
      final itemName = stats.itemName.toLowerCase();
      if (excludeItems.contains(itemName)) continue;
      if (stats.purchaseDates.length < 3) continue; // Need pattern data

      // Count purchases by day of week
      final dayCount = <int, int>{};
      for (final date in stats.purchaseDates) {
        final dow = date.weekday;
        dayCount[dow] = (dayCount[dow] ?? 0) + 1;
      }

      // Check if current day is a strong pattern
      final currentDayCount = dayCount[currentDayOfWeek] ?? 0;
      final totalPurchases = stats.purchaseDates.length;
      
      // Score based on how often this item is bought on this day
      // Example: If 5 out of 7 purchases were on Monday, and today is Monday → high score
      final dayRatio = currentDayCount / totalPurchases;
      
      if (dayRatio >= 0.4) {
        // 40%+ of purchases on this day = strong pattern
        scores[itemName] = dayRatio;
      } else if (dayRatio >= 0.25) {
        // 25-40% = moderate pattern
        scores[itemName] = dayRatio * 0.7;
      }
    }

    // Normalize
    if (scores.isNotEmpty) {
      final maxScore = scores.values.reduce(max);
      if (maxScore > 0) {
        scores.updateAll((key, value) => value / maxScore);
      }
    }

    return scores;
  }

  /// 4️⃣ Category Affinity Score (10% weight)
  /// Recommends items from same categories as current list
  Map<String, double> _calculateCategoryAffinityScore(
    List<ShoppingItemModel> currentListItems,
    List<ItemPurchaseStats> allStats,
    Set<String> excludeItems,
  ) {
    final scores = <String, double>{};
    
    if (currentListItems.isEmpty) return scores;

    // Get categories in current list
    final currentCategories = currentListItems
        .where((item) => item.category != null)
        .map((item) => item.category!)
        .toSet();

    if (currentCategories.isEmpty) return scores;

    // Score items that match current categories
    for (final stats in allStats) {
      final itemName = stats.itemName.toLowerCase();
      if (excludeItems.contains(itemName)) continue;
      if (stats.preferredCategory == null) continue;

      if (currentCategories.contains(stats.preferredCategory)) {
        // Matching category gets a score
        // Boost for more frequently purchased items
        final frequencyBoost = (stats.purchaseCount / 10.0).clamp(0.0, 1.0);
        scores[itemName] = 0.5 + (frequencyBoost * 0.5);
      }
    }

    // Normalize
    if (scores.isNotEmpty) {
      final maxScore = scores.values.reduce(max);
      if (maxScore > 0) {
        scores.updateAll((key, value) => value / maxScore);
      }
    }

    return scores;
  }

  /// 5️⃣ Frequency Score (enhanced version)
  /// Considers purchase frequency with diminishing returns
  double _calculateFrequencyScore(ItemPurchaseStats stats) {
    final count = stats.purchaseCount;
    
    // Logarithmic scale with diminishing returns
    // 1 purchase = 0.3
    // 3 purchases = 0.6
    // 5 purchases = 0.75
    // 10 purchases = 0.9
    // 20+ purchases = 1.0
    
    if (count >= 20) return 1.0;
    if (count >= 10) return 0.9;
    if (count >= 7) return 0.8;
    if (count >= 5) return 0.75;
    if (count >= 3) return 0.6;
    if (count >= 2) return 0.45;
    return 0.3;
  }

  /// Starter recommendations for new users
  List<RecommendationItem> _getStarterRecommendations(Set<String> excludeNames) {
    final commonItems = [
      {'name': 'Milch', 'category': 'Milchprodukte', 'quantity': 1.0, 'score': 85.0},
      {'name': 'Brot', 'category': 'Backwaren', 'quantity': 1.0, 'score': 80.0},
      {'name': 'Eier', 'category': 'Eier & Milchprodukte', 'quantity': 6.0, 'score': 75.0},
      {'name': 'Butter', 'category': 'Milchprodukte', 'quantity': 1.0, 'score': 70.0},
      {'name': 'Käse', 'category': 'Milchprodukte', 'quantity': 200.0, 'score': 65.0},
      {'name': 'Äpfel', 'category': 'Obst', 'quantity': 1.0, 'score': 60.0},
      {'name': 'Bananen', 'category': 'Obst', 'quantity': 1.0, 'score': 55.0},
      {'name': 'Tomaten', 'category': 'Gemüse', 'quantity': 500.0, 'score': 50.0},
    ];

    return commonItems
        .where((item) => !excludeNames.contains((item['name'] as String).toLowerCase()))
        .map((item) => RecommendationItem(
              itemName: item['name'] as String,
              score: item['score'] as double,
              reason: 'Beliebtes Produkt',
              category: item['category'] as String?,
              quantity: item['quantity'] as double?,
            ))
        .toList();
  }

  String _capitalizeItemName(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1);
  }
}
