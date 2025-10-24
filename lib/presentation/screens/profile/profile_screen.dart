import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:shoply/presentation/screens/profile/settings/display_name_screen.dart';
import 'package:shoply/presentation/screens/profile/settings/personal_info_screen.dart';
import 'package:shoply/presentation/screens/profile/settings/diet_preferences_screen.dart';
import 'package:shoply/presentation/screens/profile/settings/language_screen.dart';
import 'package:shoply/presentation/screens/profile/settings/theme_screen.dart';
import 'package:shoply/presentation/screens/profile/settings/notifications_screen.dart';
import 'package:shoply/presentation/screens/profile/settings/help_support_screen.dart';
import 'package:shoply/presentation/state/language_provider.dart';
import 'package:shoply/core/localization/localization_helper.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = SupabaseService.instance.currentUser;
    final email = user?.email ?? 'No email';
    final displayName = user?.userMetadata?['display_name'] ?? 'User';
    final currentLanguage = ref.watch(languageProvider);
    
    final languageNames = {
      'de': 'Deutsch',
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'it': 'Italiano',
      'tr': 'Türkçe',
    };
    final languageName = languageNames[currentLanguage] ?? 'Deutsch';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('profile'), style: AppTextStyles.h2),
      ),
      body: ListView(
        padding: const EdgeInsets.only(
          left: AppDimensions.screenHorizontalPadding,
          right: AppDimensions.screenHorizontalPadding,
          top: AppDimensions.screenHorizontalPadding,
          bottom: 120, // Extra Padding für Navigation Bar
        ),
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
          _buildSectionTitle(context.tr('preferences')),
          _buildListTile(
            context,
            icon: Icons.person_outline,
            title: context.tr('display_name'),
            subtitle: displayName,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DisplayNameScreen()),
            ),
          ),
          _buildListTile(
            context,
            icon: Icons.badge_outlined,
            title: 'Personal Information',
            subtitle: 'Age, height, gender',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PersonalInfoScreen()),
            ),
          ),
          _buildListTile(
            context,
            icon: Icons.restaurant,
            title: context.tr('diet_preferences'),
            subtitle: context.tr('no_restrictions'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const DietPreferencesScreen()),
            ),
          ),
          _buildListTile(
            context,
            icon: Icons.language,
            title: context.tr('language'),
            subtitle: languageName,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LanguageScreen()),
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacingLarge),
          
          _buildSectionTitle(context.tr('appearance')),
          _buildListTile(
            context,
            icon: Icons.dark_mode_outlined,
            title: context.tr('theme'),
            subtitle: 'System',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ThemeScreen()),
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacingLarge),
          
          _buildSectionTitle(context.tr('notifications')),
          _buildListTile(
            context,
            icon: Icons.notifications_outlined,
            title: context.tr('push_notifications'),
            subtitle: context.tr('manage_preferences'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacingLarge),
          
          _buildSectionTitle(context.tr('help_support')),
          _buildListTile(
            context,
            icon: Icons.help_outline,
            title: context.tr('help_support'),
            subtitle: 'FAQ, Contact, Feedback',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
            ),
          ),
          
          const SizedBox(height: AppDimensions.spacingLarge),
          
          _buildSectionTitle(context.tr('about')),
          _buildListTile(
            context,
            icon: Icons.info_outline,
            title: context.tr('app_version'),
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
            label: Text(context.tr('sign_out')),
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
