import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('de', ''),
  ];

  // Common
  String get appName => _localizedValues[locale.languageCode]!['app_name']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get edit => _localizedValues[locale.languageCode]!['edit']!;
  String get add => _localizedValues[locale.languageCode]!['add']!;
  String get search => _localizedValues[locale.languageCode]!['search']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get yes => _localizedValues[locale.languageCode]!['yes']!;
  String get no => _localizedValues[locale.languageCode]!['no']!;

  // Lists
  String get myLists => _localizedValues[locale.languageCode]!['my_lists']!;
  String get createList => _localizedValues[locale.languageCode]!['create_list']!;
  String get listName => _localizedValues[locale.languageCode]!['list_name']!;
  String get shareList => _localizedValues[locale.languageCode]!['share_list']!;
  String get deleteList => _localizedValues[locale.languageCode]!['delete_list']!;
  String get emptyList => _localizedValues[locale.languageCode]!['empty_list']!;

  // Items
  String get itemName => _localizedValues[locale.languageCode]!['item_name']!;
  String get quantity => _localizedValues[locale.languageCode]!['quantity']!;
  String get unit => _localizedValues[locale.languageCode]!['unit']!;
  String get notes => _localizedValues[locale.languageCode]!['notes']!;
  String get addItem => _localizedValues[locale.languageCode]!['add_item']!;
  String get editItem => _localizedValues[locale.languageCode]!['edit_item']!;
  String get deleteItem => _localizedValues[locale.languageCode]!['delete_item']!;
  String get completeShopping => _localizedValues[locale.languageCode]!['complete_shopping']!;

  // Categories
  String get category => _localizedValues[locale.languageCode]!['category']!;
  String get sortByCategory => _localizedValues[locale.languageCode]!['sort_by_category']!;
  String get sortAlphabetically => _localizedValues[locale.languageCode]!['sort_alphabetically']!;
  String get sortByQuantity => _localizedValues[locale.languageCode]!['sort_by_quantity']!;
  String get customSort => _localizedValues[locale.languageCode]!['custom_sort']!;

  // Auth
  String get signIn => _localizedValues[locale.languageCode]!['sign_in']!;
  String get signUp => _localizedValues[locale.languageCode]!['sign_up']!;
  String get signOut => _localizedValues[locale.languageCode]!['sign_out']!;
  String get email => _localizedValues[locale.languageCode]!['email']!;
  String get password => _localizedValues[locale.languageCode]!['password']!;

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Shoply',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'loading': 'Loading...',
      'error': 'Error',
      'yes': 'Yes',
      'no': 'No',
      // Lists
      'my_lists': 'My Lists',
      'create_list': 'Create List',
      'list_name': 'List Name',
      'share_list': 'Share List',
      'delete_list': 'Delete List',
      'empty_list': 'No items yet. Add your first item!',
      // Items
      'item_name': 'Item Name',
      'quantity': 'Quantity',
      'unit': 'Unit',
      'notes': 'Notes',
      'add_item': 'Add Item',
      'edit_item': 'Edit Item',
      'delete_item': 'Delete Item',
      'complete_shopping': 'Complete Shopping',
      // Categories
      'category': 'Category',
      'sort_by_category': 'By Category',
      'sort_alphabetically': 'Alphabetical',
      'sort_by_quantity': 'By Quantity',
      'custom_sort': 'Custom (Drag & Drop)',
      // Auth
      'sign_in': 'Sign In',
      'sign_up': 'Sign Up',
      'sign_out': 'Sign Out',
      'email': 'Email',
      'password': 'Password',
    },
    'de': {
      'app_name': 'Shoply',
      'cancel': 'Abbrechen',
      'save': 'Speichern',
      'delete': 'Löschen',
      'edit': 'Bearbeiten',
      'add': 'Hinzufügen',
      'search': 'Suchen',
      'loading': 'Lädt...',
      'error': 'Fehler',
      'yes': 'Ja',
      'no': 'Nein',
      // Lists
      'my_lists': 'Meine Listen',
      'create_list': 'Liste erstellen',
      'list_name': 'Listenname',
      'share_list': 'Liste teilen',
      'delete_list': 'Liste löschen',
      'empty_list': 'Noch keine Artikel. Füge deinen ersten Artikel hinzu!',
      // Items
      'item_name': 'Artikelname',
      'quantity': 'Menge',
      'unit': 'Einheit',
      'notes': 'Notizen',
      'add_item': 'Artikel hinzufügen',
      'edit_item': 'Artikel bearbeiten',
      'delete_item': 'Artikel löschen',
      'complete_shopping': 'Einkauf abschließen',
      // Categories
      'category': 'Kategorie',
      'sort_by_category': 'Nach Kategorie',
      'sort_alphabetically': 'Alphabetisch',
      'sort_by_quantity': 'Nach Menge',
      'custom_sort': 'Benutzerdefiniert (Drag & Drop)',
      // Auth
      'sign_in': 'Anmelden',
      'sign_up': 'Registrieren',
      'sign_out': 'Abmelden',
      'email': 'E-Mail',
      'password': 'Passwort',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'de'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
