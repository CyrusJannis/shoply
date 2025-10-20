import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shoply/core/theme/app_theme.dart';
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

    return MaterialApp.router(
      key: ValueKey('$language-$themeMode'), // Force rebuild when language or theme changes
      title: 'ShoplyAI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
