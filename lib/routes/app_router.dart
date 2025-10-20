import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/presentation/screens/auth/login_screen.dart';
import 'package:shoply/presentation/screens/auth/signup_screen.dart';
import 'package:shoply/presentation/screens/home/home_screen.dart';
import 'package:shoply/presentation/screens/lists/lists_screen.dart';
import 'package:shoply/presentation/screens/lists/list_detail_screen.dart';
import 'package:shoply/presentation/screens/recipes/recipes_screen.dart';
import 'package:shoply/presentation/screens/recipes/recipe_detail_screen.dart';
import 'package:shoply/presentation/screens/recipes/add_recipe_screen.dart';
import 'package:shoply/presentation/screens/profile/profile_screen.dart';
import 'package:shoply/presentation/screens/main_scaffold.dart';
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
            path: '/lists',
            name: 'lists',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ListsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':listId',
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
            ],
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
    redirect: (context, state) {
      final isLoggedIn = SupabaseService.instance.currentUser != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSigningUp = state.matchedLocation == '/signup';
      
      if (!isLoggedIn && !isLoggingIn && !isSigningUp) {
        return '/login';
      }
      
      if (isLoggedIn && (isLoggingIn || isSigningUp)) {
        return '/home';
      }
      
      return null;
    },
  );
});
