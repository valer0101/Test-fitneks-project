// lib/screens/onboarding/location_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/trainer_onboarding_provider.dart';

class LocationPage extends ConsumerWidget {
  const LocationPage({super.key});

  // A sample list of timezones. A real app would use a more comprehensive list or a package.
  static const List<String> _timezones = [
    'GMT-5:00 Eastern Time',
    'GMT-6:00 Central Time',
    'GMT-7:00 Mountain Time',
    'GMT-8:00 Pacific Time',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(trainerOnboardingProvider);
    final onboardingNotifier = ref.read(trainerOnboardingProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text(
          'Where are you based?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'This helps us recommend your streams and show accurate times.'
        ),
        const SizedBox(height: 32),
        TextFormField(
          initialValue: onboardingState.location,
          decoration: const InputDecoration(
            labelText: 'Your City',
            hintText: 'e.g., New York, NY',
          ),
          onChanged: (value) => onboardingNotifier.updateLocation(value),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<String>(
          value: onboardingState.timezone.isEmpty ? null : onboardingState.timezone,
          decoration: const InputDecoration(
            labelText: 'Your Timezone',
          ),
          hint: const Text('Select your timezone'),
          items: _timezones.map((String value) {
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