// lib/screens/onboarding/goals_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/trainer_onboarding_provider.dart';

class GoalsPage extends ConsumerWidget {
  const GoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGoals = ref.watch(trainerOnboardingProvider).goals;
    final onboardingNotifier = ref.read(trainerOnboardingProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text('What goals can you help with?', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Select all that apply.'),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: Goal.values.map((goal) {
            final isSelected = selectedGoals.contains(goal);
            return ChoiceChip(
              label: Text(goal.displayName),
              selected: isSelected,
              onSelected: (_) => onboardingNotifier.toggleGoal(goal),
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }
}