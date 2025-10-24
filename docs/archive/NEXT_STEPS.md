# 🎯 Next Steps - Development Roadmap

This guide outlines the exact steps to continue developing Shoply, prioritized by importance and dependencies.

## 🚀 Phase 1: Essential Features (Week 1-2)

### 1. Implement Real-time Sync (Priority: CRITICAL)

**Why:** This is the core differentiator for a shared shopping list app.

**What to do:**

1. **Add Realtime Subscription to List Detail Screen**

Edit `lib/presentation/screens/lists/list_detail_screen.dart`:

```dart
@override
void initState() {
  super.initState();
  
  // Subscribe to realtime changes
  _subscription = SupabaseService.instance.client
    .channel('shopping_items:list_id=eq.${widget.listId}')
    .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'shopping_items',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'list_id',
        value: widget.listId,
      ),
      callback: (payload) {
        // Refresh items when changes occur
        ref.read(itemsNotifierProvider(widget.listId).notifier).loadItems();
      },
    )
    .subscribe();
}

@override
void dispose() {
  _subscription?.unsubscribe();
  super.dispose();
}
```

2. **Enable Realtime in Supabase**
   - Go to Database → Replication
   - Enable for `shopping_items` table
   - Enable for `shopping_lists` table

3. **Test:**
   - Open same list on two devices
   - Add item on device A
   - Should appear on device B instantly

**Files to modify:**
- `lib/presentation/screens/lists/list_detail_screen.dart`

**Time estimate:** 2-3 hours

---

### 2. Build List Sharing UI (Priority: HIGH)

**Why:** Users need to share lists with family/friends.

**What to do:**

1. **Create Share Screen**

Create `lib/presentation/screens/lists/share_list_screen.dart`:

```dart
class ShareListScreen extends StatelessWidget {
  final String listId;
  final String listName;
  
  // UI with:
  // - Display 6-digit code (generate if not exists)
  // - QR code (use qr_flutter package)
  // - Share buttons (WhatsApp, Email, SMS)
  // - Copy code button
}
```

2. **Create Join Screen**

Create `lib/presentation/screens/lists/join_list_screen.dart`:

```dart
class JoinListScreen extends StatelessWidget {
  // UI with:
  // - Text field to enter 6-digit code
  // - "Scan QR Code" button
  // - "Join List" button
  // - Use mobile_scanner for QR scanning
}
```

3. **Update Lists Screen**
   - Add "Join List" button
   - Add share icon to list cards

4. **Test:**
   - Create list on device A
   - Generate share code
   - Join list on device B using code
   - Verify both users can see and edit

**Files to create:**
- `lib/presentation/screens/lists/share_list_screen.dart`
- `lib/presentation/screens/lists/join_list_screen.dart`
- `lib/presentation/widgets/qr_code_widget.dart`

**Time estimate:** 4-6 hours

---

### 3. Implement Shopping History (Priority: HIGH)

**Why:** Users want to track what they bought and reuse lists.

**What to do:**

1. **Create History Repository**

Create `lib/data/repositories/history_repository.dart`:

```dart
class HistoryRepository {
  Future<void> completeShoppingTrip(String listId) async {
    // Get all items from list
    // Create snapshot in shopping_history table
    // Update purchase_frequency for checked items
    // Optionally clear checked items
  }
  
  Future<List<HistoryModel>> getUserHistory() async {
    // Get all history entries for user
  }
}
```

2. **Add "Complete Trip" Button**

In `lib/presentation/screens/lists/list_detail_screen.dart`:
- Add floating action button for "Complete Shopping"
- Show confirmation dialog
- Call repository to save history
- Navigate to history screen

3. **Create History Screen**

Create `lib/presentation/screens/home/history_screen.dart`:
- List all past shopping trips
- Show date, list name, item count
- Tap to view details
- "Recreate List" button

4. **Update Home Screen**
   - Connect history widget to actual data
   - Show last 3 trips

**Files to create:**
- `lib/data/repositories/history_repository.dart`
- `lib/presentation/screens/home/history_screen.dart`
- `lib/presentation/state/history_provider.dart`

**Time estimate:** 4-5 hours

---

### 4. Smart Recommendations (Priority: MEDIUM)

**Why:** Helps users remember commonly purchased items.

**What to do:**

1. **Create Recommendation Service**

Create `lib/data/services/recommendation_service.dart`:

```dart
class RecommendationService {
  Future<List<String>> getRecommendations(String userId) async {
    // Query purchase_frequency table
    // Calculate which items are likely needed
    // Formula: days_since_last > avg_days * 0.9
    // Return top 5 items
  }
}
```

2. **Update Home Screen**
   - Fetch recommendations on load
   - Display in cards
   - Add "Add to List" button for each item

3. **Track Purchase Frequency**
   - In history repository, update frequency when completing trip
   - Calculate average days between purchases

**Files to create:**
- `lib/data/services/recommendation_service.dart`

**Files to modify:**
- `lib/presentation/screens/home/home_screen.dart`
- `lib/data/repositories/history_repository.dart`

**Time estimate:** 3-4 hours

---

## 🎨 Phase 2: User Experience (Week 3)

### 5. Onboarding Flow

**Files to create:**
- `lib/presentation/screens/onboarding/onboarding_flow.dart`
- `lib/presentation/screens/onboarding/welcome_screen.dart`
- `lib/presentation/screens/onboarding/profile_setup_screen.dart`
- `lib/presentation/screens/onboarding/diet_preferences_screen.dart`

