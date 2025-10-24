import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/presentation/state/onboarding_provider.dart';
import 'package:shoply/presentation/widgets/onboarding/onboarding_layout.dart';

class OnboardingAgeScreen extends ConsumerStatefulWidget {
  const OnboardingAgeScreen({super.key});

  @override
  ConsumerState<OnboardingAgeScreen> createState() => _OnboardingAgeScreenState();
}

class _OnboardingAgeScreenState extends ConsumerState<OnboardingAgeScreen> {
  final _ageController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    final age = ref.read(onboardingDataProvider).age;
    if (age != null) {
      _ageController.text = age.toString();
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final text = _ageController.text;
    if (text.isEmpty) return false;
    final age = int.tryParse(text);
    return age != null && age >= 13 && age <= 120;
  }

  void _onNext() {
    final age = int.parse(_ageController.text);
    ref.read(onboardingDataProvider.notifier).updateAge(age);
    context.push('/onboarding/height');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return OnboardingLayout(
      title: 'How old are you?',
      subtitle: 'This helps us provide age-appropriate nutrition recommendations.',
      currentStep: 1,
      totalSteps: 4,
      isNextEnabled: _isValid,
      onBack: () => context.pop(),
      onSkip: () => context.go('/login'),
      onNext: _onNext,
      child: Column(
        children: [
          // Age input field
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'Enter your age',
                hintStyle: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 24),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: 16),
          
          // Helper text
          Text(
            'You must be at least 13 years old to use this app',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Quick select buttons
          Text(
            'Or select a range',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              _buildAgeRangeChip(context, '13-17'),
              _buildAgeRangeChip(context, '18-24'),
              _buildAgeRangeChip(context, '25-34'),
              _buildAgeRangeChip(context, '35-44'),
              _buildAgeRangeChip(context, '45-54'),
              _buildAgeRangeChip(context, '55+'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAgeRangeChip(BuildContext context, String range) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        // Set middle value of range
        final parts = range.split('-');
        if (parts.length == 2) {
          if (parts[1] == '+') {
            _ageController.text = '60';
          } else {
            final start = int.parse(parts[0]);
            final end = int.parse(parts[1]);
            _ageController.text = ((start + end) ~/ 2).toString();
          }
          setState(() {});
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Text(
          range,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
