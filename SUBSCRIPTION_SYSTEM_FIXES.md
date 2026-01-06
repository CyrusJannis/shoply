# Subscription System - Critical Fixes Required

## 🔴 Issues Found (November 10, 2025)

### 1. **Table Name Inconsistency** - CRITICAL
**Location**: `lib/data/services/subscription_service.dart`

**Problem**:
- Line 214: Queries `users` table
- Line 338: Updates `user_profiles` table

**Impact**: Updates fail silently on real devices

**Fix**: Change line 338 from:
```dart
await _supabase.from('user_profiles').update({
```
To:
```dart
await _supabase.from('users').update({
```

---

### 2. **Purchase Completion Logic** - CRITICAL  
**Location**: `lib/data/services/subscription_service.dart` line 263-317

**Problem**: 
```dart
final result = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
return result;  // This returns immediately, doesn't wait for purchase!
```

The `buyNonConsumable` method returns a `bool` indicating if the purchase **request** was sent, NOT if the purchase completed. The actual purchase result comes through `_onPurchaseUpdate` callback.

**Impact**: 
- Paywall shows success before purchase completes
- User might cancel Apple popup but app thinks they subscribed
- Race conditions between UI and purchase stream

**Fix**: Use a Completer pattern to wait for actual purchase completion.

---

### 3. **Trial Check Logic** - MEDIUM
**Location**: Line 241

**Problem**:
```dart
if (current.trialEndsAt != null) {
  print('⚠️ User already used trial');
  return false;
}
```

This checks if trial was EVER activated, but doesn't check if it was used. A user could have `trial_ends_at` set but subscription_status could be 'expired' or 'inactive'.

**Better Logic**:
```dart
if (current.status == SubscriptionStatus.trial || 
    (current.trialEndsAt != null && current.trialEndsAt!.isAfter(DateTime.now()))) {
  return false; // Trial already active
}

if (current.trialEndsAt != null) {
  return false; // Trial already used (even if expired)
}
```

---

### 4. **Premium Check Logic** - MEDIUM
**Location**: Line 92-96

**Problem**:
```dart
final isPremium = (status == SubscriptionStatus.trial || status == SubscriptionStatus.active) &&
    (expiresAt == null || expiresAt.isAfter(DateTime.now()));
```

The `expiresAt == null` condition makes isPremium true even without an expiration date. This might be intentional for lifetime subscriptions, but it's risky.

**Recommendation**: Be explicit:
```dart
final isPremium = (status == SubscriptionStatus.trial || status == SubscriptionStatus.active) &&
    (expiresAt == null || (expiresAt.isAfter(DateTime.now())));
```

Or better yet, always require expiresAt:
```dart
final isPremium = (status == SubscriptionStatus.trial || status == SubscriptionStatus.active) &&
    expiresAt != null && expiresAt.isAfter(DateTime.now());
```

---

### 5. **Missing Receipt Validation** - SECURITY RISK
**Location**: `_verifyAndActivateSubscription` method

**Problem**: 
The app activates subscriptions based on purchase events WITHOUT validating the receipt with Apple/Google servers.

**Impact**: 
- Users could potentially fake purchase events
- No protection against refunds
- No server-side verification

**Recommendation**: 
Implement server-side receipt validation via Supabase Edge Function:
1. Send receipt to Edge Function
2. Edge Function validates with Apple/Google
3. Only then activate subscription

---

### 6. **No Purchase Stream Recovery** - MEDIUM
**Location**: `initialize()` method

**Problem**:
If the purchase stream subscription fails or disconnects, there's no automatic reconnection.

**Fix**: Add error handling and auto-reconnect:
```dart
_subscription = _iap.purchaseStream.listen(
  _onPurchaseUpdate,
  onError: (error) {
    if (kDebugMode) {
      print('❌ Purchase stream error: $error');
    }
    // Reconnect after delay
    Future.delayed(Duration(seconds: 5), () {
      _subscription?.cancel();
      initialize();
    });
  },
  cancelOnError: false,
);
```

---

### 7. **Product Price Display** - FIXED ✅
**Status**: Already fixed in PaywallModal
- Now loads real prices from IAP
- Shows correct currency formatting

---

### 8. **Missing Subscription State Management** - MEDIUM
**Problem**: No reactive state management for subscription changes

**Recommendation**: Add StreamProvider in Riverpod:
```dart
final subscriptionProvider = StreamProvider<SubscriptionData>((ref) async* {
  while (true) {
    yield await SubscriptionService().getSubscriptionStatus();
    await Future.delayed(Duration(minutes: 5)); // Poll every 5 min
  }
});
```

---

## ✅ Priority Fixes (Do These First)

1. **Fix table name** (5 minutes) - Line 338
2. **Implement purchase completion wait** (30 minutes)
3. **Test on real device** (essential before release)

## 📋 Testing Checklist

- [ ] Test on real iPhone (simulator can't test IAP)
- [ ] Test monthly subscription purchase
- [ ] Test yearly subscription purchase
- [ ] Test trial activation
- [ ] Test restore purchases
- [ ] Test expired subscription behavior
- [ ] Test cancelled subscription
- [ ] Verify Apple popup shows correctly
- [ ] Verify correct prices display
- [ ] Test with sandbox Apple ID
- [ ] Verify receipt validation works

