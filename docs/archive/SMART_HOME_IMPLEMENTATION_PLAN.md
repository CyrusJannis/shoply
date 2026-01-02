# Smart Shopping List Home - Implementation Plan

## Overview
Transform the Home page into a smart shopping list that auto-opens the last active list and provides AI-powered recommendations based on purchase history and user behavior.

## Current State Analysis

### Existing Structure
- **Home Screen**: Shows list overview, shopping history
- **Lists Tab**: Removed from navigation (Prompt 1)
- **List Detail Screen**: Shows individual shopping list items
- **Shopping History**: Tracks completed shopping trips with items

### Data Models
- `ShoppingListModel`: List metadata (id, name, itemCount, etc.)
- `ShoppingItemModel`: Individual items (name, quantity, category, isChecked, etc.)
- `ShoppingHistory`: Completed trips with items

## Implementation Requirements

### 1. Purchase Frequency Tracking

#### New Data Model: `ItemPurchaseStats`
```dart
class ItemPurchaseStats {
  final String itemName;
  final int purchaseCount;          // Total times purchased
  final DateTime firstPurchase;      // First time bought
  final DateTime lastPurchase;       // Most recent purchase
  final List<DateTime> purchaseDates; // All purchase dates
  final double averageDaysBetween;   // Average days between purchases
  final String? preferredCategory;   // Most common category
  final double? preferredQuantity;   // Most common quantity
}
```

#### Database Schema
```sql
CREATE TABLE item_purchase_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  item_name TEXT NOT NULL,
  purchase_count INTEGER DEFAULT 1,
  first_purchase TIMESTAMP NOT NULL,
  last_purchase TIMESTAMP NOT NULL,
  purchase_dates TIMESTAMP[] DEFAULT '{}',
  average_days_between DOUBLE PRECISION,
  preferred_category TEXT,
  preferred_quantity DOUBLE PRECISION,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, item_name)
);

CREATE INDEX idx_purchase_stats_user ON item_purchase_stats(user_id);
CREATE INDEX idx_purchase_stats_last_purchase ON item_purchase_stats(last_purchase);
```

### 2. Smart Recommendation Algorithm

#### Scoring System
Each item gets a recommendation score based on:

**Frequency Score (0-40 points)**
- 10+ purchases: 40 points
- 7-9 purchases: 30 points
- 4-6 purchases: 20 points
- 2-3 purchases: 10 points
- 1 purchase: 5 points

**Recency Score (0-30 points)**
- Based on days since last purchase vs average interval
- Overdue (>1.2x average): 30 points
- Due soon (0.8-1.2x average): 25 points
- Recently bought (<0.5x average): 5 points
- Never bought: 0 points

**Preference Score (0-20 points)**
- Marked as favorite: 20 points
- Frequently selected category: 10 points
- Consistent quantity: 5 points

**Timing Score (0-10 points)**
- Cyclical pattern detected: 10 points
- Seasonal item in season: 8 points
- No pattern: 0 points

**Total Score: 0-100 points**

#### Algorithm Logic
```dart
double calculateRecommendationScore(ItemPurchaseStats stats) {
  double score = 0.0;
  
  // Frequency Score (0-40)
  if (stats.purchaseCount >= 10) score += 40;
  else if (stats.purchaseCount >= 7) score += 30;
  else if (stats.purchaseCount >= 4) score += 20;
  else if (stats.purchaseCount >= 2) score += 10;
  else score += 5;
  
  // Recency Score (0-30)
  final daysSinceLastPurchase = DateTime.now().difference(stats.lastPurchase).inDays;
  final avgDays = stats.averageDaysBetween;
  
  if (avgDays > 0) {
    final ratio = daysSinceLastPurchase / avgDays;
    if (ratio > 1.2) score += 30;  // Overdue
    else if (ratio >= 0.8) score += 25;  // Due soon
    else if (ratio < 0.5) score += 5;  // Recently bought
  }
  
  // Preference Score (0-20)
  if (stats.isFavorite) score += 20;
  else if (stats.preferredCategory != null) score += 10;
  
  // Timing Score (0-10)
  if (stats.hasCyclicalPattern) score += 10;
  
  return score;
}
```

### 3. Auto-Open Last Active List

