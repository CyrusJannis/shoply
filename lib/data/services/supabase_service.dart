import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shoply/core/config/env.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  // Sign in with Google (Native - more reliable)
  Future<AuthResponse> signInWithGoogle() async {
    try {
      print('🔵 Starting native Google Sign-In...');
      
      // Initialize Google Sign-In
      final googleSignIn = GoogleSignIn(
        // serverClientId is the Web Client ID - used for backend token verification
        serverClientId: '901497821159-c2u63ailh5c2kunnsje62ol7ffekk50f.apps.googleusercontent.com',
        // clientId will be automatically read from Info.plist (iOS Client ID)
      );
      
      // Trigger Google Sign-In flow
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }
      
      print('🟢 Google user signed in: ${googleUser.email}');
      
      // Get Google Auth credentials
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;
      
      if (accessToken == null) {
        throw Exception('No Access Token found');
      }
      if (idToken == null) {
        throw Exception('No ID Token found');
      }
      
      print('🟢 Got tokens, signing in to Supabase...');
      print('🔵 ID Token: ${idToken.substring(0, 50)}...');
      print('🔵 Access Token: ${accessToken.substring(0, 50)}...');
      
      // Sign in to Supabase with Google credentials
      // Use the simpler signInWithIdToken without nonce
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
      
      print('✅ Successfully signed in to Supabase');
      return response;
    } catch (e) {
      print('🔴 Google Sign-In Error: $e');
      print('🔴 Error type: ${e.runtimeType}');
      rethrow;
    }
  }

  // Sign in with Apple (Native iOS)
  Future<AuthResponse> signInWithApple() async {
    try {
      // Get Apple ID credential
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Sign in to Supabase with the credential
      final response = await client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        nonce: credential.state,
      );

      return response;
    } catch (e) {
      print('Apple Sign-In Error: $e');
      rethrow;
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
