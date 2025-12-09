// lib/screens/learner_onboarding/learner_muscle_groups_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/learner_onboarding_provider.dart';
import 'package:frontend/providers/trainer_onboarding_provider.dart' show MuscleGroup;

class LearnerMuscleGroupsPage extends ConsumerWidget {
  const LearnerMuscleGroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroups = ref.watch(learnerOnboardingProvider).muscleGroups;
    final notifier = ref.read(learnerOnboardingProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text('Any muscle groups to focus on?', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('This is optional, but helps improve recommendations.'),
        const SizedBox(height: 32),
        
        // Mannequin Heatmap Placeholder
        SizedBox(
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(75),
                ),
              ),
              if (selectedGroups.contains(MuscleGroup.Chest))
                _buildHighlightPlaceholder(Colors.orange.withOpacity(0.5)),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Selection Chips
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12.0,
          runSpacing: 12.0,
          children: MuscleGroup.values.map((group) {
            final isSelected = selectedGroups.contains(group);
            return ChoiceChip(
              label: Text(group.name),
              selected: isSelected,
              onSelected: (_) => notifier.toggleMuscleGroup(group),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHighlightPlaceholder(Color color) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}