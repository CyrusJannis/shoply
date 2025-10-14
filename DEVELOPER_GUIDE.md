# 👨‍💻 Shoply Developer Guide

A comprehensive guide for developers working on the Shoply project.

## 🏗️ Architecture Overview

Shoply follows **Clean Architecture** principles with clear separation of concerns:

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│  (UI, Widgets, State Management)        │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│          Domain Layer                   │
│    (Business Logic, Use Cases)          │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│           Data Layer                    │
│ (Repositories, Services, Data Sources)  │
└─────────────────────────────────────────┘
```

### Layer Responsibilities

**Presentation Layer** (`lib/presentation/`)
- Screens and UI components
- State management with Riverpod
- User input handling
- Navigation

**Data Layer** (`lib/data/`)
- Models and data structures
- Repositories for data access
- Services for external APIs
- Local and remote data sources

**Core** (`lib/core/`)
- Constants (colors, dimensions, text styles)
- Theme configuration
- Utilities and helpers
- Configuration files

## 🔧 Tech Stack

### Frontend
- **Flutter** - Cross-platform framework
- **Riverpod** - State management
- **Go Router** - Navigation
- **Material 3** - Design system

### Backend
- **Supabase** - BaaS (Backend as a Service)
  - PostgreSQL database
  - Authentication
  - Real-time subscriptions
  - Storage
  - Row Level Security

### Local Storage
- **Hive** - NoSQL local database (configured, not yet used)
- **Shared Preferences** - Simple key-value storage
- **Flutter Secure Storage** - Secure credential storage

## 📝 Coding Standards

### Naming Conventions

**Files and Directories:**
```
snake_case.dart              # All Dart files
feature_name_screen.dart     # Screens
feature_name_widget.dart     # Widgets
feature_name_model.dart      # Models
feature_name_repository.dart # Repositories
```

**Classes:**
```dart
class UserModel {}           // PascalCase
class AuthService {}
class ShoppingListRepository {}
```

**Variables and Functions:**
```dart
String userName = '';        // camelCase
void fetchUserData() {}
final isLoading = false;
```

**Constants:**
```dart
const double spacingLarge = 24.0;  // camelCase
static const String appName = 'Shoply';
```

**Private Members:**
```dart
String _privateVariable = '';     // Leading underscore
void _privateMethod() {}
```

### Code Organization

**Imports:**
```dart
// 1. Dart/Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 2. Package imports (alphabetically)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 3. Project imports (alphabetically)
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/data/models/user_model.dart';
```

**Class Structure:**
```dart
class MyWidget extends StatelessWidget {
  // 1. Static constants
  static const double buttonHeight = 48.0;
  
  // 2. Fields
  final String title;
  final VoidCallback? onTap;
  
  // 3. Constructor
  const MyWidget({
    super.key,
    required this.title,
    this.onTap,
  });
  
  // 4. Lifecycle methods
  @override
  void initState() { /* ... */ }
  
  // 5. Build method
  @override
  Widget build(BuildContext context) { /* ... */ }
  
  // 6. Private methods
  void _handleTap() { /* ... */ }
  
  // 7. Helper methods
  Widget _buildTitle() { /* ... */ }
}
```

### Documentation

**File Headers:**
```dart
/// Shopping list repository for managing list CRUD operations.
/// 
/// Handles all database operations for shopping lists including
/// creating, reading, updating, and deleting lists, as well as
/// managing list sharing and member operations.
class ListRepository {
  // ...
}
```

**Public APIs:**
```dart
/// Creates a new shopping list for the current user.
/// 
/// [name] The name of the new list.
/// 
/// Returns the created [ShoppingListModel].
/// Throws an [Exception] if user is not authenticated.
Future<ShoppingListModel> createList(String name) async {
  // ...
}
```

## 🎨 UI/UX Guidelines

### Design Principles

1. **Consistency** - Use predefined constants for colors, spacing, typography
2. **Simplicity** - Keep UI clean and uncluttered
3. **Feedback** - Always show loading states and user feedback
4. **Accessibility** - Support screen readers, proper contrast, scalable text

### Using Design System

**Colors:**
```dart
// ✅ Good
Container(color: AppColors.lightAccent)

