import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/livestream_model.dart';
import '../services/api_service.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';  // ✅ ADD THIS
import 'package:cloud_firestore/cloud_firestore.dart';  // ✅ ADD THIS for Timestamp
import 'dart:convert';
import 'dart:typed_data';
import '../services/chat_reminder_service.dart';
import 'dart:developer' as developer;
import '../models/follow_notification_model.dart';
import '../services/chat_gift_prompt_service.dart';



part 'live_stream_provider.freezed.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});
// ============= State Classes =============

@freezed
class LiveStreamState with _$LiveStreamState {
  const factory LiveStreamState({
    LiveStream? livestream,
    String? token,
    String? roomName,
    @Default(false) bool isOwner,
    @Default(false) bool isLoading,
    @Default(false) bool isConnecting,
    String? error,
  }) = _LiveStreamState;
}

@freezed
class RoomState with _$RoomState {
  const factory RoomState({
    Room? room,
    @Default(false) bool isConnected,
    @Default(false) bool isMicEnabled,
    @Default(false) bool isCameraEnabled,
    LocalParticipant? localParticipant,
    @Default([]) List<RemoteParticipant> remoteParticipants,
    @Default(0) int viewerCount,
    EventsListener<RoomEvent>? listener,
  }) = _RoomState;
}

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String senderId,
    required String senderName,
    required String message,
    required DateTime timestamp,
    @Default(false) bool isTrainer,
    @Default(false) bool isGiftSender,
  }) = _ChatMessage;
}

@freezed
class WaitlistEntry with _$WaitlistEntry {
  const factory WaitlistEntry({
    required String userId,
    required String userName,
    String? profilePicture,
    required DateTime requestedAt,
  }) = _WaitlistEntry;
}

@freezed
class GradeRequest with _$GradeRequest {
  const factory GradeRequest({
    required String userId,
    required String userName,
    required DateTime requestedAt,
  }) = _GradeRequest;
}


@freezed
class GiftSummary with _$GiftSummary {
  const factory GiftSummary({
    @Default(0.0) double totalAmount,
    @Default(0) int giftCount,
    @Default(0) int rubyCount,           // ✅ Added
    @Default(0) int proteinShakeCount,   // ✅ Added
    @Default(0) int proteinBarCount,     // ✅ Added
    @Default(0) int proteinPowderCount,  // ✅ Added
    @Default([]) List<GiftTransaction> transactions,
  }) = _GiftSummary;
}

@freezed
class GiftTransaction with _$GiftTransaction {
  const factory GiftTransaction({
    required String senderName,
    required double amount,
    required String giftType,  // ✅ Added to track gift type
    required DateTime timestamp,
  }) = _GiftTransactionImpl;
}

// ============= Notifiers =============


class LiveStreamNotifier extends StateNotifier<LiveStreamState> {
  final Ref ref;
  final String livestreamId;

  LiveStreamNotifier(this.ref, this.livestreamId) : super(const LiveStreamState()) {
    print('🏗️ LiveStreamNotifier CONSTRUCTOR called for livestream: $livestreamId');
    _initialize();
  }

