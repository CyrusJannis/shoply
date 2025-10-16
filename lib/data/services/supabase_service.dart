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

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    return await client.auth.signInWithOAuth(OAuthProvider.google);
  }

  // Sign in with Apple
  Future<bool> signInWithApple() async {
    return await client.auth.signInWithOAuth(OAuthProvider.apple);
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

  // Database methods
  PostgrestQueryBuilder from(String table) => client.from(table);

  // Storage methods
  SupabaseStorageClient get storage => client.storage;

  // Realtime methods
  RealtimeChannel channel(String name) => client.channel(name);
}
