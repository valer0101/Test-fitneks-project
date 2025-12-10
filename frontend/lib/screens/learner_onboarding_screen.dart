// lib/screens/learner_onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/app_theme.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/learner_onboarding_provider.dart';
import '../../widgets/gradient_elevated_button.dart';

// Import all your pages
import 'learner_onboarding/learner_location_page.dart';
import 'learner_onboarding/learner_workout_types_page.dart';
import 'learner_onboarding/learner_goals_page.dart';
import 'learner_onboarding/learner_muscle_groups_page.dart';
import 'learner_onboarding/learner_submission_page.dart';
import 'learner_onboarding/learner_bio_page.dart';
import 'onboarding/shared/username_page.dart';

class LearnerOnboardingScreen extends ConsumerStatefulWidget {
  const LearnerOnboardingScreen({super.key});

  @override
  ConsumerState<LearnerOnboardingScreen> createState() =>
      _LearnerOnboardingScreenState();
}

class _LearnerOnboardingScreenState
    extends ConsumerState<LearnerOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Widget> _pages = [
    const UsernamePage(userRole: 'Learner'),
    const LearnerBioPage(),
    const LearnerLocationPage(),
    const LearnerWorkoutTypesPage(),
    const LearnerGoalsPage(),
    const LearnerMuscleGroupsPage(),
    const LearnerSubmissionPage(),
  ];

  final List<int> _optionalPages = const [1, 4, 5];

  void _onPageChanged(int page) => setState(() => _currentPage = page);

  // --- START: ADDED VALIDATION LOGIC ---
  bool _validateCurrentPage() {
    final state = ref.read(learnerOnboardingProvider);

    // --- START: DEBUG PRINTS ---
    // We only care about the location page right now (which is at index 1)
    if (_currentPage == 1) {
      print("--- Validating Location Page ---");
      print("Location from state: '${state.location}'");
      print("Timezone from state: '${state.timezone}'");
      print("Is Location empty? ${state.location.isEmpty}");
      print("Is Timezone empty? ${state.timezone.isEmpty}");
    }
    // --- END: DEBUG PRINTS ---

    switch (_currentPage) {
      case 0: // Username & Display Name Page
        return state.username.isNotEmpty && state.displayName.isNotEmpty;
      case 2: // Location & Timezone Page
        return state.location.isNotEmpty && state.timezone.isNotEmpty;
      case 3: // Workout Types Page
        return state.workoutTypes.isNotEmpty;
      default:
        return true;
    }
  }

  void _nextPage() {
    if (_validateCurrentPage()) {
      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      } else {
        _submitForm();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields on this page.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // --- END: ADDED VALIDATION LOGIC ---

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  void _submitForm() {
    final onboardingData = ref.read(learnerOnboardingProvider);

    ref
        .read(authProvider.notifier)
        .updateLearnerProfile(onboardingData)
        .then((success) {
      print(
          '🎯 Onboarding success: $success, navigating to /learner-dashboard/friends'); // ADD THIS
      if (success && mounted) {
        context.go('/learner-dashboard');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to update profile. Please try again.')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.fitneksGradient,
          ),
        ),
        title: const Text('Complete Your Profile'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / _pages.length,
            backgroundColor: Colors.grey[300],
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_currentPage > 0)
              TextButton(onPressed: _previousPage, child: const Text('Back')),
            Row(
              children: [
                if (_optionalPages.contains(_currentPage))
                  TextButton(
                      onPressed: _nextPage, child: const Text('Skip for Now')),
                const SizedBox(width: 8),
                GradientElevatedButton(
                  onPressed: _nextPage,
                  child: Text(_currentPage == _pages.length - 1
                      ? 'Complete Profile'
                      : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