  Future<void> _initialize() async {
    print('🚀 ========================================');
    print('🚀 LiveStreamNotifier._initialize() START');
    print('🚀 Livestream ID: $livestreamId');
    print('🚀 ========================================');
    
    state = state.copyWith(isLoading: true);
    print('🚀 State updated: isLoading = true');
    
    try {
      print('🔑 Getting auth state...');
      final authState = ref.read(authProvider);
      final token = authState.token;
      
      print('🔑 Token exists: ${token != null}');
      
      if (token == null) {
        print('❌ No token - throwing exception');
        throw Exception('Authentication required');
      }
      
      print('📡 Calling API: /api/livestreams/$livestreamId');
      final response = await ref.read(apiServiceProvider).get(
        '/api/livestreams/$livestreamId',
        token: token,
      );
      
      print('✅ API Response received');
      print('📦 Response data keys: ${response.keys}');
      
      final livestream = LiveStream.fromJson(response['data']);
      print('✅ Livestream parsed: ${livestream.title}');
      
      state = state.copyWith(
        livestream: livestream,
        isLoading: false,
      );
      
      print('🔗 Calling joinStream()...');
      await joinStream();
      print('✅ _initialize() COMPLETE');
    } catch (e) {
      print('❌ ========================================');
      print('❌ ERROR in _initialize()');
      print('❌ Error: $e');
      print('❌ ========================================');
      
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> joinStream() async {
  print('🔌 joinStream() START');
  state = state.copyWith(isConnecting: true);
  
  try {
    final authState = ref.read(authProvider);
    final token = authState.token;
    
    if (token == null) {
      throw Exception('Authentication required');
    }

    print('📡 Calling API: /api/livestreams/$livestreamId/join');
    final response = await ref.read(apiServiceProvider).post(
      '/api/livestreams/$livestreamId/join',
      {},
      token: token,
    );
    
    print('✅ Join response received');
    final data = response;

    state = state.copyWith(
      token: data['token'],
      roomName: data['roomName'],
      isOwner: data['isOwner'],
      isConnecting: false,
    );

    print('🎥 Connecting to LiveKit room: ${data['roomName']}');
    await ref.read(roomProvider.notifier).connect(
      data['token'],
      data['roomName'],
    );
    print('✅ joinStream() COMPLETE');
  } catch (e) {
    print('❌ ERROR in joinStream(): $e');
    print('❌ Error type: ${e.runtimeType}');
    
    // ✅ CHECK IF THIS IS A BAN ERROR (403 Forbidden)
    if (e is ApiException) {
      print('🔍 ApiException - Status: ${e.statusCode}, Message: ${e.message}');
      
      if (e.statusCode == 403) {
        print('🚫 USER IS BANNED (403 Forbidden)');
        state = state.copyWith(
          isConnecting: false,
          error: 'banned', // Special error flag for banned users
        );
        return;
      }
    }
    
    // Other errors
    state = state.copyWith(
      isConnecting: false,
      error: e.toString(),
    );
  }
}

  Future<void> endStream() async {
    try {
      final authState = ref.read(authProvider);
      final token = authState.token;
      
      if (token == null) {
        throw Exception('Authentication required');
      }
      
      print('🛑 Ending stream - Step 1: Notifying participants');
      
      // First, notify all participants that stream is ending
      final roomNotifier = ref.read(roomProvider.notifier);
      await roomNotifier.publishData({
        'event': 'stream_ended',
        'message': 'The trainer has ended the live stream',
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      print('🛑 Ending stream - Step 2: Calling backend API');
      
      // Call the backend API
      await ref.read(apiServiceProvider).post(
        '/api/livestreams/$livestreamId/end',
        {},
        token: token,
      );
      
      print('🛑 Ending stream - Step 3: Disconnecting from room');
      
      // Finally disconnect
      await ref.read(roomProvider.notifier).disconnect();
      
      print('✅ Stream ended and disconnected successfully');
    } catch (e) {
      print('❌ Error ending stream: $e');
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }
}


class RoomNotifier extends StateNotifier<RoomState> {
  static const String livekitUrl = String.fromEnvironment('LIVEKIT_URL',
  defaultValue: 'wss://fitnecksxx.livekit.cloud'); // Your URL as fallback

  RoomNotifier() : super(const RoomState());

  Future<void> connect(String token, String roomName) async {
      print('🔗 Attempting to connect to LiveKit room: $roomName');

    
    try {
      final room = Room();


       print('🔗 Room created, setting up listeners...');

      
      // Set up event listeners
final listener = room.createListener();
listener
  ..on<RoomDisconnectedEvent>((event) => _handleDisconnect())
  ..on<ParticipantConnectedEvent>((event) => _handleParticipantConnected(event))
  ..on<ParticipantDisconnectedEvent>((event) => _handleParticipantDisconnected(event))
  ..on<DataReceivedEvent>((event) => _handleDataReceived(event))
  ..on<LocalTrackPublishedEvent>((event) => _handleLocalTrackPublished(event))
  ..on<TrackSubscribedEvent>((event) => _handleTrackSubscribed(event))
  ..on<TrackPublishedEvent>((event) => _handleTrackPublished(event))        // ✅ ADD THIS
  ..on<TrackMutedEvent>((event) => _handleTrackMuted(event))          // ✅ ADD THIS
  ..on<TrackUnmutedEvent>((event) => _handleTrackUnmuted(event))      // ✅ ADD THIS
  ..on<TrackUnpublishedEvent>((event) => _handleTrackUnpublished(event)); // ✅ ADD THIS
    print('🔗 Connecting to LiveKit URL: $livekitUrl');

      // Connect to room
      await room.connect(
  livekitUrl,
  token,
  roomOptions: const RoomOptions(
    adaptiveStream: true,
    dynacast: true,
    defaultVideoPublishOptions: VideoPublishOptions(
      simulcast: true,
      videoCodec: 'h264',
    ),
  ),
  fastConnectOptions: FastConnectOptions(
    microphone: const TrackOption(enabled: false),
    camera: const TrackOption(enabled: false),
  ),
);

    print('🔗 Room connection successful!');






      state = state.copyWith(
        room: room,
        isConnected: true,
        localParticipant: room.localParticipant,
        remoteParticipants: room.remoteParticipants.values.toList(),
        listener: listener,
        viewerCount: room.remoteParticipants.length + 1,
      );

      // Enable camera and mic for trainers by default CAMERA AND MIC OFF FOR TESTING
  //  await enableCamera(true);
  //  await enableMicrophone(true);


// Only enable camera/mic for trainers automatically

if (room.localParticipant?.metadata != null) {
  final metadata = json.decode(room.localParticipant!.metadata!);
  final role = metadata['role'];
  
  if (role == 'trainer') {
    await enableCamera(true);
    await enableMicrophone(true);
  }
  // Learners start with camera/mic OFF
}


    } catch (e) {
    print('❌ Failed to connect to room: $e');
    print('❌ LiveKit URL: $livekitUrl');
    print('❌ Token: ${token.substring(0, 20)}...');
    }
  }

  Future<void> disconnect() async {
    await state.room?.disconnect();
    state.listener?.dispose();
    state = const RoomState();
  }

Future<void> enableMicrophone(bool enable) async {
  print('🎤 enableMicrophone called with: $enable');
  
  if (state.room == null) {  // ← Changed from _room to state.room
    print('❌ enableMicrophone: Room is null');
    return;
  }
  
  final localParticipant = state.room!.localParticipant;  // ← Changed from _room
  if (localParticipant == null) {
    print('❌ enableMicrophone: Local participant is null');
    return;
  }
  
  print('🎤 Current microphone enabled state: ${localParticipant.isMicrophoneEnabled()}');
  
  try {
    if (enable) {
      // Enable microphone
      await localParticipant.setMicrophoneEnabled(true);
      print('✅ Microphone enabled');
      
      // Wait a moment for track to publish
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verify track published
      print('🎤 Audio tracks after enable: ${localParticipant.audioTrackPublications.length}');
      
      if (localParticipant.audioTrackPublications.isEmpty) {
        print('⚠️ WARNING: Microphone enabled but no audio track published!');
        // Try to manually publish audio track
        final audioTrack = await LocalAudioTrack.create();
        await localParticipant.publishAudioTrack(audioTrack);
        print('🎤 Manually published audio track');
      }
    } else {
      // Disable microphone
      await localParticipant.setMicrophoneEnabled(false);
      print('✅ Microphone disabled');
    }
    
    // Update state
    state = state.copyWith(
      isMicEnabled: enable,
    );
    
    // Log final state
    print('🎤 Final microphone enabled state: ${localParticipant.isMicrophoneEnabled()}');
    print('🎤 Final audio tracks count: ${localParticipant.audioTrackPublications.length}');
    
  } catch (e, stackTrace) {
    print('❌ Error in enableMicrophone: $e');
    print('❌ Stack trace: $stackTrace');
  }
}



Future<void> enableCamera(bool enable) async {
  print('📹 enableCamera called with: $enable');
  
  if (state.room == null) {  // ← Changed from _room to state.room
    print('❌ enableCamera: Room is null');
    return;
  }
  
  final localParticipant = state.room!.localParticipant;  // ← Changed from _room
  if (localParticipant == null) {
    print('❌ enableCamera: Local participant is null');
    return;
  }
  
  print('📹 Current camera enabled state: ${localParticipant.isCameraEnabled()}');
  
  try {
    if (enable) {
      // Enable camera
      await localParticipant.setCameraEnabled(true);
      print('✅ Camera enabled');
      
      // Wait a moment for track to publish
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Verify track published
      print('📹 Video tracks after enable: ${localParticipant.videoTrackPublications.length}');
      
      if (localParticipant.videoTrackPublications.isEmpty) {
        print('⚠️ WARNING: Camera enabled but no video track published!');
        // Try to manually publish camera track
        final videoTrack = await LocalVideoTrack.createCameraTrack();
        await localParticipant.publishVideoTrack(videoTrack);
        print('📹 Manually published video track');
      }
    } else {
      // Disable camera
      await localParticipant.setCameraEnabled(false);
      print('✅ Camera disabled');
    }
    
    // Update state
    state = state.copyWith(
      isCameraEnabled: enable,
    );
    
    // Log final state
    print('📹 Final camera enabled state: ${localParticipant.isCameraEnabled()}');
    print('📹 Final video tracks count: ${localParticipant.videoTrackPublications.length}');
    
  } catch (e, stackTrace) {
    print('❌ Error in enableCamera: $e');
    print('❌ Stack trace: $stackTrace');
  }
}


  // Add this method to your RoomProvider class (around line 200-250)
// Place this RIGHT AFTER the enableCamera method closes (after line 435)
  Future<void> publishData(Map<String, dynamic> data) async {
    final room = state.room;
    
    if (room == null) {
      print('❌ Cannot publish data: room is null');
      return;
    }

    try {
      final jsonData = json.encode(data);
      final uint8List = Uint8List.fromList(utf8.encode(jsonData));
      
      await room.localParticipant?.publishData(
        uint8List,
        reliable: true,
      );
      
      print('✅ Data published: ${data['type']}');
    } catch (e) {
      print('❌ Error publishing data: $e');
      rethrow;
    }
  }

  void _handleDisconnect() {
    state = state.copyWith(isConnected: false);
  }

  void _handleParticipantConnected(ParticipantConnectedEvent event) {
    state = state.copyWith(
      remoteParticipants: state.room?.remoteParticipants.values.toList() ?? [],
      viewerCount: (state.room?.remoteParticipants.length ?? 0) + 1,
    );
  }

  void _handleParticipantDisconnected(ParticipantDisconnectedEvent event) {
    state = state.copyWith(
      remoteParticipants: state.room?.remoteParticipants.values.toList() ?? [],
      viewerCount: (state.room?.remoteParticipants.length ?? 0) + 1,
    );
  }

  void _handleDataReceived(DataReceivedEvent event) {
    // This will be handled by individual feature providers (chat, waitlist, etc.)
  }

  void _handleLocalTrackPublished(LocalTrackPublishedEvent event) {
    // Track publishing handled
  }

  void _handleTrackSubscribed(TrackSubscribedEvent event) {
    // Track subscription handled
  }



void _handleTrackMuted(TrackMutedEvent event) {
  print('🔇 Track muted in RoomNotifier: ${event.participant.identity}');
  // Force state update to trigger widget rebuilds
  state = state.copyWith(
    remoteParticipants: state.room?.remoteParticipants.values.toList() ?? [],
  );
}

void _handleTrackUnmuted(TrackUnmutedEvent event) {
  print('🔊 Track unmuted in RoomNotifier: ${event.participant.identity}');
  // Force state update to trigger widget rebuilds
  state = state.copyWith(
    remoteParticipants: state.room?.remoteParticipants.values.toList() ?? [],
  );
}

void _handleTrackUnpublished(TrackUnpublishedEvent event) {
  print('📹 Track unpublished in RoomNotifier: ${event.participant.identity}');
  // Force state update to trigger widget rebuilds
  state = state.copyWith(
    remoteParticipants: state.room?.remoteParticipants.values.toList() ?? [],
  );
}

void _handleTrackPublished(TrackPublishedEvent event) {
  print('📹 Track published in RoomNotifier: ${event.participant.identity} - ${event.publication.kind}');
  // Force state update to trigger widget rebuilds
  state = state.copyWith(
    remoteParticipants: state.room?.remoteParticipants.values.toList() ?? [],
  );
}



}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref ref;
  final String livestreamId;
  
  ChatNotifier(this.ref, this.livestreamId) : super([]) {
    _listenToMessages();
    _listenToFirestoreMessages();
  }

  void _listenToMessages() {
    final room = ref.read(roomProvider).room;
    if (room == null) return;
    
    final listener = room.createListener();
    listener.on<DataReceivedEvent>((event) {
      try {
        final data = json.decode(utf8.decode(event.data));
        if (data['type'] == 'chat') {
          _processMessage(data);
        }
      } catch (e) {
        print('Error parsing chat message from LiveKit: $e');
      }
    });
  }

  // ============= COMPLETE REPLACEMENT for ChatNotifier._listenToFirestoreMessages() =============
// This is the ENTIRE method - delete the old one and paste this complete version
// Location: Inside ChatNotifier class in live_stream_provider.dart (around line 355-420)

void _listenToFirestoreMessages() {
  print('🔥 ChatNotifier: Starting to listen to Firestore messages for $livestreamId');
  
  final firestoreService = ref.read(firestoreServiceProvider);
  firestoreService.watchChatMessages(livestreamId).listen((messages) {
    print('🔥 Received ${messages.length} chat messages from Firestore');
    
    // ✅ STEP 1: Track count BEFORE processing
    final previousCount = state.length;
    
    // ✅ STEP 2: Process messages (only ONE chatMessages definition!)
    final chatMessages = messages
      .where((messageData) {
        final hasTimestamp = messageData['timestamp'] != null;
        if (!hasTimestamp) {
          print('DEBUG: Skipping message without timestamp: ${messageData['id']}');
        }
        return hasTimestamp;
      })
      .map((messageData) {
        return ChatMessage(
          id: messageData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          senderId: messageData['senderId'] ?? '0',
          senderName: messageData['senderName'] ?? 'Unknown',
          message: messageData['message'] ?? '',
          timestamp: (messageData['timestamp'] as Timestamp).toDate(),
          isTrainer: messageData['isTrainer'] ?? false,
          isGiftSender: messageData['isGiftSender'] ?? false,
        );
      }).toList();
    
    print('DEBUG: Processed ${chatMessages.length} messages');
    
    // ✅ STEP 3: Update state FIRST
    state = chatMessages;
    
    // ✅ STEP 4: Track NEW messages for reminder system
    final newCount = chatMessages.length;
    final newMessages = newCount - previousCount;
    
    if (newMessages > 0) {
      print('💬 [ChatNotifier] Detected $newMessages new messages');
      print('💬 [ChatNotifier] Attempting to get reminder service...');
      
      // Try to get the service
      final reminderService = ref.read(chatReminderServiceProvider(livestreamId));
      
      if (reminderService != null) {
        print('✅ [ChatNotifier] Got reminder service, tracking messages...');
        
        // Track each new message
        for (int i = 0; i < newMessages; i++) {
          reminderService.trackMessage();
          print('💬 [ChatNotifier] Tracked message ${i + 1}/$newMessages');
        }
      } else {
        print('⚠️ [ChatNotifier] Reminder service is null - service may not be initialized yet');
      }
    }
    
    print('DEBUG: State now has ${state.length} messages');
  });
}

  void _processMessage(Map<String, dynamic> data) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: data['senderId'],
      senderName: data['senderName'],
      message: data['message'],
      timestamp: DateTime.parse(data['timestamp']),
      isTrainer: data['isTrainer'] ?? false,
      isGiftSender: data['isGiftSender'] ?? false,
    );
    state = [...state, message];
  }

  Future<void> sendMessage(String message) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    
    if (user == null) return;
    
    final firestoreService = ref.read(firestoreServiceProvider);
    await firestoreService.sendChatMessage(
      livestreamId: livestreamId,
      senderId: user.id.toString(),
      senderName: user.displayName ?? user.username,
      message: message,
      isTrainer: user.role == 'Trainer',
    );
    
    print('💬 Chat message written to Firestore');
  }

  Future<void> addGiftMessage(String senderName, String giftMessage) async {
    final firestoreService = ref.read(firestoreServiceProvider);
    await firestoreService.sendChatMessage(
      livestreamId: livestreamId,
      senderId: 'gift_${DateTime.now().millisecondsSinceEpoch}',
      senderName: senderName,
      message: giftMessage,
      isTrainer: false,
      isGiftSender: true,
    );
    
    print('🎁 Gift message written to Firestore');
  }
}

// FIXED WaitlistNotifier - Replace in live_stream_provider.dart (around lines 570-667)

class WaitlistNotifier extends StateNotifier<List<WaitlistEntry>> {
  final Ref ref;
  final String livestreamId;
  final Set<String> _processedRequestIds = {};  // ✅ Track processed requests
  
