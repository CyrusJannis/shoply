# 🎁 Apple Introductory Offer Setup Guide

## Overview

**Apple Introductory Offers** let you offer free trials directly through the App Store. When configured:
- ✅ Apple Wallet popup shows "14 Days Free, then $X.XX/month"
- ✅ Apple validates trial eligibility automatically
- ✅ Apple manages trial countdown and auto-conversion to paid
- ✅ Much better user trust and conversion rates

---

## 📋 Step-by-Step Setup in App Store Connect

### 1. **Access Subscriptions**

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **"My Apps"**
3. Select **"Shoply"**
4. In the sidebar, click **"Subscriptions"**

### 2. **Configure Introductory Offer for Monthly Subscription**

1. Click on **"Premium Monthly"** subscription (product ID: `shoply_premium_monthly`)
2. Scroll to **"Introductory Offer"** section
3. Click **"Set Up Introductory Offer"** or **"Edit"** if already exists
4. Configure:
   - **Offer Type**: Free Trial
   - **Duration**: 14 days
   - **Number of Periods**: 1
5. Click **"Save"**

### 3. **Configure Introductory Offer for Yearly Subscription**

1. Click on **"Premium Yearly"** subscription (product ID: `shoply_premium_yearly`)
2. Scroll to **"Introductory Offer"** section
3. Click **"Set Up Introductory Offer"** or **"Edit"** if already exists
4. Configure:
   - **Offer Type**: Free Trial
   - **Duration**: 14 days
   - **Number of Periods**: 1
5. Click **"Save"**

### 4. **Submit for Review**

1. After configuring both subscriptions, click **"Submit for Review"**
2. Apple will review the changes (usually within 24-48 hours)
3. Once approved, the introductory offers will be live

---

## 🎯 How It Works

### User Experience (First-Time Subscriber):

1. User taps **"🎉 Try Premium Free"** button
2. **Apple Wallet popup appears** showing:
   ```
   Premium Monthly Subscription
   
   ✓ 14 Days Free
   
   Then $2.99/month
   
   Your subscription will automatically renew unless
   auto-renew is turned off at least 24 hours before
   the end of the current period.
   
   [Subscribe] [Cancel]
   ```
3. User confirms with **Face ID / Touch ID / Password**
4. Trial activates immediately
5. User enjoys 14 days of premium features
6. **Apple automatically converts to paid** after 14 days

### User Experience (Trial Already Used):

1. User taps **"🎉 Try Premium Free"** button
2. **Apple Wallet popup appears** showing:
   ```
   Premium Monthly Subscription
   
   $2.99/month
   
   Your subscription will automatically renew...
   
   [Subscribe] [Cancel]
   ```
3. **No trial shown** (Apple detects user already used it)
4. User pays immediately
5. Subscription activates

---

## 🔄 How Your App Handles It

Your Flutter app **doesn't need to detect trials manually** - Apple handles everything:

### Current Code (Already Correct):

```dart
// In paywall_modal.dart
Future<void> _startTrial() async {
  // This triggers Apple's purchase flow
  final tier = _isYearly 
      ? SubscriptionTier.premiumYearly 
      : SubscriptionTier.premiumMonthly;
  
  // Apple automatically applies introductory offer if eligible
  final purchased = await _subscriptionService.purchaseSubscription(tier);
  
  if (purchased) {
    // Success! (whether trial or paid, doesn't matter)
    Navigator.pop(context, true);
  }
}
```

### Database Function (Smart Detection):

Your `activate_subscription()` function already handles this:

```sql
-- If user has never had a trial (trial_ends_at IS NULL)
IF is_trial_eligible THEN
  -- Activate as trial (14 days)
  UPDATE users SET 
    subscription_status = 'trial',
    subscription_expires_at = NOW() + INTERVAL '14 days',
    trial_ends_at = NOW() + INTERVAL '14 days'
  ...
ELSE
  -- Activate as paid subscription
  UPDATE users SET 
    subscription_status = 'active',
    subscription_expires_at = expiry_date_param
  ...
END IF;
```

---

## 🎨 What Changed in the UI

### Button Text:
- **Before**: "🎉 Start Free Trial"
- **After**: "🎉 Try Premium Free"
- **Reason**: Shorter, more action-oriented

### Button Subtitle:
- **Before**: "Try free for 14 days, then $X.XX/month"
- **After**: "14 days free, then $X.XX/month"
- **Reason**: Matches Apple's terminology in popup

### Fine Print:
- Added: **"Free trial for new users only."**
- **Reason**: Sets correct expectation (Apple enforces this)

---

## ✅ Testing Checklist

### Before Introductory Offers Are Configured:

When you tap "Try Premium Free":
- ❌ Apple popup shows: "$2.99/month" (no trial mentioned)
- ❌ User gets charged immediately (no 14-day grace period)

### After Introductory Offers Are Configured:

When you tap "Try Premium Free" (first-time user):
- ✅ Apple popup shows: "14 Days Free, then $2.99/month"
- ✅ User sees clear trial information before confirming
- ✅ Premium activates immediately but no charge for 14 days
- ✅ After 14 days, auto-converts to paid subscription

When you tap "Try Premium Free" (trial already used):
- ✅ Apple popup shows: "$2.99/month" (no trial)
- ✅ User gets charged immediately
- ✅ Subscription activates

