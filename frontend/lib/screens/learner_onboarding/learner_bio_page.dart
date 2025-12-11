// lib/screens/learner_onboarding/learner_bio_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/learner_onboarding_provider.dart';

class LearnerBioPage extends ConsumerWidget {
  const LearnerBioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(learnerOnboardingProvider);
    final onboardingNotifier = ref.read(learnerOnboardingProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text(
          'Tell us about yourself',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Share what inspires you on your fitness journey. This is optional.'
        ),
        const SizedBox(height: 32),
        TextFormField(
          initialValue: onboardingState.bio,
          decoration: const InputDecoration(
            labelText: 'Your Bio',
            hintText: 'e.g., I love hiking and am looking to build strength for my next adventure...',
            alignLabelWithHint: true,
          ),
          onChanged: (value) => onboardingNotifier.updateBio(value),
          maxLines: 5,
          maxLength: 150,
        ),
      ],
    );
  }
}