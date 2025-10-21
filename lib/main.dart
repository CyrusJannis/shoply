import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shoply/app.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:shoply/data/services/native_oauth_service.dart';
import 'package:shoply/data/services/product_classifier_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize Hive for local storage
    await Hive.initFlutter();

    // Initialize Supabase
    await SupabaseService.initialize();
    
    // Initialize Native OAuth Service
    await NativeOAuthService.initialize();
    
    // Initialize Product Classifier Service
    await ProductClassifierService.instance.initialize();

    // Handle deep links for OAuth - this ensures the app returns from browser
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        print('✅ User signed in successfully');
      } else if (event == AuthChangeEvent.signedOut) {
        print('👋 User signed out');
      }
    });
  } catch (e, stackTrace) {
    print('❌ Error during initialization: $e');
    print('Stack trace: $stackTrace');
  }

  // Run the app
  runApp(
    const ProviderScope(
      child: ShoplyAIApp(),
    ),
  );
}