**Features:**
- Welcome screen with app preview
- Set display name
- Choose diet preferences
- Enable notifications prompt
- Mark onboarding as complete in database

**Time estimate:** 4-5 hours

---

### 6. Profile Settings

**What to do:**
- Make all settings functional
- Edit display name
- Edit diet preferences
- Change theme (light/dark/system)
- Language selection (German/English)
- Store preferences in database

**Files to modify:**
- `lib/presentation/screens/profile/profile_screen.dart`

**Time estimate:** 3-4 hours

---

### 7. Sign Up Screen

**What to do:**

Create `lib/presentation/screens/auth/signup_screen.dart`:
- Email & password fields
- Display name field
- Password confirmation
- Terms acceptance checkbox
- Call `authService.signUp()`
- Navigate to onboarding

**Time estimate:** 2-3 hours

---

## 📱 Phase 3: Advanced Features (Week 4)

### 8. Barcode Scanner

**What to do:**

1. Install and configure `mobile_scanner`
2. Create scanner screen
3. Integrate Open Food Facts API
4. Pre-fill item form with scanned data

**Files to create:**
- `lib/presentation/screens/scanner/barcode_scanner_screen.dart`
- `lib/data/services/product_lookup_service.dart`

**Time estimate:** 4-5 hours

---

### 9. Recipe System

**What to do:**

1. Seed database with sample recipes
2. Build recipe list screen
3. Build recipe detail screen
4. Implement "Add to List" for ingredients
5. Servings adjustment logic

**Files to create:**
- `lib/presentation/screens/recipes/recipe_detail_screen.dart`
- `lib/data/repositories/recipe_repository.dart`
- `lib/presentation/state/recipes_provider.dart`

**Time estimate:** 6-8 hours

---

### 10. Push Notifications

**What to do:**

1. Set up Firebase Cloud Messaging
2. Create notification service
3. Request notification permissions
4. Handle foreground/background notifications
5. Create Supabase Edge Function to send notifications

**Files to create:**
- `lib/data/services/notification_service.dart`
- `supabase/functions/send-notification/index.ts`

**Time estimate:** 5-6 hours

---

## 💾 Phase 4: Offline & Polish (Week 5)

### 11. Offline Support

**What to do:**

1. Set up Hive boxes for local storage
2. Implement sync service
3. Queue operations when offline
4. Sync when connection restored
5. Handle conflicts

**Files to create:**
- `lib/data/local/local_database.dart`
- `lib/data/services/sync_service.dart`

**Time estimate:** 8-10 hours

---

### 12. Testing & Bug Fixes

**What to do:**

1. Write unit tests for utilities
2. Write widget tests for screens
3. Integration tests for critical flows
4. Manual testing on multiple devices
5. Fix all bugs

**Time estimate:** 10-15 hours

---

### 13. App Store Preparation

**What to do:**

1. Create app icons
2. Create screenshots
3. Write app descriptions
4. Set up signing certificates
5. Test builds
6. Submit to stores

**Time estimate:** 5-8 hours

---

## 📊 Tracking Your Progress

Create a simple checklist:

```markdown
## Development Checklist

### Phase 1: Essential
- [ ] Real-time sync
- [ ] List sharing
- [ ] Shopping history
- [ ] Smart recommendations

### Phase 2: UX
- [ ] Onboarding flow
- [ ] Profile settings
- [ ] Sign up screen

### Phase 3: Advanced
- [ ] Barcode scanner
- [ ] Recipe system
- [ ] Push notifications

### Phase 4: Polish
- [ ] Offline support
- [ ] Testing
- [ ] App store prep
```

---

## 🛠️ Development Tips

### Daily Workflow

1. **Pick one feature** from the list above
2. **Read the description** and understand requirements
3. **Create the files** needed
4. **Implement the feature** following existing patterns
5. **Test thoroughly** on at least one device
6. **Commit your changes** with clear message
7. **Update the checklist**

### Code Quality

- Follow existing code style
- Use proper error handling
- Add comments for complex logic
- Keep functions small and focused
- Reuse existing widgets and utilities

### Testing Strategy

- Test on both Android and iOS
- Test with slow network
- Test offline scenarios
- Test edge cases (empty lists, long names, etc.)
- Get feedback from real users

### Getting Help

If you get stuck:
1. Check Flutter documentation
2. Check Supabase documentation
3. Search Stack Overflow
4. Review similar code in the project
5. Break the problem into smaller pieces

---

## 🎯 Success Metrics

You'll know you're done when:

- [ ] All Phase 1 features work
- [ ] App works offline
- [ ] Real-time sync is smooth
- [ ] No critical bugs
- [ ] App is published to stores
- [ ] Users are actively using it

---

## 📞 Quick Reference

**Important Files:**
- Main entry: `lib/main.dart`
- Navigation: `lib/routes/app_router.dart`
- Theme: `lib/core/theme/app_theme.dart`
- Supabase: `lib/data/services/supabase_service.dart`

**Common Tasks:**
- Add new screen: Create in `lib/presentation/screens/`
- Add new widget: Create in `lib/presentation/widgets/`
- Add new model: Create in `lib/data/models/`
- Add new repository: Create in `lib/data/repositories/`

**Commands:**
```bash
flutter run              # Run app
flutter test             # Run tests
flutter clean            # Clean build files
flutter pub get          # Install dependencies
flutter doctor           # Check setup
```

---

**Good luck! 🚀**

Start with real-time sync, then sharing, then history. These three features will make your app competitive and useful. Everything else is bonus!
