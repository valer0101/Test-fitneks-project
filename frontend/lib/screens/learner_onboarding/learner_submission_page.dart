// lib/screens/learner_onboarding/learner_submission_page.dart
import 'package:flutter/material.dart';

class LearnerSubmissionPage extends StatelessWidget {
  const LearnerSubmissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('You\'re Ready to Go!', style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          const Text('Click below to complete your profile and find your first workout.', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}