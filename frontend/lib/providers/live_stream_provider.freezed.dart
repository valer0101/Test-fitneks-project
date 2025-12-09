// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'live_stream_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$LiveStreamState {
  LiveStream? get livestream => throw _privateConstructorUsedError;
  String? get token => throw _privateConstructorUsedError;
  String? get roomName => throw _privateConstructorUsedError;
  bool get isOwner => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isConnecting => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;

  /// Create a copy of LiveStreamState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $LiveStreamStateCopyWith<LiveStreamState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $LiveStreamStateCopyWith<$Res> {
  factory $LiveStreamStateCopyWith(
          LiveStreamState value, $Res Function(LiveStreamState) then) =
      _$LiveStreamStateCopyWithImpl<$Res, LiveStreamState>;
  @useResult
  $Res call(
      {LiveStream? livestream,
      String? token,
      String? roomName,
      bool isOwner,
      bool isLoading,
      bool isConnecting,
      String? error});
}

/// @nodoc
class _$LiveStreamStateCopyWithImpl<$Res, $Val extends LiveStreamState>
    implements $LiveStreamStateCopyWith<$Res> {
  _$LiveStreamStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of LiveStreamState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? livestream = freezed,
    Object? token = freezed,
    Object? roomName = freezed,
    Object? isOwner = null,
    Object? isLoading = null,
    Object? isConnecting = null,
    Object? error = freezed,
  }) {
    return _then(_value.copyWith(
      livestream: freezed == livestream
          ? _value.livestream
          : livestream // ignore: cast_nullable_to_non_nullable
              as LiveStream?,
      token: freezed == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String?,
      roomName: freezed == roomName
          ? _value.roomName
          : roomName // ignore: cast_nullable_to_non_nullable
              as String?,
      isOwner: null == isOwner
          ? _value.isOwner
          : isOwner // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isConnecting: null == isConnecting
          ? _value.isConnecting
          : isConnecting // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$LiveStreamStateImplCopyWith<$Res>
    implements $LiveStreamStateCopyWith<$Res> {
  factory _$$LiveStreamStateImplCopyWith(_$LiveStreamStateImpl value,
          $Res Function(_$LiveStreamStateImpl) then) =
      __$$LiveStreamStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {LiveStream? livestream,
      String? token,
      String? roomName,
      bool isOwner,
      bool isLoading,
      bool isConnecting,
      String? error});
}

/// @nodoc
class __$$LiveStreamStateImplCopyWithImpl<$Res>
    extends _$LiveStreamStateCopyWithImpl<$Res, _$LiveStreamStateImpl>
    implements _$$LiveStreamStateImplCopyWith<$Res> {
  __$$LiveStreamStateImplCopyWithImpl(
      _$LiveStreamStateImpl _value, $Res Function(_$LiveStreamStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of LiveStreamState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? livestream = freezed,
    Object? token = freezed,
    Object? roomName = freezed,
    Object? isOwner = null,
    Object? isLoading = null,
    Object? isConnecting = null,
    Object? error = freezed,
  }) {
    return _then(_$LiveStreamStateImpl(
      livestream: freezed == livestream
          ? _value.livestream
          : livestream // ignore: cast_nullable_to_non_nullable
              as LiveStream?,
      token: freezed == token
          ? _value.token
          : token // ignore: cast_nullable_to_non_nullable
              as String?,
      roomName: freezed == roomName
          ? _value.roomName
          : roomName // ignore: cast_nullable_to_non_nullable
              as String?,
      isOwner: null == isOwner
          ? _value.isOwner
          : isOwner // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isConnecting: null == isConnecting
          ? _value.isConnecting
          : isConnecting // ignore: cast_nullable_to_non_nullable
              as bool,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$LiveStreamStateImpl implements _LiveStreamState {
  const _$LiveStreamStateImpl(
      {this.livestream,
      this.token,
      this.roomName,
      this.isOwner = false,
      this.isLoading = false,
      this.isConnecting = false,
      this.error});

  @override
  final LiveStream? livestream;
  @override
  final String? token;
  @override
  final String? roomName;
  @override
  @JsonKey()
  final bool isOwner;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isConnecting;
  @override
  final String? error;

  @override
  String toString() {
    return 'LiveStreamState(livestream: $livestream, token: $token, roomName: $roomName, isOwner: $isOwner, isLoading: $isLoading, isConnecting: $isConnecting, error: $error)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$LiveStreamStateImpl &&
            (identical(other.livestream, livestream) ||
                other.livestream == livestream) &&
            (identical(other.token, token) || other.token == token) &&
            (identical(other.roomName, roomName) ||
                other.roomName == roomName) &&
            (identical(other.isOwner, isOwner) || other.isOwner == isOwner) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isConnecting, isConnecting) ||
                other.isConnecting == isConnecting) &&
            (identical(other.error, error) || other.error == error));
  }

  @override
  int get hashCode => Object.hash(runtimeType, livestream, token, roomName,
      isOwner, isLoading, isConnecting, error);

  /// Create a copy of LiveStreamState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$LiveStreamStateImplCopyWith<_$LiveStreamStateImpl> get copyWith =>
      __$$LiveStreamStateImplCopyWithImpl<_$LiveStreamStateImpl>(
          this, _$identity);
}

abstract class _LiveStreamState implements LiveStreamState {
  const factory _LiveStreamState(
      {final LiveStream? livestream,
      final String? token,
      final String? roomName,
      final bool isOwner,
      final bool isLoading,
      final bool isConnecting,
      final String? error}) = _$LiveStreamStateImpl;

  @override
  LiveStream? get livestream;
  @override
  String? get token;
  @override
  String? get roomName;
  @override
  bool get isOwner;
  @override
  bool get isLoading;
  @override
  bool get isConnecting;
  @override
  String? get error;

  /// Create a copy of LiveStreamState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$LiveStreamStateImplCopyWith<_$LiveStreamStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$RoomState {
  Room? get room => throw _privateConstructorUsedError;
  bool get isConnected => throw _privateConstructorUsedError;
  bool get isMicEnabled => throw _privateConstructorUsedError;
  bool get isCameraEnabled => throw _privateConstructorUsedError;
  LocalParticipant? get localParticipant => throw _privateConstructorUsedError;
  List<RemoteParticipant> get remoteParticipants =>
      throw _privateConstructorUsedError;
  int get viewerCount => throw _privateConstructorUsedError;
  EventsListener<RoomEvent>? get listener => throw _privateConstructorUsedError;

  /// Create a copy of RoomState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RoomStateCopyWith<RoomState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoomStateCopyWith<$Res> {
  factory $RoomStateCopyWith(RoomState value, $Res Function(RoomState) then) =
      _$RoomStateCopyWithImpl<$Res, RoomState>;
  @useResult
  $Res call(
      {Room? room,
      bool isConnected,
      bool isMicEnabled,
      bool isCameraEnabled,
      LocalParticipant? localParticipant,
      List<RemoteParticipant> remoteParticipants,
      int viewerCount,
      EventsListener<RoomEvent>? listener});
}

/// @nodoc
class _$RoomStateCopyWithImpl<$Res, $Val extends RoomState>
    implements $RoomStateCopyWith<$Res> {
  _$RoomStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RoomState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? room = freezed,
    Object? isConnected = null,
    Object? isMicEnabled = null,
    Object? isCameraEnabled = null,
    Object? localParticipant = freezed,
    Object? remoteParticipants = null,
    Object? viewerCount = null,
    Object? listener = freezed,
  }) {
    return _then(_value.copyWith(
      room: freezed == room
          ? _value.room
          : room // ignore: cast_nullable_to_non_nullable
              as Room?,
      isConnected: null == isConnected
          ? _value.isConnected
          : isConnected // ignore: cast_nullable_to_non_nullable
              as bool,
      isMicEnabled: null == isMicEnabled
          ? _value.isMicEnabled
          : isMicEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isCameraEnabled: null == isCameraEnabled
          ? _value.isCameraEnabled
          : isCameraEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      localParticipant: freezed == localParticipant
          ? _value.localParticipant
          : localParticipant // ignore: cast_nullable_to_non_nullable
              as LocalParticipant?,
      remoteParticipants: null == remoteParticipants
          ? _value.remoteParticipants
          : remoteParticipants // ignore: cast_nullable_to_non_nullable
              as List<RemoteParticipant>,
      viewerCount: null == viewerCount
          ? _value.viewerCount
          : viewerCount // ignore: cast_nullable_to_non_nullable
              as int,
      listener: freezed == listener
          ? _value.listener
          : listener // ignore: cast_nullable_to_non_nullable
              as EventsListener<RoomEvent>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoomStateImplCopyWith<$Res>
    implements $RoomStateCopyWith<$Res> {
  factory _$$RoomStateImplCopyWith(
          _$RoomStateImpl value, $Res Function(_$RoomStateImpl) then) =
      __$$RoomStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Room? room,
      bool isConnected,
      bool isMicEnabled,
      bool isCameraEnabled,
      LocalParticipant? localParticipant,
      List<RemoteParticipant> remoteParticipants,
      int viewerCount,
      EventsListener<RoomEvent>? listener});
}

/// @nodoc
class __$$RoomStateImplCopyWithImpl<$Res>
    extends _$RoomStateCopyWithImpl<$Res, _$RoomStateImpl>
    implements _$$RoomStateImplCopyWith<$Res> {
  __$$RoomStateImplCopyWithImpl(
      _$RoomStateImpl _value, $Res Function(_$RoomStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of RoomState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? room = freezed,
    Object? isConnected = null,
    Object? isMicEnabled = null,
    Object? isCameraEnabled = null,
    Object? localParticipant = freezed,
    Object? remoteParticipants = null,
    Object? viewerCount = null,
    Object? listener = freezed,
  }) {
    return _then(_$RoomStateImpl(
      room: freezed == room
          ? _value.room
          : room // ignore: cast_nullable_to_non_nullable
              as Room?,
      isConnected: null == isConnected
          ? _value.isConnected
          : isConnected // ignore: cast_nullable_to_non_nullable
              as bool,
      isMicEnabled: null == isMicEnabled
          ? _value.isMicEnabled
          : isMicEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      isCameraEnabled: null == isCameraEnabled
          ? _value.isCameraEnabled
          : isCameraEnabled // ignore: cast_nullable_to_non_nullable
              as bool,
      localParticipant: freezed == localParticipant
          ? _value.localParticipant
          : localParticipant // ignore: cast_nullable_to_non_nullable
              as LocalParticipant?,
      remoteParticipants: null == remoteParticipants
          ? _value._remoteParticipants
          : remoteParticipants // ignore: cast_nullable_to_non_nullable
              as List<RemoteParticipant>,
      viewerCount: null == viewerCount
          ? _value.viewerCount
          : viewerCount // ignore: cast_nullable_to_non_nullable
              as int,
      listener: freezed == listener
          ? _value.listener
          : listener // ignore: cast_nullable_to_non_nullable
              as EventsListener<RoomEvent>?,
    ));
  }
}

/// @nodoc

class _$RoomStateImpl implements _RoomState {
  const _$RoomStateImpl(
      {this.room,
      this.isConnected = false,
      this.isMicEnabled = false,
      this.isCameraEnabled = false,
      this.localParticipant,
      final List<RemoteParticipant> remoteParticipants = const [],
      this.viewerCount = 0,
      this.listener})
      : _remoteParticipants = remoteParticipants;

  @override
  final Room? room;
  @override
  @JsonKey()
  final bool isConnected;
  @override
  @JsonKey()
  final bool isMicEnabled;
  @override
  @JsonKey()
  final bool isCameraEnabled;
  @override
  final LocalParticipant? localParticipant;
  final List<RemoteParticipant> _remoteParticipants;
  @override
  @JsonKey()
  List<RemoteParticipant> get remoteParticipants {
    if (_remoteParticipants is EqualUnmodifiableListView)
      return _remoteParticipants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_remoteParticipants);
  }

  @override
  @JsonKey()
  final int viewerCount;
  @override
  final EventsListener<RoomEvent>? listener;

  @override
  String toString() {
    return 'RoomState(room: $room, isConnected: $isConnected, isMicEnabled: $isMicEnabled, isCameraEnabled: $isCameraEnabled, localParticipant: $localParticipant, remoteParticipants: $remoteParticipants, viewerCount: $viewerCount, listener: $listener)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoomStateImpl &&
            (identical(other.room, room) || other.room == room) &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected) &&
            (identical(other.isMicEnabled, isMicEnabled) ||
                other.isMicEnabled == isMicEnabled) &&
            (identical(other.isCameraEnabled, isCameraEnabled) ||
                other.isCameraEnabled == isCameraEnabled) &&
            (identical(other.localParticipant, localParticipant) ||
                other.localParticipant == localParticipant) &&
            const DeepCollectionEquality()
                .equals(other._remoteParticipants, _remoteParticipants) &&
            (identical(other.viewerCount, viewerCount) ||
                other.viewerCount == viewerCount) &&
            (identical(other.listener, listener) ||
                other.listener == listener));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      room,
      isConnected,
      isMicEnabled,
      isCameraEnabled,
      localParticipant,
      const DeepCollectionEquality().hash(_remoteParticipants),
      viewerCount,
      listener);

  /// Create a copy of RoomState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RoomStateImplCopyWith<_$RoomStateImpl> get copyWith =>
      __$$RoomStateImplCopyWithImpl<_$RoomStateImpl>(this, _$identity);
}

