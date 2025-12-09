// lib/screens/onboarding/shared/submission_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/providers/trainer_onboarding_provider.dart';
import 'package:frontend/providers/learner_onboarding_provider.dart';

class SubmissionPage extends ConsumerWidget {
  const SubmissionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'You\'re all set!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Click below to complete your profile and get started.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              final user = ref.read(authProvider).user;
              bool success = false;

              // 1. Submit the correct onboarding data to the backend
              if (user?.role == 'Trainer') {
                final trainerData = ref.read(trainerOnboardingProvider);
                success = await ref.read(authProvider.notifier).updateTrainerProfile(trainerData);
              } else {
                final learnerData = ref.read(learnerOnboardingProvider);
                success = await ref.read(authProvider.notifier).updateLearnerProfile(learnerData);
              }

              // Remove loading indicator
              if (context.mounted) Navigator.pop(context);

              if (success && context.mounted) {
                // 2. After a successful submission, refresh the profile data
                await ref.read(profileProvider.notifier).refreshProfile();
                
                // 3. Navigate to the correct dashboard
                if (user?.role == 'Trainer') {
                   context.go('/trainer-dashboard');
                } else {
                   context.go('/home'); // Or your learner dashboard
                }
              } else if (context.mounted) {
                // Handle the error case
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Something went wrong. Please try again.')),
                );
              }
            },
            child: const Text(
              'Complete Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
          ),
        ],
      ),
    );
  }
}

