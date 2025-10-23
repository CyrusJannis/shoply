import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shoply/core/config/env.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseClient? _client;

  SupabaseService._();

  static SupabaseService get instance {
    _instance ??= SupabaseService._();
    return _instance!;
  }

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase has not been initialized. Call initialize() first.');
    }
    return _client!;
  }

  // Auth methods
  User? get currentUser => client.auth.currentUser;
  Session? get currentSession => client.auth.currentSession;
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  // Sign in with Google (Platform-specific)
  Future<bool> signInWithGoogle() async {
    // Check if platform supports Google Sign-In
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android) {
      try {
        print('🔵 Starting Google Sign-In...');

        // Use OAuth flow - Supabase handles the redirect URL automatically
        final response = await client.auth.signInWithOAuth(
          OAuthProvider.google,
        );

        return response; // Returns bool indicating if OAuth flow was initiated
      } catch (e) {
        print('🔴 Google Sign-In Error: $e');
        // Check if it's a configuration error
        if (e.toString().contains('validation_failed') || e.toString().contains('OAuth secret')) {
          throw Exception('Google Sign-In ist noch nicht konfiguriert. Bitte verwenden Sie Email/Passwort.');
        }
        rethrow;
      }
    } else {
      // For macOS or other platforms, show unsupported message
      throw Exception('Google Sign-In wird auf dieser Plattform nicht unterstützt. Bitte verwenden Sie Email/Passwort.');
    }
  }

  // Sign in with Apple (iOS only)
  Future<bool> signInWithApple() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        // For iOS, this would use the native Apple Sign-In
        // Since sign_in_with_apple is commented out, use OAuth flow
        final response = await client.auth.signInWithOAuth(
          OAuthProvider.apple,
        );
        return response; // Returns bool indicating if OAuth flow was initiated
      } catch (e) {
        print('Apple Sign-In Error: $e');
        // Check if it's a configuration error
        if (e.toString().contains('validation_failed') || e.toString().contains('OAuth secret')) {
          throw Exception('Apple Sign-In ist noch nicht konfiguriert. Bitte verwenden Sie Email/Passwort.');
        }
        rethrow;
      }
    } else {
      throw Exception('Apple Sign-In ist nur auf iOS-Geräten verfügbar.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Update user
  Future<UserResponse> updateUser(UserAttributes attributes) async {
    return await client.auth.updateUser(attributes);
  }

  // Update user metadata
  Future<void> updateUserMetadata(Map<String, dynamic> metadata) async {
    final userId = client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    // Update auth metadata
    await client.auth.updateUser(UserAttributes(data: metadata));

    // Also update in users table
    if (metadata.containsKey('display_name')) {
      await client.from('users').update({
        'display_name': metadata['display_name'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    }

    if (metadata.containsKey('diet_preferences')) {
      await client.from('users').update({
        'diet_preferences': metadata['diet_preferences'],
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    }
  }

  // Database methods
  PostgrestQueryBuilder from(String table) => client.from(table);

  // Storage methods
  SupabaseStorageClient get storage => client.storage;

  // Realtime methods
  RealtimeChannel channel(String name) => client.channel(name);
}
