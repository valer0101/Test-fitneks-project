// lib/screens/trainer_onboarding_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'onboarding/bio_page.dart';
import 'onboarding/location_page.dart';
import 'package:frontend/app_theme.dart';
import 'onboarding/workout_types_page.dart';
import 'onboarding/muscle_groups_page.dart';
import 'onboarding/goals_page.dart';
import 'onboarding/submission_page.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/trainer_onboarding_provider.dart';
import 'onboarding/shared/username_page.dart';

class TrainerOnboardingScreen extends ConsumerStatefulWidget {
  const TrainerOnboardingScreen({super.key});

  @override
  ConsumerState<TrainerOnboardingScreen> createState() => _TrainerOnboardingScreenState();
}

class _TrainerOnboardingScreenState extends ConsumerState<TrainerOnboardingScreen> {
  // Inside _TrainerOnboardingScreenState...
  final List<int> _optionalPages = const [1, 4, 5];
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // We will build and add the individual form pages to this list
  final List<Widget> _pages = [
    // Placeholder for Page 1: Username & Display Name
    const UsernamePage(userRole: 'Trainer'),
    // Placeholder for Page 2: Bio
    const BioPage(), 
    // Placeholder for Page 3: Location & Timezone
    const LocationPage(), 
    // ... and so on for the other steps
    const WorkoutTypesPage(), 
    const GoalsPage(),
    const MuscleGroupsPage(), // <-- Replace the next placeholder
    const SubmissionPage(), 
  ];

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }


 // 1. Add this new validation function
  bool _validateCurrentPage() {
  final state = ref.read(trainerOnboardingProvider);
  switch (_currentPage) {
    // --- MANDATORY PAGES ---
    case 0: // Username & Display Name Page
      return state.username.isNotEmpty && state.displayName.isNotEmpty;
    case 2: // Location & Timezone Page
      return state.location.isNotEmpty && state.timezone.isNotEmpty;
    case 3: // Workout Types Page
      return state.workoutTypes.isNotEmpty;
    
    // --- OPTIONAL PAGES ---
    // For all other pages (1=Bio, 4=Goals, 5=Muscle Groups), always allow "Next"
    default: 
      return true;
  }
}


  void _nextPage() {
    if (_validateCurrentPage()) {
      // If the current page is valid, proceed
      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      } else {
        _submitForm();
      }
    } else {
      // If not valid, show an error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields on this page.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


// Add this new function to handle the final submission
  void _submitForm() {
    // Read the final data from the onboarding provider
    final onboardingData = ref.read(trainerOnboardingProvider);
    
    // Call the method in your AuthProvider to send the data to the backend
    ref.read(authProvider.notifier).updateTrainerProfile(onboardingData).then((success) {
      // After a successful submission, navigate to the dashboard
      if (success && context.mounted) {
        context.go('/trainer-dashboard');
      } else {
        // Optionally, show an error if submission fails
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile. Please try again.')),
        );
      }
    });
  }


  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Trainer Profile'),
        bottom: PreferredSize(
      preferredSize: const Size.fromHeight(4.0),
      child: LinearProgressIndicator(
        value: (_currentPage + 1) / _pages.length, // Calculates progress
        backgroundColor: Colors.grey[300],
        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
      ),
    ),

      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const NeverScrollableScrollPhysics(), // Disable swiping
        children: _pages,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Back Button
            _currentPage > 0
                ? TextButton(onPressed: _previousPage, child: const Text('Back'))
                : const SizedBox(), // Empty space to keep buttons on the right

            // Group the Skip and Next buttons together
            Row(
              children: [
                // Conditionally show the Skip button
                if (_optionalPages.contains(_currentPage))
                  TextButton(
                    onPressed: _nextPage, // Skip just goes to the next page
                    child: const Text('Skip for Now'),
                  ),
                
                const SizedBox(width: 8),

                // The main action button
                ElevatedButton(
                  onPressed: _nextPage,
                  child: Text(_currentPage == _pages.length - 1 ? 'Complete Profile' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}