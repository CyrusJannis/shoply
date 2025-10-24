import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoply/core/constants/app_dimensions.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:shoply/presentation/state/auth_provider.dart';

class PersonalInfoScreen extends ConsumerStatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  ConsumerState<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends ConsumerState<PersonalInfoScreen> {
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  String _selectedHeightUnit = 'cm';
  String? _selectedGender;
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) return;

    try {
      final response = await SupabaseService.instance
          .from('users')
          .select('age, height, height_unit, gender')
          .eq('id', user.id)
          .maybeSingle();

      if (response != null && mounted) {
        setState(() {
          if (response['age'] != null) {
            _ageController.text = response['age'].toString();
          }
          if (response['height'] != null) {
            _heightController.text = response['height'].toString();
          }
          _selectedHeightUnit = response['height_unit'] as String? ?? 'cm';
          _selectedGender = response['gender'] as String?;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _saveChanges() async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final age = _ageController.text.isNotEmpty ? int.parse(_ageController.text) : null;
      final height = _heightController.text.isNotEmpty ? double.parse(_heightController.text) : null;

      await SupabaseService.instance.from('users').update({
        'age': age,
        'height': height,
        'height_unit': _selectedHeightUnit,
        'gender': _selectedGender,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);

      if (mounted) {
        setState(() => _hasChanges = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal information updated')),
        );
        // Refresh user data
        ref.invalidate(currentUserProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppDimensions.screenHorizontalPadding),
        children: [
          // Age section
          Text(
            'Age',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: const InputDecoration(
                hintText: 'Enter your age',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
                suffixText: 'years',
              ),
              onChanged: (_) => setState(() => _hasChanges = true),
            ),
          ),

          const SizedBox(height: 24),

          // Height section
          Text(
            'Height',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

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
          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800.withOpacity(0.3) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: TextField(
              controller: _heightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: InputDecoration(
                hintText: _selectedHeightUnit == 'cm' ? '170' : '5.7',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                suffixText: _selectedHeightUnit,
              ),
              onChanged: (_) => setState(() => _hasChanges = true),
            ),
          ),

          const SizedBox(height: 24),

          // Gender section
          Text(
            'Gender',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          _buildGenderCard(
            context,
            gender: 'male',
            icon: Icons.male_rounded,
            label: 'Male',
          ),
          const SizedBox(height: 12),
          _buildGenderCard(
            context,
            gender: 'female',
            icon: Icons.female_rounded,
            label: 'Female',
          ),
          const SizedBox(height: 12),
          _buildGenderCard(
            context,
            gender: 'other',
            icon: Icons.transgender_rounded,
            label: 'Other',
          ),
          const SizedBox(height: 12),
          _buildGenderCard(
            context,
            gender: 'prefer_not_to_say',
            icon: Icons.help_outline_rounded,
            label: 'Prefer not to say',
          ),

          const SizedBox(height: 32),

          // Info text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.blue.shade900.withOpacity(0.2) : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This information helps us provide personalized nutrition recommendations.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitButton(BuildContext context, String unit, String label) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final isSelected = _selectedHeightUnit == unit;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedHeightUnit = unit;
          _heightController.clear();
          _hasChanges = true;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
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
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? (isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600)
                    : null,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
              ),
            ),
          ],
        ),
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
          _hasChanges = true;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDarkMode ? Colors.blue.shade400.withOpacity(0.3) : Colors.blue.shade100)
                    : (isDarkMode ? Colors.grey.shade700.withOpacity(0.3) : Colors.grey.shade200),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected
                    ? (isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600)
                    : (isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
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
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
