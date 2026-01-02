import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:adaptive_platform_ui/adaptive_platform_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shoply/core/localization/app_localizations.dart';
import 'package:shoply/core/theme/app_theme.dart';
import 'package:shoply/core/widgets/update_dialog.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:shoply/presentation/state/theme_provider.dart';
import 'package:shoply/presentation/state/language_provider.dart';
import 'package:shoply/presentation/widgets/dynamic_tutorial_overlay.dart';
import 'package:shoply/routes/app_router.dart';
import 'package:shoply/data/services/deep_link_service.dart';

class ShoplyAIApp extends ConsumerStatefulWidget {
  const ShoplyAIApp({super.key});

  @override
  ConsumerState<ShoplyAIApp> createState() => _ShoplyAIAppState();
}

class _ShoplyAIAppState extends ConsumerState<ShoplyAIApp> {
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    
    // Initialize deep link service after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDeepLinks();
    });
    
    _authSubscription = SupabaseService.instance.authStateChanges.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
           ref.read(routerProvider).go('/reset-password');
        });
      }
    });
  }
  
  /// Initialize deep link handling
  Future<void> _initializeDeepLinks() async {
    try {
      final router = ref.read(routerProvider);
      await DeepLinkService.instance.initialize(router);
      
      // Process any pending deep link that opened the app
      DeepLinkService.instance.processPendingDeepLink();
    } catch (e) {
      debugPrint('⚠️ [APP] Failed to initialize deep links: $e');
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    // Watch theme mode
    final themeMode = ref.watch(themeModeProvider);
    // Watch language
    final languageCode = ref.watch(languageProvider);

    return AdaptiveApp.router(
      key: ValueKey('$themeMode-$languageCode'), // Force rebuild when theme or language changes
      title: 'Shoply',
      materialLightTheme: AppTheme.lightTheme,
      materialDarkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      // Localization - use selected language
      locale: Locale(languageCode),
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

        // Wrap with dynamic tutorial overlay
        return DynamicTutorialOverlay(
          child: child!,
        );
      },
    );
  }
}
