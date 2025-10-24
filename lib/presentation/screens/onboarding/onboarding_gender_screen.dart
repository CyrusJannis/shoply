import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/presentation/state/onboarding_provider.dart';
import 'package:shoply/presentation/widgets/onboarding/onboarding_layout.dart';

class OnboardingGenderScreen extends ConsumerStatefulWidget {
  const OnboardingGenderScreen({super.key});

  @override
  ConsumerState<OnboardingGenderScreen> createState() => _OnboardingGenderScreenState();
}

class _OnboardingGenderScreenState extends ConsumerState<OnboardingGenderScreen> {
  String? _selectedGender;
  
  @override
  void initState() {
    super.initState();
    _selectedGender = ref.read(onboardingDataProvider).gender;
  }

  void _onNext() {
    if (_selectedGender != null) {
      ref.read(onboardingDataProvider.notifier).updateGender(_selectedGender!);
      context.push('/onboarding/diet-preferences');
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingLayout(
      title: 'What\'s your gender?',
      subtitle: 'This helps us provide personalized nutrition recommendations.',
      currentStep: 3,
      totalSteps: 4,
      isNextEnabled: _selectedGender != null,
      onBack: () => context.pop(),
      onSkip: () => context.go('/login'),
      onNext: _onNext,
      child: Column(
        children: [
          _buildGenderCard(
            context,
            gender: 'male',
            icon: Icons.male_rounded,
            label: 'Male',
          ),
          const SizedBox(height: 16),
          _buildGenderCard(
            context,
            gender: 'female',
            icon: Icons.female_rounded,
            label: 'Female',
          ),
          const SizedBox(height: 16),
          _buildGenderCard(
            context,
            gender: 'other',
            icon: Icons.transgender_rounded,
            label: 'Other',
          ),
          const SizedBox(height: 16),
          _buildGenderCard(
            context,
            gender: 'prefer_not_to_say',
            icon: Icons.help_outline_rounded,
            label: 'Prefer not to say',
          ),
        ],
      ),
    );
  }

  Widget _buildGenderCard(
    BuildContext context, {
    required String gender,
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isSelected = _selectedGender == gender;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedGender = gender;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
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
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDarkMode ? Colors.blue.shade400.withOpacity(0.3) : Colors.blue.shade100)
                    : (isDarkMode ? Colors.grey.shade700.withOpacity(0.3) : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 32,
                color: isSelected
                    ? (isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600)
                    : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? (isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600)
                      : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
