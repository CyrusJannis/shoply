import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoply/data/services/supabase_service.dart';

class OnboardingData {
  final int? age;
  final double? height;
  final String? heightUnit;
  final String? gender;
  final List<String> dietPreferences;

  const OnboardingData({
    this.age,
    this.height,
    this.heightUnit = 'cm',
    this.gender,
    this.dietPreferences = const [],
  });

  OnboardingData copyWith({
    int? age,
    double? height,
    String? heightUnit,
    String? gender,
    List<String>? dietPreferences,
  }) {
    return OnboardingData(
      age: age ?? this.age,
      height: height ?? this.height,
      heightUnit: heightUnit ?? this.heightUnit,
      gender: gender ?? this.gender,
      dietPreferences: dietPreferences ?? this.dietPreferences,
    );
  }

  bool get isComplete =>
      age != null &&
      height != null &&
      heightUnit != null &&
      gender != null &&
      dietPreferences.isNotEmpty;
}

class OnboardingDataNotifier extends StateNotifier<OnboardingData> {
  OnboardingDataNotifier() : super(const OnboardingData());

  void updateAge(int age) {
    state = state.copyWith(age: age);
  }

  void updateHeight(double height, String unit) {
    state = state.copyWith(height: height, heightUnit: unit);
  }

  void updateGender(String gender) {
    state = state.copyWith(gender: gender);
  }

  void updateDietPreferences(List<String> preferences) {
    state = state.copyWith(dietPreferences: preferences);
  }

  void toggleDietPreference(String preference) {
    final currentPreferences = List<String>.from(state.dietPreferences);
    if (currentPreferences.contains(preference)) {
      currentPreferences.remove(preference);
    } else {
      currentPreferences.add(preference);
    }
    state = state.copyWith(dietPreferences: currentPreferences);
  }

  Future<void> saveToBackend() async {
    final user = SupabaseService.instance.currentUser;
    if (user == null) return;

    try {
      await SupabaseService.instance.from('users').update({
        'age': state.age,
        'height': state.height,
        'height_unit': state.heightUnit,
        'gender': state.gender,
        'diet_preferences': state.dietPreferences,
        'onboarding_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      rethrow;
    }
  }

  void reset() {
    state = const OnboardingData();
  }
}

final onboardingDataProvider =
    StateNotifierProvider<OnboardingDataNotifier, OnboardingData>((ref) {
  return OnboardingDataNotifier();
});
