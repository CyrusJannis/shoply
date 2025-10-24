import 'package:flutter/material.dart';
import 'package:shoply/core/constants/app_dimensions.dart';

class OnboardingLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onNext;
  final VoidCallback? onSkip;
  final VoidCallback? onBack;
  final bool isNextEnabled;
  final int currentStep;
  final int totalSteps;

  const OnboardingLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.onNext,
    this.onSkip,
    this.onBack,
    this.isNextEnabled = true,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar with back and skip
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (onBack != null)
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                    )
                  else
                    const SizedBox(width: 48),
                  
                  // Progress indicator
                  Row(
                    children: List.generate(
                      totalSteps,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index < currentStep
                              ? (isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600)
                              : (isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300),
                        ),
                      ),
                    ),
                  ),
                  
                  if (onSkip != null)
                    TextButton(
                      onPressed: onSkip,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.screenHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Title
                    Text(
                      title,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                    
                    if (subtitle != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                          height: 1.5,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 40),
                    
                    // Child content
                    child,
                  ],
                ),
              ),
            ),
            
            // Next button
            if (onNext != null)
              Padding(
                padding: const EdgeInsets.all(AppDimensions.screenHorizontalPadding),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isNextEnabled ? onNext : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode ? Colors.blue.shade400 : Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      disabledBackgroundColor: isDarkMode 
                          ? Colors.grey.shade800 
                          : Colors.grey.shade300,
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
