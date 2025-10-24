import 'package:shoply/data/models/item_purchase_stats.dart';
import 'package:shoply/data/models/recommendation_item.dart';
import 'package:shoply/data/models/shopping_item_model.dart';
import 'package:shoply/data/services/purchase_tracking_service.dart';

class RecommendationService {
  final PurchaseTrackingService _trackingService = PurchaseTrackingService();

  /// Get smart recommendations for a shopping list
  Future<List<RecommendationItem>> getRecommendations({
    required List<ShoppingItemModel> currentListItems,
    int limit = 8,
  }) async {
    try {
      // Get all purchase stats
      final allStats = await _trackingService.getAllStats();
      if (allStats.isEmpty) return [];

      // Get current item names (lowercase for comparison)
      final currentItemNames = currentListItems
          .map((item) => item.name.trim().toLowerCase())
          .toSet();

      // Filter out items already in the list
      final availableStats = allStats
          .where((stats) => !currentItemNames.contains(stats.itemName))
          .toList();

      if (availableStats.isEmpty) return [];

      // Calculate scores for each item
      final recommendations = availableStats.map((stats) {
        final score = _calculateRecommendationScore(stats);
        final reason = _generateReason(stats);

        return RecommendationItem(
          itemName: stats.itemName,
          score: score,
          reason: reason,
          stats: stats,
          category: stats.preferredCategory,
          quantity: stats.preferredQuantity,
        );
      }).toList();

      // Sort by score (highest first) and take top N
      recommendations.sort((a, b) => b.score.compareTo(a.score));
      return recommendations.take(limit).toList();
    } catch (e) {
      print('❌ Error generating recommendations: $e');
      return [];
    }
  }

  /// Calculate recommendation score (0-100)
  double _calculateRecommendationScore(ItemPurchaseStats stats) {
    double score = 0.0;

    // Frequency Score (0-40 points)
    score += _calculateFrequencyScore(stats.purchaseCount);

    // Recency Score (0-30 points)
    score += _calculateRecencyScore(stats);

    // Preference Score (0-20 points)
    score += _calculatePreferenceScore(stats);

    // Timing Score (0-10 points)
    score += _calculateTimingScore(stats);

    return score.clamp(0.0, 100.0);
  }

  /// Calculate frequency score based on purchase count
  double _calculateFrequencyScore(int purchaseCount) {
    if (purchaseCount >= 10) return 40.0;
    if (purchaseCount >= 7) return 30.0;
    if (purchaseCount >= 4) return 20.0;
    if (purchaseCount >= 2) return 10.0;
    return 5.0;
  }

  /// Calculate recency score based on time since last purchase
  double _calculateRecencyScore(ItemPurchaseStats stats) {
    final daysSince = stats.daysSinceLastPurchase;
    final avgDays = stats.averageDaysBetween;

    // If no average (only 1 purchase), use simple recency
    if (avgDays == null || avgDays <= 0) {
      if (daysSince > 30) return 25.0;
      if (daysSince > 14) return 20.0;
      if (daysSince > 7) return 15.0;
      return 5.0;
    }

    // Calculate ratio of days since last purchase to average interval
    final ratio = daysSince / avgDays;

    if (ratio > 1.2) return 30.0;  // Overdue - highest priority
    if (ratio >= 0.8) return 25.0;  // Due soon
    if (ratio >= 0.5) return 15.0;  // Approaching due date
    return 5.0;  // Recently bought
  }

  /// Calculate preference score
  double _calculatePreferenceScore(ItemPurchaseStats stats) {
    double score = 0.0;

    // High purchase count indicates preference
    if (stats.purchaseCount >= 5) {
      score += 10.0;
    }

    // Consistent category indicates preference
    if (stats.preferredCategory != null) {
      score += 5.0;
    }

    // Consistent quantity indicates preference
    if (stats.preferredQuantity != null) {
      score += 5.0;
    }

    return score;
  }

  /// Calculate timing score based on purchase patterns
  double _calculateTimingScore(ItemPurchaseStats stats) {
    if (stats.purchaseDates.length < 3) return 0.0;

    // Check for cyclical pattern (consistent intervals)
    final intervals = <int>[];
    final sortedDates = [...stats.purchaseDates]..sort();

    for (int i = 1; i < sortedDates.length; i++) {
      intervals.add(sortedDates[i].difference(sortedDates[i - 1]).inDays);
    }

    if (intervals.isEmpty) return 0.0;

    // Calculate standard deviation of intervals
    final mean = intervals.reduce((a, b) => a + b) / intervals.length;
    final variance = intervals
        .map((interval) => (interval - mean) * (interval - mean))
        .reduce((a, b) => a + b) / intervals.length;
    final stdDev = variance.isFinite ? variance : 0.0;

    // Low standard deviation = consistent pattern
    if (stdDev < mean * 0.3) return 10.0;  // Very consistent
    if (stdDev < mean * 0.5) return 7.0;   // Somewhat consistent
    return 0.0;
  }

  /// Generate human-readable reason for recommendation
  String _generateReason(ItemPurchaseStats stats) {
    // Check if overdue
    if (stats.isOverdue) {
      final daysOverdue = stats.daysSinceLastPurchase - (stats.averageDaysBetween ?? 0).round();
      return 'Overdue by $daysOverdue days';
    }

    // Check if due soon
    if (stats.isDueSoon) {
      return 'Usually buy every ${stats.averageDaysBetween?.round() ?? 0} days';
    }

    // High frequency
    if (stats.purchaseCount >= 10) {
      return 'You buy this often (${stats.purchaseCount}x)';
    }

    // Regular purchase
    if (stats.purchaseCount >= 5) {
      return 'Regular purchase';
    }

    // Recent but not too recent
    if (stats.daysSinceLastPurchase > 7) {
      return 'Last bought ${stats.daysSinceLastPurchase} days ago';
    }

    // Default
    return 'Frequently purchased';
  }

  /// Get recommendations by category
  Future<Map<String, List<RecommendationItem>>> getRecommendationsByCategory({
    required List<ShoppingItemModel> currentListItems,
  }) async {
    final recommendations = await getRecommendations(
      currentListItems: currentListItems,
      limit: 20,
    );

    final Map<String, List<RecommendationItem>> byCategory = {};

    for (final rec in recommendations) {
      final category = rec.category ?? 'Other';
      byCategory.putIfAbsent(category, () => []).add(rec);
    }

    return byCategory;
  }
}