abstract class _RoomState implements RoomState {
  const factory _RoomState(
      {final Room? room,
      final bool isConnected,
      final bool isMicEnabled,
      final bool isCameraEnabled,
      final LocalParticipant? localParticipant,
      final List<RemoteParticipant> remoteParticipants,
      final int viewerCount,
      final EventsListener<RoomEvent>? listener}) = _$RoomStateImpl;

  @override
  Room? get room;
  @override
  bool get isConnected;
  @override
  bool get isMicEnabled;
  @override
  bool get isCameraEnabled;
  @override
  LocalParticipant? get localParticipant;
  @override
  List<RemoteParticipant> get remoteParticipants;
  @override
  int get viewerCount;
  @override
  EventsListener<RoomEvent>? get listener;

  /// Create a copy of RoomState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RoomStateImplCopyWith<_$RoomStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ChatMessage {
  String get id => throw _privateConstructorUsedError;
  String get senderId => throw _privateConstructorUsedError;
  String get senderName => throw _privateConstructorUsedError;
  String get message => throw _privateConstructorUsedError;
  DateTime get timestamp => throw _privateConstructorUsedError;
  bool get isTrainer => throw _privateConstructorUsedError;
  bool get isGiftSender => throw _privateConstructorUsedError;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ChatMessageCopyWith<ChatMessage> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatMessageCopyWith<$Res> {
  factory $ChatMessageCopyWith(
          ChatMessage value, $Res Function(ChatMessage) then) =
      _$ChatMessageCopyWithImpl<$Res, ChatMessage>;
  @useResult
  $Res call(
      {String id,
      String senderId,
      String senderName,
      String message,
      DateTime timestamp,
      bool isTrainer,
      bool isGiftSender});
}

/// @nodoc
class _$ChatMessageCopyWithImpl<$Res, $Val extends ChatMessage>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? senderName = null,
    Object? message = null,
    Object? timestamp = null,
    Object? isTrainer = null,
    Object? isGiftSender = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: null == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isTrainer: null == isTrainer
          ? _value.isTrainer
          : isTrainer // ignore: cast_nullable_to_non_nullable
              as bool,
      isGiftSender: null == isGiftSender
          ? _value.isGiftSender
          : isGiftSender // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatMessageImplCopyWith<$Res>
    implements $ChatMessageCopyWith<$Res> {
  factory _$$ChatMessageImplCopyWith(
          _$ChatMessageImpl value, $Res Function(_$ChatMessageImpl) then) =
      __$$ChatMessageImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String senderId,
      String senderName,
      String message,
      DateTime timestamp,
      bool isTrainer,
      bool isGiftSender});
}

