# Onboarding Flow - Quick Start Guide

## What Was Built

A complete onboarding flow that runs **BEFORE** login/signup for first-time users, collecting:
1. Age
2. Height (with unit selection)
3. Gender
4. Dietary preferences (12 options with card-based UI)

## How to Test

### Testing First-Time User Flow

1. **Create a new user account:**
   ```bash
   # Run the app
   flutter run
   ```

2. **Sign up with a new email:**
   - Click "Sign Up" on login screen
   - Enter email and password
   - Complete signup

3. **You'll be automatically redirected to onboarding:**
   - Welcome screen appears first
   - Click "Get Started"
   - Complete all 4 data collection screens
   - Data is saved to database
   - Redirected to home screen

### Testing Returning User Flow

1. **Log in with existing account:**
   - If onboarding was completed, goes directly to home
   - If onboarding was not completed, goes to onboarding

### Testing Profile Settings

1. **Navigate to Profile tab**
2. **Click "Personal Information":**
   - Edit age, height, gender
   - Changes save to database
3. **Click "Dietary Preferences":**
   - Toggle preferences on/off
   - Same card UI as onboarding

## Key Features

### Onboarding Screens

#### 1. Welcome Screen (`/onboarding`)
- App introduction
- 3 key features listed
- "Get Started" button
- "Skip" option (goes to login)

#### 2. Age Screen (`/onboarding/age`)
- Number input for age
- Validation: 13-120 years
- Quick select buttons (13-17, 18-24, etc.)
- Progress: 1/4

#### 3. Height Screen (`/onboarding/height`)
- Unit selector: cm or ft
- Number input with unit display
- Quick select common heights
- Progress: 2/4

#### 4. Gender Screen (`/onboarding/gender`)
- Card-based selection
- Options: Male, Female, Other, Prefer not to say
- Visual selection feedback
- Progress: 3/4

#### 5. Diet Preferences (`/onboarding/diet-preferences`)
- 12 dietary options with icons
- Multi-select cards
- "No Restrictions" option
- Selected count display
- Progress: 4/4
- Saves to database on completion

### Design Features

✅ **Card-Based Selection** - Modern, tappable cards
✅ **No Emojis** - Uses Material icons only
✅ **Visual Feedback** - Animated selection states
✅ **Progress Indicator** - Dots showing current step
✅ **Back Navigation** - Can go back to previous screens
✅ **Skip Option** - Can skip to login anytime
✅ **Dark Mode** - Full support for light/dark themes
✅ **Smooth Animations** - 200ms transitions

## Database Schema

The onboarding flow requires these columns in your `users` table:

```sql
-- Personal information
age: integer
height: double precision
height_unit: text ('cm' or 'ft')
gender: text ('male', 'female', 'other', 'prefer_not_to_say')

-- Dietary preferences (array of strings)
diet_preferences: text[]

-- Onboarding tracking
onboarding_completed: boolean (default: false)
updated_at: timestamp
```

### SQL to Add Missing Columns

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS age integer;
ALTER TABLE users ADD COLUMN IF NOT EXISTS height double precision;
ALTER TABLE users ADD COLUMN IF NOT EXISTS height_unit text DEFAULT 'cm';
ALTER TABLE users ADD COLUMN IF NOT EXISTS gender text;
ALTER TABLE users ADD COLUMN IF NOT EXISTS diet_preferences text[] DEFAULT '{}';
ALTER TABLE users ADD COLUMN IF NOT EXISTS onboarding_completed boolean DEFAULT false;
```

## Dietary Preferences List

The following 12 options are available:

1. **Vegetarian** - No meat or fish
2. **Vegan** - No animal products
3. **Gluten-Free** - No gluten-containing foods
4. **Dairy-Free** - No milk or dairy products
5. **Keto** - Low-carb, high-fat diet
6. **Paleo** - Whole foods, no processed items
7. **Low-Carb** - Reduced carbohydrate intake
8. **Halal** - Islamic dietary laws
9. **Kosher** - Jewish dietary laws
10. **Pescatarian** - Vegetarian plus fish
11. **Nut-Free** - No nuts or nut products
12. **Low-Sodium** - Reduced salt intake

Plus: **No Restrictions** option (clears all selections)

## Navigation Flow

```
Login/Signup
    ↓