#### Last Active List Tracking
Add to `ShoppingListModel`:
```dart
DateTime? lastAccessedAt;
```

#### Database Update
```sql
ALTER TABLE shopping_lists ADD COLUMN last_accessed_at TIMESTAMP;
CREATE INDEX idx_lists_last_accessed ON shopping_lists(last_accessed_at DESC);
```

#### Home Screen Logic
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  // Get last accessed list
  final lastListId = ref.watch(lastAccessedListProvider);
  
  // Auto-navigate to last list on first load
  useEffect(() {
    if (lastListId != null) {
      Future.microtask(() => context.push('/list/$lastListId'));
    }
    return null;
  }, []);
  
  // Show lists overview if no last list
  return ListsOverviewScreen();
}
```

### 4. Recommendation UI Component

#### Location
Display at **top** of shopping list (above items)

#### Design
```
┌─────────────────────────────────────┐
│ 🎯 Suggested Items                  │
│                                     │
│ ┌─────────────────────────────────┐│
│ │ 🥛 Milk              [+] Add    ││
│ │ Last bought 6 days ago          ││
│ └─────────────────────────────────┘│
│                                     │
│ ┌─────────────────────────────────┐│
│ │ 🍞 Bread             [+] Add    ││
│ │ You buy this weekly             ││
│ └─────────────────────────────────┘│
│                                     │
│ [Show More] (if >5 recommendations) │
└─────────────────────────────────────┘
```

#### Features
- Collapsible section
- One-tap add to list
- Shows reason for recommendation
- Limit to top 5-8 items
- Dismissible recommendations
- Refresh button

### 5. Lists Overview Screen

Replace old Home content with:

#### Sections
1. **Active Lists** (sorted by last accessed)
2. **Shopping History** (recent completed trips)
3. **Create New List** button

#### Navigation
- Accessible via back button from list detail
- Or "View All Lists" button in app bar

## Implementation Steps

### Phase 1: Data Layer (Priority: High)
1. ✅ Create `ItemPurchaseStats` model
2. ✅ Create database migration for `item_purchase_stats` table
3. ✅ Create `PurchaseTrackingService` to manage stats
4. ✅ Update `ShoppingHistoryService` to track purchase stats
5. ✅ Add `lastAccessedAt` to `ShoppingListModel`

### Phase 2: Recommendation Engine (Priority: High)
1. ✅ Create `RecommendationService` with scoring algorithm
2. ✅ Implement frequency calculation
3. ✅ Implement recency scoring
4. ✅ Implement preference detection
5. ✅ Create recommendation provider

### Phase 3: UI Components (Priority: High)
1. ✅ Create `RecommendationCard` widget
2. ✅ Create `RecommendationsSection` widget
3. ✅ Integrate into `ListDetailScreen`
4. ✅ Add collapse/expand functionality
5. ✅ Implement one-tap add to list

### Phase 4: Auto-Open Logic (Priority: High)
1. ✅ Create `lastAccessedListProvider`
2. ✅ Update list access tracking
3. ✅ Modify Home screen to auto-navigate
4. ✅ Handle no-list case

### Phase 5: Lists Overview (Priority: Medium)
1. ✅ Create `ListsOverviewScreen`
2. ✅ Move Home content to overview
3. ✅ Add navigation from list detail
4. ✅ Update routing

### Phase 6: Polish & Optimization (Priority: Low)
1. ⏳ Add loading states
2. ⏳ Implement caching
3. ⏳ Add analytics
4. ⏳ Performance optimization
5. ⏳ Error handling

## File Structure

```
lib/
├── data/
│   ├── models/
│   │   ├── item_purchase_stats.dart (NEW)
│   │   └── recommendation_item.dart (NEW)
│   │
│   └── services/
│       ├── purchase_tracking_service.dart (NEW)
│       ├── recommendation_service.dart (NEW)
│       └── shopping_history_service.dart (MODIFY)
│
├── presentation/
│   ├── screens/
│   │   ├── home/
│   │   │   ├── home_screen.dart (MODIFY - auto-open logic)
│   │   │   └── lists_overview_screen.dart (NEW)
│   │   │
│   │   └── lists/
│   │       └── list_detail_screen.dart (MODIFY - add recommendations)
│   │
│   ├── state/
│   │   ├── last_accessed_list_provider.dart (NEW)
│   │   └── recommendations_provider.dart (NEW)
│   │
│   └── widgets/
│       └── recommendations/
│           ├── recommendation_card.dart (NEW)
│           └── recommendations_section.dart (NEW)
│
└── routes/
    └── app_router.dart (MODIFY - update home routing)
