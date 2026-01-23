import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/localization/localization_helper.dart';
import 'package:shoply/data/services/subscription_service.dart';
import 'package:shoply/presentation/providers/subscription_provider.dart';

/// Premium subscription screen - minimalist, premium design matching app style
class SubscriptionScreen extends ConsumerStatefulWidget {
  final bool showCloseButton;
  
  const SubscriptionScreen({
    super.key,
    this.showCloseButton = true,
  });

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  String _selectedProductId = SubscriptionProducts.yearlyId;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final products = ref.watch(subscriptionProductsProvider);
    ref.watch(subscriptionNotifierProvider);
    
    ref.listen(subscriptionErrorProvider, (_, asyncError) {
      asyncError.whenData((error) {
        if (error.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.background(context),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (widget.showCloseButton)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.textSecondary(context),
                          size: 20,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 36),
                  const Spacer(),
                  TextButton(
                    onPressed: _isLoading ? null : _restorePurchases,
                    child: Text(
                      context.tr('restore_purchases'),
                      style: TextStyle(
                        color: AppColors.textTertiary(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    
                    // Premium Icon - Simple and clean
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isDark 
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : AppColors.accent.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.workspace_premium_rounded,
                        size: 40,
                        color: AppColors.accent,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      'Shoply Pro',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      context.tr('unlock_premium_features'),
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Features - Simple list
                    _buildFeaturesList(context, isDark),
                    
                    const SizedBox(height: 40),
                    
                    // Subscription Plans
                    if (products.isNotEmpty)
                      _buildSubscriptionPlans(context, isDark, products)
                    else
                      _buildLoadingPlans(context),
                    
                    const SizedBox(height: 24),
                    
                    // CTA Button
                    _buildCTAButton(context, products),
                    
                    const SizedBox(height: 24),
                    
                    // Terms
                    Text(
                      context.tr('subscription_terms'),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary(context),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesList(BuildContext context, bool isDark) {
    final features = [
      (Icons.restaurant_menu_rounded, context.tr('premium_feature_cooking_mode')),
      (Icons.auto_awesome_rounded, context.tr('premium_feature_ai')),
      (Icons.calendar_month_rounded, context.tr('premium_feature_meal_planning')),
      (Icons.block_rounded, context.tr('premium_feature_no_ads')),
    ];

    return Column(
      children: features.map((feature) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  feature.$1,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  feature.$2,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ),
              Icon(
                Icons.check_rounded,
                color: AppColors.accent,
                size: 22,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubscriptionPlans(BuildContext context, bool isDark, List<ProductDetails> products) {
    final sortedProducts = List<ProductDetails>.from(products)
      ..sort((a, b) => a.id == SubscriptionProducts.yearlyId ? -1 : 1);

    return Column(
      children: sortedProducts.map((product) {
        final isSelected = _selectedProductId == product.id;
        final isYearly = product.id == SubscriptionProducts.yearlyId;
        
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedProductId = product.id);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.accent.withValues(alpha: 0.1)
                  : AppColors.surface(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? AppColors.accent
                    : AppColors.border(context),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Radio
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected 
                          ? AppColors.accent
                          : AppColors.textTertiary(context),
                      width: 2,
                    ),
                    color: isSelected ? AppColors.accent : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                
                // Plan info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isYearly ? context.tr('yearly') : context.tr('monthly'),
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary(context),
                            ),
                          ),
                          if (isYearly) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                context.tr('save_percent', params: {'percent': '50'}),
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isYearly
                            ? context.tr('billed_yearly')
                            : context.tr('billed_monthly'),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Price
                Text(
                  product.price,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLoadingPlans(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(AppColors.accent),
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            context.tr('loading_subscriptions'),
            style: TextStyle(color: AppColors.textSecondary(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildCTAButton(BuildContext context, List<ProductDetails> products) {
    final selectedProduct = products.where((p) => p.id == _selectedProductId).firstOrNull;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading || selectedProduct == null 
            ? null 
            : () => _subscribe(selectedProduct),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                context.tr('subscribe_now'),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _subscribe(ProductDetails product) async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    
    debugPrint('💳 [UI] Starting purchase for: ${product.id}');
    
    final success = await ref.read(subscriptionNotifierProvider.notifier).purchase(product);
    
    debugPrint('💳 [UI] Purchase initiated: $success');
    
    if (mounted) {
      if (!success) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _restorePurchases() async {
    HapticFeedback.mediumImpact();
    setState(() => _isLoading = true);
    
    await ref.read(subscriptionNotifierProvider.notifier).restore();
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      if (ref.read(isSubscribedProvider)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('purchases_restored')),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('no_purchases_found')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
}

/// Show subscription screen as a full-screen modal
Future<bool?> showSubscriptionSheet(BuildContext context) {
  return Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (context) => const SubscriptionScreen(),
    ),
  );
}
