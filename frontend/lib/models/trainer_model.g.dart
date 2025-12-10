// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trainer_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Trainer _$TrainerFromJson(Map<String, dynamic> json) => Trainer(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      displayName: json['displayName'] as String?,
      xp: (json['xp'] as num).toInt(),
      profilePicture: json['profilePicture'] as String?,
    );

Map<String, dynamic> _$TrainerToJson(Trainer instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'displayName': instance.displayName,
      'xp': instance.xp,
      'profilePicture': instance.profilePicture,
    };
