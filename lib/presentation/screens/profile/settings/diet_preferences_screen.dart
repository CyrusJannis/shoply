import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoply/core/constants/app_colors.dart';
import 'package:shoply/core/constants/categories.dart';
import 'package:shoply/presentation/state/auth_provider.dart';
import 'package:shoply/core/localization/localization_helper.dart';

class DietPreferencesScreen extends ConsumerStatefulWidget {
  const DietPreferencesScreen({super.key});

  @override
  ConsumerState<DietPreferencesScreen> createState() => _DietPreferencesScreenState();
}

class _DietPreferencesScreenState extends ConsumerState<DietPreferencesScreen> {
  Set<String> _selectedPreferences = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value;
    _selectedPreferences = Set.from(user?.dietPreferences ?? []);
  }

  Future<void> _savePreferences() async {
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateDietPreferences(_selectedPreferences.toList());
      
      // Refresh user data
      ref.invalidate(currentUserProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('diet_prefs_saved')),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('diet_preferences')),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _savePreferences,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(context.tr('save'), style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            context.tr('select_diet_prefs'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            context.tr('diet_warning_desc'),
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ...Categories.dietPreferences.map((preference) {
            final isSelected = _selectedPreferences.contains(preference);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                title: Text(preference),
                subtitle: _getDietDescription(preference),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedPreferences.add(preference);
                    } else {
                      _selectedPreferences.remove(preference);
                    }
                  });
                },
                activeColor: AppColors.info,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget? _getDietDescription(String preference) {
    final descriptions = {
      'None / No restrictions': 'Keine Einschränkungen',
      'Vegetarian': 'Kein Fleisch oder Fisch',
      'Vegan': 'Keine tierischen Produkte',
      'Gluten-free': 'Kein Gluten (Weizen, etc.)',
      'Lactose-free': 'Keine Laktose (Milchprodukte)',
      'Low-carb / Keto': 'Wenig Kohlenhydrate',
      'Halal': 'Nach islamischen Regeln',
      'Kosher': 'Nach jüdischen Regeln',
      'Nut allergy': 'Keine Nüsse',
      'Other allergies': 'Andere Allergien',
    };

    final desc = descriptions[preference];
    return desc != null ? Text(desc, style: const TextStyle(fontSize: 12)) : null;
  }
}
