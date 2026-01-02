import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/app_text_styles.dart';
import 'package:shoply/core/localization/localization_helper.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:shoply/presentation/state/lists_provider.dart';

/// Full screen list settings with member management
class ListSettingsScreen extends ConsumerStatefulWidget {
  final String listId;
  final String listName;
  final String ownerId;

  const ListSettingsScreen({
    super.key,
    required this.listId,
    required this.listName,
    required this.ownerId,
  });

  @override
  ConsumerState<ListSettingsScreen> createState() => _ListSettingsScreenState();
}

class _ListSettingsScreenState extends ConsumerState<ListSettingsScreen> {
  List<Map<String, dynamic>> _members = [];
  bool _isLoading = true;
  String? _currentUserId;
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = SupabaseService.instance.currentUser?.id;
    _isCreator = _currentUserId == widget.ownerId;
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    
    try {
      // Get all members of this list
      final membersResponse = await SupabaseService.instance
          .from('list_members')
          .select('user_id, role')
          .eq('list_id', widget.listId);

      final List<Map<String, dynamic>> members = [];
      
      for (final member in (membersResponse as List)) {
        final userId = member['user_id'] as String;
        final role = member['role'] as String? ?? 'member';
        
        // Fetch user details
        final userResponse = await SupabaseService.instance
            .from('users')
            .select('display_name, avatar_url, email')
            .eq('id', userId)
            .maybeSingle();
        
        members.add({
          'user_id': userId,
          'role': role,
          'display_name': userResponse?['display_name'] as String? ?? 'Unknown',
          'avatar_url': userResponse?['avatar_url'] as String?,
          'email': userResponse?['email'] as String?,
          'is_owner': role == 'owner',
        });
      }
      
      // Sort: owner first, then by name
      members.sort((a, b) {
        if (a['is_owner'] == true && b['is_owner'] != true) return -1;
        if (b['is_owner'] == true && a['is_owner'] != true) return 1;
        return (a['display_name'] as String).compareTo(b['display_name'] as String);
      });
      
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to load members: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeMember(String userId, String displayName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('remove_member')),
        content: Text(context.tr('remove_member_confirm', params: {'name': displayName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('remove')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance
            .from('list_members')
            .delete()
            .eq('list_id', widget.listId)
            .eq('user_id', userId);
        
        HapticFeedback.mediumImpact();
        await _loadMembers();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('member_removed', params: {'name': displayName})),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Failed to remove member: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('error_generic', params: {'error': e.toString()})),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _leaveList() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('leave_list')),
        content: Text(context.tr('leave_list_confirm', params: {'name': widget.listName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('leave')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.instance
            .from('list_members')
            .delete()
            .eq('list_id', widget.listId)
            .eq('user_id', _currentUserId!);
        
        HapticFeedback.heavyImpact();
        
        // Refresh lists and go back to home
        ref.invalidate(listsNotifierProvider);
        
        if (mounted) {
          context.go('/home');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('left_list', params: {'name': widget.listName})),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Failed to leave list: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('error_generic', params: {'error': e.toString()})),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteList() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('delete_list_question')),
        content: Text(context.tr('delete_list_confirm_message', params: {'name': widget.listName})),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(listsNotifierProvider.notifier).deleteList(widget.listId);
        HapticFeedback.heavyImpact();
        
        if (mounted) {
          context.go('/home');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('list_deleted', params: {'name': widget.listName})),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ Failed to delete list: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('error_generic', params: {'error': e.toString()})),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.grey.shade50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('list_settings'),
          style: AppTextStyles.h2.copyWith(fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // List name section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.accentColor(context).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.shopping_cart_rounded,
                            color: AppColors.accentColor(context),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.listName,
                                style: AppTextStyles.h3.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_members.length} ${context.tr('members')}',
                                style: TextStyle(
                                  color: AppColors.textSecondary(context),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Members section
                  Text(
                    context.tr('members'),
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _members.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        indent: 70,
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                      itemBuilder: (context, index) {
                        final member = _members[index];
                        final isOwner = member['is_owner'] == true;
                        final isCurrentUser = member['user_id'] == _currentUserId;
                        final displayName = member['display_name'] as String;
                        final avatarUrl = member['avatar_url'] as String?;
                        final userId = member['user_id'] as String;
                        
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          onTap: () {
                            // Navigate to user's recipe page
                            context.push('/author/$userId', extra: {'authorName': displayName});
                          },
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.accentColor(context).withValues(alpha: 0.2),
                            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentColor(context),
                                    ),
                                  )
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  displayName + (isCurrentUser ? ' (${context.tr('you')})' : ''),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (isOwner)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentColor(context).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    context.tr('creator'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.accentColor(context),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          trailing: _isCreator && !isOwner
                              ? IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  onPressed: () => _removeMember(member['user_id'] as String, displayName),
                                )
                              : null,
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Actions section
                  if (!_isCreator) ...[
                    // Leave list button (for non-creators)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _leaveList,
                        icon: const Icon(Icons.exit_to_app_rounded, color: Colors.red),
                        label: Text(
                          context.tr('leave_list'),
                          style: const TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Delete list button (for creator only)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _deleteList,
                        icon: const Icon(Icons.delete_forever_rounded, color: Colors.white),
                        label: Text(
                          context.tr('delete_list'),
                          style: const TextStyle(color: Colors.white),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('delete_list_hint'),
                      style: TextStyle(
                        color: AppColors.textSecondary(context),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}
