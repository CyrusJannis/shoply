# 🧪 Subscription & Trial Testing Guide

## 🗄️ **1. Reset Trial Status in Database**

### **Option A: Via Supabase Dashboard** (Recommended)

1. Go to: https://supabase.com/dashboard/project/YOUR_PROJECT_ID/editor
2. Click **"SQL Editor"**
3. Paste and run:

```sql
-- Reset trial status for ALL users
UPDATE users
SET 
  trial_ends_at = NULL,
  subscription_status = 'inactive',
  subscription_tier = 'free',
  subscription_expires_at = NULL
WHERE trial_ends_at IS NOT NULL 
   OR subscription_status IN ('trial', 'active');
```

4. Verify:

```sql
SELECT 
  id,
  email,
  subscription_status,
  subscription_tier,
  trial_ends_at,
  subscription_expires_at
FROM users
ORDER BY created_at DESC
LIMIT 10;
```

### **Option B: Reset Only YOUR User**

```sql
-- Replace with YOUR email
UPDATE users
SET 
  trial_ends_at = NULL,
  subscription_status = 'inactive',
  subscription_tier = 'free',
  subscription_expires_at = NULL
WHERE email = 'your.email@example.com';
```

---

## ✅ **2. Verify Current Logic**

### **Trial Activation Flow:**

Based on `/database/migrations/20251110_smart_trial_detection.sql`:

```
User clicks "Try Premium Free" 
  ↓
paywall_modal.dart → _startTrial()
  ↓
Calls: subscriptionService.purchaseSubscription(tier)
  ↓
Shows **Apple Pay/Wallet Popup** ✅
  ↓
User confirms subscription (even for free trial!)
  ↓
Purchase stream receives event
  ↓
_verifyAndActivateSubscription() 
  ↓
Calls Supabase RPC: activate_subscription()
  ↓
Database function checks: trial_ends_at IS NULL?
  ↓
  YES → Activates TRIAL (14 days free)
  NO  → Activates PAID subscription
```

### **Key Points:**

✅ **Apple Pay Popup ALWAYS shows** - Even for free trials (App Store requirement)
✅ **Trial only activated AFTER user confirms** in Apple popup
✅ **Trial eligibility:** User has `trial_ends_at = NULL`
✅ **Trial duration:** 14 days (configured in DB function)
✅ **After trial:** Auto-converts to paid subscription if not cancelled

---

## 🧪 **3. Testing Steps**

### **A. Test on Simulator (Fallback Mode):**

1. Build and run app
2. Navigate to Premium feature
3. Click "Try Premium Free"
4. **Expected:** Subscription activates directly (no Apple popup on simulator)
5. **Log:** `⚠️ [IAP] IAP not available - Activating subscription directly for testing`

**Note:** Simulator can't test Apple IAP! Use real device.

---

### **B. Test on Real iPhone (FULL TEST):**

#### **Step 1: Setup Sandbox Tester**

1. Go to: https://appstoreconnect.apple.com
2. **Users and Access** → **Sandbox Testers**
3. Create test Apple ID (e.g., `test@example.com`)
4. On iPhone: **Settings** → **App Store** → Scroll down → **Sandbox Account** → Sign in with test Apple ID

#### **Step 2: Configure Products in App Store Connect**

1. Go to your app in App Store Connect
2. **App Store** → **Subscriptions**
3. Verify products exist:
   - `shoply_premium_monthly` (e.g., $2.99/month)
   - `shoply_premium_yearly` (e.g., $29.99/year)
4. **IMPORTANT:** Set **Introductory Offer**:
   - Type: **Free Trial**
   - Duration: **14 days**

#### **Step 3: Test Trial Flow**

1. **Reset trial in database** (see step 1)
2. **Build and run** app in **Release mode** on iPhone
3. **Logout and login** to refresh subscription status
4. Navigate to Premium feature or Settings → Subscription
5. Click **"Try Premium Free"**
6. **EXPECTED:**
   - ✅ Apple Pay/Wallet popup appears
   - ✅ Shows: "Free for 14 days, then $X.XX/month"
   - ✅ User can use Face ID / Touch ID to confirm
   - ✅ OR user can cancel
7. **Confirm** subscription
8. **EXPECTED in App:**
   - ✅ Success message: "Free trial activated!"
   - ✅ Premium features unlocked
   - ✅ Settings shows: "Trial - expires in 14 days"
