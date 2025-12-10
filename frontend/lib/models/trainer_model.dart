import 'package:json_annotation/json_annotation.dart';

part 'trainer_model.g.dart';

@JsonSerializable()
class Trainer {
  final int id;
  final String username;
  final String? displayName;
  final int xp;
  final String? profilePicture;

  const Trainer({
    required this.id,
    required this.username,
    this.displayName,
    required this.xp,
    this.profilePicture,
  });

  factory Trainer.fromJson(Map<String, dynamic> json) => _$TrainerFromJson(json);
  Map<String, dynamic> toJson() => _$TrainerToJson(this);
}