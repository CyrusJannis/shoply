import 'package:flutter/material.dart';

class Categories {
  static const List<String> all = [
    'Obst und Gemüse',
    'Fleisch und Wurst',
    'Backwaren',
    'Blumen und Pflanzen',
    'Kühlprodukte',
    'Tiefkühlprodukte',
    'Grundnahrungsmittel',
    'Konserven',
    'Gewürze',
    'Würzmittel',
    'Frühstücksprodukte',
    'Süßigkeiten',
    'Snacks',
    'Getränke',
    'Haushaltswaren',
    'Reinigungsmittel',
    'Papierwaren',
    'Drogerie',
    'Körperpflege',
    'Kosmetik',
    'Hygieneartikel',
    'Babyartikel',
    'Tierbedarf',
    'Non-Food',
    'Haushaltsgeräte',
    'Schreibwaren',
    'Textilien',
    'Spielzeug',
    'Saisonartikel',
    'Kassenbereich',
  ];

  // Category colors mapping
  static const Map<String, Color> colors = {
    'Obst und Gemüse': Color(0xFF4CAF50), // Green
    'Fleisch und Wurst': Color(0xFFF44336), // Red
    'Backwaren': Color(0xFF8D6E63), // Brown
    'Blumen und Pflanzen': Color(0xFFE91E63), // Pink
    'Kühlprodukte': Color(0xFF2196F3), // Blue
    'Tiefkühlprodukte': Color(0xFF00BCD4), // Cyan
    'Grundnahrungsmittel': Color(0xFFFF9800), // Orange
    'Konserven': Color(0xFF9C27B0), // Purple
    'Gewürze': Color(0xFFFF5722), // Deep Orange
    'Würzmittel': Color(0xFF795548), // Brown 700
    'Frühstücksprodukte': Color(0xFFFFEB3B), // Yellow
    'Süßigkeiten': Color(0xFFE91E63), // Pink
    'Snacks': Color(0xFF3F51B5), // Indigo
    'Getränke': Color(0xFF009688), // Teal
    'Haushaltswaren': Color(0xFF607D8B), // Blue Grey
    'Reinigungsmittel': Color(0xFF4CAF50), // Green
    'Papierwaren': Color(0xFF8BC34A), // Light Green
    'Drogerie': Color(0xFF9C27B0), // Purple
    'Körperpflege': Color(0xFFE91E63), // Pink
    'Kosmetik': Color(0xFF3F51B5), // Indigo
    'Hygieneartikel': Color(0xFF2196F3), // Blue
    'Babyartikel': Color(0xFFFF9800), // Orange
    'Tierbedarf': Color(0xFF8D6E63), // Brown
    'Non-Food': Color(0xFF607D8B), // Blue Grey
    'Haushaltsgeräte': Color(0xFF9E9E9E), // Grey
    'Schreibwaren': Color(0xFF3F51B5), // Indigo
    'Textilien': Color(0xFF795548), // Brown
    'Spielzeug': Color(0xFFFF5722), // Deep Orange
    'Saisonartikel': Color(0xFF4CAF50), // Green
    'Kassenbereich': Color(0xFF2196F3), // Blue
  };

  // Category icons mapping
  static const Map<String, String> icons = {
    'Obst und Gemüse': '🥬',
    'Fleisch und Wurst': '🥩',
    'Backwaren': '🍞',
    'Blumen und Pflanzen': '🌸',
    'Kühlprodukte': '🥛',
    'Tiefkühlprodukte': '🧊',
    'Grundnahrungsmittel': '🌾',
    'Konserven': '🥫',
    'Gewürze': '🧂',
    'Würzmittel': '🍯',
    'Frühstücksprodukte': '🥣',
    'Süßigkeiten': '🍬',
    'Snacks': '🍿',
    'Getränke': '🥤',
    'Haushaltswaren': '🍽️',
    'Reinigungsmittel': '🧹',
    'Papierwaren': '🧻',
    'Drogerie': '💊',
    'Körperpflege': '🧴',
    'Kosmetik': '💄',
    'Hygieneartikel': '🪥',
    'Babyartikel': '🍼',
    'Tierbedarf': '🐾',
    'Non-Food': '📦',
    'Haushaltsgeräte': '⚡',
    'Schreibwaren': '✏️',
    'Textilien': '🧺',
    'Spielzeug': '🧸',
    'Saisonartikel': '🎄',
    'Kassenbereich': '🛒',
  };

