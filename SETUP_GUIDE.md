# Shoply - Developer Setup Guide

## 🚀 Quick Start

### Prerequisites
- **Flutter**: 3.5+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- **Xcode**: 15+ (for iOS development)
- **Android Studio**: Latest (for Android development)
- **Git**: Latest version

### Initial Setup

1. **Clone the repository**
```bash
git clone https://github.com/CyrusJannis/shoply.git
cd shoply
```

2. **Install dependencies**
```bash
flutter pub get
cd ios && pod install && cd ..
```

3. **Set up environment**
- All API keys are already in `lib/core/config/env.dart`
- Supabase is pre-configured
- No additional setup needed!

4. **Run the app**

**For iOS Simulator:**
```bash
# Build for simulator
flutter build ios --simulator --debug

# Install on simulator (replace with your simulator ID)
xcrun simctl list  # Find your simulator ID
xcrun simctl install <SIMULATOR_ID> build/ios/iphonesimulator/Runner.app
xcrun simctl launch <SIMULATOR_ID> com.dominik.shoply
```

**For Android:**
```bash
flutter run
```

## 📁 Project Structure

```
lib/
├── core/               # Core functionality
│   ├── config/        # Environment & configuration
│   ├── constants/     # App constants (colors, text styles, etc.)
│   ├── localization/  # i18n translations (EN/DE)
│   ├── services/      # Service locator
│   ├── theme/         # App theming
│   └── utils/         # Utility functions
│
├── data/              # Data layer
│   ├── models/        # Data models (Recipe, User, List, etc.)
│   ├── repositories/  # Data access layer (ItemRepository, ListRepository)
│   └── services/      # Business logic services
│       ├── Recipe services (recipe_service.dart, recipe_rating_service.dart)
│       ├── AI services (ai_ingredient_analyzer.dart, gemini_*)
│       ├── User services (user_service.dart, subscription_service.dart)
│       └── Utility services (analytics_service.dart, supabase_service.dart)
│
├── presentation/      # UI layer
│   ├── screens/       # Full-page screens
│   │   ├── home/      # Home dashboard
│   │   ├── lists/     # Shopping lists
│   │   ├── recipes/   # Recipe browsing & creation
│   │   ├── ai/        # AI features dashboard
│   │   └── profile/   # User profile & settings
│   ├── widgets/       # Reusable UI components
│   ├── state/         # Riverpod providers
│   └── routes/        # Navigation (app_router.dart)
│
└── main.dart          # App entry point
```

## 🎯 Key Services

### Service Locator (NEW!)
All services are now accessible via the `Services` class:

```dart
import 'package:shoply/core/services/service_locator.dart';

// Access services anywhere
Services.recipes.createRecipe(...);
Services.items.addItem(...);
Services.supabase.client;
```

### Main Services:
- **RecipeService**: CRUD for recipes
- **ItemRepository**: Shopping list items
- **ListRepository**: Shopping lists
- **SubscriptionService**: Premium features & IAP
- **AIIngredientAnalyzer**: AI-powered ingredient analysis
- **GeminiCategorizationService**: Smart item categorization

## 🔑 Important Files

### Configuration
- `lib/core/config/env.dart` - API keys (Supabase, Gemini)
- `lib/core/constants/` - Colors, text styles, dimensions
- `lib/core/localization/` - Translations (EN/DE)

### State Management (Riverpod)
- `lib/presentation/state/auth_provider.dart` - User authentication
- `lib/presentation/state/lists_provider.dart` - Shopping lists
- `lib/presentation/state/items_provider.dart` - List items

### Navigation
- `lib/routes/app_router.dart` - All app routes (90+ routes)

## 🛠️ Common Tasks

### Adding a New Feature

1. **Create the model** (if needed)
```dart
// lib/data/models/your_model.dart
class YourModel {
  final String id;
  final String name;
  // ...
}
```

2. **Create the service**
```dart
// lib/data/services/your_service.dart
class YourService {
  static final YourService instance = YourService._internal();
  YourService._internal();
  
  Future<void> doSomething() async {
    // Implementation
  }
}
```

3. **Add to Service Locator**
```dart
// lib/core/services/service_locator.dart
static YourService get yourService => YourService.instance;
```

