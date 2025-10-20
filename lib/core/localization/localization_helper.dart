import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoply/core/localization/app_translations.dart';
import 'package:shoply/presentation/state/language_provider.dart';

extension LocalizationExtension on BuildContext {
  String tr(String key, {Map<String, String>? params}) {
    // Get language from provider
    final container = ProviderScope.containerOf(this);
    final languageCode = container.read(languageProvider);
    return AppTranslations.get(key, languageCode, params: params);
  }
}
