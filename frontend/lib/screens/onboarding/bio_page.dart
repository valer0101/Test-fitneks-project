// lib/screens/onboarding/bio_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/trainer_onboarding_provider.dart';

class BioPage extends ConsumerWidget {
  const BioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(trainerOnboardingProvider);
    final onboardingNotifier = ref.read(trainerOnboardingProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text(
          'Tell us about yourself',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Share what inspires you as a trainer. This is optional.'
        ),
        const SizedBox(height: 32),
        TextFormField(
          initialValue: onboardingState.bio,
          decoration: const InputDecoration(
            labelText: 'Your Bio',
            hintText: 'e.g., Passionate about helping others achieve their fitness goals through yoga and calisthenics...',
            alignLabelWithHint: true,
          ),
          onChanged: (value) => onboardingNotifier.updateBio(value),
          maxLines: 5, // Makes the text field taller
          maxLength: 150, // Enforces the character limit
        ),
      ],
    );
  }
}