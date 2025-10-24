import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/presentation/state/onboarding_provider.dart';
import 'package:shoply/presentation/widgets/onboarding/onboarding_layout.dart';

class OnboardingHeightScreen extends ConsumerStatefulWidget {
  const OnboardingHeightScreen({super.key});

  @override
  ConsumerState<OnboardingHeightScreen> createState() => _OnboardingHeightScreenState();
}

class _OnboardingHeightScreenState extends ConsumerState<OnboardingHeightScreen> {
  final _heightController = TextEditingController();
  String _selectedUnit = 'cm';
  
  @override
  void initState() {
    super.initState();
    final data = ref.read(onboardingDataProvider);
    if (data.height != null) {
      _heightController.text = data.height!.toStringAsFixed(0);
      _selectedUnit = data.heightUnit ?? 'cm';
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    super.dispose();
  }

  bool get _isValid {
    final text = _heightController.text;
    if (text.isEmpty) return false;
    final height = double.tryParse(text);
    if (height == null) return false;
    
    if (_selectedUnit == 'cm') {
      return height >= 100 && height <= 250;
    } else {
      return height >= 3 && height <= 8;
    }
  }

  void _onNext() {
    final height = double.parse(_heightController.text);
    ref.read(onboardingDataProvider.notifier).updateHeight(height, _selectedUnit);
    context.push('/onboarding/gender');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return OnboardingLayout(
      title: 'What\'s your height?',
      subtitle: 'Help us calculate your nutritional needs accurately.',
      currentStep: 2,
      totalSteps: 4,
      isNextEnabled: _isValid,
      onBack: () => context.pop(),
      onSkip: () => context.go('/login'),
      onNext: _onNext,
      child: Column(
        children: [
          // Unit selector
          Row(
            children: [
              Expanded(
                child: _buildUnitButton(context, 'cm', 'Centimeters'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUnitButton(context, 'ft', 'Feet'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Height input field
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: _selectedUnit == 'cm' ? '170' : '5.7',
                      hintStyle: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.3),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 24),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Text(
                    _selectedUnit,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Helper text
          Text(
            _selectedUnit == 'cm' 
                ? 'Enter height between 100-250 cm'
                : 'Enter height between 3-8 feet',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5),
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Common heights
          Text(
            'Common heights',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _selectedUnit == 'cm'
                ? [
                    _buildHeightChip(context, '150'),
                    _buildHeightChip(context, '160'),
                    _buildHeightChip(context, '170'),
                    _buildHeightChip(context, '180'),
                    _buildHeightChip(context, '190'),
                  ]
                : [
                    _buildHeightChip(context, '5.0'),
                    _buildHeightChip(context, '5.5'),
                    _buildHeightChip(context, '6.0'),
                    _buildHeightChip(context, '6.5'),
                  ],
          ),
        ],
      ),
    );
  }

  Widget _buildUnitButton(BuildContext context, String unit, String label) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isSelected = _selectedUnit == unit;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedUnit = unit;
          _heightController.clear();
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDarkMode ? Colors.blue.shade400.withOpacity(0.2) : Colors.blue.shade50)
              : (isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600)
                : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              unit.toUpperCase(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600)
                    : null,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeightChip(BuildContext context, String height) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        _heightController.text = height;
        setState(() {});
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
          '$height $_selectedUnit',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