Check onboarding_completed
    ↓
┌───────────────┬────────────────┐
│ false         │ true           │
↓               ↓                │
Onboarding      Home             │
    ↓                            │
Welcome                          │
    ↓                            │
Age (1/4)                        │
    ↓                            │
Height (2/4)                     │
    ↓                            │
Gender (3/4)                     │
    ↓                            │
Diet Prefs (4/4)                 │
    ↓                            │
Save to DB                       │
    ↓                            │
Set onboarding_completed = true  │
    ↓                            │
Home ←───────────────────────────┘
```

## Files Structure

```
lib/
├── data/
│   └── models/
│       └── user_model.dart (MODIFIED - added age, height, gender)
│
├── presentation/
│   ├── screens/
│   │   ├── onboarding/ (NEW)
│   │   │   ├── onboarding_welcome_screen.dart
│   │   │   ├── onboarding_age_screen.dart
│   │   │   ├── onboarding_height_screen.dart
│   │   │   ├── onboarding_gender_screen.dart
│   │   │   └── onboarding_diet_preferences_screen.dart
│   │   │
│   │   └── profile/
│   │       ├── profile_screen.dart (MODIFIED - added personal info menu)
│   │       └── settings/
│   │           ├── personal_info_screen.dart (NEW)
│   │           └── diet_preferences_screen.dart (MODIFIED - card UI)
│   │
│   ├── state/
│   │   └── onboarding_provider.dart (NEW)
│   │
│   └── widgets/
│       └── onboarding/ (NEW)
│           └── onboarding_layout.dart
│
└── routes/
    └── app_router.dart (MODIFIED - added onboarding routes & redirect)
```

## Common Issues & Solutions

### Issue: Onboarding doesn't show for new users
**Solution:** Check that `onboarding_completed` column exists and defaults to `false`

### Issue: Can't save data to database
**Solution:** Verify all columns exist in Supabase `users` table

### Issue: Routing loops or errors
**Solution:** Check that router redirect logic is working correctly

### Issue: UI looks broken
**Solution:** Ensure all imports are correct and no missing dependencies

### Issue: Dark mode colors wrong
**Solution:** Check theme brightness checks in each screen

## Testing Checklist

- [ ] New user sees onboarding after signup
- [ ] Returning user skips onboarding
- [ ] All 5 screens display correctly
- [ ] Age validation works (13-120)
- [ ] Height unit switching works
- [ ] Gender selection works
- [ ] Diet preferences toggle correctly
- [ ] Multiple preferences can be selected
- [ ] "No Restrictions" clears selections
- [ ] Progress dots update correctly
- [ ] Back button works
- [ ] Skip button goes to login
- [ ] Data saves to database
- [ ] User redirected to home after completion
- [ ] Personal info editable in Profile
- [ ] Diet preferences editable in Profile
- [ ] Changes persist to database
- [ ] Works in light mode
- [ ] Works in dark mode

## Next Steps

After testing the onboarding flow:

1. **Use the collected data:**
   - Implement nutrition calculations based on age/height/gender
   - Filter recipes by dietary preferences
   - Personalize AI recommendations

2. **Add analytics:**
   - Track onboarding completion rates
   - Identify where users drop off
   - Measure time to complete

3. **Enhance the experience:**
   - Add illustrations/animations
   - Include tutorial tooltips
   - Add "Why we ask" explanations

4. **Integrate with AI features:**
   - Use preferences for meal planning
   - Calculate personalized nutrition goals
   - Filter shopping recommendations

## Support

If you encounter issues:
1. Check console for error messages
2. Verify database schema is correct
3. Ensure Supabase connection works
4. Test with a fresh user account
5. Check that all files were created correctly

## Summary

✅ **5 onboarding screens** created with modern card-based UI
✅ **State management** with Riverpod provider
✅ **Routing logic** with first-time user detection
✅ **Profile settings** for editing collected data
✅ **Database integration** with Supabase
✅ **Consistent design** matching app theme
✅ **Full dark mode** support
✅ **No emojis** - icon-based design

The onboarding flow is production-ready and can be tested immediately!
