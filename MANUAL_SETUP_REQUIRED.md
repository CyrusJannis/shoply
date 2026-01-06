# Manual Setup Required

These items CANNOT be completed by AI and require human action:

---

## 🍎 App Store Configuration
- [ ] Create in-app purchase products in App Store Connect
  - Product ID: `shoply_premium_monthly` ($2.99/month, 14-day trial)
  - Product ID: `shoply_premium_yearly` ($29.99/year, 14-day trial)
  - Configure auto-renewable subscriptions
  - Set up introductory offers (14-day free trial)
- [ ] Submit app for review with IAP
- [ ] Test with sandbox accounts before production

---

## 🤖 Google Play Configuration
- [ ] Create subscription products in Play Console (matching Apple)
  - Product ID: `shoply_premium_monthly`
  - Product ID: `shoply_premium_yearly`
- [ ] Configure billing profile
- [ ] Set up free trial period
- [ ] Enable real-time developer notifications

---

## 💾 Supabase Configuration

### Storage Bucket Setup
- [ ] Create `list-backgrounds` storage bucket
  - Settings → Storage → New Bucket
  - Name: `list-backgrounds`
  - Public: ✅ Yes (enabled)
  - File size limit: 5MB per file
  - Allowed MIME types: image/jpeg, image/png, image/webp
- [ ] Set bucket to public readable
  - Go to bucket policies
  - Add policy: `SELECT` for `public` role
- [ ] Configure storage size limits (50MB per user recommended)
  - Add RLS policy to limit total storage per user

### Database Schema Updates
Run these SQL migrations in Supabase SQL Editor:

```sql
-- 1. Add background columns to shopping_lists table
ALTER TABLE shopping_lists 
ADD COLUMN IF NOT EXISTS background_type TEXT 
CHECK (background_type IN ('color', 'gradient', 'image')) 
DEFAULT 'color';

ALTER TABLE shopping_lists 
ADD COLUMN IF NOT EXISTS background_value TEXT;

ALTER TABLE shopping_lists 
ADD COLUMN IF NOT EXISTS background_image_url TEXT;

-- 2. Create user_preferences table for theme settings
CREATE TABLE IF NOT EXISTS user_preferences (
  user_id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  theme_mode TEXT CHECK (theme_mode IN ('light', 'dark', 'true_black', 'high_contrast', 'warm', 'cool')) DEFAULT 'light',
  accent_color TEXT DEFAULT '#2196F3',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only access their own preferences
CREATE POLICY "Users can view their own preferences" 
ON user_preferences FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own preferences" 
ON user_preferences FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own preferences" 
ON user_preferences FOR INSERT 
WITH CHECK (auth.uid() = user_id);

-- 3. Create ingredient_diet_tags table
CREATE TABLE IF NOT EXISTS ingredient_diet_tags (
  ingredient_name TEXT PRIMARY KEY,
  is_vegan BOOLEAN DEFAULT TRUE,
  is_vegetarian BOOLEAN DEFAULT TRUE,
  is_gluten_free BOOLEAN DEFAULT TRUE,
  is_dairy_free BOOLEAN DEFAULT TRUE,
  contains_nuts BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 4. Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_shopping_lists_background_type 
ON shopping_lists(background_type);

CREATE INDEX IF NOT EXISTS idx_ingredient_diet_tags_vegan 
ON ingredient_diet_tags(is_vegan) WHERE is_vegan = FALSE;

CREATE INDEX IF NOT EXISTS idx_ingredient_diet_tags_vegetarian 
ON ingredient_diet_tags(is_vegetarian) WHERE is_vegetarian = FALSE;
```

---

## 📝 Content Population

### Ingredient Diet Tags Database
- [ ] Pre-populate `ingredient_diet_tags` table with common ingredients
  - Minimum 500+ common ingredients needed
  - Categories to cover:
    - Meats (chicken, beef, pork, fish, etc.)
    - Dairy (milk, cheese, butter, yogurt, etc.)
    - Grains (wheat, rice, oats, barley, etc.)
    - Vegetables (all major vegetables)
    - Fruits (all major fruits)
    - Nuts & Seeds
    - Condiments & Spices
    - Sweeteners

**Option 1: Use AI Script** (Recommended)
```sql
-- Example entries (expand to 500+):
INSERT INTO ingredient_diet_tags (ingredient_name, is_vegan, is_vegetarian, is_gluten_free, is_dairy_free, contains_nuts) VALUES
('chicken', FALSE, FALSE, TRUE, TRUE, FALSE),
('milk', FALSE, FALSE, TRUE, FALSE, FALSE),
('eggs', FALSE, FALSE, TRUE, TRUE, FALSE),
('wheat flour', TRUE, TRUE, FALSE, TRUE, FALSE),
('almonds', TRUE, TRUE, TRUE, TRUE, TRUE),
('butter', FALSE, FALSE, TRUE, FALSE, FALSE),
('tofu', TRUE, TRUE, TRUE, TRUE, FALSE),
('honey', FALSE, TRUE, TRUE, TRUE, FALSE),
('fish', FALSE, FALSE, TRUE, TRUE, FALSE),
('cheese', FALSE, FALSE, TRUE, FALSE, FALSE);
-- ... add 490+ more
```

