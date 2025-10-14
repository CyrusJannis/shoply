class Categories {
  static const List<String> all = [
    'Fruits & Vegetables',
    'Meat & Fish',
    'Dairy & Eggs',
    'Bakery & Bread',
    'Beverages',
    'Snacks & Sweets',
    'Frozen Foods',
    'Pantry & Canned Goods',
    'Household & Cleaning',
    'Personal Care',
    'Other',
  ];

  // Category icons mapping
  static const Map<String, String> icons = {
    'Fruits & Vegetables': '🥬',
    'Meat & Fish': '🍖',
    'Dairy & Eggs': '🥛',
    'Bakery & Bread': '🍞',
    'Beverages': '🥤',
    'Snacks & Sweets': '🍫',
    'Frozen Foods': '🧊',
    'Pantry & Canned Goods': '🥫',
    'Household & Cleaning': '🧹',
    'Personal Care': '🧴',
    'Other': '📦',
  };

  // Category keywords for auto-detection
  static const Map<String, List<String>> keywords = {
    'Fruits & Vegetables': [
      'apple', 'banana', 'orange', 'grape', 'strawberry', 'watermelon',
      'lemon', 'lime', 'tomato', 'cucumber', 'lettuce', 'spinach', 
      'carrot', 'potato', 'onion', 'garlic', 'broccoli', 'cauliflower',
      'pepper', 'zucchini', 'eggplant', 'mushroom', 'avocado', 'mango',
      'pineapple', 'kiwi', 'pear', 'peach', 'plum', 'berry', 'salad',
      'kohl', 'rabi', 'gurke', 'paprika', 'zwiebel', 'kartoffel', 'obst',
      'gemüse', 'salat',
    ],
    'Meat & Fish': [
      'chicken', 'beef', 'pork', 'lamb', 'turkey', 'duck', 'salmon',
      'tuna', 'cod', 'shrimp', 'fish', 'seafood', 'bacon', 'sausage',
      'ham', 'ground meat', 'steak', 'meat', 'hähnchen', 'fleisch',
      'fisch', 'lachs', 'thunfisch', 'schwein', 'rind', 'wurst',
    ],
    'Dairy & Eggs': [
      'milk', 'cheese', 'yogurt', 'butter', 'cream', 'sour cream',
      'eggs', 'cottage cheese', 'mozzarella', 'cheddar', 'parmesan',
      'milch', 'käse', 'joghurt', 'sahne', 'quark', 'ei', 'eier',
    ],
    'Bakery & Bread': [
      'bread', 'baguette', 'rolls', 'bagels', 'croissant', 'flour',
      'yeast', 'baking powder', 'baking soda', 'toast', 'brot',
      'brötchen', 'mehl', 'hefe', 'backpulver',
    ],
    'Beverages': [
      'water', 'juice', 'soda', 'cola', 'coffee', 'tea', 'beer',
      'wine', 'alcohol', 'lemonade', 'wasser', 'saft', 'kaffee',
      'tee', 'bier', 'wein', 'limonade',
    ],
    'Snacks & Sweets': [
      'chips', 'chocolate', 'candy', 'cookies', 'crackers', 'nuts',
      'popcorn', 'pretzels', 'ice cream', 'schokolade', 'kekse',
      'bonbon', 'süßigkeiten', 'eis', 'nüsse',
    ],
    'Frozen Foods': [
      'frozen vegetables', 'frozen pizza', 'frozen meals', 'ice cream',
      'frozen fruit', 'tiefkühl', 'gefr oren', 'tk',
    ],
    'Pantry & Canned Goods': [
      'rice', 'pasta', 'noodles', 'cereal', 'oats', 'canned tomatoes',
      'canned beans', 'soup', 'sauce', 'oil', 'vinegar', 'spices',
      'salt', 'pepper', 'sugar', 'reis', 'nudeln', 'dose', 'konserve',
      'öl', 'essig', 'gewürze', 'zucker', 'salz', 'pfeffer',
    ],
    'Household & Cleaning': [
      'detergent', 'soap', 'toilet paper', 'paper towels', 'dish soap',
      'cleaner', 'sponges', 'trash bags', 'waschmittel', 'seife',
      'toilettenpapier', 'küchenpapier', 'spülmittel', 'reiniger',
      'müllbeutel', 'schwamm',
    ],
    'Personal Care': [
      'toothpaste', 'toothbrush', 'deodorant', 'shaving cream', 'shampoo',
      'lotion', 'tissues', 'cotton', 'band-aids', 'zahnpasta',
      'zahnbürste', 'deo', 'rasierschaum', 'creme', 'taschentücher',
      'pflaster',
    ],
  };

  // Diet preferences
  static const List<String> dietPreferences = [
    'None / No restrictions',
    'Vegetarian',
    'Vegan',
    'Gluten-free',
    'Lactose-free',
    'Low-carb / Keto',
    'Halal',
    'Kosher',
    'Nut allergy',
    'Other allergies',
  ];

  // Diet-incompatible foods
  static const Map<String, List<String>> dietRestrictions = {
    'Vegan': [
      'meat', 'fish', 'chicken', 'beef', 'pork', 'lamb', 'turkey',
      'milk', 'cheese', 'yogurt', 'butter', 'cream', 'eggs', 'honey',
      'fleisch', 'fisch', 'milch', 'käse', 'eier',
    ],
    'Vegetarian': [
      'meat', 'fish', 'chicken', 'beef', 'pork', 'lamb', 'turkey',
      'gelatin', 'fleisch', 'fisch',
    ],
    'Gluten-free': [
      'bread', 'pasta', 'wheat', 'barley', 'rye', 'flour', 'cereal',
      'brot', 'nudeln', 'weizen', 'mehl',
    ],
    'Lactose-free': [
      'milk', 'cheese', 'yogurt', 'butter', 'cream', 'ice cream',
      'milch', 'käse', 'joghurt', 'sahne', 'eis',
    ],
  };

  // Units
  static const List<String> units = [
    'pcs',
    'kg',
    'g',
    'l',
    'ml',
    'dozen',
    'pack',
    'bottle',
    'can',
    'box',
  ];
}
