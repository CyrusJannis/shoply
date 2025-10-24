# Navigation Migration Notes

## Overview
This document tracks references to removed routes that need to be updated as part of the Lists integration into Home screen.

## Removed Routes
- `/lists` - Lists overview page
- `/lists/:listId` - Individual list detail pages
- `/offers` - Stores/Offers page

## Files with References to Removed Routes

### 1. Home Screen
**File:** `lib/presentation/screens/home/home_screen.dart`

**References:**
- Line 10: `import 'package:shoply/presentation/state/lists_provider.dart'` - ✅ Still needed
- Line 119: `context.go('/lists?create=true')` - ⚠️ Needs update
- Line 185: `context.push('/lists/${list.id}?name=...')` - ⚠️ Needs update

**Action Required:**
These navigation calls currently try to navigate to the removed `/lists` route. Since Lists functionality is being integrated into Home, these need to be updated to either:
1. Show a modal/dialog for list creation instead of navigation
2. Navigate to a new in-app list detail view
3. Use bottom sheets or overlays for list management

### 2. Other Files
**Files that still exist but are no longer routed:**
- `lib/presentation/screens/lists/lists_screen.dart` - Can be kept for reference or removed
- `lib/presentation/screens/lists/list_detail_screen.dart` - Can be kept for reference or removed
- `lib/presentation/screens/lists/lists_screen_old.dart` - Can be removed
- `lib/presentation/screens/offers/offers_screen.dart` - Can be removed

## Recommended Next Steps

### Phase 1: Update Home Screen Navigation (High Priority)
1. Replace `context.go('/lists?create=true')` with a modal dialog or bottom sheet
2. Replace `context.push('/lists/${list.id}...')` with an in-app detail view
3. Consider using `showModalBottomSheet()` or `showDialog()` for list creation
4. Consider using a full-screen overlay or slide-in panel for list details

### Phase 2: Clean Up Unused Files (Medium Priority)
1. Remove or archive old list screen files if no longer needed
2. Remove offers screen files
3. Update any imports that reference these files

### Phase 3: Update State Management (Low Priority)
1. Verify `lists_provider.dart` still works correctly
2. Update any list-related state management to work with the new in-app views
3. Ensure list operations (create, edit, delete) work without route navigation

## Example Implementation for List Creation

### Current (Broken):
```dart
TextButton(
  onPressed: () => context.go('/lists?create=true'),
  child: Text('Create List'),
)
```

### Recommended (Modal):
```dart
TextButton(
  onPressed: () {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateListBottomSheet(),
    );
  },
  child: Text('Create List'),
)
```

### Recommended (Dialog):
```dart
TextButton(
  onPressed: () {
    showDialog(
      context: context,
      builder: (context) => CreateListDialog(),
    );
  },
  child: Text('Create List'),
)
```

## Example Implementation for List Detail

### Current (Broken):
```dart
onTap: () => context.push('/lists/${list.id}?name=${list.name}')
```

### Recommended (Bottom Sheet):
```dart
onTap: () {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => ListDetailBottomSheet(
      listId: list.id,
      listName: list.name,
    ),
  );
}
```

### Recommended (Full Screen Overlay):
```dart
onTap: () {
  Navigator.of(context).push(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => ListDetailScreen(
        listId: list.id,
        listName: list.name,
      ),
    ),
  );
}
```

## Testing After Migration

1. **List Creation**:
   - [ ] Can create new lists from Home screen
   - [ ] Modal/dialog appears correctly
   - [ ] List is saved and appears in Home screen
   - [ ] Proper error handling

2. **List Detail View**:
   - [ ] Can view list details from Home screen
   - [ ] All list items are displayed
   - [ ] Can add/edit/delete items
   - [ ] Can navigate back to Home screen
   - [ ] State is preserved correctly

3. **Navigation**:
   - [ ] No broken navigation links
   - [ ] Back button works correctly
   - [ ] Bottom navigation bar remains accessible
   - [ ] No route errors in console

## Timeline

- **Immediate**: Navigation bar redesign (✅ Complete)
- **Short-term** (1-2 weeks): Update Home screen navigation references
- **Medium-term** (2-4 weeks): Implement new list creation/detail views
- **Long-term** (1-2 months): Clean up old files and optimize state management

## Notes

- The Lists functionality is still fully operational via the state provider
- Only the navigation routes have been removed
- The UI components can be reused in modals/bottom sheets
- Consider user experience when choosing between modals, bottom sheets, or overlays
- Maintain consistency with the new glassmorphism design language
