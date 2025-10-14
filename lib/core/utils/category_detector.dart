import 'package:shoply/core/constants/categories.dart';

class CategoryDetector {
  /// Detects the category of an item based on its name
  static String detectCategory(String itemName) {
    if (itemName.isEmpty) return 'Other';
    
    final normalizedName = itemName.toLowerCase().trim();
    
    // Check each category's keywords
    for (final entry in Categories.keywords.entries) {
      for (final keyword in entry.value) {
        if (normalizedName.contains(keyword.toLowerCase())) {
          return entry.key;
        }
      }
    }
    
    return 'Other';
  }
  
  /// Gets the icon emoji for a category
  static String getCategoryIcon(String category) {
    return Categories.icons[category] ?? '📦';
  }
  
  /// Gets all category names
  static List<String> getAllCategories() {
    return Categories.all;
  }
}
