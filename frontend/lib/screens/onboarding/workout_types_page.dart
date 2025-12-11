// lib/screens/onboarding/workout_types_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/trainer_onboarding_provider.dart';

class WorkoutTypesPage extends ConsumerWidget {
  const WorkoutTypesPage({super.key});

  // This map links each workout type to a specific icon
  static const Map<WorkoutType, IconData> _workoutIcons = {
    WorkoutType.Weights: Icons.fitness_center,
    WorkoutType.Calisthenics: Icons.accessibility_new,
    WorkoutType.Resistance: Icons.waves, 
    WorkoutType.Yoga: Icons.self_improvement,
    WorkoutType.Pilates: Icons.sports_gymnastics,  // Example icon
    WorkoutType.Dance: Icons.music_note,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTypes = ref.watch(trainerOnboardingProvider).workoutTypes;
    final onboardingNotifier = ref.read(trainerOnboardingProvider.notifier);

    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text(
          'What are your specialties?',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text('Select all the workout types you are proficient in.'),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: WorkoutType.values.map((type) {
            final isSelected = selectedTypes.contains(type);
            return ChoiceChip(
              avatar: Icon( // <-- The icon is added here
                _workoutIcons[type],
                color: isSelected ? Colors.white : Theme.of(context).primaryColor,
              ),
              label: Text(type.name),
              selected: isSelected,
              onSelected: (bool selected) {
                onboardingNotifier.toggleWorkoutType(type);
              },
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
              showCheckmark: false,
            );
          }).toList(),
        ),
      ],
    );
  }
}