**Option 2: Use Gemini AI** to generate on-demand
- Fallback for unknown ingredients
- Cache results in database for future use

---

## ⚖️ Legal Content
- [ ] Write Terms of Service 
  - Location: `lib/presentation/screens/legal/terms_of_service_screen.dart`
  - Must include:
    - Service description
    - Payment terms (subscriptions, trials, cancellation)
    - User responsibilities
    - Liability limitations
    - Dispute resolution
  - **Consult legal professional** - this is critical!

- [ ] Write Privacy Policy
  - Location: `lib/presentation/screens/legal/privacy_policy_screen.dart`
  - Must include:
    - Data collection practices
    - AI usage (Gemini API)
    - Supabase storage details
    - Third-party services
    - GDPR compliance (if serving EU users)
    - User rights (data deletion, export)
  - **Consult legal professional** - GDPR fines are severe!

---

## 🧪 Testing Requirements

### Sandbox Testing
- [ ] Create iOS sandbox test users
  - Go to App Store Connect → Users and Access → Sandbox Testers
  - Create 2-3 test accounts with different emails
  - **Never use real Apple ID for sandbox testing!**

- [ ] Create Google Play sandbox test users
  - Go to Play Console → Setup → License testing
  - Add test user emails

- [ ] Test full purchase flow on physical devices
  - Test monthly subscription
  - Test yearly subscription
  - Test free trial activation
  - Test subscription cancellation
  - Test subscription expiration
  - Test subscription renewal
  - Test restore purchases

- [ ] Verify receipt validation works
  - Check server-side validation (Supabase Edge Function)
  - Test with expired receipts
  - Test with tampered receipts

### Device Testing Checklist
- [ ] Test on iPhone (iOS 15+)
- [ ] Test on Android device (Android 8+)
- [ ] Test on iPad
- [ ] Test on different screen sizes
- [ ] Test with poor network (airplane mode toggle)
- [ ] Test with VPN enabled

---

## 🚀 Deployment Checklist

### Pre-Deployment
- [ ] Update app version in `pubspec.yaml`
  - Current: 1.0.0
  - Suggest: 1.1.0 (for major feature update)
- [ ] Update version in `ios/Runner/Info.plist` (CFBundleShortVersionString)
- [ ] Update version in `android/app/build.gradle` (versionName, versionCode)
- [ ] Run final tests on both platforms
- [ ] Check for console errors/warnings
- [ ] Verify no API keys in code
- [ ] Review app permissions (camera, storage)

### Build Generation
- [ ] Generate iOS release build
  ```bash
  flutter build ios --release
  ```
- [ ] Generate Android release build (AAB)
  ```bash
  flutter build appbundle --release
  ```
- [ ] Generate Android APK (for testing)
  ```bash
  flutter build apk --release
  ```

### App Store Submission
- [ ] Submit to Apple App Store
  - Upload via Xcode or Transporter
  - Fill in App Store Connect metadata
  - Add screenshots (required sizes)
  - Write app description
  - Submit for review
  - Estimated review time: 24-48 hours

- [ ] Submit to Google Play Store
  - Upload AAB via Play Console
  - Fill in store listing
  - Add screenshots
  - Complete questionnaire
  - Submit for review
  - Estimated review time: 1-7 days

### Post-Deployment Monitoring
- [ ] Monitor crash reports (first 48 hours critical)
  - Use Firebase Crashlytics or Sentry
  - Check for subscription-related crashes
  - Monitor image upload failures
- [ ] Check analytics for user behavior
- [ ] Monitor subscription conversion rate
- [ ] Watch for user reviews and feedback
- [ ] Prepare hotfix branch for urgent issues

---

## 📊 Analytics Setup (Optional but Recommended)
- [ ] Set up Firebase Analytics
- [ ] Set up Crashlytics
- [ ] Configure custom events:
  - `subscription_started`
  - `free_trial_activated`
  - `background_customized`
  - `theme_changed`
  - `diet_preference_set`
  - `recipe_filtered_by_diet`

---

## 🔒 Security Review
- [ ] Review RLS policies in Supabase
- [ ] Verify API keys are in environment variables (not hardcoded)
- [ ] Check file upload validation (size, type)
- [ ] Test authentication edge cases
- [ ] Verify subscription status cannot be manipulated client-side
- [ ] Test rate limiting on AI endpoints

---

## ⚠️ Known Limitations
These are technical limitations that cannot be automated:

1. **Camera Access**: Requires real device testing
2. **IAP Testing**: Requires sandbox accounts and real devices
3. **Storage Limits**: Needs Supabase dashboard configuration
4. **Legal Content**: Requires professional legal review
5. **Ingredient Database**: Needs manual curation or AI script
6. **Cross-Platform Testing**: Requires both iOS and Android devices

---

## 📞 Support Resources
- Supabase Docs: https://supabase.com/docs
- Flutter IAP: https://pub.dev/packages/in_app_purchase
- App Store Connect: https://appstoreconnect.apple.com
- Google Play Console: https://play.google.com/console
- Firebase Console: https://console.firebase.google.com

---

**Last Updated**: November 6, 2025
**Maintained by**: Development Team