// ❌ Bad
Container(color: Color(0xFFAEEAFB))
```

**Spacing:**
```dart
// ✅ Good
SizedBox(height: AppDimensions.spacingMedium)

// ❌ Bad
SizedBox(height: 16.0)
```

**Typography:**
```dart
// ✅ Good
Text('Title', style: AppTextStyles.h2)

// ❌ Bad
Text('Title', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))
```

### Widget Patterns

**Loading State:**
```dart
isLoading
  ? const LoadingIndicator()
  : YourContent()
```

**Empty State:**
```dart
items.isEmpty
  ? EmptyState(
      icon: Icons.list_alt,
      title: 'No items',
      subtitle: 'Add your first item',
    )
  : ItemsList(items: items)
```

**Error State:**
```dart
hasError
  ? ErrorWidget(
      message: error.toString(),
      onRetry: () => refetch(),
    )
  : YourContent()
```

## 🔄 State Management with Riverpod

### Provider Types

**Provider** - For read-only values:
```dart
final configProvider = Provider<Config>((ref) => Config());
```

**FutureProvider** - For async data:
```dart
final userProvider = FutureProvider<User>((ref) async {
  return await fetchUser();
});
```

**StreamProvider** - For streams:
```dart
final authStateProvider = StreamProvider<User?>((ref) {
  return authService.authStateChanges;
});
```

**StateNotifierProvider** - For mutable state:
```dart
final counterProvider = StateNotifierProvider<Counter, int>((ref) {
  return Counter();
});
```

### Consuming Providers

**In Widgets:**
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    
    return user.when(
      data: (user) => Text(user.name),
      loading: () => LoadingIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}
```

**Reading vs Watching:**
```dart
// Watch - rebuilds when value changes
final user = ref.watch(userProvider);

// Read - one-time read, no rebuild
final user = ref.read(userProvider);

// Read in callbacks/methods
onPressed: () {
  final notifier = ref.read(counterProvider.notifier);
  notifier.increment();
}
```

## 💾 Working with Data

### Repository Pattern

**Creating a Repository:**
```dart
class FeatureRepository {
  final SupabaseService _supabase;

  FeatureRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  Future<List<Item>> getItems() async {
    final response = await _supabase
        .from('items')
        .select()
        .order('created_at');
    
    return (response as List)
        .map((json) => Item.fromJson(json))
        .toList();
  }

  Future<Item> createItem(Map<String, dynamic> data) async {
    final response = await _supabase
        .from('items')
        .insert(data)
        .select()
        .single();
    
    return Item.fromJson(response);
  }
}
```

**Using Repository:**
```dart
final repoProvider = Provider<FeatureRepository>((ref) {
  return FeatureRepository();
});

final itemsProvider = FutureProvider<List<Item>>((ref) async {
  final repo = ref.watch(repoProvider);
  return repo.getItems();
});
```

### Models

**Creating a Model:**
```dart
class Item extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;

  const Item({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Item copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, name, createdAt];
}
```

## 🔒 Security Best Practices

### Authentication

```dart
// ✅ Good - Check authentication before operations
final user = SupabaseService.instance.currentUser;
if (user == null) throw Exception('User not authenticated');

// ✅ Good - Use secure storage for tokens
await secureStorage.write(key: 'token', value: token);

// ❌ Bad - Don't store credentials in plain text
await prefs.setString('password', password); // NEVER!
```

### RLS Policies

Always test that:
- Users can only access their own data
- Members can only see shared list data
- Owners have proper permissions

### Input Validation

```dart
// ✅ Good - Validate on client AND server
if (email.isEmpty || !email.contains('@')) {
  throw ValidationException('Invalid email');
}

// ✅ Good - Sanitize input
final sanitized = input.trim();

// ❌ Bad - Trust user input
final result = await db.query('SELECT * FROM users WHERE name = $input');
```

## 🧪 Testing

### Unit Tests

