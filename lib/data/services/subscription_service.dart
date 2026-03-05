import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Subscription product IDs - must match App Store Connect / Google Play Console
class SubscriptionProducts {
  // Monthly subscription
  static const String monthlyId = 'shoply_pro_monthly';
  // Yearly subscription
  static const String yearlyId = 'shoply_pro_yearly';
  
  static const Set<String> allIds = {monthlyId, yearlyId};
}

/// Subscription status enum
enum SubscriptionStatus {
  unknown,
  notSubscribed,
  subscribed,
  expired,
  pending,
}

/// Service for handling in-app subscriptions (iOS & Android)
class SubscriptionService {
  static final SubscriptionService instance = SubscriptionService._();
  SubscriptionService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  
  // Stream subscription for purchase updates
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // Available products from store
  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;
  
  // Current subscription status
  SubscriptionStatus _status = SubscriptionStatus.unknown;
  SubscriptionStatus get status => _status;
  
  // Active subscription details
  PurchaseDetails? _activePurchase;
  PurchaseDetails? get activePurchase => _activePurchase;
  
  // Callbacks for UI updates
  final _statusController = StreamController<SubscriptionStatus>.broadcast();
  Stream<SubscriptionStatus> get statusStream => _statusController.stream;
  
  // Error callback
  final _errorController = StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorController.stream;
  
  // Loading state
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Store availability
  bool _isStoreAvailable = false;
  bool get isStoreAvailable => _isStoreAvailable;
  
  // SharedPreferences key
  static const String _subscriptionKey = 'subscription_status';
  static const String _subscriptionExpiryKey = 'subscription_expiry';

  /// Initialize the subscription service
  Future<void> initialize() async {
    debugPrint('💳 [SUBSCRIPTION] Initializing subscription service...');
    
    // Check if IAP is available
    final available = await _iap.isAvailable();
    _isStoreAvailable = available;
    if (!available) {
      debugPrint('⚠️ [SUBSCRIPTION] In-app purchases not available');
      _status = SubscriptionStatus.notSubscribed;
      _statusController.add(_status);
      return;
    }
    
    // Load cached subscription status
    await _loadCachedStatus();
    
    // Listen to purchase updates
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: _onPurchaseStreamDone,
      onError: _onPurchaseStreamError,
    );
    
    // Load products from store
    await _loadProducts();
    
    // Restore purchases to check current subscription status
    await restorePurchases();
    
    // Note: iOS StoreKit delegate is handled automatically by the in_app_purchase package
    