/// @nodoc
class __$$ChatMessageImplCopyWithImpl<$Res>
    extends _$ChatMessageCopyWithImpl<$Res, _$ChatMessageImpl>
    implements _$$ChatMessageImplCopyWith<$Res> {
  __$$ChatMessageImplCopyWithImpl(
      _$ChatMessageImpl _value, $Res Function(_$ChatMessageImpl) _then)
      : super(_value, _then);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? senderId = null,
    Object? senderName = null,
    Object? message = null,
    Object? timestamp = null,
    Object? isTrainer = null,
    Object? isGiftSender = null,
  }) {
    return _then(_$ChatMessageImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      senderId: null == senderId
          ? _value.senderId
          : senderId // ignore: cast_nullable_to_non_nullable
              as String,
      senderName: null == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String,
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isTrainer: null == isTrainer
          ? _value.isTrainer
          : isTrainer // ignore: cast_nullable_to_non_nullable
              as bool,
      isGiftSender: null == isGiftSender
          ? _value.isGiftSender
          : isGiftSender // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$ChatMessageImpl implements _ChatMessage {
  const _$ChatMessageImpl(
      {required this.id,
      required this.senderId,
      required this.senderName,
      required this.message,
      required this.timestamp,
      this.isTrainer = false,
      this.isGiftSender = false});

  @override
  final String id;
  @override
  final String senderId;
  @override
  final String senderName;
  @override
  final String message;
  @override
  final DateTime timestamp;
  @override
  @JsonKey()
  final bool isTrainer;
  @override
  @JsonKey()
  final bool isGiftSender;

  @override
  String toString() {
    return 'ChatMessage(id: $id, senderId: $senderId, senderName: $senderName, message: $message, timestamp: $timestamp, isTrainer: $isTrainer, isGiftSender: $isGiftSender)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatMessageImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.senderId, senderId) ||
                other.senderId == senderId) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.message, message) || other.message == message) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.isTrainer, isTrainer) ||
                other.isTrainer == isTrainer) &&
            (identical(other.isGiftSender, isGiftSender) ||
                other.isGiftSender == isGiftSender));
  }

  @override
  int get hashCode => Object.hash(runtimeType, id, senderId, senderName,
      message, timestamp, isTrainer, isGiftSender);

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      __$$ChatMessageImplCopyWithImpl<_$ChatMessageImpl>(this, _$identity);
}

