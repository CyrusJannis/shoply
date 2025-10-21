import 'package:shoply/data/models/product_category.dart';

/// Maps between ProductCategory enum and string category names
class CategoryMapper {
  /// Convert ProductCategory enum to display string
  static String toDisplayString(ProductCategory category) {
    return category.displayName;
  }

  /// Convert display string to ProductCategory enum
  static ProductCategory fromDisplayString(String displayName) {
    for (final category in ProductCategory.values) {
      if (category.displayName == displayName) {
        return category;
      }
    }
    return ProductCategory.fruitsVegetables; // Default fallback
  }

  /// Get category icon emoji
  static String getIcon(String categoryName) {
    final category = fromDisplayString(categoryName);
    return _getCategoryIcon(category);
  }

  static String _getCategoryIcon(ProductCategory category) {
    switch (category) {
      case ProductCategory.fruitsVegetables:
        return '🥬';
      case ProductCategory.meatFish:
        return '🥩';
      case ProductCategory.bakery:
        return '🍞';
      case ProductCategory.flowersPlants:
        return '🌸';
      case ProductCategory.dairy:
        return '🥛';
      case ProductCategory.frozen:
        return '🧊';
      case ProductCategory.staples:
        return '🌾';
      case ProductCategory.canned:
        return '🥫';
      case ProductCategory.spices:
        return '🧂';
      case ProductCategory.condiments:
        return '🍯';
      case ProductCategory.breakfast:
        return '🥣';
      case ProductCategory.sweets:
        return '🍬';
      case ProductCategory.snacks:
        return '🍿';
      case ProductCategory.beverages:
        return '🥤';
      case ProductCategory.household:
        return '🍽️';
      case ProductCategory.cleaning:
        return '🧹';
      case ProductCategory.paper:
        return '🧻';
      case ProductCategory.drugstore:
        return '💊';
      case ProductCategory.bodycare:
        return '🧴';
      case ProductCategory.cosmetics:
        return '💄';
      case ProductCategory.hygiene:
        return '🪥';
      case ProductCategory.baby:
        return '🍼';
      case ProductCategory.petSupplies:
        return '🐾';
      case ProductCategory.nonFood:
        return '📦';
      case ProductCategory.appliances:
        return '⚡';
      case ProductCategory.stationery:
        return '✏️';
      case ProductCategory.textiles:
        return '🧺';
      case ProductCategory.toys:
        return '🧸';
      case ProductCategory.seasonal:
        return '🎄';
      case ProductCategory.checkout:
        return '🛒';
    }
  }

  /// Get all category names as strings
  static List<String> getAllCategoryNames() {
    return ProductCategory.values
        .map((category) => category.displayName)
        .toList();
  }
}
