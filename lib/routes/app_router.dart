import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/presentation/screens/auth/login_screen.dart';
import 'package:shoply/presentation/screens/auth/signup_screen.dart';
import 'package:shoply/presentation/screens/home/home_screen.dart';
import 'package:shoply/presentation/screens/ai/ai_screen.dart';
import 'package:shoply/presentation/screens/recipes/recipes_screen.dart';
import 'package:shoply/presentation/screens/recipes/recipe_detail_screen.dart';
import 'package:shoply/presentation/screens/recipes/add_recipe_screen.dart';
import 'package:shoply/presentation/screens/profile/profile_screen.dart';
import 'package:shoply/presentation/screens/lists/list_detail_screen.dart';
import 'package:shoply/presentation/screens/main_scaffold.dart';
import 'package:shoply/presentation/screens/onboarding/onboarding_welcome_screen.dart';
import 'package:shoply/presentation/screens/onboarding/onboarding_age_screen.dart';
import 'package:shoply/presentation/screens/onboarding/onboarding_height_screen.dart';
import 'package:shoply/presentation/screens/onboarding/onboarding_gender_screen.dart';
import 'package:shoply/presentation/screens/onboarding/onboarding_diet_preferences_screen.dart';
import 'package:shoply/data/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Helper class to refresh GoRouter when auth state changes
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<AuthState> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
      (AuthState _) {
        notifyListeners();
      },
    );
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final supabase = SupabaseService.instance;
  
  return GoRouter(
    initialLocation: '/login',
    refreshListenable: GoRouterRefreshStream(supabase.authStateChanges),
    routes: [
      // Auth routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      
      // Onboarding routes
      GoRoute(
        path: '/onboarding',
        name: 'onboarding-welcome',
        builder: (context, state) => const OnboardingWelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/age',
        name: 'onboarding-age',
        builder: (context, state) => const OnboardingAgeScreen(),
      ),
      GoRoute(
        path: '/onboarding/height',
        name: 'onboarding-height',
        builder: (context, state) => const OnboardingHeightScreen(),
      ),
      GoRoute(
        path: '/onboarding/gender',
        name: 'onboarding-gender',
        builder: (context, state) => const OnboardingGenderScreen(),
      ),
      GoRoute(
        path: '/onboarding/diet-preferences',
        name: 'onboarding-diet-preferences',
        builder: (context, state) => const OnboardingDietPreferencesScreen(),
      ),
      
      // Main app with bottom navigation
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/lists/:listId',
            name: 'list-detail',
            builder: (context, state) {
              final listId = state.pathParameters['listId']!;
              final listName = state.uri.queryParameters['name'] ?? 'Shopping List';
              return ListDetailScreen(
                listId: listId,
                listName: listName,
              );
            },
          ),
          GoRoute(
            path: '/ai',
            name: 'ai',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AIScreen(),
            ),
          ),
          GoRoute(
            path: '/recipes',
            name: 'recipes',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const RecipesScreen(),
            ),
            routes: [
              GoRoute(
                path: 'add',
                name: 'add-recipe',
                builder: (context, state) => const AddRecipeScreen(),
              ),
              GoRoute(
                path: ':recipeId',
                name: 'recipe-detail',
                builder: (context, state) {
                  final recipeId = state.pathParameters['recipeId']!;
                  return RecipeDetailScreen(recipeId: recipeId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
    redirect: (context, state) async {
      final isLoggedIn = SupabaseService.instance.currentUser != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSigningUp = state.matchedLocation == '/signup';
      final isOnboarding = state.matchedLocation.startsWith('/onboarding');
      
      // Not logged in - redirect to login
      if (!isLoggedIn && !isLoggingIn && !isSigningUp && !isOnboarding) {
        return '/login';
      }
      
      // Logged in - check onboarding status
      if (isLoggedIn) {
        try {
          final user = SupabaseService.instance.currentUser;
          if (user != null) {
            final response = await SupabaseService.instance
                .from('users')
                .select('onboarding_completed')
                .eq('id', user.id)
                .maybeSingle();
            
            final onboardingCompleted = response?['onboarding_completed'] as bool? ?? false;
            
            // If not completed onboarding and not on onboarding/login/signup pages
            if (!onboardingCompleted && !isOnboarding && !isLoggingIn && !isSigningUp) {
              return '/onboarding';
            }
            
            // If completed onboarding and on login/signup pages
            if (onboardingCompleted && (isLoggingIn || isSigningUp)) {
              return '/home';
            }
          }
        } catch (e) {
          // On error, allow navigation to continue
          print('Error checking onboarding status: $e');
        }
      }
      
      return null;
    },
  );
});
