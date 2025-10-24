import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:shoply/core/localization/app_localizations.dart';
import 'package:shoply/core/theme/app_theme.dart';
import 'package:shoply/core/widgets/update_dialog.dart';
import 'package:shoply/presentation/state/language_provider.dart';
import 'package:shoply/presentation/state/theme_provider.dart';
import 'package:shoply/routes/app_router.dart';

class ShoplyAIApp extends ConsumerWidget {
  const ShoplyAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Watch language to rebuild app when it changes
    final language = ref.watch(languageProvider);
    // Watch theme mode
    final themeMode = ref.watch(themeModeProvider);

    return AdaptiveApp.router(
      key: ValueKey('$language-$themeMode'), // Force rebuild when language or theme changes
      title: 'Shoply',
      materialLightTheme: AppTheme.lightTheme,
      materialDarkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      // Localization
      locale: Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // Show update dialog on first launch of new version
      builder: (context, child) {
        // Show update dialog for new versions
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showUpdateDialogIfNeeded(context);
        });

        return child!;
      },
    );
  }
}