    debugPrint('✅ [SUBSCRIPTION] Subscription service initialized');
  }

  /// Load products from the store
  Future<void> _loadProducts() async {
    debugPrint('💳 [SUBSCRIPTION] Loading products...');
    
    final response = await _iap.queryProductDetails(SubscriptionProducts.allIds);
    
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint('⚠️ [SUBSCRIPTION] Products not found: ${response.notFoundIDs}');
    }
    
    if (response.error != null) {
      debugPrint('❌ [SUBSCRIPTION] Error loading products: ${response.error}');
      _errorController.add('Failed to load subscription options');
      return;
    }
    
    _products = response.productDetails;
    debugPrint('✅ [SUBSCRIPTION] Loaded ${_products.length} products');
    
    for (final product in _products) {
      debugPrint('   - ${product.id}: ${product.title} - ${product.price}');
    }
  }

  /// Handle purchase updates
  void _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    debugPrint('💳 [SUBSCRIPTION] Purchase update received: ${purchaseDetailsList.length} items');
    
    for (final purchase in purchaseDetailsList) {
      debugPrint('   - ${purchase.productID}: ${purchase.status}');
      
      switch (purchase.status) {
        case PurchaseStatus.pending:
          _status = SubscriptionStatus.pending;
          _statusController.add(_status);
          break;
          
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _handleSuccessfulPurchase(purchase);
          break;
          
        case PurchaseStatus.error:
          _handlePurchaseError(purchase);
          break;
          
        case PurchaseStatus.canceled:
          debugPrint('💳 [SUBSCRIPTION] Purchase canceled');
          _isLoading = false;
          break;
      }
      
      // Complete the purchase
      if (purchase.pendingCompletePurchase) {
        _iap.completePurchase(purchase);
      }
    }
  }

  /// Handle successful purchase
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    debugPrint('✅ [SUBSCRIPTION] Purchase successful: ${purchase.productID}');
    
    _activePurchase = purchase;
    _status = SubscriptionStatus.subscribed;
    _isLoading = false;
    
    // Cache the subscription status
    await _cacheSubscriptionStatus(true);
    
    _statusController.add(_status);
  }

  /// Handle purchase error
  void _handlePurchaseError(PurchaseDetails purchase) {
    debugPrint('❌ [SUBSCRIPTION] Purchase error: ${purchase.error}');
    
    _status = SubscriptionStatus.notSubscribed;
    _isLoading = false;
    
    final errorMessage = purchase.error?.message ?? 'Purchase failed';
    _errorController.add(errorMessage);
    _statusController.add(_status);
  }

  void _onPurchaseStreamDone() {
    debugPrint('💳 [SUBSCRIPTION] Purchase stream closed');
    _subscription?.cancel();
  }

  void _onPurchaseStreamError(dynamic error) {
    debugPrint('❌ [SUBSCRIPTION] Purchase stream error: $error');
    _errorController.add('Purchase stream error');
  }

  /// Purchase a subscription
  Future<bool> purchaseSubscription(ProductDetails product) async {
    debugPrint('💳 [SUBSCRIPTION] Purchasing: ${product.id}');
    
    _isLoading = true;
    
    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      
      // For subscriptions, use buyNonConsumable
      final success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      
      if (!success) {
        debugPrint('❌ [SUBSCRIPTION] Purchase initiation failed');
        _isLoading = false;
        _errorController.add('Could not initiate purchase');
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ [SUBSCRIPTION] Purchase error: $e');
      _isLoading = false;
      _errorController.add('Purchase failed: $e');
      return false;
    }
  }

  /// Restore previous purchases
  Future<void> restorePurchases() async {
    debugPrint('💳 [SUBSCRIPTION] Restoring purchases...');
    
    _isLoading = true;
    
    try {
      await _iap.restorePurchases();
      
      // Give some time for restore to complete
      await Future.delayed(const Duration(seconds: 2));
      
      // If no subscription was restored, mark as not subscribed
      if (_status == SubscriptionStatus.unknown) {
        _status = SubscriptionStatus.notSubscribed;
        _statusController.add(_status);
      }
      
      _isLoading = false;
      debugPrint('✅ [SUBSCRIPTION] Restore complete. Status: $_status');
    } catch (e) {
      debugPrint('❌ [SUBSCRIPTION] Restore error: $e');
      _isLoading = false;
      _status = SubscriptionStatus.notSubscribed;
      _statusController.add(_status);
    }
  }

  /// Check if user is subscribed
  bool get isSubscribed => _status == SubscriptionStatus.subscribed;

  /// Cache subscription status locally
  Future<void> _cacheSubscriptionStatus(bool isSubscribed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subscriptionKey, isSubscribed);
    
    if (isSubscribed) {
      // Cache expiry date (30 days for monthly, 365 for yearly)
      final expiry = DateTime.now().add(const Duration(days: 30));
      await prefs.setString(_subscriptionExpiryKey, expiry.toIso8601String());
    }
  }

  /// Load cached subscription status
  Future<void> _loadCachedStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getBool(_subscriptionKey) ?? false;
    
    if (cached) {
      // Check if subscription has expired
      final expiryString = prefs.getString(_subscriptionExpiryKey);
      if (expiryString != null) {
        final expiry = DateTime.tryParse(expiryString);
        if (expiry != null && expiry.isAfter(DateTime.now())) {
          _status = SubscriptionStatus.subscribed;
          debugPrint('💳 [SUBSCRIPTION] Loaded cached subscription (valid until $expiry)');
        } else {
          _status = SubscriptionStatus.expired;
          debugPrint('💳 [SUBSCRIPTION] Cached subscription expired');
        }
      }
    } else {
      _status = SubscriptionStatus.notSubscribed;
    }
    
    _statusController.add(_status);
  }

  /// Get product by ID
  ProductDetails? getProduct(String productId) {
    try {
      return _products.firstWhere((p) => p.id == productId);
    } catch (_) {
      return null;
    }
  }

  /// Get monthly product
  ProductDetails? get monthlyProduct => getProduct(SubscriptionProducts.monthlyId);

  /// Get yearly product
  ProductDetails? get yearlyProduct => getProduct(SubscriptionProducts.yearlyId);

  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
    _errorController.close();
  }
}