abstract class _ChatMessage implements ChatMessage {
  const factory _ChatMessage(
      {required final String id,
      required final String senderId,
      required final String senderName,
      required final String message,
      required final DateTime timestamp,
      final bool isTrainer,
      final bool isGiftSender}) = _$ChatMessageImpl;

  @override
  String get id;
  @override
  String get senderId;
  @override
  String get senderName;
  @override
  String get message;
  @override
  DateTime get timestamp;
  @override
  bool get isTrainer;
  @override
  bool get isGiftSender;

  /// Create a copy of ChatMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ChatMessageImplCopyWith<_$ChatMessageImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$WaitlistEntry {
  String get userId => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError;
  String? get profilePicture => throw _privateConstructorUsedError;
  DateTime get requestedAt => throw _privateConstructorUsedError;

  /// Create a copy of WaitlistEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WaitlistEntryCopyWith<WaitlistEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WaitlistEntryCopyWith<$Res> {
  factory $WaitlistEntryCopyWith(
          WaitlistEntry value, $Res Function(WaitlistEntry) then) =
      _$WaitlistEntryCopyWithImpl<$Res, WaitlistEntry>;
  @useResult
  $Res call(
      {String userId,
      String userName,
      String? profilePicture,
      DateTime requestedAt});
}

