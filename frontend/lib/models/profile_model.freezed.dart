// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profile_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) {
  return _ProfileModel.fromJson(json);
}

/// @nodoc
mixin _$ProfileModel {
  int get id => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  String? get bio => throw _privateConstructorUsedError;
  String? get location => throw _privateConstructorUsedError;
  String? get timezone => throw _privateConstructorUsedError;
  List<String> get workoutTypes => throw _privateConstructorUsedError;
  List<String> get goals => throw _privateConstructorUsedError;
  List<String> get muscleGroups => throw _privateConstructorUsedError;
  String? get profilePictureUrl => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  bool get onboardingCompleted => throw _privateConstructorUsedError;
  @DateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;
  @DateTimeConverter()
  DateTime get updatedAt => throw _privateConstructorUsedError;
  int get xp => throw _privateConstructorUsedError;
  int get level => throw _privateConstructorUsedError;
  int get rubies => throw _privateConstructorUsedError;
  int get proteinShakes => throw _privateConstructorUsedError;
  int get proteinBars => throw _privateConstructorUsedError;
  int get profileBoosts => throw _privateConstructorUsedError;
  int get notifyBoosts => throw _privateConstructorUsedError;
  Map<String, dynamic>? get unlockedGifts => throw _privateConstructorUsedError;
  @NullableDateTimeConverter()
  DateTime? get lastStreamCompletedAt => throw _privateConstructorUsedError;
  int get xpToNextLevel => throw _privateConstructorUsedError;
  double get xpProgress => throw _privateConstructorUsedError;
  int get giftValue => throw _privateConstructorUsedError;

  /// Serializes this ProfileModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfileModelCopyWith<ProfileModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfileModelCopyWith<$Res> {
  factory $ProfileModelCopyWith(
          ProfileModel value, $Res Function(ProfileModel) then) =
      _$ProfileModelCopyWithImpl<$Res, ProfileModel>;
  @useResult
  $Res call(
      {int id,
      String email,
      String username,
      String displayName,
      String? bio,
      String? location,
      String? timezone,
      List<String> workoutTypes,
      List<String> goals,
      List<String> muscleGroups,
      String? profilePictureUrl,
      String role,
      bool onboardingCompleted,
      @DateTimeConverter() DateTime createdAt,
      @DateTimeConverter() DateTime updatedAt,
      int xp,
      int level,
      int rubies,
      int proteinShakes,
      int proteinBars,
      int profileBoosts,
      int notifyBoosts,
      Map<String, dynamic>? unlockedGifts,
      @NullableDateTimeConverter() DateTime? lastStreamCompletedAt,
      int xpToNextLevel,
      double xpProgress,
      int giftValue});
}