  WaitlistNotifier(this.ref, this.livestreamId) : super([]) {
    _listenToFirestoreJoinRequests();  // ✅ Use ONLY Firestore (single source)
  }

  // ✅ REMOVED: _listenToWaitlist() - Don't listen to LiveKit to avoid duplicates

  // ✅ FIXED: Listen to Firestore join requests properly
  void _listenToFirestoreJoinRequests() {
    final firestoreService = ref.read(firestoreServiceProvider);
    
    firestoreService.watchJoinRequests(livestreamId).listen((requests) {
      print('🔥 Firestore snapshot: ${requests.length} pending join requests');
      
      // ✅ Build a map of current requests by ID
      final currentRequestIds = <String>{};
      final newEntries = <WaitlistEntry>[];
      
      for (final requestData in requests) {
        final requestId = requestData['id'] as String? ?? '';
        final learnerId = requestData['learnerId'] as String? ?? '';
        
        if (requestId.isEmpty) continue;
        
        currentRequestIds.add(requestId);
        
        // ✅ Only create entry if we haven't seen this request before
        if (!_processedRequestIds.contains(requestId)) {
          print('📥 New join request: $requestId from ${requestData['learnerName']}');
          _processedRequestIds.add(requestId);
        }
        
        // Add to new entries list (will become new state)
        newEntries.add(WaitlistEntry(
          userId: learnerId,
          userName: requestData['learnerName'] ?? 'Unknown',
          profilePicture: requestData['profilePicture'],
          requestedAt: requestData['timestamp'] != null 
              ? (requestData['timestamp'] as Timestamp).toDate()
              : DateTime.now(),
        ));
      }
      
      // ✅ Clean up processed IDs for requests that are no longer pending
      _processedRequestIds.removeWhere((id) => !currentRequestIds.contains(id));
      
      // ✅ Update state with current pending requests
      state = newEntries;
      print('✅ Updated waitlist: ${state.length} pending requests');
    });
  }