9. **Verify in Database:**
   ```sql
   SELECT 
     subscription_status,    -- Should be 'trial'
     trial_ends_at,          -- Should be NOW() + 14 days
     subscription_expires_at -- Should be NOW() + 14 days
   FROM users
   WHERE email = 'your@email.com';
   ```

#### **Step 4: Test Second Trial Attempt (Should Fail)**

1. Try clicking "Try Premium Free" again
2. **EXPECTED:**
   - ✅ Button shows "Start Subscription" (no free trial mentioned)
   - ✅ User must pay immediately (no free trial)
   - ✅ OR shows "Trial already used" message

#### **Step 5: Test Paid Subscription**

1. **Reset trial** in database again
2. **Use trial once** (to mark `trial_ends_at`)
3. **Wait for trial to expire** OR manually update database:
   ```sql
   UPDATE users
   SET 
     subscription_status = 'expired',
     subscription_expires_at = NOW() - INTERVAL '1 day'
   WHERE email = 'your@email.com';
   ```
4. Click "Subscribe" again
5. **EXPECTED:**
   - ✅ Apple popup shows **PAID** price (no free trial)
   - ✅ User must pay with sandbox account
   - ✅ Subscription activates as 'active' (not 'trial')

#### **Step 6: Test Restore Purchases**

1. **Uninstall app**
2. **Reinstall app**
3. Login with same account
4. Navigate to Settings → Subscription
5. Click **"Restore Purchases"**
6. **EXPECTED:**
   - ✅ Previous subscription restored
   - ✅ Premium features work again

---

## 🔍 **4. Debug Checklist**

### **If Apple Popup doesn't appear:**

- ❌ Check: Are you on real device? (Simulator can't show Apple popup)
- ❌ Check: Is IAP available? (Look for log: `[IAP] isAvailable: true`)
- ❌ Check: Are products loaded? (Look for log: `Loaded X products`)
- ❌ Check: Sandbox account signed in? (Settings → App Store)

### **If trial doesn't activate:**

- ❌ Check database: `trial_ends_at` should be NULL before trial
- ❌ Check logs: `[IAP] Purchase update: ... - purchased`
- ❌ Check Supabase RPC: `activate_subscription` function exists
- ❌ Check migration: `20251110_smart_trial_detection.sql` was run

### **If trial activates but user pays immediately:**

- ❌ Check App Store Connect: Introductory offer configured?
- ❌ Check: `trial_ends_at` was NULL in database?
- ❌ Check logs: Should say "ACTIVATE AS TRIAL"

---

## 📊 **5. Expected Database States**

### **State 1: New User (Trial Eligible)**
```sql
trial_ends_at: NULL
subscription_status: 'inactive'
subscription_tier: 'free'
```

### **State 2: Active Trial**
```sql
trial_ends_at: '2024-11-28 14:00:00'  -- NOW() + 14 days
subscription_status: 'trial'
subscription_tier: 'premium_monthly' OR 'premium_yearly'
subscription_expires_at: '2024-11-28 14:00:00'  -- Same as trial_ends_at
```

### **State 3: Trial Expired (User must pay)**
```sql
trial_ends_at: '2024-11-14 14:00:00'  -- Past date
subscription_status: 'expired'
subscription_tier: 'premium_monthly' OR 'premium_yearly'
subscription_expires_at: '2024-11-14 14:00:00'  -- Past date
```

### **State 4: Paid Subscription (Trial already used)**
```sql
trial_ends_at: '2024-11-14 14:00:00'  -- Past date (trial was used)
subscription_status: 'active'
subscription_tier: 'premium_monthly' OR 'premium_yearly'
subscription_expires_at: '2024-12-14 14:00:00'  -- Future date
```

---

## 🎯 **6. Key Code Locations**

- **Paywall UI:** `/lib/presentation/widgets/subscription/paywall_modal.dart`
- **Subscription Logic:** `/lib/data/services/subscription_service.dart`
- **Database Function:** `/database/migrations/20251110_smart_trial_detection.sql`
- **Trial Check:** Line 23-24 in migration (checks if `trial_ends_at IS NULL`)

---

## ✅ **Summary: Logic is CORRECT!**

Your implementation is already set up correctly:

1. ✅ **Apple Pay popup shows** for both trial and paid subscriptions
2. ✅ **Trial only activates AFTER user confirms** in Apple popup
3. ✅ **Trial eligibility checked** by `trial_ends_at IS NULL`
4. ✅ **14-day trial** then auto-converts to paid
5. ✅ **One trial per user** (checked in database)

**Just reset the database and test on a real device!** 🚀
