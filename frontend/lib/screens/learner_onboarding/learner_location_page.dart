// lib/screens/learner_onboarding/learner_location_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/learner_onboarding_provider.dart';

class LearnerLocationPage extends ConsumerStatefulWidget {
  const LearnerLocationPage({super.key});

  @override
  ConsumerState<LearnerLocationPage> createState() => _LearnerLocationPageState();
}

class _LearnerLocationPageState extends ConsumerState<LearnerLocationPage> {
  late final TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(
      text: ref.read(learnerOnboardingProvider).location,
    );
  }

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(learnerOnboardingProvider);
    final onboardingNotifier = ref.read(learnerOnboardingProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text(
          'Where are you located?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'This helps us recommend local trainers and show accurate stream times.'
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _locationController,
          decoration: const InputDecoration(
            labelText: 'Your City',
            hintText: 'e.g., San Francisco, CA',
          ),
          onChanged: (value) {
            onboardingNotifier.updateLocation(value.trim());
          },
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: onboardingState.timezone.isEmpty ? null : onboardingState.timezone,
          decoration: const InputDecoration(
            labelText: 'Your Timezone',
          ),
          hint: const Text('Select your timezone'),
          items: const [
            'GMT-5:00 Eastern Time',
            'GMT-6:00 Central Time',
            'GMT-7:00 Mountain Time',
            'GMT-8:00 Pacific Time',
          ].map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onboardingNotifier.updateTimezone(newValue);
            }
          },
        ),
      ],
    );
  }
}