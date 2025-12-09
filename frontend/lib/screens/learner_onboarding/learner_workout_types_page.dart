// lib/screens/learner_onboarding/learner_workout_types_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/learner_onboarding_provider.dart';
import 'package:frontend/providers/trainer_onboarding_provider.dart' show WorkoutType;

class LearnerWorkoutTypesPage extends ConsumerWidget {
  const LearnerWorkoutTypesPage({super.key});

  // This map links each workout type to a specific icon
  static const Map<WorkoutType, IconData> _workoutIcons = {
    WorkoutType.Weights: Icons.fitness_center,
    WorkoutType.Calisthenics: Icons.accessibility_new,
    WorkoutType.Resistance: Icons.waves,
    WorkoutType.Yoga: Icons.self_improvement,
    WorkoutType.Pilates: Icons.sports_gymnastics,
    WorkoutType.Dance: Icons.music_note,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTypes = ref.watch(learnerOnboardingProvider).workoutTypes;
    final notifier = ref.read(learnerOnboardingProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text('What workouts interest you?', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('This will help us recommend the best trainers for you.'),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: WorkoutType.values.map((type) {
            final isSelected = selectedTypes.contains(type);
            return ChoiceChip(
              avatar: Icon(
                _workoutIcons[type],
                color: isSelected ? Colors.white : Theme.of(context).primaryColor,
              ),
              label: Text(type.name),
              selected: isSelected,
              onSelected: (_) => notifier.toggleWorkoutType(type),
            );
          }).toList(),
        ),
      ],
    );
  }
}