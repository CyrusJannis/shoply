# Navigation Bar Quick Reference

## New Navigation Structure

### Tab Order (Left to Right)
1. **Home** 🏠 - `Icons.home_rounded`
2. **AI** ✨ - `Icons.auto_awesome_rounded` (Highlighted with gradient)
3. **Recipes** 🍽️ - `Icons.restaurant_rounded`
4. **Profile** 👤 - `Icons.person_rounded`

## Visual Design

### Glassmorphism Effect
```dart
// Background blur
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40)
)

// Semi-transparent background
Light mode: Colors.white.withOpacity(0.7)
Dark mode: Colors.black.withOpacity(0.5)

// Floating appearance
Margins: EdgeInsets.only(left: 16, right: 16, bottom: 24)
Border radius: 30px
Shadow: 30px blur, 10px offset
```

### AI Tab Special Styling
- **Gradient Background**: Purple → Blue
- **Glow Effect**: Shadow with 12px blur
- **White Icon**: Stands out from other tabs

## Routes

| Tab | Route | Screen |
|-----|-------|--------|
| Home | `/home` | `HomeScreen` |
| AI | `/ai` | `AIScreen` |
| Recipes | `/recipes` | `RecipesScreen` |
| Profile | `/profile` | `ProfileScreen` |

## Removed Routes
- ❌ `/lists` - Lists functionality to be integrated into Home
- ❌ `/lists/:listId` - List detail pages
- ❌ `/offers` - Stores/Offers section removed

## Key Features

### Icon-Only Design
- No text labels for cleaner appearance
- Icons are self-explanatory
- Larger tap targets (72px height)

### Smooth Animations
- 200ms transition duration
- `Curves.easeInOut` for natural feel
- Size changes: 24px → 28px when active

### Responsive States
- **Inactive**: Gray color, smaller size (24px)
- **Active (Regular)**: Black/White, larger size (28px), subtle background
- **Active (AI)**: White icon, gradient background, glow effect

## Implementation Files

### Modified
- `lib/routes/app_router.dart` - Routing configuration
- `lib/presentation/screens/main_scaffold.dart` - Navigation bar UI

### Created
- `lib/presentation/screens/ai/ai_screen.dart` - AI placeholder page

## Testing Checklist

- [ ] All 4 tabs navigate correctly
- [ ] Glassmorphism effect visible in both themes
- [ ] AI tab shows gradient when selected
- [ ] Smooth animations between tabs
- [ ] Navigation bar floats above content
- [ ] Proper spacing from screen edges
- [ ] Icons are clearly visible
- [ ] Tap targets are adequate (72px height)

## Color Palette

### Light Mode
- Background: `rgba(255, 255, 255, 0.7)`
- Border: `rgba(255, 255, 255, 0.5)`
- Active icon: `#000000`
- Inactive icon: `#757575`
- AI gradient: `#BA68C8` → `#64B5F6`

### Dark Mode
- Background: `rgba(0, 0, 0, 0.5)`
- Border: `rgba(255, 255, 255, 0.1)`
- Active icon: `#FFFFFF`
- Inactive icon: `#BDBDBD`
- AI gradient: `#AB47BC` → `#42A5F5`

## Accessibility

- Minimum tap target: 72px height × 25% width per tab
- High contrast maintained for all icons
- Smooth animations (not too fast)
- Clear visual feedback on selection
- Icons are universally recognizable

## Future Enhancements

1. Add haptic feedback on tap
2. Implement swipe gestures between tabs
3. Add badge notifications (e.g., new AI features)
4. Consider adding subtle sound effects
5. Add accessibility labels for screen readers
