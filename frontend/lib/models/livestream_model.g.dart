// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'livestream_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiveStream _$LiveStreamFromJson(Map<String, dynamic> json) => LiveStream(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      status: $enumDecode(_$LiveStreamStatusEnumMap, json['status']),
      visibility:
          $enumDecode(_$LiveStreamVisibilityEnumMap, json['visibility']),
      scheduledAt: DateTime.parse(json['scheduledAt'] as String),
      maxParticipants: (json['maxParticipants'] as num).toInt(),
      isRecurring: json['isRecurring'] as bool,
      equipmentNeeded: (json['equipmentNeeded'] as List<dynamic>)
          .map((e) => $enumDecode(_$EquipmentEnumMap, e))
          .toList(),
      workoutStyle: $enumDecode(_$WorkoutStyleEnumMap, json['workoutStyle']),
      giftRequirement: (json['giftRequirement'] as num).toInt(),
      musclePoints: json['musclePoints'] as Map<String, dynamic>,
      totalPossiblePoints: (json['totalPossiblePoints'] as num).toInt(),
      trainerId: (json['trainerId'] as num).toInt(),
      trainer: json['trainer'] == null
          ? null
          : Trainer.fromJson(json['trainer'] as Map<String, dynamic>),
      parentStreamId: json['parentStreamId'] as String?,
      eventId: json['eventId'] as String?,
    );

Map<String, dynamic> _$LiveStreamToJson(LiveStream instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'title': instance.title,
      'description': instance.description,
      'status': _$LiveStreamStatusEnumMap[instance.status]!,
      'visibility': _$LiveStreamVisibilityEnumMap[instance.visibility]!,
      'scheduledAt': instance.scheduledAt.toIso8601String(),
      'maxParticipants': instance.maxParticipants,
      'isRecurring': instance.isRecurring,
      'equipmentNeeded':
          instance.equipmentNeeded.map((e) => _$EquipmentEnumMap[e]!).toList(),
      'workoutStyle': _$WorkoutStyleEnumMap[instance.workoutStyle]!,
      'giftRequirement': instance.giftRequirement,
      'musclePoints': instance.musclePoints,
      'totalPossiblePoints': instance.totalPossiblePoints,
      'trainerId': instance.trainerId,
      'trainer': instance.trainer?.toJson(),
      'parentStreamId': instance.parentStreamId,
      'eventId': instance.eventId,
    };

const _$LiveStreamStatusEnumMap = {
  LiveStreamStatus.SCHEDULED: 'SCHEDULED',
  LiveStreamStatus.LIVE: 'LIVE',
  LiveStreamStatus.ENDED: 'ENDED',
  LiveStreamStatus.CANCELED: 'CANCELED',
};

const _$LiveStreamVisibilityEnumMap = {
  LiveStreamVisibility.PUBLIC: 'PUBLIC',
  LiveStreamVisibility.PRIVATE: 'PRIVATE',
};

const _$EquipmentEnumMap = {
  Equipment.DUMBBELLS: 'DUMBBELLS',
  Equipment.KETTLEBELL: 'KETTLEBELL',
  Equipment.PLATES: 'PLATES',
  Equipment.YOGA_BLOCK: 'YOGA_BLOCK',
  Equipment.YOGA_MAT: 'YOGA_MAT',
  Equipment.RESISTANCE_BAND: 'RESISTANCE_BAND',
  Equipment.PULL_UP_BAR: 'PULL_UP_BAR',
  Equipment.NO_EQUIPMENT: 'NO_EQUIPMENT',
};

const _$WorkoutStyleEnumMap = {
  WorkoutStyle.WEIGHTS: 'WEIGHTS',
  WorkoutStyle.CALISTHENICS: 'CALISTHENICS',
  WorkoutStyle.RESISTANCE: 'RESISTANCE',
  WorkoutStyle.YOGA: 'YOGA',
  WorkoutStyle.PILATES: 'PILATES',
  WorkoutStyle.MOBILITY: 'MOBILITY',
};
