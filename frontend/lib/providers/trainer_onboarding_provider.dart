// lib/providers/trainer_onboarding_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// Enums for all our multi-select pages
enum WorkoutType { Weights, Calisthenics, Resistance, Yoga, Pilates, Dance }
enum Goal { GainMuscle, IncreaseFlexibility, LoseWeight }
enum MuscleGroup { Chest, Back, Arms, Legs, Abs }

// Add this extension to create a user-friendly display name
extension GoalExtension on Goal {
  String get displayName {
    switch (this) {
      case Goal.GainMuscle:
        return 'Gain Muscle';
      case Goal.IncreaseFlexibility:
        return 'Increase Flexibility';
      case Goal.LoseWeight:
        return 'Lose Weight';
    }
  }
}

// This class now holds all the data from our multi-page form
class TrainerOnboardingState {
  final String username;
  final String displayName;
  final String bio;
  final String location;
  final String timezone;
  final List<WorkoutType> workoutTypes;
  final List<Goal> goals;
  final List<MuscleGroup> muscleGroups; // <-- New property

  TrainerOnboardingState({
    this.username = '',
    this.displayName = '',
    this.bio = '',
    this.location = '',
    this.timezone = '',
    this.workoutTypes = const [],
    this.goals = const [],
    this.muscleGroups = const [], // <-- Initialize
  });

  TrainerOnboardingState copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? location,
    String? timezone,
    List<WorkoutType>? workoutTypes,
    List<Goal>? goals,
    List<MuscleGroup>? muscleGroups, // <-- Add to copyWith
  }) {
    return TrainerOnboardingState(
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      timezone: timezone ?? this.timezone,
      workoutTypes: workoutTypes ?? this.workoutTypes,
      goals: goals ?? this.goals,
      muscleGroups: muscleGroups ?? this.muscleGroups, // <-- Add
    );
  }


Map<String, dynamic> toJson() {
    return {
      'username': username,
      'displayName': displayName,
      'bio': bio,
      'location': location,
      'timezone': timezone,
      'workoutTypes': workoutTypes.map((e) => e.name).toList(),
      'goals': goals.map((e) => e.name).toList(),
      'muscleGroups': muscleGroups.map((e) => e.name).toList(),
    };
  }


}

// The Notifier that manages the state
class TrainerOnboardingNotifier extends StateNotifier<TrainerOnboardingState> {
  TrainerOnboardingNotifier() : super(TrainerOnboardingState());

  void updateUsername(String username) => state = state.copyWith(username: username);
  void updateDisplayName(String displayName) => state = state.copyWith(displayName: displayName);
  void updateBio(String bio) => state = state.copyWith(bio: bio);
  void updateLocation(String location) => state = state.copyWith(location: location);
  void updateTimezone(String timezone) => state = state.copyWith(timezone: timezone);

  void toggleWorkoutType(WorkoutType type) {
    final currentTypes = state.workoutTypes;
    if (currentTypes.contains(type)) {
      state = state.copyWith(workoutTypes: List.from(currentTypes)..remove(type));
    } else {
      state = state.copyWith(workoutTypes: List.from(currentTypes)..add(type));
    }
  }

  void toggleGoal(Goal goal) {
    final currentGoals = state.goals;
    if (currentGoals.contains(goal)) {
      state = state.copyWith(goals: List.from(currentGoals)..remove(goal));
    } else {
      state = state.copyWith(goals: List.from(currentGoals)..add(goal));
    }
  }

  void toggleMuscleGroup(MuscleGroup group) { // <-- New method
    final currentGroups = state.muscleGroups;
    if (currentGroups.contains(group)) {
      state = state.copyWith(muscleGroups: List.from(currentGroups)..remove(group));
    } else {
      state = state.copyWith(muscleGroups: List.from(currentGroups)..add(group));
    }
  }
}

// The global provider
final trainerOnboardingProvider =
    StateNotifierProvider<TrainerOnboardingNotifier, TrainerOnboardingState>(
  (ref) => TrainerOnboardingNotifier(),
);