/// @nodoc
class _$WaitlistEntryCopyWithImpl<$Res, $Val extends WaitlistEntry>
    implements $WaitlistEntryCopyWith<$Res> {
  _$WaitlistEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WaitlistEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? userName = null,
    Object? profilePicture = freezed,
    Object? requestedAt = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      profilePicture: freezed == profilePicture
          ? _value.profilePicture
          : profilePicture // ignore: cast_nullable_to_non_nullable
              as String?,
      requestedAt: null == requestedAt
          ? _value.requestedAt
          : requestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WaitlistEntryImplCopyWith<$Res>
    implements $WaitlistEntryCopyWith<$Res> {
  factory _$$WaitlistEntryImplCopyWith(
          _$WaitlistEntryImpl value, $Res Function(_$WaitlistEntryImpl) then) =
      __$$WaitlistEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String userId,
      String userName,
      String? profilePicture,
      DateTime requestedAt});
}

/// @nodoc
class __$$WaitlistEntryImplCopyWithImpl<$Res>
    extends _$WaitlistEntryCopyWithImpl<$Res, _$WaitlistEntryImpl>
    implements _$$WaitlistEntryImplCopyWith<$Res> {
  __$$WaitlistEntryImplCopyWithImpl(
      _$WaitlistEntryImpl _value, $Res Function(_$WaitlistEntryImpl) _then)
      : super(_value, _then);

  /// Create a copy of WaitlistEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? userName = null,
    Object? profilePicture = freezed,
    Object? requestedAt = null,
  }) {
    return _then(_$WaitlistEntryImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      profilePicture: freezed == profilePicture
          ? _value.profilePicture
          : profilePicture // ignore: cast_nullable_to_non_nullable
              as String?,
      requestedAt: null == requestedAt
          ? _value.requestedAt
          : requestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$WaitlistEntryImpl implements _WaitlistEntry {
  const _$WaitlistEntryImpl(
      {required this.userId,
      required this.userName,
      this.profilePicture,
      required this.requestedAt});

  @override
  final String userId;
  @override
  final String userName;
  @override
  final String? profilePicture;
  @override
  final DateTime requestedAt;

  @override
  String toString() {
    return 'WaitlistEntry(userId: $userId, userName: $userName, profilePicture: $profilePicture, requestedAt: $requestedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WaitlistEntryImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.profilePicture, profilePicture) ||
                other.profilePicture == profilePicture) &&
            (identical(other.requestedAt, requestedAt) ||
                other.requestedAt == requestedAt));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, userId, userName, profilePicture, requestedAt);

  /// Create a copy of WaitlistEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WaitlistEntryImplCopyWith<_$WaitlistEntryImpl> get copyWith =>
      __$$WaitlistEntryImplCopyWithImpl<_$WaitlistEntryImpl>(this, _$identity);
}

abstract class _WaitlistEntry implements WaitlistEntry {
  const factory _WaitlistEntry(
      {required final String userId,
      required final String userName,
      final String? profilePicture,
      required final DateTime requestedAt}) = _$WaitlistEntryImpl;

  @override
  String get userId;
  @override
  String get userName;
  @override
  String? get profilePicture;
  @override
  DateTime get requestedAt;

  /// Create a copy of WaitlistEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WaitlistEntryImplCopyWith<_$WaitlistEntryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$GradeRequest {
  String get userId => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError;
  DateTime get requestedAt => throw _privateConstructorUsedError;

  /// Create a copy of GradeRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GradeRequestCopyWith<GradeRequest> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GradeRequestCopyWith<$Res> {
  factory $GradeRequestCopyWith(
          GradeRequest value, $Res Function(GradeRequest) then) =
      _$GradeRequestCopyWithImpl<$Res, GradeRequest>;
  @useResult
  $Res call({String userId, String userName, DateTime requestedAt});
}