  // Category keywords for auto-detection
  static const Map<String, List<String>> keywords = {
    'Obst & Gemüse': [
      'apfel', 'äpfel', 'banane', 'orange', 'birne', 'traube', 'erdbeere', 'himbeere',
      'blaubeere', 'kirsche', 'pfirsich', 'pflaume', 'melone', 'ananas', 'mango',
      'kiwi', 'zitrone', 'limette', 'avocado', 'tomate', 'gurke', 'salat', 'kopfsalat',
      'karotte', 'möhre', 'kartoffel', 'zwiebel', 'knoblauch', 'paprika', 'zucchini',
      'aubergine', 'brokkoli', 'blumenkohl', 'kohl', 'spinat', 'pilz', 'champignon',
      'lauch', 'sellerie', 'radieschen', 'rettich', 'kürbis', 'mais', 'erbse',
      'bohne', 'obst', 'gemüse', 'kräuter', 'petersilie', 'basilikum', 'rucola',
      'apple', 'banana', 'orange', 'grape', 'strawberry', 'watermelon', 'lemon',
      'lime', 'tomato', 'cucumber', 'lettuce', 'carrot', 'potato', 'onion', 'garlic',
    ],
    'Fleisch, Fisch & Ersatzprodukte': [
      'fleisch', 'hähnchen', 'huhn', 'rind', 'schwein', 'lamm', 'pute', 'ente',
      'wurst', 'schinken', 'salami', 'bacon', 'speck', 'hack', 'hackfleisch',
      'steak', 'schnitzel', 'fisch', 'lachs', 'thunfisch', 'forelle', 'kabeljau',
      'garnele', 'shrimp', 'muschel', 'tofu', 'tempeh', 'seitan', 'veggie',
      'vegetarisch', 'vegan', 'fleischersatz', 'chicken', 'beef', 'pork', 'fish',
      'salmon', 'tuna', 'meat', 'sausage',
    ],
    'Kühlprodukte': [
      'milch', 'joghurt', 'quark', 'sahne', 'butter', 'margarine', 'käse',
      'frischkäse', 'mozzarella', 'gouda', 'emmentaler', 'parmesan', 'feta',
      'ei', 'eier', 'pudding', 'dessert', 'aufstrich', 'hummus', 'frischmilch',
      'milk', 'cheese', 'yogurt', 'cream', 'eggs',
    ],
    'Tiefkühlprodukte': [
      'tiefkühl', 'gefrier', 'frozen', 'tk', 'eis', 'eiscreme', 'pizza',
      'pommes', 'fischstäbchen', 'gemüsemix', 'tiefgefroren', 'ice cream',
    ],
    'Backwaren & Getreide': [
      'brot', 'brötchen', 'toast', 'baguette', 'croissant', 'kuchen', 'torte',
      'mehl', 'zucker', 'salz', 'backpulver', 'hefe', 'reis', 'nudel', 'pasta',
      'spaghetti', 'penne', 'fusilli', 'müsli', 'haferflocken', 'cornflakes',
      'getreide', 'quinoa', 'couscous', 'bulgur', 'bread', 'flour', 'rice',
      'noodles', 'cereal',
    ],
    'Konserven & Trockenware': [
      'dose', 'konserve', 'bohnen', 'kichererbsen', 'linsen', 'erbsen',
      'mais', 'tomatenmark', 'passata', 'tomatensauce', 'pesto', 'marmelade',
      'honig', 'nuss', 'nüsse', 'mandel', 'cashew', 'erdnuss', 'rosine',
      'trockenobst', 'datteln', 'feige', 'canned', 'beans', 'nuts',
    ],
    'Gewürze & Würzmittel': [
      'gewürz', 'pfeffer', 'paprika', 'curry', 'kurkuma', 'zimt', 'muskat',
      'oregano', 'thymian', 'rosmarin', 'koriander', 'kreuzkümmel', 'chili',
      'cayenne', 'vanille', 'essig', 'öl', 'olivenöl', 'sonnenblumenöl',
      'rapsöl', 'senf', 'ketchup', 'mayonnaise', 'soße', 'sauce', 'brühe',
      'bouillon', 'maggi', 'würze', 'spices', 'pepper', 'oil', 'vinegar',
    ],
    'Snacks & Süßwaren': [
      'chips', 'schokolade', 'schoko', 'bonbon', 'gummibärchen', 'keks',
      'cookie', 'riegel', 'snack', 'knabber', 'salzstange', 'cracker',
      'popcorn', 'nachtisch', 'süß', 'candy', 'lutscher', 'chocolate',
      'cookies', 'sweets',
    ],
    'Getränke': [
      'wasser', 'saft', 'limo', 'cola', 'fanta', 'sprite', 'bier', 'wein',
      'sekt', 'champagner', 'kaffee', 'tee', 'kakao', 'smoothie',
      'energy', 'drink', 'getränk', 'mineralwasser', 'sprudel', 'water',
      'juice', 'coffee', 'tea', 'beer', 'wine',
    ],
    'Haushalt & Hygiene': [
      'putzen', 'reiniger', 'spülmittel', 'waschmittel', 'weichspüler',
      'toilettenpapier', 'klopapier', 'küchenpapier', 'serviette', 'müllbeutel',
      'schwamm', 'bürste', 'seife', 'shampoo', 'duschgel', 'zahnpasta',
      'zahnbürste', 'deo', 'creme', 'lotion', 'rasier', 'windel', 'taschentuch',
      'hygiene', 'haushalt', 'detergent', 'soap', 'toilet paper', 'shampoo',
      'toothpaste',
    ],
    'Tierbedarf': [
      'hund', 'katze', 'tier', 'futter', 'hundefutter', 'katzenfutter',
      'leckerli', 'streu', 'katzenstreu', 'napf', 'leine', 'spielzeug',
      'vogel', 'fisch', 'aquarium', 'pet', 'dog', 'cat', 'food',
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
