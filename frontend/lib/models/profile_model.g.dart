// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfileModelImpl _$$ProfileModelImplFromJson(Map<String, dynamic> json) =>
    _$ProfileModelImpl(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      username: json['username'] as String,
      displayName: json['displayName'] as String,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      timezone: json['timezone'] as String?,
      workoutTypes: (json['workoutTypes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      goals:
          (json['goals'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      muscleGroups: (json['muscleGroups'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      profilePictureUrl: json['profilePictureUrl'] as String?,
      role: json['role'] as String,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      createdAt:
          const DateTimeConverter().fromJson(json['createdAt'] as String),
      updatedAt:
          const DateTimeConverter().fromJson(json['updatedAt'] as String),
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      level: (json['level'] as num?)?.toInt() ?? 0,
      rubies: (json['rubies'] as num?)?.toInt() ?? 0,
      proteinShakes: (json['proteinShakes'] as num?)?.toInt() ?? 0,
      proteinBars: (json['proteinBars'] as num?)?.toInt() ?? 0,
      profileBoosts: (json['profileBoosts'] as num?)?.toInt() ?? 0,
      notifyBoosts: (json['notifyBoosts'] as num?)?.toInt() ?? 0,
      unlockedGifts: json['unlockedGifts'] as Map<String, dynamic>?,
      lastStreamCompletedAt: const NullableDateTimeConverter()
          .fromJson(json['lastStreamCompletedAt'] as String?),
      xpToNextLevel: (json['xpToNextLevel'] as num?)?.toInt() ?? 100,
      xpProgress: (json['xpProgress'] as num?)?.toDouble() ?? 0.0,
      giftValue: (json['giftValue'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$ProfileModelImplToJson(_$ProfileModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'username': instance.username,
      'displayName': instance.displayName,
      'bio': instance.bio,
      'location': instance.location,
      'timezone': instance.timezone,
      'workoutTypes': instance.workoutTypes,
      'goals': instance.goals,
      'muscleGroups': instance.muscleGroups,
      'profilePictureUrl': instance.profilePictureUrl,
      'role': instance.role,
      'onboardingCompleted': instance.onboardingCompleted,
      'createdAt': const DateTimeConverter().toJson(instance.createdAt),
      'updatedAt': const DateTimeConverter().toJson(instance.updatedAt),
      'xp': instance.xp,
      'level': instance.level,
      'rubies': instance.rubies,
      'proteinShakes': instance.proteinShakes,
      'proteinBars': instance.proteinBars,
      'profileBoosts': instance.profileBoosts,
      'notifyBoosts': instance.notifyBoosts,
      'unlockedGifts': instance.unlockedGifts,
      'lastStreamCompletedAt': const NullableDateTimeConverter()
          .toJson(instance.lastStreamCompletedAt),
      'xpToNextLevel': instance.xpToNextLevel,
      'xpProgress': instance.xpProgress,
      'giftValue': instance.giftValue,
    };