/// @nodoc
class _$GradeRequestCopyWithImpl<$Res, $Val extends GradeRequest>
    implements $GradeRequestCopyWith<$Res> {
  _$GradeRequestCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GradeRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? userName = null,
    Object? requestedAt = null,
  }) {
    return _then(_value.copyWith(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      requestedAt: null == requestedAt
          ? _value.requestedAt
          : requestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GradeRequestImplCopyWith<$Res>
    implements $GradeRequestCopyWith<$Res> {
  factory _$$GradeRequestImplCopyWith(
          _$GradeRequestImpl value, $Res Function(_$GradeRequestImpl) then) =
      __$$GradeRequestImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String userId, String userName, DateTime requestedAt});
}

/// @nodoc
class __$$GradeRequestImplCopyWithImpl<$Res>
    extends _$GradeRequestCopyWithImpl<$Res, _$GradeRequestImpl>
    implements _$$GradeRequestImplCopyWith<$Res> {
  __$$GradeRequestImplCopyWithImpl(
      _$GradeRequestImpl _value, $Res Function(_$GradeRequestImpl) _then)
      : super(_value, _then);

  /// Create a copy of GradeRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? userName = null,
    Object? requestedAt = null,
  }) {
    return _then(_$GradeRequestImpl(
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      userName: null == userName
          ? _value.userName
          : userName // ignore: cast_nullable_to_non_nullable
              as String,
      requestedAt: null == requestedAt
          ? _value.requestedAt
          : requestedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$GradeRequestImpl implements _GradeRequest {
  const _$GradeRequestImpl(
      {required this.userId,
      required this.userName,
      required this.requestedAt});

  @override
  final String userId;
  @override
  final String userName;
  @override
  final DateTime requestedAt;

  @override
  String toString() {
    return 'GradeRequest(userId: $userId, userName: $userName, requestedAt: $requestedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GradeRequestImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.requestedAt, requestedAt) ||
                other.requestedAt == requestedAt));
  }

  @override
  int get hashCode => Object.hash(runtimeType, userId, userName, requestedAt);

  /// Create a copy of GradeRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GradeRequestImplCopyWith<_$GradeRequestImpl> get copyWith =>
      __$$GradeRequestImplCopyWithImpl<_$GradeRequestImpl>(this, _$identity);
}

abstract class _GradeRequest implements GradeRequest {
  const factory _GradeRequest(
      {required final String userId,
      required final String userName,
      required final DateTime requestedAt}) = _$GradeRequestImpl;

  @override
  String get userId;
  @override
  String get userName;
  @override
  DateTime get requestedAt;

  /// Create a copy of GradeRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GradeRequestImplCopyWith<_$GradeRequestImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$GiftSummary {
  double get totalAmount => throw _privateConstructorUsedError;
  int get giftCount => throw _privateConstructorUsedError;
  int get rubyCount => throw _privateConstructorUsedError; // ✅ Added
  int get proteinShakeCount => throw _privateConstructorUsedError; // ✅ Added
  int get proteinBarCount => throw _privateConstructorUsedError; // ✅ Added
  int get proteinPowderCount => throw _privateConstructorUsedError; // ✅ Added
  List<GiftTransaction> get transactions => throw _privateConstructorUsedError;

  /// Create a copy of GiftSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GiftSummaryCopyWith<GiftSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GiftSummaryCopyWith<$Res> {
  factory $GiftSummaryCopyWith(
          GiftSummary value, $Res Function(GiftSummary) then) =
      _$GiftSummaryCopyWithImpl<$Res, GiftSummary>;
  @useResult
  $Res call(
      {double totalAmount,
      int giftCount,
      int rubyCount,
      int proteinShakeCount,
      int proteinBarCount,
      int proteinPowderCount,
      List<GiftTransaction> transactions});
}

/// @nodoc
class _$GiftSummaryCopyWithImpl<$Res, $Val extends GiftSummary>
    implements $GiftSummaryCopyWith<$Res> {
  _$GiftSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GiftSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalAmount = null,
    Object? giftCount = null,
    Object? rubyCount = null,
    Object? proteinShakeCount = null,
    Object? proteinBarCount = null,
    Object? proteinPowderCount = null,
    Object? transactions = null,
  }) {
    return _then(_value.copyWith(
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      giftCount: null == giftCount
          ? _value.giftCount
          : giftCount // ignore: cast_nullable_to_non_nullable
              as int,
      rubyCount: null == rubyCount
          ? _value.rubyCount
          : rubyCount // ignore: cast_nullable_to_non_nullable
              as int,
      proteinShakeCount: null == proteinShakeCount
          ? _value.proteinShakeCount
          : proteinShakeCount // ignore: cast_nullable_to_non_nullable
              as int,
      proteinBarCount: null == proteinBarCount
          ? _value.proteinBarCount
          : proteinBarCount // ignore: cast_nullable_to_non_nullable
              as int,
      proteinPowderCount: null == proteinPowderCount
          ? _value.proteinPowderCount
          : proteinPowderCount // ignore: cast_nullable_to_non_nullable
              as int,
      transactions: null == transactions
          ? _value.transactions
          : transactions // ignore: cast_nullable_to_non_nullable
              as List<GiftTransaction>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GiftSummaryImplCopyWith<$Res>
    implements $GiftSummaryCopyWith<$Res> {
  factory _$$GiftSummaryImplCopyWith(
          _$GiftSummaryImpl value, $Res Function(_$GiftSummaryImpl) then) =
      __$$GiftSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double totalAmount,
      int giftCount,
      int rubyCount,
      int proteinShakeCount,
      int proteinBarCount,
      int proteinPowderCount,
      List<GiftTransaction> transactions});
}

/// @nodoc
class __$$GiftSummaryImplCopyWithImpl<$Res>
    extends _$GiftSummaryCopyWithImpl<$Res, _$GiftSummaryImpl>
    implements _$$GiftSummaryImplCopyWith<$Res> {
  __$$GiftSummaryImplCopyWithImpl(
      _$GiftSummaryImpl _value, $Res Function(_$GiftSummaryImpl) _then)
      : super(_value, _then);

  /// Create a copy of GiftSummary
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalAmount = null,
    Object? giftCount = null,
    Object? rubyCount = null,
    Object? proteinShakeCount = null,
    Object? proteinBarCount = null,
    Object? proteinPowderCount = null,
    Object? transactions = null,
  }) {
    return _then(_$GiftSummaryImpl(
      totalAmount: null == totalAmount
          ? _value.totalAmount
          : totalAmount // ignore: cast_nullable_to_non_nullable
              as double,
      giftCount: null == giftCount
          ? _value.giftCount
          : giftCount // ignore: cast_nullable_to_non_nullable
              as int,
      rubyCount: null == rubyCount
          ? _value.rubyCount
          : rubyCount // ignore: cast_nullable_to_non_nullable
              as int,
      proteinShakeCount: null == proteinShakeCount
          ? _value.proteinShakeCount
          : proteinShakeCount // ignore: cast_nullable_to_non_nullable
              as int,
      proteinBarCount: null == proteinBarCount
          ? _value.proteinBarCount
          : proteinBarCount // ignore: cast_nullable_to_non_nullable
              as int,
      proteinPowderCount: null == proteinPowderCount
          ? _value.proteinPowderCount
          : proteinPowderCount // ignore: cast_nullable_to_non_nullable
              as int,
      transactions: null == transactions
          ? _value._transactions
          : transactions // ignore: cast_nullable_to_non_nullable
              as List<GiftTransaction>,
    ));
  }
}

