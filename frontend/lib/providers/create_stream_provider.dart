import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/livestream_model.dart';
import '../services/livestream_repository.dart';
part 'create_stream_provider.freezed.dart';

/// State class for create stream form
@freezed
class CreateStreamState with _$CreateStreamState {
  const CreateStreamState._(); // Private constructor for custom getters
  
  const factory CreateStreamState({
    String? title,
    String? description,
    @Default(0) int giftRequirement,
    @Default(LiveStreamVisibility.PUBLIC) LiveStreamVisibility visibility,
    int? maxParticipants,
    @Default(true) bool goLiveNow,
    DateTime? scheduledAt,
    @Default(false) bool isRecurring,
    @Default([]) List<Equipment> equipmentNeeded,
    WorkoutStyle? workoutStyle,
    @Default({
      'arms': 0,
      'chest': 0,
      'back': 0,
      'abs': 0,
      'legs': 0,
    }) Map<String, int> musclePoints,
    @Default(false) bool isSubmitting,
    String? errorMessage,
  }) = _CreateStreamState;
  
  /// Calculate total possible points learners can earn
  int get totalPossiblePoints {
    return musclePoints.values.fold(0, (sum, points) => sum + points);
  }
  
  /// Check if any muscle points are set
  bool get hasMusclePoints {
    return musclePoints.values.any((points) => points > 0);
  }
}

/// State notifier for managing create stream form state
class CreateStreamNotifier extends StateNotifier<CreateStreamState> {
  CreateStreamNotifier() : super(const CreateStreamState());

  /// Update stream title
  void updateTitle(String value) {
    state = state.copyWith(title: value, errorMessage: null);
  }

  /// Update stream description
  void updateDescription(String value) {
    state = state.copyWith(description: value, errorMessage: null);
  }

  /// Update gift requirement
  void updateGiftRequirement(int value) {
    state = state.copyWith(giftRequirement: value);
  }

  /// Update stream visibility
  void updateVisibility(LiveStreamVisibility value) {
    state = state.copyWith(visibility: value);
  }

  /// Update max participants
  void updateMaxParticipants(int value) {
    state = state.copyWith(maxParticipants: value);
  }

  /// Toggle go live now vs schedule
  void toggleGoLiveNow(bool value) {
    state = state.copyWith(
      goLiveNow: value,
      scheduledAt: value ? null : state.scheduledAt,
    );
  }

  /// Update scheduled date/time
  void updateScheduledAt(DateTime value) {
    state = state.copyWith(scheduledAt: value);
  }

  /// Toggle recurring streams
  void toggleRecurring(bool value) {
    state = state.copyWith(isRecurring: value);
  }

  /// Toggle equipment selection with NO_EQUIPMENT logic
 void toggleEquipment(Equipment equipment) {
  final currentEquipment = List<Equipment>.from(state.equipmentNeeded);
  
  if (equipment == Equipment.NO_EQUIPMENT) {  // ✅ Changed
    if (!currentEquipment.contains(Equipment.NO_EQUIPMENT)) {  // ✅ Changed
      state = state.copyWith(equipmentNeeded: [Equipment.NO_EQUIPMENT]);  // ✅ Changed
    } else {
      state = state.copyWith(equipmentNeeded: []);
    }
  } else {
    currentEquipment.remove(Equipment.NO_EQUIPMENT);  // ✅ Changed
    
    if (currentEquipment.contains(equipment)) {
      currentEquipment.remove(equipment);
    } else {
      currentEquipment.add(equipment);
    }
    
    state = state.copyWith(equipmentNeeded: currentEquipment);
  }
}

  /// Select workout style
  void selectWorkoutStyle(WorkoutStyle value) {
    state = state.copyWith(workoutStyle: value);
  }

  /// Update muscle point value for specific muscle group
  /// Points represent both intensity (0-5) and points learners can earn
  void updateMusclePoint(String muscleGroup, int value) {
    final updatedPoints = Map<String, int>.from(state.musclePoints);
    updatedPoints[muscleGroup] = value.clamp(0, 5);
    state = state.copyWith(musclePoints: updatedPoints);
  }

  /// Reset form to initial state
  void resetForm() {
    state = const CreateStreamState();
  }


// ✅ Add this method to load existing livestream data
void loadFromLivestream(LiveStream livestream) {
  state = CreateStreamState(
    title: livestream.title,
    description: livestream.description,
    visibility: livestream.visibility,
    maxParticipants: livestream.maxParticipants,
    goLiveNow: false,  // Always false when editing
    scheduledAt: livestream.scheduledAt,
    isRecurring: livestream.isRecurring,
    equipmentNeeded: livestream.equipmentNeeded,
    workoutStyle: livestream.workoutStyle,
    giftRequirement: livestream.giftRequirement,
    musclePoints: Map<String, int>.from(livestream.musclePoints as Map),
  );
}

// ✅ Update the submitStream method to handle both create and update
Future<LiveStream?> submitStream(
  LivestreamRepository repository,
  String token,
  {String? livestreamId}
) async {
  state = state.copyWith(isSubmitting: true, errorMessage: null);
  
  try {
    print('🔍 Submitting stream...');
    print('🔍 Livestream ID: $livestreamId');
    print('🔍 Title: ${state.title}');
    print('🔍 Go Live Now: ${state.goLiveNow}');
    
    LiveStream livestream;
    
    if (livestreamId != null) {
      // UPDATE existing stream
      print('📝 Updating livestream: $livestreamId');
      livestream = await repository.updateLivestream(
        livestreamId,
        state,
        token,
      );
      print('✅ Stream updated successfully');
    } else {
      // CREATE new stream
      print('🆕 Creating NEW livestream');
      livestream = await repository.createLiveStream(  // ✅ Note: capital S
        state,
        token,
      );
      print('✅ Stream created successfully with ID: ${livestream.id}');
    }
    
    state = state.copyWith(
      isSubmitting: false,
    );
    
    return livestream;
    
  } catch (e) {
    print('❌ Error submitting stream: $e');
    state = state.copyWith(
      isSubmitting: false,
      errorMessage: 'Failed to create stream: Network error occurred',
    );
    return null;
  }
}





}

/// Provider for create stream state management
final createStreamProvider = StateNotifierProvider<CreateStreamNotifier, CreateStreamState>((ref) {
  return CreateStreamNotifier();
});

/// Provider for livestream repository
final livestreamRepositoryProvider = Provider<LivestreamRepository>((ref) {
  return LivestreamRepository();
});