```dart
// test/core/utils/category_detector_test.dart
void main() {
  group('CategoryDetector', () {
    test('should detect Fruits & Vegetables category', () {
      final result = CategoryDetector.detectCategory('apple');
      expect(result, 'Fruits & Vegetables');
    });

    test('should default to Other for unknown items', () {
      final result = CategoryDetector.detectCategory('xyz123');
      expect(result, 'Other');
    });
  });
}
```

### Widget Tests

```dart
// test/presentation/widgets/list_card_test.dart
void main() {
  testWidgets('ListCard displays list name', (tester) async {
    final list = ShoppingListModel(
      id: '1',
      name: 'Test List',
      ownerId: '1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListCard(
            list: list,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Test List'), findsOneWidget);
  });
}
```

### Integration Tests

```dart
// integration_test/app_test.dart
void main() {
  testWidgets('Complete user flow', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Login
    await tester.enterText(find.byType(TextField).first, 'test@example.com');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    // Create list
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    // ... more steps
  });
}
```

## 🐛 Debugging

### Common Issues

**"Supabase has not been initialized"**
```dart
// Solution: Make sure initialize is called in main.dart
await SupabaseService.initialize();
```

**"RLS policy violation"**
```dart
// Solution: Check your RLS policies in Supabase
// Make sure user has permission to access the data
```

**"setState called after dispose"**
```dart
// Solution: Check mounted before setState
if (mounted) {
  setState(() { /* ... */ });
}
```

### Debugging Tools

**Print Debugging:**
```dart
print('DEBUG: User ID = ${user.id}');
debugPrint('Long message that needs wrapping...');
```

**Flutter DevTools:**
```bash
flutter run
# Press 'v' to open DevTools in browser
```

**Supabase Logs:**
- Dashboard → Logs → API Logs
- See all database queries and responses

## 📦 Adding New Features

### Checklist

1. **Plan the feature**
   - Define requirements
   - Design UI mockups
   - Plan database changes

2. **Update database if needed**
   - Add tables/columns in Supabase
   - Update RLS policies
   - Test queries

3. **Create data model**
   - Add model class in `lib/data/models/`
   - Implement fromJson/toJson
   - Add to exports

4. **Create repository**
   - Add repository in `lib/data/repositories/`
   - Implement CRUD methods
   - Add error handling

5. **Create provider**
   - Add provider in `lib/presentation/state/`
   - Implement state logic
   - Handle loading/error states

6. **Create UI**
   - Add screen in `lib/presentation/screens/`
   - Add widgets in `lib/presentation/widgets/`
   - Add to router

7. **Test**
   - Write unit tests
   - Write widget tests
   - Manual testing

8. **Document**
   - Add comments
   - Update README if needed
   - Update PROJECT_STATUS.md

## 🚀 Deployment

### Pre-deployment Checklist

- [ ] All tests passing
- [ ] No console errors/warnings
- [ ] Works on physical devices
- [ ] Works on iOS and Android
- [ ] Tested offline scenarios
- [ ] Proper error handling
- [ ] Loading states everywhere
- [ ] No hardcoded credentials
- [ ] Environment variables configured
- [ ] App icons created
- [ ] Screenshots ready
- [ ] Store listings written

### Build Commands

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle (Play Store):**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 📞 Getting Help

### Documentation Links

- [Flutter Docs](https://flutter.dev/docs)
- [Riverpod Docs](https://riverpod.dev)
- [Supabase Docs](https://supabase.com/docs)
- [Go Router Docs](https://pub.dev/packages/go_router)

### Project Documentation

- `README.md` - Overview and setup
- `QUICKSTART.md` - 10-minute setup
- `SETUP_GUIDE.md` - Detailed setup
- `PROJECT_STATUS.md` - Current progress
- `NEXT_STEPS.md` - What to build next
- `IMPLEMENTATION_SUMMARY.md` - What's been built

### Community

- Flutter Discord
- Flutter Reddit
- Stack Overflow (tag: flutter)
- Supabase Discord

---

**Happy Coding! 🎉**

This guide will be updated as the project evolves. Contributions welcome!