/// @nodoc
class _$ProfileModelCopyWithImpl<$Res, $Val extends ProfileModel>
    implements $ProfileModelCopyWith<$Res> {
  _$ProfileModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? username = null,
    Object? displayName = null,
    Object? bio = freezed,
    Object? location = freezed,
    Object? timezone = freezed,
    Object? workoutTypes = null,
    Object? goals = null,
    Object? muscleGroups = null,
    Object? profilePictureUrl = freezed,
    Object? role = null,
    Object? onboardingCompleted = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? xp = null,
    Object? level = null,
    Object? rubies = null,
    Object? proteinShakes = null,
    Object? proteinBars = null,
    Object? profileBoosts = null,
    Object? notifyBoosts = null,
    Object? unlockedGifts = freezed,
    Object? lastStreamCompletedAt = freezed,
    Object? xpToNextLevel = null,
    Object? xpProgress = null,
    Object? giftValue = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      timezone: freezed == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String?,
      workoutTypes: null == workoutTypes
          ? _value.workoutTypes
          : workoutTypes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      goals: null == goals
          ? _value.goals
          : goals // ignore: cast_nullable_to_non_nullable
              as List<String>,
      muscleGroups: null == muscleGroups
          ? _value.muscleGroups
          : muscleGroups // ignore: cast_nullable_to_non_nullable
              as List<String>,
      profilePictureUrl: freezed == profilePictureUrl
          ? _value.profilePictureUrl
          : profilePictureUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      onboardingCompleted: null == onboardingCompleted
          ? _value.onboardingCompleted
          : onboardingCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      xp: null == xp
          ? _value.xp
          : xp // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      rubies: null == rubies
          ? _value.rubies
          : rubies // ignore: cast_nullable_to_non_nullable
              as int,
      proteinShakes: null == proteinShakes
          ? _value.proteinShakes
          : proteinShakes // ignore: cast_nullable_to_non_nullable
              as int,
      proteinBars: null == proteinBars
          ? _value.proteinBars
          : proteinBars // ignore: cast_nullable_to_non_nullable
              as int,
      profileBoosts: null == profileBoosts
          ? _value.profileBoosts
          : profileBoosts // ignore: cast_nullable_to_non_nullable
              as int,
      notifyBoosts: null == notifyBoosts
          ? _value.notifyBoosts
          : notifyBoosts // ignore: cast_nullable_to_non_nullable
              as int,
      unlockedGifts: freezed == unlockedGifts
          ? _value.unlockedGifts
          : unlockedGifts // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      lastStreamCompletedAt: freezed == lastStreamCompletedAt
          ? _value.lastStreamCompletedAt
          : lastStreamCompletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      xpToNextLevel: null == xpToNextLevel
          ? _value.xpToNextLevel
          : xpToNextLevel // ignore: cast_nullable_to_non_nullable
              as int,
      xpProgress: null == xpProgress
          ? _value.xpProgress
          : xpProgress // ignore: cast_nullable_to_non_nullable
              as double,
      giftValue: null == giftValue
          ? _value.giftValue
          : giftValue // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfileModelImplCopyWith<$Res>
    implements $ProfileModelCopyWith<$Res> {
  factory _$$ProfileModelImplCopyWith(
          _$ProfileModelImpl value, $Res Function(_$ProfileModelImpl) then) =
      __$$ProfileModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String email,
      String username,
      String displayName,
      String? bio,
      String? location,
      String? timezone,
      List<String> workoutTypes,
      List<String> goals,
      List<String> muscleGroups,
      String? profilePictureUrl,
      String role,
      bool onboardingCompleted,
      @DateTimeConverter() DateTime createdAt,
      @DateTimeConverter() DateTime updatedAt,
      int xp,
      int level,
      int rubies,
      int proteinShakes,
      int proteinBars,
      int profileBoosts,
      int notifyBoosts,
      Map<String, dynamic>? unlockedGifts,
      @NullableDateTimeConverter() DateTime? lastStreamCompletedAt,
      int xpToNextLevel,
      double xpProgress,
      int giftValue});
}

