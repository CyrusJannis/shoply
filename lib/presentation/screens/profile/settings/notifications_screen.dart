import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/localization/localization_helper.dart';
import 'package:shoply/data/services/notification_diagnostic_service.dart';
import 'package:shoply/data/services/fcm_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Notification preferences
  bool _recipeLikes = true;
  bool _recipeComments = true;
  bool _listUpdates = true;
  bool _listInvites = true;
  bool _sharedListChanges = true;
  bool _newRecipes = false;
  bool _weeklyDigest = true;
  bool _promotions = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = AppColors.background(context);
    final textPrimary = AppColors.textPrimary(context);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          context.tr('push_notifications'),
          style: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.only(bottom: 100 + MediaQuery.of(context).padding.bottom),
        children: [
          // Rezepte Section
          _buildSectionHeader('🍳 ${context.tr('recipes')}'),
          _buildNotificationTile(
            title: context.tr('recipe_likes'),
            subtitle: context.tr('recipe_likes_desc'),
            value: _recipeLikes,
            onChanged: (val) => setState(() => _recipeLikes = val),
          ),
          _buildNotificationTile(
            title: context.tr('comments'),
            subtitle: context.tr('comments_desc'),
            value: _recipeComments,
            onChanged: (val) => setState(() => _recipeComments = val),
          ),
          _buildNotificationTile(
            title: context.tr('new_recipes_notif'),
            subtitle: context.tr('new_recipes_desc'),
            value: _newRecipes,
            onChanged: (val) => setState(() => _newRecipes = val),
          ),

          const Divider(height: 32),

          // Listen Section
          _buildSectionHeader('📝 ${context.tr('lists')}'),
          _buildNotificationTile(
            title: context.tr('list_updates'),
            subtitle: context.tr('list_updates_desc'),
            value: _listUpdates,
            onChanged: (val) => setState(() => _listUpdates = val),
          ),
          _buildNotificationTile(
            title: context.tr('list_invites'),
            subtitle: context.tr('list_invites_desc'),
            value: _listInvites,
            onChanged: (val) => setState(() => _listInvites = val),
          ),
          _buildNotificationTile(
            title: context.tr('shared_list_changes'),
            subtitle: context.tr('shared_list_changes_desc'),
            value: _sharedListChanges,
            onChanged: (val) => setState(() => _sharedListChanges = val),
          ),

          const Divider(height: 32),

          // Allgemein Section
          _buildSectionHeader('📬 ${context.tr('general')}'),
          _buildNotificationTile(
            title: context.tr('weekly_digest'),
            subtitle: context.tr('weekly_digest_desc'),
            value: _weeklyDigest,
            onChanged: (val) => setState(() => _weeklyDigest = val),
          ),
          _buildNotificationTile(
            title: context.tr('promotions'),
            subtitle: context.tr('promotions_desc'),
            value: _promotions,
            onChanged: (val) => setState(() => _promotions = val),
          ),

          const SizedBox(height: 24),

          // Save Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _savePreferences,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: AppColors.info,
              ),
              child: Text(context.tr('save_settings')),
            ),
          ),

          // Debug Section (only in debug mode)
          if (kDebugMode) ...[
            const Divider(height: 32),
            _buildSectionHeader('🔧 Debug Tools'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    'FCM Token: ${FCMService.instance.token != null ? "✅ Available" : "❌ Not available"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: FCMService.instance.token != null ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _runDiagnostic,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Run Notification Diagnostic'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _sendTestNotification,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Test Notification'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _forceSaveToken,
                    icon: const Icon(Icons.save),
                    label: const Text('Force Save FCM Token'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _runDiagnostic() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🔍 Running diagnostic... check console')),
    );
    
    final results = await NotificationDiagnosticService.instance.runDiagnostic();
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Diagnostic Results'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: results.entries.map((e) => 
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${e.key}: ${e.value}', style: const TextStyle(fontSize: 12)),
                )
              ).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _sendTestNotification() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📤 Sending test notification...')),
    );
    
    final success = await NotificationDiagnosticService.instance.sendTestNotificationToSelf();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? '✅ Test notification sent! Check your device' 
            : '❌ Failed to send. Check console for details'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  Future<void> _forceSaveToken() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('💾 Saving FCM token...')),
    );
    
    final success = await NotificationDiagnosticService.instance.forceSaveFcmToken();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success 
            ? '✅ Token saved to database!' 
            : '❌ Failed to save token'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
      setState(() {}); // Refresh to show updated token status
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildNotificationTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.info,
    );
  }

  void _savePreferences() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Benachrichtigungseinstellungen gespeichert!'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }
}
