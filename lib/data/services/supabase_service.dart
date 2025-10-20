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

  // Get Google OAuth URL for WebView
  Future<String> getGoogleOAuthUrl() async {
    final response = await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'shoply://auth-callback',
      authScreenLaunchMode: LaunchMode.platformDefault,
    );
    
    // The URL is generated but not opened
    // We'll extract it from the auth flow
    return '${client.auth.currentSession?.accessToken ?? ''}';
  }
  
  // Sign in with Google (WebView OAuth)
  Future<String> getGoogleAuthUrl() async {
    // Generate OAuth URL manually
    final redirectUrl = Uri.encodeComponent('shoply://auth-callback');
    final url = '${Env.supabaseUrl}/auth/v1/authorize?provider=google&redirect_to=$redirectUrl';
    print('Generated OAuth URL: $url');
    return url;
  }
  
  // Handle OAuth callback
  Future<void> handleOAuthCallback(String url) async {
    print('Handling OAuth callback: $url');
    final uri = Uri.parse(url);
    
    // Extract tokens from URL
    final code = uri.queryParameters['code'];
    if (code != null) {
      print('Got auth code, exchanging for session...');
      // The deep link handler in main.dart will handle this
    }
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    return await client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: 'shoply://auth-callback',
    );
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