/// @nodoc

class _$GiftSummaryImpl implements _GiftSummary {
  const _$GiftSummaryImpl(
      {this.totalAmount = 0.0,
      this.giftCount = 0,
      this.rubyCount = 0,
      this.proteinShakeCount = 0,
      this.proteinBarCount = 0,
      this.proteinPowderCount = 0,
      final List<GiftTransaction> transactions = const []})
      : _transactions = transactions;

  @override
  @JsonKey()
  final double totalAmount;
  @override
  @JsonKey()
  final int giftCount;
  @override
  @JsonKey()
  final int rubyCount;
// ✅ Added
  @override
  @JsonKey()
  final int proteinShakeCount;
// ✅ Added
  @override
  @JsonKey()
  final int proteinBarCount;
// ✅ Added
  @override
  @JsonKey()
  final int proteinPowderCount;
// ✅ Added
  final List<GiftTransaction> _transactions;
// ✅ Added
  @override
  @JsonKey()
  List<GiftTransaction> get transactions {
    if (_transactions is EqualUnmodifiableListView) return _transactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_transactions);
  }

  @override
  String toString() {
    return 'GiftSummary(totalAmount: $totalAmount, giftCount: $giftCount, rubyCount: $rubyCount, proteinShakeCount: $proteinShakeCount, proteinBarCount: $proteinBarCount, proteinPowderCount: $proteinPowderCount, transactions: $transactions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GiftSummaryImpl &&
            (identical(other.totalAmount, totalAmount) ||
                other.totalAmount == totalAmount) &&
            (identical(other.giftCount, giftCount) ||
                other.giftCount == giftCount) &&
            (identical(other.rubyCount, rubyCount) ||
                other.rubyCount == rubyCount) &&
            (identical(other.proteinShakeCount, proteinShakeCount) ||
                other.proteinShakeCount == proteinShakeCount) &&
            (identical(other.proteinBarCount, proteinBarCount) ||
                other.proteinBarCount == proteinBarCount) &&
            (identical(other.proteinPowderCount, proteinPowderCount) ||
                other.proteinPowderCount == proteinPowderCount) &&
            const DeepCollectionEquality()
                .equals(other._transactions, _transactions));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      totalAmount,
      giftCount,
      rubyCount,
      proteinShakeCount,
      proteinBarCount,
      proteinPowderCount,
      const DeepCollectionEquality().hash(_transactions));

  /// Create a copy of GiftSummary
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GiftSummaryImplCopyWith<_$GiftSummaryImpl> get copyWith =>
      __$$GiftSummaryImplCopyWithImpl<_$GiftSummaryImpl>(this, _$identity);
}

