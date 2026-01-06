# Service Organization Guide

## 📊 Current State
- **Total Services**: 33 files
- **Status**: All in `lib/data/services/` (flat structure)

## 🎯 Recommended Structure (Future Refactoring)

### Recipe Services
```
lib/data/services/recipe/
├── recipe_service.dart                    # CRUD operations
├── recipe_rating_service.dart             # Ratings & reviews
├── recipe_labeling_service.dart           # AI labeling
├── recipe_batch_labeling_utility.dart     # Batch processing
└── ingredient_substitution_service.dart    # Diet/allergy handling
```

### AI Services
```
lib/data/services/ai/
├── gemini_categorization_service.dart     # Item categorization
├── ai_ingredient_analyzer.dart            # Ingredient analysis
├── ai_recipe_labeling_service.dart        # Recipe AI labeling
├── product_classifier_service.dart        # Product classification
└── ml_recommendation_service.dart         # ML recommendations
```

### Shopping Services
```
lib/data/services/shopping/
├── deals_database_service.dart            # Deals storage
├── deal_extractor_service.dart            # Extract deals from flyers
├── product_matching_service.dart          # Match products to deals
├── product_knowledge_base.dart            # Product database
└── purchase_tracking_service.dart         # Track purchases
```

### User Services
```
lib/data/services/user/
├── user_service.dart                      # User CRUD
├── subscription_service.dart              # IAP & premium
├── profile_picture_service.dart           # Profile images
└── native_oauth_service.dart              # Google OAuth
```

### Utility Services
```
lib/data/services/utility/
├── supabase_service.dart                  # Supabase client
├── analytics_service.dart                 # Firebase Analytics
├── recommendation_service.dart            # General recommendations
├── ocr_service.dart                       # OCR (currently disabled)
├── tesseract_setup.dart                   # OCR setup
├── local_pdf_loader_service.dart          # PDF handling
└── store_flyer_service.dart               # Flyer management
```

## 📝 Service Inventory

### Core Services (Use Frequently)
| Service | Purpose | Singleton | Used In |
|---------|---------|-----------|---------|
| `SupabaseService` | Database & auth | ✅ | Everywhere |
| `RecipeService` | Recipe CRUD | ✅ | Recipes screen |
| `ItemRepository` | List items | ✅ | Lists |
| `ListRepository` | Shopping lists | ✅ | Lists |
| `SubscriptionService` | Premium features | ✅ | Paywall |

### AI Services
| Service | Purpose | API | Cost |
|---------|---------|-----|------|
| `GeminiCategorizationService` | Categorize items | Gemini 1.5-flash | Low (cached) |
| `AIIngredientAnalyzer` | Ingredient analysis | Gemini | Medium |
| `AIRecipeLabelingService` | Label recipes | Gemini | Low |
| `ProductClassifierService` | Fallback categorization | Local | Free |

### Shopping Services
| Service | Purpose | Database |
|---------|---------|----------|
| `DealsDatabaseService` | Store deals | Supabase |
| `DealExtractorService` | Extract from PDFs | - |
| `ProductMatchingService` | Match products | Local |
| `PurchaseTrackingService` | Track history | Supabase |

### Utility Services
| Service | Purpose | Notes |
|---------|---------|-------|
| `AnalyticsService` | Track events | iOS/Android only |
| `ProfilePictureService` | User avatars | Supabase storage |
| `OCRService` | Text recognition | Disabled (macOS issues) |
| `RecommendationService` | Suggestions | ML-based |

## 🚀 Using Services

### Via Service Locator (Recommended)
```dart
import 'package:shoply/core/services/service_locator.dart';

// Clean and discoverable
final recipe = await Services.recipes.getRecipeById(id);
final items = await Services.items.getItemsForList(listId);
```

### Direct Import (Legacy)
```dart
import 'package:shoply/data/services/recipe_service.dart';

// Works but less organized
final service = RecipeService.instance;
```

## 📋 Refactoring Checklist (Future Work)

- [ ] Create folder structure
- [ ] Move services to folders
- [ ] Update all imports across codebase (~200 files)
- [ ] Test that app still builds
- [ ] Update Service Locator imports
- [ ] Update this guide

## 💡 Quick Reference

**Need to add items?** → `Services.items` or `ItemRepository.instance`  
**Need recipes?** → `Services.recipes` or `RecipeService.instance`  
**Need AI categorization?** → `Services.aiCategorization`  
**Need subscription check?** → `Services.subscriptions.isPremium`  
**Need database?** → `Services.supabase.client`

## 🔍 Finding Services

```bash
# List all services
ls lib/data/services/

# Find where a service is used
grep -r "RecipeService" lib --include="*.dart"

# Find a specific function
grep -r "createRecipe" lib --include="*.dart"
```

## ⚠️ Known Issues

### Disabled Services (Don't Use)
- `OCRService` - macOS compatibility issues
- `TesseractSetup` - Disabled with OCR

### Partially Working
- `AnalyticsService` - iOS/Android only (not simulator)
- `NativeOAuthService` - iOS only

### Deprecated
- Old deal scanner features (see `IMPLEMENTATION_STATUS.md`)

---

**Note**: Moving services into folders is a future improvement. Current flat structure works but can be harder to navigate. Use the Service Locator for better organization in your code!