  // ✅ FIXED: Approve user AND update Firestore
  Future<void> approveUser(String userId) async {
    print('🎯 Trainer approving user: $userId');
    
    try {
      // Get current auth token
      final authState = ref.read(authProvider);
      final token = authState.token;
      
      // Call backend to get new token with canPublish permissions
      final response = await ref.read(apiServiceProvider).post(
        '/api/livestreams/$livestreamId/approve-learner',
        {'learnerId': userId},
        token: token,
      );
      
      final newToken = response['token'];
      print('🎯 Got new token for learner');
      
      // Send permission granted event with the new token
      final room = ref.read(roomProvider.notifier);
      await room.publishData({
        'event': 'permission_granted',
        'learnerId': userId,
        'token': newToken,
      });
      
      print('🎯 Permission granted event sent with real token');
      
      // ✅ CRITICAL FIX: Update Firestore status to 'approved'
      final firestoreService = ref.read(firestoreServiceProvider);
      
      // Find the request document ID for this learner
      final requests = await FirebaseFirestore.instance
          .collection('joinRequests')
          .where('livestreamId', isEqualTo: livestreamId)
          .where('learnerId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      // Update all matching requests to approved
      for (final doc in requests.docs) {
        await firestoreService.approveJoinRequest(doc.id);
        print('✅ Updated Firestore request ${doc.id} to approved');
      }
      
      // ✅ Firestore listener will automatically remove from state
      // No need to manually update state here!
      
    } catch (e) {
      print('❌ Error approving user: $e');
      // On error, manually remove from state as fallback
      state = state.where((entry) => entry.userId != userId).toList();
    }
  }

  // ✅ FIXED: Decline user AND update Firestore
  Future<void> declineUser(String userId) async {
    print('🚫 Trainer declining user: $userId');
    
    try {
      final room = ref.read(roomProvider.notifier);
      await room.publishData({
        'type': 'decline',
        'userId': userId,
      });
      
      // ✅ CRITICAL FIX: Update Firestore status to 'declined'
      final firestoreService = ref.read(firestoreServiceProvider);
      
      // Find the request document ID for this learner
      final requests = await FirebaseFirestore.instance
          .collection('joinRequests')
          .where('livestreamId', isEqualTo: livestreamId)
          .where('learnerId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .get();
      
      // Update all matching requests to declined
      for (final doc in requests.docs) {
        await firestoreService.declineJoinRequest(doc.id);
        print('✅ Updated Firestore request ${doc.id} to declined');
      }
      
      // ✅ Firestore listener will automatically remove from state
      // No need to manually update state here!
      
    } catch (e) {
      print('❌ Error declining user: $e');
      // On error, manually remove from state as fallback
      state = state.where((entry) => entry.userId != userId).toList();
    }
  }
}



class GradeRequestNotifier extends StateNotifier<List<GradeRequest>> {
  final Ref ref;
  final String livestreamId;
  bool _isListening = false;
  
  GradeRequestNotifier(this.ref, this.livestreamId) : super([]) {
    print('🎯 GradeRequestNotifier CONSTRUCTOR called for livestream: $livestreamId');
    // Don't start listening automatically - wait for room to be ready
  }

  // Call this method AFTER the room is connected
  void startListening() {
    if (_isListening) {
      print('⚠️ Already listening for grade requests');
      return;
    }
    
    print('👂 Starting to listen for grade requests on livestream: $livestreamId');
    _listenToGradeRequests();
  }

  void _listenToGradeRequests() {
    final room = ref.read(roomProvider).room;
    
    if (room == null) {
      print('❌ GradeRequestNotifier: Room is null - cannot start listening');
      return;
    }
    
    print('✅ GradeRequestNotifier: Room found, creating listener');
    _isListening = true;
    
    final listener = room.createListener();
    listener.on<DataReceivedEvent>((event) {
      try {
        final data = json.decode(utf8.decode(event.data));
        print('📨 GradeRequestNotifier received data: $data');
        
        if (data['type'] == 'grade_request') {
          print('⭐ Grade request received from: ${data['userName']}');
          
          final request = GradeRequest(
            userId: data['userId'],
            userName: data['userName'],
            requestedAt: DateTime.now(),
          );
          
          state = [...state, request];
          print('✅ Grade request added to state. Total requests: ${state.length}');
        }
      } catch (e) {
        print('❌ Error parsing grade request: $e');
      }
    });
    
    print('✅ GradeRequestNotifier: Listener fully set up');
  }

  void removeRequest(String userId) {
    print('🗑️ Removing grade request for: $userId');
    state = state.where((request) => request.userId != userId).toList();
  }

  Future<void> gradeUser(String userId, String grade, int points) async {
    print('⭐ Grading user $userId with grade: $grade, points: $points');
    
    try {
      final roomNotifier = ref.read(roomProvider.notifier);
      
      // Send grade to learner
      await roomNotifier.publishData({
        'event': 'grade_received',
        'learnerId': userId,
        'grade': grade,
        'points': points,
      });
      
      print('✅ Grade sent to learner');
      
      // Remove from pending requests
      removeRequest(userId);
      
    } catch (e) {
      print('❌ Error grading user: $e');
    }
  }
}





// FIXED GiftNotifier - Replace lines 760-846 in live_stream_provider.dart

// CORRECTED GiftNotifier - Replace lines 760-844 in live_stream_provider.dart

class GiftNotifier extends StateNotifier<GiftSummary> {
  final Ref ref;
  final String livestreamId;
  final Set<String> _processedGiftIds = {};  // ✅ Track which gifts we've seen
  
  GiftNotifier(this.ref, this.livestreamId) : super(const GiftSummary()) {
    _listenToFirestoreGifts();
  }

  void _listenToFirestoreGifts() {
    final firestoreService = ref.read(firestoreServiceProvider);
    
    firestoreService.watchGifts(livestreamId).listen((gifts) {
      print('🔥 Firestore snapshot: ${gifts.length} total gifts');
      
      // ✅ Only process NEW gifts we haven't seen before
      for (final giftData in gifts) {
        final giftId = giftData['id'] as String? ?? '';
        
        if (giftId.isNotEmpty && !_processedGiftIds.contains(giftId)) {
          print('🎁 Processing new gift: $giftId (${giftData['giftType']})');
          _processGift(giftData);
          _processedGiftIds.add(giftId);
        }
      }
    });
  }

  // ✅ FIXED: Common gift processing logic with correct gift types
  void _processGift(Map<String, dynamic> data) {
    final giftType = data['giftType'] as String;
    final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
    final quantity = (data['quantity'] as int?) ?? 1;  // ✅ Declared ONCE here
    final senderName = data['senderName'] as String? ?? 'Anonymous';
    
    print('📊 Processing gift: type=$giftType, quantity=$quantity, amount=$amount');
    
    final transaction = GiftTransaction(
      senderName: senderName,
      amount: amount,
      giftType: giftType,
      timestamp: data['timestamp'] != null 
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
    
    // ✅ FIXED: Update counts based on gift type
    int newRubyCount = state.rubyCount;
    int newShakeCount = state.proteinShakeCount;
    int newBarCount = state.proteinBarCount;
    int newPowderCount = state.proteinPowderCount;
    
    // ✅ Switch without re-declaring quantity
    switch (giftType) {
      case 'RUBY':
        newRubyCount += quantity;
        print('💎 Ruby count: ${state.rubyCount} → $newRubyCount');
        break;
      case 'PROTEIN_SHAKE':
        newShakeCount += quantity;
        print('🥤 Shake count: ${state.proteinShakeCount} → $newShakeCount');
        break;
      case 'PROTEIN_BAR':
        newBarCount += quantity;
        print('🍫 Bar count: ${state.proteinBarCount} → $newBarCount');
        break;
      case 'PROTEIN':  // ✅ Changed from PROTEIN_POWDER to match what's sent
        newPowderCount += quantity;
        print('💪 Protein count: ${state.proteinPowderCount} → $newPowderCount');
        break;
      default:
        print('⚠️ Unknown gift type: $giftType');
    }
    
    state = state.copyWith(
      totalAmount: state.totalAmount + amount,
      giftCount: state.giftCount + 1,
      rubyCount: newRubyCount,
      proteinShakeCount: newShakeCount,
      proteinBarCount: newBarCount,
      proteinPowderCount: newPowderCount,
      transactions: [...state.transactions, transaction],
    );
    
    print('✅ Updated gift summary: Ruby=$newRubyCount, Shake=$newShakeCount, Bar=$newBarCount, Protein=$newPowderCount');
  }
}

// ============= Providers =============

final liveStreamProvider = StateNotifierProvider.family<LiveStreamNotifier, LiveStreamState, String>(
  (ref, livestreamId) => LiveStreamNotifier(ref, livestreamId),
);

final roomProvider = StateNotifierProvider<RoomNotifier, RoomState>(
  (ref) => RoomNotifier(),
);


final chatMessagesProvider = StateNotifierProvider.family<ChatNotifier, List<ChatMessage>, String>(
  (ref, livestreamId) => ChatNotifier(ref, livestreamId),
);

final giftDataProvider = StateNotifierProvider.family<GiftNotifier, GiftSummary, String>(
  (ref, livestreamId) => GiftNotifier(ref, livestreamId),
);


final currentUserProvider = Provider((ref) {
  return ref.watch(authProvider).user; // Adjust based on your auth structure
});

final waitlistProvider = StateNotifierProvider.family<WaitlistNotifier, List<WaitlistEntry>, String>(
  (ref, livestreamId) => WaitlistNotifier(ref, livestreamId),
);


final gradeRequestProvider = StateNotifierProvider.family<GradeRequestNotifier, List<GradeRequest>, String>(
  (ref, livestreamId) => GradeRequestNotifier(ref, livestreamId),
);

// ============= CHAT REMINDER PROVIDERS =============
// ============= ENHANCED CHAT REMINDER PROVIDERS WITH DEBUG LOGGING =============
// Replace your existing chat reminder providers section (around lines 1050-1070) with this:


// Provider for reminder messages (completely separate from Firestore chat)
final chatRemindersProvider = StateNotifierProvider.family<ChatRemindersNotifier, List<ChatReminderMessage>, String>(
  (ref, livestreamId) {
    print('🔍 [Provider] chatRemindersProvider created for livestreamId: $livestreamId');
    return ChatRemindersNotifier(livestreamId);
  },
);

class ChatRemindersNotifier extends StateNotifier<List<ChatReminderMessage>> {
  final String livestreamId;
  
  ChatRemindersNotifier(this.livestreamId) : super([]) {
    _logDebug('🎬 ChatRemindersNotifier CONSTRUCTOR', {
      'livestreamId': livestreamId,
    });
  }
  
  void addReminder(ChatReminderMessage reminder) {
    _logDebug('➕ Adding reminder to state', {
      'reminderId': reminder.type.toString(),
      'type': reminder.type.toString(),
      'currentStateLength': state.length,
    });
    
    state = [...state, reminder];
    
    _logDebug('✅ Reminder added to state', {
      'newStateLength': state.length,
      'allReminders': state.map((r) => r.type.toString()).toList(),
    });
  }
  
  void clearReminders() {
    _logDebug('🗑️ Clearing all reminders', {
      'count': state.length,
    });
    
    state = [];
    
    _logDebug('✅ All reminders cleared', {});
  }
  
  void _logDebug(String message, Map<String, dynamic> data) {
    // Only log if debug mode is enabled in ChatReminderService
    if (!ChatReminderService.debugMode) return;

    final logMessage = '$message ${data.isNotEmpty ? data.toString() : ''}';
    developer.log(
      logMessage,
      name: 'ChatRemindersNotifier',
      time: DateTime.now(),
    );
    
    print('🔍 [ChatRemindersNotifier] $logMessage');
  }
}


// ============= FOLLOW NOTIFICATION PROVIDER =============

final followNotificationsProvider = StreamProvider.family<List<FollowNotification>, String>((ref, livestreamId) {
  print('👥 [FollowNotifications] Setting up listener for livestream: $livestreamId');
  
  final firestoreService = ref.read(firestoreServiceProvider);
  
  return firestoreService.watchFollowNotifications(livestreamId).map((notifications) {
    print('👥 [FollowNotifications] Received ${notifications.length} notifications');
    
    return notifications
        .map((data) => FollowNotification.fromFirestore(data, data['id']))
        .toList();
  });
});



// Provider for the reminder service instance
// ✅ NON-CODEGEN VERSION (works with your current setup)
// ============= DIAGNOSTIC VERSION of chatReminderServiceProvider =============
// Replace your current chatReminderServiceProvider with this version
// Location: In live_stream_provider.dart around line 1070-1120

final chatReminderServiceProvider = Provider.family<ChatReminderService?, String>(
  (ref, livestreamId) {
    print('🔍 [Provider] ========================================');
    print('🔍 [Provider] chatReminderServiceProvider CALLED');
    print('🔍 [Provider] livestreamId: $livestreamId');
    print('🔍 [Provider] ========================================');
    
    // Watch the stream state to get trainer info
    final streamState = ref.watch(liveStreamProvider(livestreamId));
    
    // Check 1: Is livestream loaded?
    if (streamState.livestream == null) {
      print('❌ [Provider] streamState.livestream is NULL - returning null');
      return null;
    }
    print('✅ [Provider] streamState.livestream exists');
    
    // Check 2: Is trainer loaded?
    if (streamState.livestream!.trainer == null) {
      print('❌ [Provider] trainer is NULL - returning null');
      return null;
    }
    print('✅ [Provider] trainer exists');
    print('🔍 [Provider] trainer.id: ${streamState.livestream!.trainer!.id}');
    print('🔍 [Provider] trainer.username: ${streamState.livestream!.trainer!.username}');
    
    final trainer = streamState.livestream!.trainer!;
    print('✅ [Provider] trainer.username exists: ${trainer.username}');
    
    // All checks passed - create service
    print('🎯 [Provider] ALL CHECKS PASSED - Creating ChatReminderService');
    print('🎯 [Provider] Creating service with:');
    print('🎯 [Provider]   - livestreamId: $livestreamId');
    print('🎯 [Provider]   - trainerId: ${trainer.id}');
    print('🎯 [Provider]   - trainerUsername: ${trainer.username}');
    
    final service = ChatReminderService(
      livestreamId: livestreamId,
      trainerId: trainer.id,
      trainerUsername: trainer.username,
      ref: ref,
    );
    
    print('🔧 [Provider] Service object created, calling initialize()...');
    service.initialize();
    print('✅ [Provider] Service initialized successfully!');
    print('✅ [Provider] Returning NON-NULL service');
    
    // Auto-dispose when provider is disposed
    ref.onDispose(() {
      print('🗑️ [Provider] Disposing service for $livestreamId');
      service.dispose();
    });
    
    return service;
  },
);



// ==================== CHAT GIFT PROMPT PROVIDERS ====================


/// Provider family that stores ChatGiftPromptService instances per livestream
final chatGiftPromptServiceProvider = 
    StateProvider.family<ChatGiftPromptService?, String>((ref, livestreamId) => null);

/// Helper to create and initialize a ChatGiftPromptService
ChatGiftPromptService createChatGiftPromptService({
  required String livestreamId,
  required String userId,
  required WidgetRef ref,
}) {
  final service = ChatGiftPromptService(
    livestreamId: livestreamId,
    userId: userId,
    ref: ref,
    shouldShowPrompt: () {
      // This callback is called by the periodic timer (every 15 minutes)
      // It triggers the gift prompt to show in the UI
      ref.read(shouldShowGiftPromptProvider(livestreamId).notifier).state = true;
    },
  );
  
  service.initialize();
  ref.read(chatGiftPromptServiceProvider(livestreamId).notifier).state = service;
  
  return service;
}

/// Helper to dispose ChatGiftPromptService
void disposeChatGiftPromptService(WidgetRef ref, String livestreamId) {  // ✅ Changed from Ref
  final service = ref.read(chatGiftPromptServiceProvider(livestreamId));
  service?.dispose();
  ref.read(chatGiftPromptServiceProvider(livestreamId).notifier).state = null;
}


/// Tracks whether gift prompt should be shown (triggered by periodic timer)
final shouldShowGiftPromptProvider = 
    StateProvider.family<bool, String>((ref, livestreamId) => false);