```

## Database Migrations

### Migration 1: Item Purchase Stats
```sql
-- Create item_purchase_stats table
CREATE TABLE item_purchase_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES auth.users(id) NOT NULL,
  item_name TEXT NOT NULL,
  purchase_count INTEGER DEFAULT 1,
  first_purchase TIMESTAMP NOT NULL,
  last_purchase TIMESTAMP NOT NULL,
  purchase_dates TIMESTAMP[] DEFAULT '{}',
  average_days_between DOUBLE PRECISION,
  preferred_category TEXT,
  preferred_quantity DOUBLE PRECISION,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, item_name)
);

CREATE INDEX idx_purchase_stats_user ON item_purchase_stats(user_id);
CREATE INDEX idx_purchase_stats_last_purchase ON item_purchase_stats(last_purchase);
CREATE INDEX idx_purchase_stats_count ON item_purchase_stats(purchase_count DESC);
```

### Migration 2: Last Accessed Tracking
```sql
-- Add last_accessed_at to shopping_lists
ALTER TABLE shopping_lists ADD COLUMN IF NOT EXISTS last_accessed_at TIMESTAMP;

-- Create index for sorting by last accessed
CREATE INDEX IF NOT EXISTS idx_lists_last_accessed 
ON shopping_lists(user_id, last_accessed_at DESC NULLS LAST);

-- Update existing lists with current timestamp
UPDATE shopping_lists 
SET last_accessed_at = updated_at 
WHERE last_accessed_at IS NULL;
```

## Testing Checklist

### Purchase Tracking
- [ ] Stats created when completing shopping trip
- [ ] Purchase count increments correctly
- [ ] Average days calculated accurately
- [ ] Preferred category detected
- [ ] Preferred quantity tracked

### Recommendations
- [ ] Top 5-8 items displayed
- [ ] Scores calculated correctly
- [ ] Frequently bought items prioritized
- [ ] Overdue items highlighted
- [ ] One-tap add works
- [ ] Recommendations refresh after add
- [ ] Empty state when no recommendations

### Auto-Open
- [ ] Last accessed list opens on app launch
- [ ] Lists overview shown if no last list
- [ ] Last accessed updates when opening list
- [ ] Sorting by last accessed works

### Navigation
- [ ] Back button goes to lists overview
- [ ] "View All Lists" accessible
- [ ] Lists overview shows all lists
- [ ] Shopping history accessible

## Success Metrics

1. **User Engagement**
   - Time to first action reduced
   - Number of list opens increased
   - Recommendation acceptance rate >30%

2. **Efficiency**
   - Items added per session increased
   - Time to complete list reduced
   - Repeat purchases identified >80%

3. **Satisfaction**
   - User feedback positive
   - Feature usage >70% of users
   - Recommendation relevance >4/5 rating

## Future Enhancements

1. **Machine Learning**
   - Predict purchase timing more accurately
   - Detect seasonal patterns
   - Personalize scoring weights

2. **Social Features**
   - Household purchase patterns
   - Shared recommendations
   - Family favorites

3. **Advanced Recommendations**
   - Recipe-based suggestions
   - Complementary items
   - Deal alerts
   - Store-specific recommendations

4. **Smart Notifications**
   - "Time to buy milk" reminders
   - Low stock alerts
   - Shopping trip suggestions

## Notes

- Purchase stats are user-specific (not shared)
- Recommendations update in real-time
- Algorithm can be tuned based on user feedback
- Privacy: All data stays in user's account
- Performance: Recommendations cached for 1 hour
- Fallback: Show popular items if no history

## Summary

This implementation transforms the Home experience from a static list overview to an intelligent shopping assistant that:
1. **Saves time** - Auto-opens your active list
2. **Reduces forgetting** - Suggests items you need
3. **Learns patterns** - Gets smarter over time
4. **Stays simple** - One-tap to add suggestions

The smart recommendation system uses purchase frequency, timing, and preferences to surface the right items at the right time, making grocery shopping faster and more efficient.
