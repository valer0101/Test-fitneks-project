import 'package:json_annotation/json_annotation.dart';
import 'trainer_model.dart';  // ✅ ADD THIS


part 'livestream_model.g.dart';

/// Live stream status enum
enum LiveStreamStatus {
  SCHEDULED,
  LIVE,
  ENDED,
  CANCELED,
}

/// Live stream visibility enum
enum LiveStreamVisibility {
  PUBLIC,
  PRIVATE,
}

/// Equipment enum
enum Equipment {
  DUMBBELLS,
  KETTLEBELL,
  PLATES,
  YOGA_BLOCK,
  YOGA_MAT,
  RESISTANCE_BAND,
  PULL_UP_BAR,
  NO_EQUIPMENT,
}

/// Workout style enum
enum WorkoutStyle {
  WEIGHTS,
  CALISTHENICS,
  RESISTANCE,
  YOGA,
  PILATES,
  MOBILITY,
}

/// Live stream model
@JsonSerializable()
class LiveStream {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final String description;
  final LiveStreamStatus status;
  final LiveStreamVisibility visibility;
  final DateTime scheduledAt;
  final int maxParticipants;
  final bool isRecurring;
  final List<Equipment> equipmentNeeded;
  final WorkoutStyle workoutStyle;
  final int giftRequirement;
  
  /// Muscle points - represents both intensity AND points learners can earn
  final Map<String, dynamic> musclePoints;
  
  /// Total possible points for learners to earn
  final int totalPossiblePoints;
  
  final int trainerId;  // Changed to int to match your schema
  final Trainer? trainer; 
  final String? parentStreamId;
  final String? eventId;

  const LiveStream({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    required this.description,
    required this.status,
    required this.visibility,
    required this.scheduledAt,
    required this.maxParticipants,
    required this.isRecurring,
    required this.equipmentNeeded,
    required this.workoutStyle,
    required this.giftRequirement,
    required this.musclePoints,
    required this.totalPossiblePoints,
    required this.trainerId,
    this.trainer,  
    this.parentStreamId,
    this.eventId,
  });

  factory LiveStream.fromJson(Map<String, dynamic> json) => 
      _$LiveStreamFromJson(json);

  Map<String, dynamic> toJson() => _$LiveStreamToJson(this);
  
  /// Get points for a specific muscle group
  int getPointsForMuscle(String muscle) {
    return musclePoints[muscle] ?? 0;
  }
  
  /// Check if stream has any muscle points set
  bool get hasMusclePoints {
    return totalPossiblePoints > 0;
  }
}