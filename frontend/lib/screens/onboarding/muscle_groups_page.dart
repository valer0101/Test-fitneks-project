// lib/screens/onboarding/muscle_groups_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/trainer_onboarding_provider.dart';
import 'package:frontend/app_theme.dart';

class MuscleGroupsPage extends ConsumerWidget {
  const MuscleGroupsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroups = ref.watch(trainerOnboardingProvider).muscleGroups;
    final notifier = ref.read(trainerOnboardingProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text(
          'Which muscle groups do you focus on?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('This helps learners find your specific workout streams.'),
        const SizedBox(height: 32),
        
        // --- The Mannequin Heatmap Placeholders ---
        SizedBox(
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Placeholder for base mannequin image
              Container(
                width: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(75),
                ),
              ),
              // Conditionally show highlight placeholders
              if (selectedGroups.contains(MuscleGroup.Chest))
                _buildHighlightPlaceholder(AppTheme.primaryOrange.withOpacity(0.5)),
              if (selectedGroups.contains(MuscleGroup.Abs))
                _buildHighlightPlaceholder(Colors.red.withOpacity(0.5)),
              // ... Add more for Back, Arms, Legs
            ],
          ),
        ),
        const SizedBox(height: 32),

        // --- The Selection Chips ---
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

  // Helper widget for placeholder highlights
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