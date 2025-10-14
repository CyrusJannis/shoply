import 'package:flutter/material.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/data/services/supabase_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.instance.currentUser;
    final displayName = user?.userMetadata?['display_name'] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hello, $displayName',
          style: AppTextStyles.h2,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // Show notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDimensions.screenHorizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shopping History Widget
            _buildWidgetCard(
              context,
              title: 'Recent Shopping Trips',
              icon: Icons.history,
              child: const Text('No recent shopping trips'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History feature coming soon')),
                );
              },
            ),
            
            const SizedBox(height: AppDimensions.cardMargin),
            
            // Promotional Flyers Widget
            _buildWidgetCard(
              context,
              title: 'Current Offers',
              icon: Icons.local_offer,
              child: const Text('No active offers'),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Flyers feature coming soon')),
                );
              },
            ),
            
            const SizedBox(height: AppDimensions.spacingLarge),
            
            // Quick Actions
            Text('Quick Actions', style: AppTextStyles.h2),
            const SizedBox(height: AppDimensions.spacingMedium),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Create new list
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Create list coming soon')),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('New List'),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingMedium),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Scan barcode
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Scanner coming soon')),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: AppDimensions.spacingLarge),
            
            // Smart Recommendations
            Text('You might need...', style: AppTextStyles.h2),
            const SizedBox(height: AppDimensions.spacingMedium),
            
            const Center(
              child: Text('No recommendations yet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWidgetCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.cardBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const SizedBox(width: AppDimensions.spacingSmall),
                  Text(title, style: AppTextStyles.h3),
                  const Spacer(),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingMedium),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