abstract class _GiftSummary implements GiftSummary {
  const factory _GiftSummary(
      {final double totalAmount,
      final int giftCount,
      final int rubyCount,
      final int proteinShakeCount,
      final int proteinBarCount,
      final int proteinPowderCount,
      final List<GiftTransaction> transactions}) = _$GiftSummaryImpl;

  @override
  double get totalAmount;
  @override
  int get giftCount;
  @override
  int get rubyCount; // ✅ Added
  @override
  int get proteinShakeCount; // ✅ Added
  @override
  int get proteinBarCount; // ✅ Added
  @override
  int get proteinPowderCount; // ✅ Added
  @override
  List<GiftTransaction> get transactions;

  /// Create a copy of GiftSummary
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GiftSummaryImplCopyWith<_$GiftSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$GiftTransaction {
  String get senderName => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  String get giftType =>
      throw _privateConstructorUsedError; // ✅ Added to track gift type
  DateTime get timestamp => throw _privateConstructorUsedError;

  /// Create a copy of GiftTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GiftTransactionCopyWith<GiftTransaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GiftTransactionCopyWith<$Res> {
  factory $GiftTransactionCopyWith(
          GiftTransaction value, $Res Function(GiftTransaction) then) =
      _$GiftTransactionCopyWithImpl<$Res, GiftTransaction>;
  @useResult
  $Res call(
      {String senderName, double amount, String giftType, DateTime timestamp});
}

/// @nodoc
class _$GiftTransactionCopyWithImpl<$Res, $Val extends GiftTransaction>
    implements $GiftTransactionCopyWith<$Res> {
  _$GiftTransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GiftTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? senderName = null,
    Object? amount = null,
    Object? giftType = null,
    Object? timestamp = null,
  }) {
    return _then(_value.copyWith(
      senderName: null == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      giftType: null == giftType
          ? _value.giftType
          : giftType // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GiftTransactionImplImplCopyWith<$Res>
    implements $GiftTransactionCopyWith<$Res> {
  factory _$$GiftTransactionImplImplCopyWith(_$GiftTransactionImplImpl value,
          $Res Function(_$GiftTransactionImplImpl) then) =
      __$$GiftTransactionImplImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String senderName, double amount, String giftType, DateTime timestamp});
}

/// @nodoc
class __$$GiftTransactionImplImplCopyWithImpl<$Res>
    extends _$GiftTransactionCopyWithImpl<$Res, _$GiftTransactionImplImpl>
    implements _$$GiftTransactionImplImplCopyWith<$Res> {
  __$$GiftTransactionImplImplCopyWithImpl(_$GiftTransactionImplImpl _value,
      $Res Function(_$GiftTransactionImplImpl) _then)
      : super(_value, _then);

  /// Create a copy of GiftTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? senderName = null,
    Object? amount = null,
    Object? giftType = null,
    Object? timestamp = null,
  }) {
    return _then(_$GiftTransactionImplImpl(
      senderName: null == senderName
          ? _value.senderName
          : senderName // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      giftType: null == giftType
          ? _value.giftType
          : giftType // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$GiftTransactionImplImpl implements _GiftTransactionImpl {
  const _$GiftTransactionImplImpl(
      {required this.senderName,
      required this.amount,
      required this.giftType,
      required this.timestamp});

  @override
  final String senderName;
  @override
  final double amount;
  @override
  final String giftType;
// ✅ Added to track gift type
  @override
  final DateTime timestamp;

  @override
  String toString() {
    return 'GiftTransaction(senderName: $senderName, amount: $amount, giftType: $giftType, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GiftTransactionImplImpl &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.giftType, giftType) ||
                other.giftType == giftType) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, senderName, amount, giftType, timestamp);

  /// Create a copy of GiftTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GiftTransactionImplImplCopyWith<_$GiftTransactionImplImpl> get copyWith =>
      __$$GiftTransactionImplImplCopyWithImpl<_$GiftTransactionImplImpl>(
          this, _$identity);
}

abstract class _GiftTransactionImpl implements GiftTransaction {
  const factory _GiftTransactionImpl(
      {required final String senderName,
      required final double amount,
      required final String giftType,
      required final DateTime timestamp}) = _$GiftTransactionImplImpl;

  @override
  String get senderName;
  @override
  double get amount;
  @override
  String get giftType; // ✅ Added to track gift type
  @override
  DateTime get timestamp;

  /// Create a copy of GiftTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GiftTransactionImplImplCopyWith<_$GiftTransactionImplImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
