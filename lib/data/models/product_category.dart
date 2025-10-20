enum ProductCategory {
  fruitsVegetables('Obst & Gemüse'),
  meatFish('Fleisch, Fisch & Ersatzprodukte'),
  dairy('Kühlprodukte'),
  frozen('Tiefkühlprodukte'),
  bakery('Backwaren & Getreide'),
  canned('Konserven & Trockenware'),
  spices('Gewürze & Würzmittel'),
  snacks('Snacks & Süßwaren'),
  beverages('Getränke'),
  household('Haushalt & Hygiene'),
  petSupplies('Tierbedarf'),
  other('Sonstiges');

  final String displayName;
  const ProductCategory(this.displayName);

  /// Get category for a product name
  static ProductCategory categorize(String productName) {
    final name = productName.toLowerCase().trim();

    // Obst & Gemüse
    if (_matchesAny(name, [
      'apfel', 'äpfel', 'banane', 'orange', 'birne', 'traube', 'erdbeere', 'himbeere',
      'blaubeere', 'kirsche', 'pfirsich', 'pflaume', 'melone', 'ananas', 'mango',
      'kiwi', 'zitrone', 'limette', 'avocado', 'tomate', 'gurke', 'salat', 'kopfsalat',
      'karotte', 'möhre', 'kartoffel', 'zwiebel', 'knoblauch', 'paprika', 'zucchini',
      'aubergine', 'brokkoli', 'blumenkohl', 'kohl', 'spinat', 'pilz', 'champignon',
      'lauch', 'sellerie', 'radieschen', 'rettich', 'kürbis', 'mais', 'erbse',
      'bohne', 'obst', 'gemüse', 'salat', 'kräuter', 'petersilie', 'basilikum',
    ])) {
      return ProductCategory.fruitsVegetables;
    }

    // Fleisch, Fisch & Ersatzprodukte
    if (_matchesAny(name, [
      'fleisch', 'hähnchen', 'huhn', 'rind', 'schwein', 'lamm', 'pute', 'ente',
      'wurst', 'schinken', 'salami', 'bacon', 'speck', 'hack', 'hackfleisch',
      'steak', 'schnitzel', 'fisch', 'lachs', 'thunfisch', 'forelle', 'kabeljau',
      'garnele', 'shrimp', 'muschel', 'tofu', 'tempeh', 'seitan', 'veggie',
      'vegetarisch', 'vegan', 'fleischersatz',
    ])) {
      return ProductCategory.meatFish;
    }

    // Kühlprodukte
    if (_matchesAny(name, [
      'milch', 'joghurt', 'quark', 'sahne', 'butter', 'margarine', 'käse',
      'frischkäse', 'mozzarella', 'gouda', 'emmentaler', 'parmesan', 'feta',
      'ei', 'eier', 'pudding', 'dessert', 'aufstrich', 'hummus', 'frischmilch',
    ])) {
      return ProductCategory.dairy;
    }

    // Tiefkühlprodukte
    if (_matchesAny(name, [
      'tiefkühl', 'gefrier', 'frozen', 'tk', 'eis', 'eiscreme', 'pizza',
      'pommes', 'fischstäbchen', 'gemüsemix', 'tiefgefroren',
    ])) {
      return ProductCategory.frozen;
    }

    // Backwaren & Getreide
    if (_matchesAny(name, [
      'brot', 'brötchen', 'toast', 'baguette', 'croissant', 'kuchen', 'torte',
      'mehl', 'zucker', 'salz', 'backpulver', 'hefe', 'reis', 'nudel', 'pasta',
      'spaghetti', 'penne', 'fusilli', 'müsli', 'haferflocken', 'cornflakes',
      'getreide', 'quinoa', 'couscous', 'bulgur',
    ])) {
      return ProductCategory.bakery;
    }

    // Konserven & Trockenware
    if (_matchesAny(name, [
      'dose', 'konserve', 'bohnen', 'kichererbsen', 'linsen', 'erbsen',
      'mais', 'tomatenmark', 'passata', 'tomatensauce', 'pesto', 'marmelade',
      'honig', 'nuss', 'nüsse', 'mandel', 'cashew', 'erdnuss', 'rosine',
      'trockenobst', 'datteln', 'feige',
    ])) {
      return ProductCategory.canned;
    }

    // Gewürze & Würzmittel
    if (_matchesAny(name, [
      'gewürz', 'pfeffer', 'paprika', 'curry', 'kurkuma', 'zimt', 'muskat',
      'oregano', 'thymian', 'rosmarin', 'koriander', 'kreuzkümmel', 'chili',
      'cayenne', 'vanille', 'essig', 'öl', 'olivenöl', 'sonnenblumenöl',
      'rapsöl', 'senf', 'ketchup', 'mayonnaise', 'soße', 'sauce', 'brühe',
      'bouillon', 'maggi', 'würze',
    ])) {
      return ProductCategory.spices;
    }

    // Snacks & Süßwaren
    if (_matchesAny(name, [
      'chips', 'schokolade', 'schoko', 'bonbon', 'gummibärchen', 'keks',
      'cookie', 'riegel', 'snack', 'knabber', 'salzstange', 'cracker',
      'popcorn', 'nachtisch', 'süß', 'candy', 'lutscher',
    ])) {
      return ProductCategory.snacks;
    }

    // Getränke
    if (_matchesAny(name, [
      'wasser', 'saft', 'limo', 'cola', 'fanta', 'sprite', 'bier', 'wein',
      'sekt', 'champagner', 'kaffee', 'tee', 'kakao', 'milch', 'smoothie',
      'energy', 'drink', 'getränk', 'mineralwasser', 'sprudel',
    ])) {
      return ProductCategory.beverages;
    }

    // Haushalt & Hygiene
    if (_matchesAny(name, [
      'putzen', 'reiniger', 'spülmittel', 'waschmittel', 'weichspüler',
      'toilettenpapier', 'klopapier', 'küchenpapier', 'serviette', 'müllbeutel',
      'schwamm', 'bürste', 'seife', 'shampoo', 'duschgel', 'zahnpasta',
      'zahnbürste', 'deo', 'creme', 'lotion', 'rasier', 'windel', 'taschentuch',
      'hygiene', 'haushalt',
    ])) {
      return ProductCategory.household;
    }

    // Tierbedarf
    if (_matchesAny(name, [
      'hund', 'katze', 'tier', 'futter', 'hundefutter', 'katzenfutter',
      'leckerli', 'streu', 'katzenstreu', 'napf', 'leine', 'spielzeug',
      'vogel', 'fisch', 'aquarium',
    ])) {
      return ProductCategory.petSupplies;
    }

    return ProductCategory.other;
  }

  static bool _matchesAny(String text, List<String> keywords) {
    return keywords.any((keyword) => text.contains(keyword));
  }
}