/// @nodoc
class __$$ProfileModelImplCopyWithImpl<$Res>
    extends _$ProfileModelCopyWithImpl<$Res, _$ProfileModelImpl>
    implements _$$ProfileModelImplCopyWith<$Res> {
  __$$ProfileModelImplCopyWithImpl(
      _$ProfileModelImpl _value, $Res Function(_$ProfileModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? email = null,
    Object? username = null,
    Object? displayName = null,
    Object? bio = freezed,
    Object? location = freezed,
    Object? timezone = freezed,
    Object? workoutTypes = null,
    Object? goals = null,
    Object? muscleGroups = null,
    Object? profilePictureUrl = freezed,
    Object? role = null,
    Object? onboardingCompleted = null,
    Object? createdAt = null,
    Object? updatedAt = null,
    Object? xp = null,
    Object? level = null,
    Object? rubies = null,
    Object? proteinShakes = null,
    Object? proteinBars = null,
    Object? profileBoosts = null,
    Object? notifyBoosts = null,
    Object? unlockedGifts = freezed,
    Object? lastStreamCompletedAt = freezed,
    Object? xpToNextLevel = null,
    Object? xpProgress = null,
    Object? giftValue = null,
  }) {
    return _then(_$ProfileModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      bio: freezed == bio
          ? _value.bio
          : bio // ignore: cast_nullable_to_non_nullable
              as String?,
      location: freezed == location
          ? _value.location
          : location // ignore: cast_nullable_to_non_nullable
              as String?,
      timezone: freezed == timezone
          ? _value.timezone
          : timezone // ignore: cast_nullable_to_non_nullable
              as String?,
      workoutTypes: null == workoutTypes
          ? _value._workoutTypes
          : workoutTypes // ignore: cast_nullable_to_non_nullable
              as List<String>,
      goals: null == goals
          ? _value._goals
          : goals // ignore: cast_nullable_to_non_nullable
              as List<String>,
      muscleGroups: null == muscleGroups
          ? _value._muscleGroups
          : muscleGroups // ignore: cast_nullable_to_non_nullable
              as List<String>,
      profilePictureUrl: freezed == profilePictureUrl
          ? _value.profilePictureUrl
          : profilePictureUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      onboardingCompleted: null == onboardingCompleted
          ? _value.onboardingCompleted
          : onboardingCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updatedAt: null == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      xp: null == xp
          ? _value.xp
          : xp // ignore: cast_nullable_to_non_nullable
              as int,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as int,
      rubies: null == rubies
          ? _value.rubies
          : rubies // ignore: cast_nullable_to_non_nullable
              as int,
      proteinShakes: null == proteinShakes
          ? _value.proteinShakes
          : proteinShakes // ignore: cast_nullable_to_non_nullable
              as int,
      proteinBars: null == proteinBars
          ? _value.proteinBars
          : proteinBars // ignore: cast_nullable_to_non_nullable
              as int,
      profileBoosts: null == profileBoosts
          ? _value.profileBoosts
          : profileBoosts // ignore: cast_nullable_to_non_nullable
              as int,
      notifyBoosts: null == notifyBoosts
          ? _value.notifyBoosts
          : notifyBoosts // ignore: cast_nullable_to_non_nullable
              as int,
      unlockedGifts: freezed == unlockedGifts
          ? _value._unlockedGifts
          : unlockedGifts // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      lastStreamCompletedAt: freezed == lastStreamCompletedAt
          ? _value.lastStreamCompletedAt
          : lastStreamCompletedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      xpToNextLevel: null == xpToNextLevel
          ? _value.xpToNextLevel
          : xpToNextLevel // ignore: cast_nullable_to_non_nullable
              as int,
      xpProgress: null == xpProgress
          ? _value.xpProgress
          : xpProgress // ignore: cast_nullable_to_non_nullable
              as double,
      giftValue: null == giftValue
          ? _value.giftValue
          : giftValue // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfileModelImpl implements _ProfileModel {
  const _$ProfileModelImpl(
      {required this.id,
      required this.email,
      required this.username,
      required this.displayName,
      this.bio,
      this.location,
      this.timezone,
      final List<String> workoutTypes = const [],
      final List<String> goals = const [],
      final List<String> muscleGroups = const [],
      this.profilePictureUrl,
      required this.role,
      this.onboardingCompleted = false,
      @DateTimeConverter() required this.createdAt,
      @DateTimeConverter() required this.updatedAt,
      this.xp = 0,
      this.level = 0,
      this.rubies = 0,
      this.proteinShakes = 0,
      this.proteinBars = 0,
      this.profileBoosts = 0,
      this.notifyBoosts = 0,
      final Map<String, dynamic>? unlockedGifts,
      @NullableDateTimeConverter() this.lastStreamCompletedAt,
      this.xpToNextLevel = 100,
      this.xpProgress = 0.0,
      this.giftValue = 0})
      : _workoutTypes = workoutTypes,
        _goals = goals,
        _muscleGroups = muscleGroups,
        _unlockedGifts = unlockedGifts;

  factory _$ProfileModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfileModelImplFromJson(json);

  @override
  final int id;
  @override
  final String email;
  @override
  final String username;
  @override
  final String displayName;
  @override
  final String? bio;
  @override
  final String? location;
  @override
  final String? timezone;
  final List<String> _workoutTypes;
  @override
  @JsonKey()
  List<String> get workoutTypes {
    if (_workoutTypes is EqualUnmodifiableListView) return _workoutTypes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_workoutTypes);
  }

  final List<String> _goals;
  @override
  @JsonKey()
  List<String> get goals {
    if (_goals is EqualUnmodifiableListView) return _goals;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_goals);
  }

  final List<String> _muscleGroups;
  @override
  @JsonKey()
  List<String> get muscleGroups {
    if (_muscleGroups is EqualUnmodifiableListView) return _muscleGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_muscleGroups);
  }

  @override
  final String? profilePictureUrl;
  @override
  final String role;
  @override
  @JsonKey()
  final bool onboardingCompleted;
  @override
  @DateTimeConverter()
  final DateTime createdAt;
  @override
  @DateTimeConverter()
  final DateTime updatedAt;
  @override
  @JsonKey()
  final int xp;
  @override
  @JsonKey()
  final int level;
  @override
  @JsonKey()
  final int rubies;
  @override
  @JsonKey()
  final int proteinShakes;
  @override
  @JsonKey()
  final int proteinBars;
  @override
  @JsonKey()
  final int profileBoosts;
  @override
  @JsonKey()
  final int notifyBoosts;
  final Map<String, dynamic>? _unlockedGifts;
  @override
  Map<String, dynamic>? get unlockedGifts {
    final value = _unlockedGifts;
    if (value == null) return null;
    if (_unlockedGifts is EqualUnmodifiableMapView) return _unlockedGifts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  @NullableDateTimeConverter()
  final DateTime? lastStreamCompletedAt;
  @override
  @JsonKey()
  final int xpToNextLevel;
  @override
  @JsonKey()
  final double xpProgress;
  @override
  @JsonKey()
  final int giftValue;

  @override
  String toString() {
    return 'ProfileModel(id: $id, email: $email, username: $username, displayName: $displayName, bio: $bio, location: $location, timezone: $timezone, workoutTypes: $workoutTypes, goals: $goals, muscleGroups: $muscleGroups, profilePictureUrl: $profilePictureUrl, role: $role, onboardingCompleted: $onboardingCompleted, createdAt: $createdAt, updatedAt: $updatedAt, xp: $xp, level: $level, rubies: $rubies, proteinShakes: $proteinShakes, proteinBars: $proteinBars, profileBoosts: $profileBoosts, notifyBoosts: $notifyBoosts, unlockedGifts: $unlockedGifts, lastStreamCompletedAt: $lastStreamCompletedAt, xpToNextLevel: $xpToNextLevel, xpProgress: $xpProgress, giftValue: $giftValue)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfileModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.bio, bio) || other.bio == bio) &&
            (identical(other.location, location) ||
                other.location == location) &&
            (identical(other.timezone, timezone) ||
                other.timezone == timezone) &&
            const DeepCollectionEquality()
                .equals(other._workoutTypes, _workoutTypes) &&
            const DeepCollectionEquality().equals(other._goals, _goals) &&
            const DeepCollectionEquality()
                .equals(other._muscleGroups, _muscleGroups) &&
            (identical(other.profilePictureUrl, profilePictureUrl) ||
                other.profilePictureUrl == profilePictureUrl) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.onboardingCompleted, onboardingCompleted) ||
                other.onboardingCompleted == onboardingCompleted) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.xp, xp) || other.xp == xp) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.rubies, rubies) || other.rubies == rubies) &&
            (identical(other.proteinShakes, proteinShakes) ||
                other.proteinShakes == proteinShakes) &&
            (identical(other.proteinBars, proteinBars) ||
                other.proteinBars == proteinBars) &&
            (identical(other.profileBoosts, profileBoosts) ||
                other.profileBoosts == profileBoosts) &&
            (identical(other.notifyBoosts, notifyBoosts) ||
                other.notifyBoosts == notifyBoosts) &&
            const DeepCollectionEquality()
                .equals(other._unlockedGifts, _unlockedGifts) &&
            (identical(other.lastStreamCompletedAt, lastStreamCompletedAt) ||
                other.lastStreamCompletedAt == lastStreamCompletedAt) &&
            (identical(other.xpToNextLevel, xpToNextLevel) ||
                other.xpToNextLevel == xpToNextLevel) &&
            (identical(other.xpProgress, xpProgress) ||
                other.xpProgress == xpProgress) &&
            (identical(other.giftValue, giftValue) ||
                other.giftValue == giftValue));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        email,
        username,
        displayName,
        bio,
        location,
        timezone,
        const DeepCollectionEquality().hash(_workoutTypes),
        const DeepCollectionEquality().hash(_goals),
        const DeepCollectionEquality().hash(_muscleGroups),
        profilePictureUrl,
        role,
        onboardingCompleted,
        createdAt,
        updatedAt,
        xp,
        level,
        rubies,
        proteinShakes,
        proteinBars,
        profileBoosts,
        notifyBoosts,
        const DeepCollectionEquality().hash(_unlockedGifts),
        lastStreamCompletedAt,
        xpToNextLevel,
        xpProgress,
        giftValue
      ]);

  /// Create a copy of ProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfileModelImplCopyWith<_$ProfileModelImpl> get copyWith =>
      __$$ProfileModelImplCopyWithImpl<_$ProfileModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfileModelImplToJson(
      this,
    );
  }
}

