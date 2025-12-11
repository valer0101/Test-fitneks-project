// lib/providers/learner_onboarding_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

// We can reuse the enums from the Trainer's provider
import 'package:frontend/providers/trainer_onboarding_provider.dart';

class LearnerOnboardingState {
  final String username;
  final String displayName;
  final String location;
  final String timezone;
  final List<WorkoutType> workoutTypes;
  final List<Goal> goals;
  final List<MuscleGroup> muscleGroups;
  final String bio; 

  LearnerOnboardingState({
    this.username = '',
    this.displayName = '',
    this.location = '',
    this.timezone = '',
    this.workoutTypes = const [],
    this.goals = const [],
    this.muscleGroups = const [],
    this.bio = '', 
  });

  // --- START: Corrected copyWith method ---
  LearnerOnboardingState copyWith({
    String? username,
    String? displayName,
    String? location,
    String? timezone,
    List<WorkoutType>? workoutTypes,
    List<Goal>? goals, // <-- Fixed syntax and added
    List<MuscleGroup>? muscleGroups, // <-- Fixed syntax and added
    String? bio, 
  }) {
    return LearnerOnboardingState(
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      location: location ?? this.location,
      timezone: timezone ?? this.timezone,
      workoutTypes: workoutTypes ?? this.workoutTypes,
      goals: goals ?? this.goals, // <-- Added
      muscleGroups: muscleGroups ?? this.muscleGroups, // <-- Added
      bio: bio ?? this.bio, 
    );
  }
  // --- END: Corrected copyWith method ---

  // --- START: Corrected toJson method ---
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'displayName': displayName,
      'bio': bio, 
      'location': location,
      'timezone': timezone,
      'workoutTypes': workoutTypes.map((e) => e.name).toList(),
      'goals': goals.map((e) => e.name).toList(), // <-- Added
      'muscleGroups': muscleGroups.map((e) => e.name).toList(), // <-- Added
    };
  }
}



class LearnerOnboardingNotifier extends StateNotifier<LearnerOnboardingState> {
  LearnerOnboardingNotifier() : super(LearnerOnboardingState());

  void updateUsername(String username) => state = state.copyWith(username: username);
  void updateDisplayName(String displayName) => state = state.copyWith(displayName: displayName);
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

// Select Goals
void toggleGoal(Goal goal) {
    final currentGoals = state.goals;
    if (currentGoals.contains(goal)) {
      state = state.copyWith(goals: List.from(currentGoals)..remove(goal));
    } else {
      state = state.copyWith(goals: List.from(currentGoals)..add(goal));
    }
  }

  // --- Select Muscle Groups ---
  void toggleMuscleGroup(MuscleGroup group) {
    final currentGroups = state.muscleGroups;
    if (currentGroups.contains(group)) {
      state = state.copyWith(muscleGroups: List.from(currentGroups)..remove(group));
    } else {
      state = state.copyWith(muscleGroups: List.from(currentGroups)..add(group));
    }
  }


void updateBio(String bio) { // <-- Add this new method
    state = state.copyWith(bio: bio);
  }



}

final learnerOnboardingProvider =
    StateNotifierProvider<LearnerOnboardingNotifier, LearnerOnboardingState>(
  (ref) => LearnerOnboardingNotifier(),
);