---

## 🧪 How to Test

### Method 1: Sandbox Testing (Recommended)

1. **Create Sandbox Test User**:
   - Go to App Store Connect → Users and Access → Sandbox Testers
   - Click "+" to add new tester
   - Use a **different email** than your Apple ID

2. **Test on Real iPhone**:
   - Sign out of your real Apple ID: Settings → App Store → Sign Out
   - Install your app (TestFlight or development build)
   - Tap "Try Premium Free"
   - Sign in with **sandbox test account** when prompted
   - **Verify**: Apple popup shows "14 Days Free"
   - Confirm purchase
   - **Verify**: Premium features unlock

3. **Test Trial Already Used**:
   - In App Store Connect → Sandbox Testers
   - Click "Clear Purchase History" for your test user
   - **OR** use a different sandbox account
   - Try purchasing again
   - **Verify**: No trial shown (goes straight to paid)

### Method 2: Production Testing

1. Upload build to TestFlight
2. Install on real iPhone
3. Use your **real Apple ID** (be careful - real charges apply!)
4. Test the flow
5. **Cancel immediately** if you don't want to keep the subscription

---

## 🚨 Important Notes

### Apple's Introductory Offer Rules:

1. **One trial per Apple ID**: User can only use trial once, ever (even if they cancel and re-subscribe)
2. **Family Sharing**: If enabled, trial applies to entire family group
3. **Price Changes**: If you change subscription price, you can offer a new introductory offer
4. **Refunds**: Trial refunds work same as regular subscriptions
5. **Grace Period**: Apple gives 16 days of grace period for billing issues during trial

### Database Sync:

- Your database function sets `trial_ends_at = NOW() + 14 days`
- This mirrors Apple's 14-day countdown
- After 14 days, Apple automatically charges user
- Your cron job (`expire_subscriptions`) checks expiry daily
- Everything stays in sync automatically

### Revenue:

- **Trial period**: $0.00 revenue
- **After 14 days**: Full subscription price ($2.99/month or $29.99/year)
- **Apple's cut**: 30% first year, 15% after
- **Your cut**: 70% first year, 85% after

---

## 📊 Expected Impact

### Before Introductory Offers:

- User sees paywall → taps button → Apple asks for **immediate payment**
- High friction, lower conversion
- Many users abandon at payment step

### After Introductory Offers:

- User sees paywall → taps button → Apple shows **"14 Days Free"**
- Lower friction, much higher conversion
- Users feel safe trying premium features
- Expected conversion boost: **30-50%** (industry average)

### Retention:

- **Trial-to-paid conversion**: 40-60% (industry average)
- Users who complete trial are **3x more likely** to keep subscription long-term
- First 14 days are critical for showcasing premium value

---

## 🎯 Next Steps

1. ✅ **Configure introductory offers** in App Store Connect (both monthly and yearly)
2. ✅ **Submit for review** (Apple approval needed)
3. ✅ **Create sandbox test accounts**
4. ✅ **Test on real iPhone** with sandbox account
5. ✅ **Verify popup shows "14 Days Free"**
6. ✅ **Upload to TestFlight** for beta testing
7. ✅ **Monitor conversion rates** in App Store Connect

---

## 📝 Current Status

- ✅ **Flutter code**: Ready (no changes needed)
- ✅ **Database function**: Ready (smart trial detection implemented)
- ✅ **UI/UX**: Polished and conversion-optimized
- ⏳ **App Store Connect**: Needs introductory offer configuration
- ⏳ **Testing**: Needs sandbox verification

---

## 💡 Pro Tips

1. **Highlight trial in paywall**: Use phrases like "No commitment", "Cancel anytime"
2. **Showcase value early**: Make sure users see premium features in first 7 days
3. **Reminder notifications**: Send reminder 2-3 days before trial ends
4. **Seamless experience**: Don't ask for credit card separately (Apple handles it)
5. **Analytics**: Track trial conversion rates in App Store Connect

---

## 🆘 Troubleshooting

### "Popup doesn't show trial"
- ✅ Verify introductory offers are approved in App Store Connect
- ✅ Check user hasn't used trial before (use fresh sandbox account)
- ✅ Ensure you're testing on **real device** (not simulator)

### "Trial activates but shows wrong duration"
- ✅ Check database: `trial_ends_at` should be NOW() + 14 days
- ✅ Verify introductory offer configured for 14 days (not 7 or 30)

### "User charged immediately even though they should get trial"
- ✅ Verify user is eligible (hasn't used trial before)
- ✅ Check introductory offer is approved and active
- ✅ Test with fresh sandbox account

---

## 📚 Additional Resources

- [Apple Docs: Introductory Offers](https://developer.apple.com/app-store/subscriptions/#introductory-offers)
- [App Store Connect Help: Subscriptions](https://help.apple.com/app-store-connect/#/dev5e9533624)
- [StoreKit Testing Guide](https://developer.apple.com/documentation/storekit/in-app_purchase/testing_in-app_purchases_in_xcode)

---

**This is the professional way to implement free trials.** Apple's introductory offers are more trustworthy, easier to manage, and significantly boost conversion rates compared to manual trial systems.
