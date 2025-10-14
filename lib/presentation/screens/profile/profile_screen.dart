import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/data/services/supabase_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.instance.currentUser;
    final email = user?.email ?? 'No email';
    final displayName = user?.userMetadata?['display_name'] ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile', style: AppTextStyles.h2),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenHorizontalPadding),
        children: [
          // Profile Section
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: AppDimensions.avatarSizeLarge / 2,
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
                    style: AppTextStyles.h1,
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingMedium),
                Text(displayName, style: AppTextStyles.h2),
                Text(
                  email,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacingXLarge),
          
          // Settings Sections
          _buildSectionTitle('Preferences'),
          _buildListTile(
            context,
            icon: Icons.person_outline,
            title: 'Display Name',
            subtitle: displayName,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Edit name coming soon')),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.restaurant,
            title: 'Diet Preferences',
            subtitle: 'No restrictions',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Diet preferences coming soon')),
              );
            },
          ),
          _buildListTile(
            context,
            icon: Icons.language,
            title: 'Language',
            subtitle: 'German',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language settings coming soon')),
              );
            },
          ),
          
          const SizedBox(height: AppDimensions.spacingLarge),
          
          _buildSectionTitle('Appearance'),
          _buildListTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Theme',
            subtitle: 'System Default',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme settings coming soon')),
              );
            },
          ),
          
          const SizedBox(height: AppDimensions.spacingLarge),
          
          _buildSectionTitle('Notifications'),
          _buildListTile(
            context,
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Enabled',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification settings coming soon')),
              );
            },
          ),
          
          const SizedBox(height: AppDimensions.spacingLarge),
          
          _buildSectionTitle('Help & Support'),
          _buildListTile(
            context,
            icon: Icons.help_outline,
            title: 'Help & Tips',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help coming soon')),
              );
            },
          ),
          
          const SizedBox(height: AppDimensions.spacingLarge),
          
          _buildSectionTitle('About'),
          _buildListTile(
            context,
            icon: Icons.info_outline,
            title: 'App Version',
            subtitle: '1.0.0',
          ),
          
          const SizedBox(height: AppDimensions.spacingXLarge),
          
          // Sign Out Button
          ElevatedButton.icon(
            onPressed: () async {
              await SupabaseService.instance.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: AppDimensions.spacingSmall,
        top: AppDimensions.spacingMedium,
      ),
      child: Text(
        title,
        style: AppTextStyles.h3.copyWith(color: Colors.grey),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppDimensions.spacingSmall),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
        onTap: onTap,
      ),
    );
  }
}