4. **Create the UI**
```dart
// lib/presentation/screens/your_feature/your_screen.dart
```

### Running Tests
```bash
flutter test
```

### Debugging

**View iOS Simulator Logs:**
```bash
xcrun simctl spawn <SIMULATOR_ID> log stream --predicate 'processImagePath contains "Runner"' 2>&1 | grep -E "YOUR_TAG"
```

**Common log tags:**
- `[RECIPE_SERVICE]` - Recipe operations
- `[ADD_RECIPE]` - Recipe creation
- `[SUBSTITUTION]` - Ingredient substitution
- `[CATEGORIZATION]` - AI categorization

## 🐛 Troubleshooting

### iOS Build Issues
1. **Clean build**
```bash
flutter clean
cd ios && pod deintegrate && pod install && cd ..
flutter pub get
```

2. **Simulator codesigning errors**
- Already fixed! We use identity '-' for simulator builds

### Common Errors

**"No such module 'Flutter'"**
```bash
cd ios && pod install && cd ..
```

**"Supabase not initialized"**
- Check `lib/core/config/env.dart` has correct Supabase URL/keys

**"Recipe not found"**
- Database query was recently fixed (recipe_likes → recipe_ratings)
- Should work now!

## 📚 Key Features

### Implemented ✅
- Shopping lists with real-time sync
- Recipe browsing & creation
- AI-powered ingredient categorization
- Diet preference & allergy detection
- Premium subscription (iOS only)
- Multi-language support (EN/DE)
- Social list sharing

### Partially Implemented ⚠️
- Android IAP (not implemented)
- OCR/Scanner features (disabled)

## 🎨 Styling

### Theme
- Uses Material 3
- Light/Dark mode support
- `adaptive_platform_ui` for iOS 26 Liquid Glass styling

### Colors
```dart
import 'package:shoply/core/constants/app_colors.dart';

AppColors.lightAccent
AppColors.premiumGold
```

### Text Styles
```dart
import 'package:shoply/core/constants/app_text_styles.dart';

AppTextStyles.h1
AppTextStyles.bodyMedium
```

## 🔐 Environment Variables

All secrets are in `lib/core/config/env.dart`:
- Supabase URL & keys
- Gemini API key
- Google OAuth client IDs

**⚠️ DO NOT commit changes to this file with real keys exposed in logs!**

## 📦 Dependencies

### Core
- `flutter_riverpod`: State management
- `go_router`: Navigation
- `supabase_flutter`: Backend

### UI
- `adaptive_platform_ui`: iOS 26 styling
- `cached_network_image`: Image caching
- `shimmer`: Loading effects

### AI
- `google_generative_ai`: Gemini AI

### Monetization
- `in_app_purchase`: iOS subscriptions

## 🚢 Deployment

### iOS TestFlight
See `READY_FOR_TESTFLIGHT.md` for manual setup required

### Android (Pending)
- IAP not implemented yet

## 💡 Tips for New Developers

1. **Use Service Locator**: Access services via `Services.serviceName`
2. **Check existing code**: Many features already implemented
3. **Follow conventions**: 
   - Models in `lib/data/models/`
   - Services in `lib/data/services/`
   - Screens in `lib/presentation/screens/`
4. **Use Riverpod**: For state management
5. **Add logging**: Use print statements with tags like `[YOUR_FEATURE]`

## 📞 Getting Help

- Check `IMPLEMENTATION_STATUS.md` for feature status
- Review `.github/copilot-instructions.md` for architecture details
- Check existing code for examples
- iOS build issues? See `DEBUG_INSTRUCTIONS.md`

## 🎯 Current Status

**Last Updated**: November 2025

**Recent Improvements**:
- ✅ Recipe creation working (image picker, validation, navigation)
- ✅ Ingredient diet detection (English + German)
- ✅ Database query fixes
- ✅ Deleted 22 duplicate files (~2,000 lines cleaned)
- ✅ Added comprehensive logging

**Known Issues**:
- Android IAP not implemented
- OCR features disabled (compatibility issues)

---

**Ready to code?** Start with `flutter run` and explore the app! 🚀
