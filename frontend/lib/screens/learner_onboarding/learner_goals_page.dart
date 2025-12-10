// lib/screens/learner_onboarding/learner_goals_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/learner_onboarding_provider.dart';
import 'package:frontend/providers/trainer_onboarding_provider.dart';
import 'package:frontend/app_theme.dart';

class LearnerGoalsPage extends ConsumerWidget {
  const LearnerGoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGoals = ref.watch(learnerOnboardingProvider).goals;
    final notifier = ref.read(learnerOnboardingProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text('What are your fitness goals?', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('This is optional, but helps us align you with the right trainers.'),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: Goal.values.map((goal) {
            final isSelected = selectedGoals.contains(goal);
            return ChoiceChip(
              label: Text(
                goal.displayName,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              selected: isSelected,
              selectedColor: AppTheme.primaryOrange,
              onSelected: (_) => notifier.toggleGoal(goal),
            );
          }).toList(),
        ),
      ],
    );
  }
}