abstract class _ProfileModel implements ProfileModel {
  const factory _ProfileModel(
      {required final int id,
      required final String email,
      required final String username,
      required final String displayName,
      final String? bio,
      final String? location,
      final String? timezone,
      final List<String> workoutTypes,
      final List<String> goals,
      final List<String> muscleGroups,
      final String? profilePictureUrl,
      required final String role,
      final bool onboardingCompleted,
      @DateTimeConverter() required final DateTime createdAt,
      @DateTimeConverter() required final DateTime updatedAt,
      final int xp,
      final int level,
      final int rubies,
      final int proteinShakes,
      final int proteinBars,
      final int profileBoosts,
      final int notifyBoosts,
      final Map<String, dynamic>? unlockedGifts,
      @NullableDateTimeConverter() final DateTime? lastStreamCompletedAt,
      final int xpToNextLevel,
      final double xpProgress,
      final int giftValue}) = _$ProfileModelImpl;

  factory _ProfileModel.fromJson(Map<String, dynamic> json) =
      _$ProfileModelImpl.fromJson;

  @override
  int get id;
  @override
  String get email;
  @override
  String get username;
  @override
  String get displayName;
  @override
  String? get bio;
  @override
  String? get location;
  @override
  String? get timezone;
  @override
  List<String> get workoutTypes;
  @override
  List<String> get goals;
  @override
  List<String> get muscleGroups;
  @override
  String? get profilePictureUrl;
  @override
  String get role;
  @override
  bool get onboardingCompleted;
  @override
  @DateTimeConverter()
  DateTime get createdAt;
  @override
  @DateTimeConverter()
  DateTime get updatedAt;
  @override
  int get xp;
  @override
  int get level;
  @override
  int get rubies;
  @override
  int get proteinShakes;
  @override
  int get proteinBars;
  @override
  int get profileBoosts;
  @override
  int get notifyBoosts;
  @override
  Map<String, dynamic>? get unlockedGifts;
  @override
  @NullableDateTimeConverter()
  DateTime? get lastStreamCompletedAt;
  @override
  int get xpToNextLevel;
  @override
  double get xpProgress;
  @override
  int get giftValue;

  /// Create a copy of ProfileModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfileModelImplCopyWith<_$ProfileModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
