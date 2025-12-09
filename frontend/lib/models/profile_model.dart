// lib/models/profile_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_model.freezed.dart';
part 'profile_model.g.dart';

// Custom DateTime converter
class DateTimeConverter implements JsonConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json);

  @override
  String toJson(DateTime object) => object.toIso8601String();
}

// Custom nullable DateTime converter
class NullableDateTimeConverter implements JsonConverter<DateTime?, String?> {
  const NullableDateTimeConverter();

  @override
  DateTime? fromJson(String? json) => json != null ? DateTime.parse(json) : null;

  @override
  String? toJson(DateTime? object) => object?.toIso8601String();
}

@freezed
class ProfileModel with _$ProfileModel {
  const factory ProfileModel({
    required int id,
    required String email,
    required String username,
    required String displayName,
    String? bio,
    String? location,
    String? timezone,
    @Default([]) List<String> workoutTypes,
    @Default([]) List<String> goals,
    @Default([]) List<String> muscleGroups,
    String? profilePictureUrl,
    required String role,
    @Default(false) bool onboardingCompleted,
    @DateTimeConverter() required DateTime createdAt,
    @DateTimeConverter() required DateTime updatedAt,
    @Default(0) int xp,
    @Default(0) int level,
    @Default(0) int rubies,
    @Default(0) int proteinShakes,
    @Default(0) int proteinBars,
    @Default(0) int profileBoosts,
    @Default(0) int notifyBoosts,
    Map<String, dynamic>? unlockedGifts,
    @NullableDateTimeConverter() DateTime? lastStreamCompletedAt,
    @Default(100) int xpToNextLevel,
    @Default(0.0) double xpProgress,
    @Default(0) int giftValue,
  }) = _ProfileModel;

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);
}