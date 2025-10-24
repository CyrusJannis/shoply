import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shoply/core/constants/app_dimensions.dart';

class OnboardingWelcomeScreen extends StatelessWidget {
  const OnboardingWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.screenHorizontalPadding),
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: Text(
                    'Skip',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App icon/illustration
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isDarkMode ? Colors.blue.shade400 : Colors.blue.shade300,
                            isDarkMode ? Colors.purple.shade400 : Colors.purple.shade300,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: (isDarkMode ? Colors.blue.shade400 : Colors.blue.shade300)
                                .withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shopping_bag_rounded,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 40),
                    
                    // Welcome title
                    Text(
                      'Welcome to ShoplyAI',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 32,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Your smart nutrition and grocery shopping companion. Let\'s personalize your experience.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                          height: 1.5,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 60),
                    
                    // Features list
                    _buildFeature(
                      context,
                      icon: Icons.restaurant_rounded,
                      title: 'Personalized Nutrition',
                      description: 'Get recommendations based on your dietary needs',
                    ),
                    const SizedBox(height: 20),
                    _buildFeature(
                      context,
                      icon: Icons.list_alt_rounded,
                      title: 'Smart Shopping Lists',
                      description: 'Organize your groceries efficiently',
                    ),
                    const SizedBox(height: 20),
                    _buildFeature(
                      context,
                      icon: Icons.auto_awesome_rounded,
                      title: 'AI-Powered Insights',
                      description: 'Discover recipes and meal plans tailored for you',
                    ),
                  ],
                ),
              ),
              
              // Get Started button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push('/onboarding/age'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.blue.shade400.withOpacity(0.2) : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade600,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
