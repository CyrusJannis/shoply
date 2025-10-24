import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/presentation/state/onboarding_provider.dart';
import 'package:shoply/presentation/widgets/onboarding/onboarding_layout.dart';

class OnboardingDietPreferencesScreen extends ConsumerStatefulWidget {
  const OnboardingDietPreferencesScreen({super.key});

  @override
  ConsumerState<OnboardingDietPreferencesScreen> createState() =>
      _OnboardingDietPreferencesScreenState();
}

class _OnboardingDietPreferencesScreenState
    extends ConsumerState<OnboardingDietPreferencesScreen> {
  final List<DietPreference> _preferences = [
    DietPreference(
      id: 'vegetarian',
      label: 'Vegetarian',
      icon: Icons.eco_rounded,
      description: 'No meat or fish',
    ),
    DietPreference(
      id: 'vegan',
      label: 'Vegan',
      icon: Icons.spa_rounded,
      description: 'No animal products',
    ),
    DietPreference(
      id: 'gluten_free',
      label: 'Gluten-Free',
      icon: Icons.grain_rounded,
      description: 'No gluten-containing foods',
    ),
    DietPreference(
      id: 'dairy_free',
      label: 'Dairy-Free',
      icon: Icons.no_drinks_rounded,
      description: 'No milk or dairy products',
    ),
    DietPreference(
      id: 'keto',
      label: 'Keto',
      icon: Icons.fitness_center_rounded,
      description: 'Low-carb, high-fat diet',
    ),
    DietPreference(
      id: 'paleo',
      label: 'Paleo',
      icon: Icons.nature_people_rounded,
      description: 'Whole foods, no processed items',
    ),
    DietPreference(
      id: 'low_carb',
      label: 'Low-Carb',
      icon: Icons.trending_down_rounded,
      description: 'Reduced carbohydrate intake',
    ),
    DietPreference(
      id: 'halal',
      label: 'Halal',
      icon: Icons.mosque_rounded,
      description: 'Islamic dietary laws',
    ),
    DietPreference(
      id: 'kosher',
      label: 'Kosher',
      icon: Icons.star_rounded,
      description: 'Jewish dietary laws',
    ),
    DietPreference(
      id: 'pescatarian',
      label: 'Pescatarian',
      icon: Icons.set_meal_rounded,
      description: 'Vegetarian plus fish',
    ),
    DietPreference(
      id: 'nut_free',
      label: 'Nut-Free',
      icon: Icons.block_rounded,
      description: 'No nuts or nut products',
    ),
    DietPreference(
      id: 'low_sodium',
      label: 'Low-Sodium',
      icon: Icons.water_drop_rounded,
      description: 'Reduced salt intake',
    ),
  ];

  Set<String> _selectedPreferences = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPreferences = Set.from(ref.read(onboardingDataProvider).dietPreferences);
  }

  Future<void> _onComplete() async {
    setState(() => _isLoading = true);

    try {
      ref
          .read(onboardingDataProvider.notifier)
          .updateDietPreferences(_selectedPreferences.toList());

      // Save to backend
      await ref.read(onboardingDataProvider.notifier).saveToBackend();

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      title: 'Dietary Preferences',
      subtitle: 'Select all that apply. You can always change these later.',
      currentStep: 4,
      totalSteps: 4,
      isNextEnabled: !_isLoading,
      onBack: () => context.pop(),
      onNext: _onComplete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selected count
          if (_selectedPreferences.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${_selectedPreferences.length} selected',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withOpacity(0.6),
                    ),
              ),
            ),

          // Preference cards
          ..._preferences.map((pref) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPreferenceCard(context, pref),
              )),

          const SizedBox(height: 16),

          // No restrictions option
          _buildNoRestrictionsCard(context),

          const SizedBox(height: 24),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard(BuildContext context, DietPreference preference) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isSelected = _selectedPreferences.contains(preference.id);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedPreferences.remove(preference.id);
          } else {
            _selectedPreferences.add(preference.id);
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? Colors.blue.shade400.withOpacity(0.2) : Colors.blue.shade50)
              : (isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600)
                : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDarkMode ? Colors.blue.shade400.withOpacity(0.3) : Colors.blue.shade100)
                    : (isDarkMode ? Colors.grey.shade700.withOpacity(0.3) : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                preference.icon,
                size: 24,
                color: isSelected
                    ? (isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600)
                    : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preference.label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? (isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    preference.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? (isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? (isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600)
                      : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoRestrictionsCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isSelected = _selectedPreferences.isEmpty;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedPreferences.clear();
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? Colors.green.shade400.withOpacity(0.2) : Colors.green.shade50)
              : (isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDarkMode ? Colors.green.shade400 : Colors.green.shade600)
                : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDarkMode ? Colors.green.shade400.withOpacity(0.3) : Colors.green.shade100)
                    : (isDarkMode ? Colors.grey.shade700.withOpacity(0.3) : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 24,
                color: isSelected
                    ? (isDarkMode ? Colors.green.shade300 : Colors.green.shade600)
                    : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Restrictions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected
                          ? (isDarkMode ? Colors.green.shade300 : Colors.green.shade600)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'I eat everything',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DietPreference {
  final String id;
  final String label;
  final IconData icon;
  final String description;

  const DietPreference({
    required this.id,
    required this.label,
    required this.icon,
    required this.description,
  });
}
