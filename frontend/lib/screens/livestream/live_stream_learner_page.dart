import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import '../../providers/live_stream_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/livestream/chat_widget.dart';
import '../../widgets/livestream/learner_self_view.dart';
import '../../widgets/livestream/gift_sending_widget.dart';
import '../../widgets/livestream/trainer_info_panel.dart';
import '../../widgets/livestream/post_stream_review_dialog.dart';
import '../../widgets/livestream/fitneks_finest_widget.dart';
import '../../widgets/livestream/gift_animation_widget.dart';
import '../../widgets/livestream/trainer_video_view.dart';
import '../../services/reminder_manager.dart';
import '../../services/firestore_service.dart';
import '../../widgets/livestream/learner_horizontal_view.dart';
import '../../widgets/livestream/viewer_tally_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/chat_reminder_service.dart';
import '../../providers/live_stream_provider.dart';
import 'dart:developer' as developer;
import '../../widgets/follow_action_button.dart';
import '../../providers/public_profile_provider.dart';
import '../../providers/follow_status_provider.dart';  // ✅ ADD THIS
import '../../services/chat_gift_prompt_service.dart';
import '../../providers/friends_provider.dart';  // ✅ Add if missing
import '../../widgets/livestream/invite_friends_dialog.dart';
import '../../widgets/livestream/share_dialog.dart';  // ✅ Correct path
import '../../widgets/livestream/video_slot_indicator.dart';


class LiveStreamLearnerPage extends ConsumerStatefulWidget {
  final String liveStreamId;

  const LiveStreamLearnerPage({
    Key? key,
    required this.liveStreamId,
  }) : super(key: key);
  
  get roomName => null;

  @override
  _LiveStreamLearnerPageState createState() => _LiveStreamLearnerPageState();
}

class _LiveStreamLearnerPageState extends ConsumerState<LiveStreamLearnerPage> {

  bool _showChat = true;
  bool _showInfo = false;  // Trainer info panel
  bool _isParticipating = false;  // User is on camera
  bool _hasRequestedToJoin = false;  // Waiting for approval
  bool _isRefreshingToken = false;  // ADD THIS FLAG
  bool _isInitializing = false;  // ✅ ADD THIS
  bool _hasInitialized = false;  // ✅ ADD THIS
  bool _showOverlays = true;  // ✅ ADD THIS
  Timer? _overlayTimer;  // ✅ ADD THIS


  String? _giftRequirementError;  // Show if can't join due to gifts
  bool _showGiftAnimation = false;
  String? _lastGiftType;
  String? _lastGiftSender;
  int _lastGiftQuantity = 1;
  EventsListener<RoomEvent>? _roomListener;
  late ReminderManager _reminderManager;
  int _learnerCount = 0;
  StreamSubscription<QuerySnapshot>? _giftSubscription;  // ← ADD HERE
  Set<String> _processedGiftIds = {};        


@override
void initState() {
  super.initState();
  print('📱 LiveStreamLearnerPage initState called');
  print('📱 LiveStream ID: ${widget.liveStreamId}');
  _reminderManager = ReminderManager();
  
  // ✅ SINGLE addPostFrameCallback with everything inside
  WidgetsBinding.instance.addPostFrameCallback((_) {
    print('📱 About to call _initializeLearnerView');
    _initializeLearnerView();

      print('🚨🚨🚨 AFTER _initializeLearnerView, BEFORE _initializeGiftPromptService'); // ✅ ADD THIS

    
    // ✅ Initialize gift prompt service IMMEDIATELY after _initializeLearnerView
    _initializeGiftPromptService();   
    
    // Track join after stream loads
    Future.delayed(const Duration(seconds: 3), () {
  if (!mounted) return;
  
  final streamState = ref.read(liveStreamProvider(widget.liveStreamId));
  final trainerUsername = streamState.livestream?.trainer?.username;
  
  // ✅ Create callback function to check follow status
  Future<bool> checkIfFollowing() async {
  if (trainerUsername == null) return false;
  
  try {
    final profileAsync = ref.read(userProfileProvider(trainerUsername));
    return profileAsync.when(
      data: (profile) => profile.viewerContext.viewerIsFollowing,
      loading: () => false,
      error: (_, __) => false,
    );
  } catch (e) {
    print('⚠️ Error checking follow status: $e');
    return false;
  }
}
  
  // ✅ NEW: Create callback to handle follow action
 Future<void> handleFollow() async {
  if (trainerUsername == null) return;
  
  try {
    final service = ref.read(profilesServiceProvider);
    await service.followUser(trainerUsername);
    
    // ✅ Invalidate profile cache
    ref.invalidate(userProfileProvider(trainerUsername));
    
    // ✅ Invalidate friends provider (THIS WAS MISSING!)
    ref.invalidate(friendsProvider);
    
    // ✅ Record follow in livestream chat (same as follow button)
    final user = ref.read(authProvider).user;
    if (user != null) {
      final streamState = ref.read(liveStreamProvider(widget.liveStreamId));
      final trainerId = streamState.livestream?.trainer?.id;
      
      if (trainerId != null) {
        final firestoreService = ref.read(firestoreServiceProvider);
        await firestoreService.recordFollowInLivestream(
          livestreamId: widget.liveStreamId,
          followerId: user.id.toString(),
          followerName: user.displayName ?? user.username,
          trainerId: trainerId.toString(),
        );
        print('👥 Follow recorded in livestream chat from banner');
      }
    }
    
    print('✅ Successfully followed $trainerUsername from banner');
  } catch (e) {
    print('❌ Error following from banner: $e');
    rethrow;
  }
}
  
  // Start reminders with both callbacks
  _reminderManager.startReminders(
    context, 
    widget.liveStreamId,
    checkIfFollowing: checkIfFollowing,
    onFollowPressed: handleFollow,  // ✅ NEW
  );
  
 final reminderService = ref.read(chatReminderServiceProvider(widget.liveStreamId));
      if (reminderService != null) {
        print('✅ Reminder service tracking started');
      } else {
        print('⚠️ Reminder service not available yet');
      }
    });
  });
  
  // ✅ Auto-hide overlays after 3 seconds on load
  _overlayTimer = Timer(const Duration(seconds: 3), () {
    if (mounted) {
      setState(() => _showOverlays = false);
    }
  });
}

@override
void dispose() {
  _overlayTimer?.cancel();  // ✅ ADD THIS LINE
  final giftPromptService = ref.read(chatGiftPromptServiceProvider(widget.liveStreamId));
giftPromptService?.dispose();
ref.read(chatGiftPromptServiceProvider(widget.liveStreamId).notifier).state = null;

  print('🔴 [LiveStreamLearnerPage] Disposing page for livestream: ${widget.liveStreamId}');
  _giftSubscription?.cancel();
  _roomListener?.dispose();
  // Service will be auto-disposed by provider - no manual disposal needed
  super.dispose();
}

  Future<void> _initializeLearnerView() async {
  // Prevent multiple simultaneous calls
  if (_isInitializing || _hasInitialized) {
    print('⚠️ Already initializing or initialized, skipping...');
    return;
  }
  
  _isInitializing = true;
  
  try {
    print('🚀 Starting learner view initialization...');
    
    // 1. Join room (this calls the modified backend endpoint)
    await ref.read(liveStreamProvider(widget.liveStreamId).notifier).joinStream();
    
    print('🔍 After joinStream - checking room connection...');
    final roomState = ref.read(roomProvider);
    print('🔍 Room connected: ${roomState.isConnected}');
    print('🔍 Room exists: ${roomState.room != null}');
    
    // 2. Setup listeners
    print('🔧 About to call _listenForTrainerEvents()');
    _listenForTrainerEvents();
    print('🔧 Called _listenForTrainerEvents()');
    
    print('🔧 >>>>>> ABOUT TO CALL _setupFirestoreGiftListener()');
    _setupFirestoreGiftListener();
    print('🔧 >>>>>> CALLED _setupFirestoreGiftListener()');

    
    _hasInitialized = true; // Mark as successfully initialized
    
  } catch (e) {
    print('❌ Error in _initializeLearnerView: $e');
    
    // ✅ Check for ban error FIRST
    if (e.toString().contains('removed from this livestream') || 
        e.toString().contains('cannot rejoin')) {
      _showBannedDialog();
      _hasInitialized = true; // Mark as done to prevent retries
      return; // Stop here
    }
    
    if (e.toString().contains('Protein Bar')) {
      setState(() => _giftRequirementError = e.toString());
      _showGiftRequirementDialog();
    } else {
      _showErrorDialog(e.toString());
    }
  } finally {
    _isInitializing = false;
  }
}

  void _listenForTrainerEvents() {
  print('🚀 _listenForTrainerEvents() called!');

  final roomState = ref.read(roomProvider);
  final room = roomState.room;
  if (room == null) {
    print('❌ Room is null, retrying in 1 second...');
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) _listenForTrainerEvents();
    });
    return;
  }
  
  print('✅ Setting up room listeners');
  
  _roomListener?.dispose(); // Dispose existing listener
  _roomListener = room.createListener();
  
  // Listen for data events
  _roomListener!.on<DataReceivedEvent>((event) {
    print('📨 📨 📨 ANY data received in learner page'); // Triple emoji to make it obvious
    
    final data = json.decode(utf8.decode(event.data));
    final currentUserId = ref.read(authProvider).user?.id.toString();
    
    print('📨 Data received: $data');
    print('📨 Current user ID: $currentUserId');
    print('📨 Data type: ${data['type']}');
    print('📨 Data event: ${data['event']}');
      
    // Listen for permission granted
    if (data['event'] == 'permission_granted' && 
        data['learnerId'] == currentUserId) {
      _handlePermissionGranted(data['token']);
    }
    
    // Listen for grade received
    if (data['event'] == 'grade_received') {
      print('🎉 🎉 🎉 GRADE RECEIVED EVENT DETECTED!');
      print('🎉 Learner ID in data: ${data['learnerId']}');
      print('🎉 Expected: learner_$currentUserId');
      
      if (data['learnerId'] == 'learner_$currentUserId') {
        print('🎉 🎉 🎉 IDs MATCH! Showing dialog...');
        final totalPoints = data['totalPoints'] ?? 0;
        final pointsBreakdown = data['points'] as Map<String, dynamic>?;
        _showGradeReceivedDialog(totalPoints, pointsBreakdown);
      } else {
        print('❌ IDs DO NOT MATCH');
      }
    }
      
  // Listen for stream end - ✅ ONLY for THIS stream
// Listen for stream end - ✅ ONLY for THIS stream
if (data['event'] == 'stream_ended') {
  final endedStreamId = data['livestreamId'];
  print('🔚 Stream ended event received');
  print('🔚 Ended stream ID: $endedStreamId');
  print('🔚 My stream ID: ${widget.liveStreamId}');
  
  // ✅ CRITICAL: Only show dialog if THIS stream ended
  if (endedStreamId == widget.liveStreamId) {
    print('🔚 My stream ended! Showing review dialog');
    
    // ✅ Disconnect from room first to clean up, then show dialog
    Future.delayed(const Duration(milliseconds: 300), () async {
      if (mounted) {
        await ref.read(roomProvider.notifier).disconnect();
        _showPostStreamReviewDialog();
      }
    });
  } else {
    print('🔚 Different stream ended, ignoring');
  }
}

    // ✅ NEW: Listen for video removal
   // ✅ NEW: Listen for video removal
    if (data['event'] == 'remove_video') {
      final removedLearnerId = data['learnerId'];
      print('🚫 Remove video event received for: $removedLearnerId');
      
      if (removedLearnerId == currentUserId) {
        print('🚫 Trainer removed MY video, stopping camera...');
        _handleVideoRemoval();
      }
    }

    // ✅ NEW: Listen for kick events
    if (data['type'] == 'kick') {
      final targetSid = data['targetSid'];
      final myParticipant = room.localParticipant;
      
      print('🚫 Kick event received - Target: $targetSid, My SID: ${myParticipant?.sid}');
      
      if (targetSid == myParticipant?.sid) {
        print('🚫 I AM BEING KICKED!');
        _handleKicked();
      }
    }




    // Listen for gift animations
    if (data['type'] == 'gift') {
      print('🎁 Processing gift event: $data');
      
      _triggerGiftAnimation(
        data['gift'] ?? 'RUBY',
        data['sender'] ?? 'Someone',
        data['quantity'] ?? 1,
      );
    }

  });
      
  // Listen for participant changes
  _roomListener!.on<ParticipantConnectedEvent>((event) {
    _updateLearnerCount();
  });
  
  _roomListener!.on<ParticipantDisconnectedEvent>((event) {
    _updateLearnerCount();
  });
  
_roomListener!.on<RoomDisconnectedEvent>((event) {
  print('🔌 Room disconnected - Reason: ${event.reason}');
  
  // ✅ DON'T show dialog on disconnect - the stream_ended event handles it
  // This prevents duplicate dialogs and race conditions
  if (event.reason == DisconnectReason.clientInitiated) {
    print('🔌 Client-initiated disconnect, no action needed');
  } else {
    print('🔌 Server disconnect: ${event.reason}');
    // The stream_ended event is the source of truth, let it handle the dialog
  }
});
  

// Listen for track subscriptions (when video tracks are published)
_roomListener!.on<TrackSubscribedEvent>((event) {
  print('📹 Track subscribed: ${event.track.kind}');
  if (event.track.kind == TrackType.VIDEO) {
    _updateLearnerCount();
  }
});

_roomListener!.on<TrackUnsubscribedEvent>((event) {
  print('📹 Track unsubscribed: ${event.track.kind}');
  if (event.track.kind == TrackType.VIDEO) {
    _updateLearnerCount();
  }
});


// Listen for track publications (when participants publish tracks)
_roomListener!.on<TrackPublishedEvent>((event) {
  print('📹 Track published: ${event.publication.kind} by ${event.participant.name}');
  if (event.publication.kind == TrackType.VIDEO) {
    _updateLearnerCount();
  }
});

_roomListener!.on<TrackUnpublishedEvent>((event) {
  print('📹 Track unpublished: ${event.publication.kind} by ${event.participant.name}');
  if (event.publication.kind == TrackType.VIDEO) {
    _updateLearnerCount();
  }

});



  print('✅ All room listeners set up successfully');

  // ✅ ADD THIS: Check for existing learner videos immediately after connecting
print('🔍 Checking for existing learner videos...');
_updateLearnerCount();
}

// ✅ Initialize gift prompt service
void _initializeGiftPromptService() {
  print('🔥🔥🔥 _initializeGiftPromptService CALLED!!!');
  
  final user = ref.read(authProvider).user;
  if (user == null) {
    print('❌ No user found, exiting');
    return;
  }
  
  print('🎬 Initializing ChatGiftPromptService');
  
  final service = ChatGiftPromptService(
    livestreamId: widget.liveStreamId,
    userId: user.id.toString(),
    ref: ref,
    shouldShowPrompt: () {
      print('🎯 Periodic gift prompt triggered by timer');
      // Set state to trigger prompt in chat widget
      ref.read(shouldShowGiftPromptProvider(widget.liveStreamId).notifier).state = true;
    },
  );
  
  service.initialize();
  ref.read(chatGiftPromptServiceProvider(widget.liveStreamId).notifier).state = service;
  
  print('✅ ChatGiftPromptService initialized');
  
  // ✅ Verification
  final verify = ref.read(chatGiftPromptServiceProvider(widget.liveStreamId));
  print('🔍 VERIFICATION: Service stored? ${verify != null ? "YES" : "NO"}');
  if (verify != null) {
    print('🔍 VERIFICATION: messageCount=${verify.messageCount}, hasSentGift=${verify.hasSentGift}');
  }
}

void _setupFirestoreGiftListener() {
  print('🎁 ════════════════════════════════════════');
  print('🎁 _setupFirestoreGiftListener CALLED');
  print('🎁 Stream ID: ${widget.liveStreamId}');
  print('🎁 ════════════════════════════════════════');
  
  Future.delayed(Duration(seconds: 1), () {
    _startFirestoreGiftListener();
  });
}

void _startFirestoreGiftListener() {
  print('🎁 ════════════════════════════════════════');
  print('🎁 _startFirestoreGiftListener CALLED');
  print('🎁 ════════════════════════════════════════');
  
  _giftSubscription = FirebaseFirestore.instance
      .collection('gifts')
      .where('livestreamId', isEqualTo: widget.liveStreamId)
      .orderBy('timestamp', descending: true)
      .snapshots()
      .listen((snapshot) {
        print('');
        print('🎁 ▼▼▼ SNAPSHOT RECEIVED ▼▼▼');
        print('🎁 Total gifts: ${snapshot.docs.length}');
        print('🎁 Changes: ${snapshot.docChanges.length}');
        
        for (var change in snapshot.docChanges) {
          print('🎁 Change type: ${change.type}');
          
          if (change.type == DocumentChangeType.added) {
            final doc = change.doc;
            final data = doc.data()!;
            final giftId = doc.id;
            
            print('🎁 NEW GIFT DETECTED:');
            print('🎁   ID: $giftId');
            print('🎁   Type: ${data['giftType']}');
            print('🎁   Sender: ${data['senderName']}');
            print('🎁   Already processed? ${_processedGiftIds.contains(giftId)}');
            
            if (_processedGiftIds.contains(giftId)) {
              print('🎁   SKIP - already processed');
              continue;
            }
            
            final timestamp = data['timestamp'] as Timestamp?;
            print('🎁   Timestamp: $timestamp');
            
            if (timestamp != null) {
              final giftTime = timestamp.toDate();
              final now = DateTime.now();
              final age = now.difference(giftTime);
              
              print('🎁   Gift time: $giftTime');
              print('🎁   Current time: $now');
              print('🎁   Age: ${age.inSeconds} seconds');
              print('🎁   Passes check (<=30s)? ${age.inSeconds <= 30}');
              
              if (age.inSeconds <= 30) {
                print('🎁   ✅ TRIGGERING ANIMATION!');
                _processedGiftIds.add(giftId);
                
                _triggerGiftAnimation(
                  data['giftType'] ?? 'RUBY',
                  data['senderName'] ?? 'Someone',
                  data['quantity'] ?? 1,
                );
                
                print('🎁   Animation triggered!');
              } else {
                print('🎁   ❌ TOO OLD - skipping');
              }
            } else {
              print('🎁   ❌ NO TIMESTAMP - skipping');
            }
          }
        }
        print('🎁 ▲▲▲ SNAPSHOT COMPLETE ▲▲▲');
        print('');
      },
      onError: (error) {
        print('❌ FIRESTORE ERROR: $error');
      });
  
  print('🎁 Listener setup complete!');
}


void _updateLearnerCount() {
  final roomState = ref.read(roomProvider);
  final room = roomState.room;
  if (room == null) {
    print('❌ _updateLearnerCount: room is null');
    return;
  }
  
  print('👥 _updateLearnerCount called');
  print('👥 Remote participants: ${room.remoteParticipants.length}');
  print('👥 Is participating: $_isParticipating');
  
  int count = 0;
  
  // ✅ Count local learner if participating
  if (_isParticipating) {
    count++;
    print('👥 ✅ Counted local participant (self)');
  }
  
  // Count remote learners with video tracks
  for (final participant in room.remoteParticipants.values) {
    print('👥 Checking participant: ${participant.sid} - ${participant.name}');
    
    // Check if participant has video track
    final hasVideo = participant.videoTrackPublications.isNotEmpty;
    print('👥   Has video: $hasVideo');
    
    if (hasVideo) {
      final metadata = participant.metadata;
      print('👥   Metadata: $metadata');
      
      if (metadata != null) {
        try {
          final meta = json.decode(metadata);
          print('👥   Role: ${meta['role']}');
          
          if (meta['role'] == 'learner') {
            count++;
            print('👥   ✅ Counted as learner');
          }
        } catch (e) {
          print('👥   ❌ Error parsing metadata: $e');
        }
      }
    }
  }
  
  print('👥 Total learner count: $count (including self if participating)');
  
  if (mounted) {
    setState(() => _learnerCount = count);
  }
}

  @override
Widget build(BuildContext context) {
  final streamState = ref.watch(liveStreamProvider(widget.liveStreamId));
  final roomState = ref.watch(roomProvider);

   print('🔵 BUILD CALLED - streamState.error: ${streamState.error}');
  print('🔵 BUILD CALLED - streamState.isLoading: ${streamState.isLoading}');

    // ✅ ADD ERROR HANDLING HERE
    if (streamState.error != null) {
      // Check if user is banned
      if (streamState.error == 'banned') {
        return Scaffold(
          backgroundColor: const Color(0xFF1A1A1A),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Access Denied',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'You have been removed from this livestream and cannot rejoin.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/learner-home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4D00),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Go to Home'),
                ),
              ],
            ),
          ),
        );
      }
      
      // Other errors
      return Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        body: Center(
          child: Text(
            'Error: ${streamState.error}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }
    
    return Scaffold(
  backgroundColor: const Color(0xFF1A1A1A),
  body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return _buildDesktopLayout();
            }
            return _buildMobileLayout();
          },
        ),
      ),
    );
  }




// ✅ NEW METHOD: Build header with stream name and viewer tally
Widget _buildHeader() {
  final streamState = ref.watch(liveStreamProvider(widget.liveStreamId));
  
  return Container(
    height: 60,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: const Color(0xFF242424),
      border: Border(
        bottom: BorderSide(color: Colors.grey[800]!),
      ),
    ),
    child: Row(
      children: [
        // Stream title
        Expanded(
          child: Text(
            streamState.livestream?.title ?? 'Live Stream',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        
        // Viewer count
        ViewerTallyWidget(livestreamId: widget.liveStreamId),
        
        const SizedBox(width: 8),
        
        // Close button
// TODO: Update to '/browse-streams' when livestream home page is built
IconButton(
  icon: const Icon(Icons.close, color: Colors.white),
  onPressed: () => context.go('/learner-dashboard'),
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(),
),
      ],
    ),
  );
}





Widget _buildFollowButton() {
  final streamState = ref.watch(liveStreamProvider(widget.liveStreamId));
  final trainerUsername = streamState.livestream?.trainer?.username ?? '';
  
  if (trainerUsername.isEmpty) {
    return const SizedBox.shrink();
  }
  
  final trainerProfileAsync = ref.watch(userProfileProvider(trainerUsername));
  
  return trainerProfileAsync.when(
    data: (profile) {
      // ✅ UPDATED: Pass livestreamId to the button
      return FollowActionButton(
        profile: profile,
        livestreamId: widget.liveStreamId,  // ✅ ADD THIS LINE
      );
    },
    loading: () => const SizedBox(
      width: 80,
      height: 36,
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFFF4D00),
          ),
        ),
      ),
    ),
    error: (error, stack) {
      print('❌ Error loading trainer profile for follow button: $error');
      
      // Fallback: Simple follow button that doesn't show follow state
      return OutlinedButton(
        onPressed: () async {
          try {
            final service = ref.read(profilesServiceProvider);
            await service.followUser(trainerUsername);
            
            // ✅ UPDATED: Also record in livestream
            final authState = ref.read(authProvider);
            final currentUser = authState.user;
            
            if (currentUser != null) {
              final firestoreService = ref.read(firestoreServiceProvider);
              final streamState = ref.read(liveStreamProvider(widget.liveStreamId));
              final trainerId = streamState.livestream?.trainer?.id;
              
              if (trainerId != null) {
                await firestoreService.recordFollowInLivestream(
                  livestreamId: widget.liveStreamId,
                  followerId: currentUser.id.toString(),
                  followerName: currentUser.displayName ?? currentUser.username,
                  trainerId: trainerId.toString(),
                );
              }
            }
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Following trainer!'),
                  backgroundColor: Color(0xFFFF4D00),
                  duration: Duration(seconds: 2),
                ),
              );
            }
            
            ref.invalidate(userProfileProvider(trainerUsername));
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFFF4D00), width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        ),
        child: const Text(
          'FOLLOW',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      );
    },
  );
}

void _showShareDialog() {
  final streamState = ref.read(liveStreamProvider(widget.liveStreamId));
  final trainerUsername = streamState.livestream?.trainer?.username ?? '';
  
  if (trainerUsername.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Unable to share - trainer info not loaded'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  showDialog(
    context: context,
    builder: (context) => ShareDialog(
      livestreamId: widget.liveStreamId,
      trainerUsername: trainerUsername,
    ),
  );
}

void _showInviteFriendsDialog() {
  final streamState = ref.read(liveStreamProvider(widget.liveStreamId));
  final livestreamTitle = streamState.livestream?.title ?? 'Live Workout';
  
  showDialog(
    context: context,
    builder: (context) => InviteFriendsDialog(
      livestreamId: widget.liveStreamId,
      livestreamTitle: livestreamTitle,
    ),
  );
}

void _toggleOverlays() {
  setState(() {
    _showOverlays = !_showOverlays;
  });
  
  // Auto-hide after 3 seconds if showing
  if (_showOverlays) {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showOverlays = false);
      }
    });
  }
}

Widget _buildMobileLayout() {
  final liveStreamState = ref.watch(liveStreamProvider(widget.liveStreamId));
  
  final trainer = liveStreamState.livestream?.trainer;
  final trainerName = trainer?.displayName ?? trainer?.username ?? 'Trainer';
  final trainerXP = trainer?.xp ?? 0;
  
  return Stack(
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final screenHeight = constraints.maxHeight;
          
      final headerHeight = 60.0;
final collapsedChatHeight = 60.0;
final slotAreaHeight = 148.0;

// Calculate if there are other learners (remote only, not local)
final roomState = ref.read(roomProvider);
final room = roomState.room;
int otherLearnersCount = 0;
if (room != null) {
  for (final participant in room.remoteParticipants.values) {
    final hasVideo = participant.videoTrackPublications.isNotEmpty;
    if (hasVideo) {
      try {
        final metadata = participant.metadata;
        if (metadata != null) {
          final meta = json.decode(metadata);
          if (meta['role'] == 'learner') {
            otherLearnersCount++;
          }
        }
      } catch (e) {}
    }
  }
}

// Slot rendering and accommodation logic
final isMobileNarrow = screenWidth < 600; // Phone
final shouldShowSlot = true; // ALWAYS render slot on mobile

bool shouldAccommodateSlot;
if (isMobileNarrow) {
  // Phone: ALWAYS accommodate
  shouldAccommodateSlot = true;
} else {
  // Tablet: Accommodate UNLESS participating with only 1 learner
  shouldAccommodateSlot = !_isParticipating || otherLearnersCount > 0;
}

double videoWidth;
double videoHeight;
double containerHeight;

if (_isParticipating) {
  final availableHeight = shouldAccommodateSlot
      ? (screenHeight - headerHeight - slotAreaHeight - collapsedChatHeight - 24)
      : (screenHeight - headerHeight - collapsedChatHeight);
  
  containerHeight = availableHeight / 2;
  videoHeight = containerHeight;
  videoWidth = videoHeight * (16 / 9);
  
  if (videoWidth > screenWidth) {
    videoWidth = screenWidth;
    videoHeight = videoWidth / (16 / 9);
    containerHeight = videoHeight;
  }
} else {
  final topSpacer = 12.0;
  final minBuffer = 20.0;
  final totalOtherContent = shouldAccommodateSlot
      ? (headerHeight + topSpacer + slotAreaHeight + collapsedChatHeight + minBuffer)
      : (headerHeight + topSpacer + collapsedChatHeight + minBuffer);
  final maxVideoHeight = screenHeight - totalOtherContent;
  
  videoWidth = screenWidth;
  videoHeight = videoWidth / (16 / 9);
  
  if (videoHeight > maxVideoHeight) {
    videoHeight = maxVideoHeight;
    videoWidth = videoHeight * (16 / 9);
  }
  
  containerHeight = videoHeight;
}

final topSpacerHeight = _isParticipating ? 0.0 : 12.0;
final videoTotalHeight = _isParticipating ? (containerHeight * 2) : containerHeight;
final slotHeightInLayout = shouldAccommodateSlot ? slotAreaHeight : 0.0;
final contentHeight = headerHeight + topSpacerHeight + videoTotalHeight + slotHeightInLayout;
final spacerHeight = (screenHeight - collapsedChatHeight - contentHeight).clamp(0.0, double.infinity);

print('📐 Participating: $_isParticipating');
print('📐 Video: ${videoWidth}x${videoHeight}');
print('📐 Spacer: $spacerHeight');
print('📐 Should show slot: $shouldShowSlot');
print('📐 Should accommodate slot: $shouldAccommodateSlot');
          
          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                // Trainer info bar
                Container(
                  height: headerHeight,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFFFF4D00),
                        child: const Icon(Icons.person, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              trainerName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '$trainerXP XP',
                              style: const TextStyle(
                                color: Color(0xFFFF4D00),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _showInfoModal,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildFollowButton(),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => context.go('/learner-dashboard'),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.close, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),
                ),

                // Trainer video - centered with black bars
                    // Add top margin when trainer is alone to reduce empty space
                    // Top spacer when trainer is alone (black to match video background)
                    if (!_isParticipating)
                      Container(
                        height: 12,
                        color: Colors.black,
                      ),
                    
                    // Trainer video - centered, full width on mobile
                  // Trainer video - full screen width
// Trainer video - full screen width with black gap below when participating
// Trainer video - rounded corners when letterboxed
Container(
  width: double.infinity,
  height: containerHeight + (_isParticipating ? 16 : 0),
  color: Colors.black,
  padding: _isParticipating 
      ? const EdgeInsets.only(bottom: 16) 
      : EdgeInsets.zero,
  child: Center(
    child: Container(
      width: videoWidth,
      height: videoHeight,
      child: ClipRRect(
        // Apply rounded corners when video is letterboxed (narrower than screen)
        borderRadius: videoWidth < screenWidth 
            ? BorderRadius.circular(12)
            : BorderRadius.zero,
        child: GestureDetector(
          onTap: _toggleOverlays,
          behavior: HitTestBehavior.opaque,
          child: Stack(
            fit: StackFit.expand,
            children: [
              TrainerVideoView(livestreamId: widget.liveStreamId),
              
              // Viewer tally - always visible
              Positioned(
                top: 12,
                right: 12,
                child: ViewerTallyWidget(livestreamId: widget.liveStreamId, isMobile: true),
              ),
              
              // Stream title - toggleable with fade
              AnimatedOpacity(
                opacity: _showOverlays ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      ref.watch(liveStreamProvider(widget.liveStreamId)).livestream?.title ?? 'Live Workout',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
),

                // Learner self view - centered, full width on mobile
                    // Learner self view - full width with visually equal padding
                    if (_isParticipating)
                      Container(
                        width: double.infinity,
                        height: containerHeight,
                        color: Colors.black,
                        child: Center(
                          child: Container(
                            width: videoWidth,
                            height: videoHeight,
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFFFF4D00),
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LearnerSelfView(
                                livestreamId: widget.liveStreamId,
                                onRequestGrade: _requestGrade,
                                onStopSharing: _stopSharing,
                              ),
                            ),
                          ),
                        ),
                      ),

             // Video slot area - conditional based on device width
// Video slot area - ALWAYS render on mobile
if (shouldShowSlot)
  Container(
    margin: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 8),
    decoration: BoxDecoration(
      color: Colors.grey[900],
      borderRadius: BorderRadius.circular(12),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VideoSlotIndicator(  // NO condition - always show
          livestreamId: widget.liveStreamId,
          isMobile: true,
          backgroundColor: Colors.grey[900],
          includeLocalParticipant: _isParticipating,
        ),
        
        Container(
          height: 120,
          child: _learnerCount > 0
              ? LearnerHorizontalView(
                  livestreamId: widget.liveStreamId,
                  isMobile: true,
                )
              : Center(
                  child: Text(
                    _isParticipating 
                        ? 'No other learners yet...'
                        : 'Waiting for learners to join...',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                ),
        ),
      ],
    ),
  ),

                // Dark spacer - fills remaining gap above chat
                Container(
                  height: spacerHeight,
                  color: const Color(0xFF1A1A1A),
                ),

                // Space for chat
                SizedBox(height: _showChat ? 300 : 60),
              ],
            ),
          );
        },
      ),
      
      // Chat panel - fixed at bottom
      Positioned(
  left: 0,
  right: 0,
  bottom: 0,
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    height: _showChat ? 300 : 60,
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFF242424).withOpacity(.99),  // Bottom: 95% opaque
          const Color(0xFF242424).withOpacity(0.85),  // 85%
          const Color(0xFF242424).withOpacity(0.50),  // 60%
          const Color(0xFF242424).withOpacity(0.20),  // Top: 30% transparent
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],  // Gradient positions
      ),
    ),
          child: Column(
            children: [
              // Toggle bar
              Container(
                height: 59,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showChat = !_showChat),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat, color: Colors.white),
                          const SizedBox(width: 8),
                          const Text(
                            'Live Questions',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const Spacer(),
                    
                    if (!_showChat) ...[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF4D00),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: _showGiftSelectorDialog,
                          icon: const Icon(
                            Icons.card_giftcard,
                            color: Colors.white,
                            size: 22,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    
                    GestureDetector(
                      onTap: () => setState(() => _showChat = !_showChat),
                      child: Icon(
                        _showChat ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Chat content
              if (_showChat)
                Expanded(
                  child: ChatWidget(
                    livestreamId: widget.liveStreamId,
                    isMobile: true,
                    showGiftButton: true,
                  ),
                ),
            ],
          ),
        ),
      ),
      
      // Floating buttons - Share and Invite
      Positioned(
        bottom: 100,
        right: 12,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Share button
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _showShareDialog,
                icon: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
              ),
            ),
            const SizedBox(height: 12),
            
            // Invite button
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _showInviteFriendsDialog,
                icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),

      // JOIN VIDEO button
      if (!_isParticipating)
        Positioned(
          bottom: 310,
          right: 16,
          child: SizedBox(
            width: 142,
            height: 35,
            child: ElevatedButton.icon(
              onPressed: _hasRequestedToJoin ? null : _showJoinVideoDialog,
              icon: const Icon(Icons.videocam, size: 15),
              label: Text(
                _hasRequestedToJoin ? 'Request Sent...' : 'JOIN VIDEO',
                style: const TextStyle(fontSize: 12),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasRequestedToJoin ? Colors.grey : const Color(0xFFFF4D00),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),

      // Gift animations
      if (_showGiftAnimation && _lastGiftType != null && _lastGiftSender != null)
        Positioned.fill(
          child: GiftAnimationWidget(
            giftType: _lastGiftType!,
            senderName: _lastGiftSender!,
            quantity: _lastGiftQuantity,
            onComplete: () {
              if (mounted) {
                setState(() => _showGiftAnimation = false);
              }
            },
          ),
        ),
    ],
  );
}

 Widget _buildDesktopLayout() {
  return Stack(
    children: [
      Row(
        children: [
          // Left side: Video + learner grid
         // Left side: Video + learner grid
Expanded(
  flex: 2,
  child: LayoutBuilder(
    builder: (context, outerConstraints) {
      final panelWidth = outerConstraints.maxWidth;
      final viewportHeight = outerConstraints.maxHeight;
      final headerHeight = 60.0;
      final isWide = panelWidth >= 800;
      
      // Calculate other learners count (remote only, not local)
      final roomState = ref.watch(roomProvider);
      final room = roomState.room;
      int otherLearnersCount = 0;
      if (room != null) {
        for (final participant in room.remoteParticipants.values) {
          final hasVideo = participant.videoTrackPublications.isNotEmpty;
          if (hasVideo) {
            try {
              final metadata = participant.metadata;
              if (metadata != null) {
                final meta = json.decode(metadata);
                if (meta['role'] == 'learner') {
                  otherLearnersCount++;
                }
              }
            } catch (e) {}
          }
        }
      }
      
      // Slot logic
      final shouldShowSlot = true; // ALWAYS render
      bool shouldAccommodateSlot;
      
      if (isWide) {
        // Wide: ALWAYS accommodate
        shouldAccommodateSlot = true;
      } else {
        // Narrow: Accommodate UNLESS participating with only 1 learner
        shouldAccommodateSlot = !_isParticipating || otherLearnersCount > 0;
      }
      
      if (isWide) {
        // WIDE DESKTOP: Fixed layout with Column + Expanded
        return Column(
          children: [
            _buildHeader(),
            
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final slotHeight = _isParticipating ? 140.0 : 180.0;
                  final slotMargin = 32.0;
                  final availableHeight = constraints.maxHeight - slotHeight - slotMargin;
                  
                  return Column(
                    children: [
                      // Videos
                      Container(
                        height: availableHeight,
                        color: const Color(0xFF1A1A1A),
                        padding: const EdgeInsets.all(8.0),
                        child: _isParticipating
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, videoConstraints) {
                                          final availableWidth = videoConstraints.maxWidth;
                                          final availableHeight = videoConstraints.maxHeight;
                                          final widthBasedHeight = availableWidth / (16 / 9);
                                          final heightBasedWidth = availableHeight * (16 / 9);
                                          final useFullWidth = widthBasedHeight <= availableHeight;
                                          
                                          return Center(
                                            child: SizedBox(
                                              width: useFullWidth ? availableWidth : heightBasedWidth,
                                              height: useFullWidth ? widthBasedHeight : availableHeight,
                                              child: TrainerVideoView(livestreamId: widget.liveStreamId),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: const Color(0xFFFF4D00), width: 2),
                                      ),
                                      child: LayoutBuilder(
                                        builder: (context, videoConstraints) {
                                          final availableWidth = videoConstraints.maxWidth;
                                          final availableHeight = videoConstraints.maxHeight;
                                          final widthBasedHeight = availableWidth / (16 / 9);
                                          final heightBasedWidth = availableHeight * (16 / 9);
                                          final useFullWidth = widthBasedHeight <= availableHeight;
                                          
                                          return Center(
                                            child: SizedBox(
                                              width: useFullWidth ? availableWidth : heightBasedWidth,
                                              height: useFullWidth ? widthBasedHeight : availableHeight,
                                              child: LearnerSelfView(
                                                livestreamId: widget.liveStreamId,
                                                onRequestGrade: _requestGrade,
                                                onStopSharing: _stopSharing,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: LayoutBuilder(
                                  builder: (context, videoConstraints) {
                                    final availableWidth = videoConstraints.maxWidth;
                                    final availableHeight = videoConstraints.maxHeight;
                                    final widthBasedHeight = availableWidth / (16 / 9);
                                    final heightBasedWidth = availableHeight * (16 / 9);
                                    final useFullWidth = widthBasedHeight <= availableHeight;
                                    
                                    return Center(
                                      child: SizedBox(
                                        width: useFullWidth ? availableWidth : heightBasedWidth,
                                        height: useFullWidth ? widthBasedHeight : availableHeight,
                                        child: TrainerVideoView(livestreamId: widget.liveStreamId),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                      
                      // Learner slot - ALWAYS visible
                      Container(
                        height: slotHeight,
                        margin: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VideoSlotIndicator(  // NO condition - always show
                              livestreamId: widget.liveStreamId,
                              isMobile: false,
                              backgroundColor: Colors.grey[900],
                              includeLocalParticipant: _isParticipating,
                            ),
                            
                            Expanded(
                              child: _learnerCount > 0
                                  ? Align(
                                      alignment: Alignment.centerLeft,
                                      child: LearnerHorizontalView(
                                        livestreamId: widget.liveStreamId,
                                        isMobile: false,
                                      ),
                                    )
                                  : Align(
                                      alignment: const Alignment(0, -0.5),
                                      child: Text(
                                        'Waiting for learners to join...',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      } else {
        // NARROW DESKTOP: Scrollable layout
        final slotAreaHeight = shouldAccommodateSlot ? (_isParticipating ? 120.0 : 180.0) : 0.0;
        final minBuffer = shouldAccommodateSlot ? 16.0 : 0.0;
        
        return SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              
              LayoutBuilder(
                builder: (context, videoOuterConstraints) {
                  final availableVideoHeight = shouldAccommodateSlot 
                      ? (viewportHeight - headerHeight - slotAreaHeight - minBuffer)
                      : (viewportHeight - headerHeight);
                  
                  if (_isParticipating) {
                    // Stacked videos
                    return Container(
                      height: availableVideoHeight,
                      color: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final availableWidth = constraints.maxWidth;
                                  final availableHeight = constraints.maxHeight;
                                  final widthBasedHeight = availableWidth / (16 / 9);
                                  final heightBasedWidth = availableHeight * (16 / 9);
                                  final useFullWidth = widthBasedHeight <= availableHeight;
                                  
                                  return Center(
                                    child: SizedBox(
                                      width: useFullWidth ? availableWidth : heightBasedWidth,
                                      height: useFullWidth ? widthBasedHeight : availableHeight,
                                      child: TrainerVideoView(livestreamId: widget.liveStreamId),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFFF4D00), width: 2),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final availableWidth = constraints.maxWidth;
                                  final availableHeight = constraints.maxHeight;
                                  final widthBasedHeight = availableWidth / (16 / 9);
                                  final heightBasedWidth = availableHeight * (16 / 9);
                                  final useFullWidth = widthBasedHeight <= availableHeight;
                                  
                                  return Center(
                                    child: SizedBox(
                                      width: useFullWidth ? availableWidth : heightBasedWidth,
                                      height: useFullWidth ? widthBasedHeight : availableHeight,
                                      child: LearnerSelfView(
                                        livestreamId: widget.liveStreamId,
                                        onRequestGrade: _requestGrade,
                                        onStopSharing: _stopSharing,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    // Single trainer video
                    return Container(
                      height: availableVideoHeight,
                      color: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth;
                            final availableHeight = constraints.maxHeight;
                            final widthBasedHeight = availableWidth / (16 / 9);
                            final heightBasedWidth = availableHeight * (16 / 9);
                            final useFullWidth = widthBasedHeight <= availableHeight;
                            
                            return Center(
                              child: SizedBox(
                                width: useFullWidth ? availableWidth : heightBasedWidth,
                                height: useFullWidth ? widthBasedHeight : availableHeight,
                                child: TrainerVideoView(livestreamId: widget.liveStreamId),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }
                },
              ),
              
              // Learner slot - ALWAYS rendered
              Container(
                height: _isParticipating ? 120 : 180,
                margin: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    VideoSlotIndicator(  // NO condition - always show
                      livestreamId: widget.liveStreamId,
                      isMobile: false,
                      backgroundColor: Colors.grey[900],
                      includeLocalParticipant: _isParticipating,
                    ),
                    
                    Expanded(
                      child: _learnerCount > 0
                          ? Align(
                              alignment: Alignment.centerLeft,
                              child: LearnerHorizontalView(
                                livestreamId: widget.liveStreamId,
                                isMobile: false,
                              ),
                            )
                          : Align(
                              alignment: const Alignment(0, -0.5),
                              child: Text(
                                'Waiting for learners to join...',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    },
  ),
),
          
          // Right side: Info panel + chat
          Container(
            width: 340,
            color: Colors.grey[900],
            child: Column(
              children: [
                // Trainer Profile Section (Always Visible)
              Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.grey[850],
    border: Border(
      bottom: BorderSide(color: Colors.grey[800]!),
    ),
  ),
  child: Column(
    children: [
      Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFFFF4D00),
            child: const Icon(Icons.person, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 12),
          
          Expanded(
            child: Consumer(
              builder: (context, ref, _) {
                final streamState = ref.watch(liveStreamProvider(widget.liveStreamId));
                final trainer = streamState.livestream?.trainer;
                final username = trainer?.username ?? 'Trainer';
                final xp = trainer?.xp ?? 0;
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$xp XP',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      
      Row(
  children: [
    Expanded(
      flex: 2,
      child: _buildFollowButton(),
    ),
    const SizedBox(width: 8),
    
    // Share button - same height as follow button
    SizedBox(
      height: 32,  // ✅ Fixed height to match follow button
      width: 32,
      child: ElevatedButton(
        onPressed: _showShareDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[700],
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Icon(Icons.share, size: 20),
      ),
    ),
    const SizedBox(width: 8),
    
    // Invite button - same height as follow button
    SizedBox(
      height: 32,  // ✅ Fixed height to match follow button
      width: 32,
      child: ElevatedButton(
        onPressed: _showInviteFriendsDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[700],
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
        child: const Icon(Icons.person_add, size: 20),
      ),
    ),
  ],
),
      
      if (!_isParticipating && !_hasRequestedToJoin) ...[
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _showJoinVideoDialog,
            icon: const Icon(Icons.videocam, size: 20),
            label: const Text('JOIN VIDEO'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
      
      if (_hasRequestedToJoin && !_isParticipating) ...[
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[700],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'Request Sent...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ],
  ),
),
                          
                
                // Tab selector
                Container(
                  height: 48,
                  color: Colors.grey[850],
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _showInfo = false),
                          child: Text(
                            'Chat',
                            style: TextStyle(
                              color: !_showInfo ? Color(0xFFFF4D00) : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: () => setState(() => _showInfo = true),
                          child: Text(
                            'Info',
                            style: TextStyle(
                              color: _showInfo ? Color(0xFFFF4D00) : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: _showInfo
                      ? TrainerInfoPanel(livestreamId: widget.liveStreamId)
                      : ChatWidget(
                          livestreamId: widget.liveStreamId,
                          isMobile: false,
                          showGiftButton: true,
                        ),
                ),
                
                // Fitneks Finest
                Container(
                  height: 200,
                  child: FitneksFinestWidget(
                    currentLivestreamId: widget.liveStreamId,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      

// ✅ ADD GIFT ANIMATION OVERLAY FOR DESKTOP
      if (_showGiftAnimation && _lastGiftType != null && _lastGiftSender != null)
        Positioned.fill(
          child: GiftAnimationWidget(
            giftType: _lastGiftType!,
            senderName: _lastGiftSender!,
            quantity: _lastGiftQuantity,
            onComplete: () {
              if (mounted) {
                setState(() => _showGiftAnimation = false);
              }
            },
          ),
        ),


      // Floating Action Button for SEND GIFT
      Positioned(
        bottom: 24,
        left: 0,
        right: 380, // Account for right panel width
        child: Center(
          child: FloatingActionButton.extended(
            onPressed: _showGiftSelectorDialog,
            backgroundColor: const Color(0xFF2B5FFF),
            icon: const Icon(Icons.card_giftcard, color: Colors.white),
            label: const Text(
              'SEND GIFT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

  Widget _buildJoinLiveButton() {
    if (_isParticipating) {
      return SizedBox.shrink(); // Hide if already participating
    }
    
    String buttonText = 'JOIN VIDEO';
    Color buttonColor = Color(0xFFFF4D00);
    VoidCallback? onPressed = _showJoinVideoDialog;
    
    if (_hasRequestedToJoin) {
      buttonText = 'Request Sent...';
      buttonColor = Colors.grey;
      onPressed = null;
    }
    
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.videocam),
      label: Text(buttonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  Widget _buildSendGiftButton() {
    return ElevatedButton.icon(
      onPressed: _showGiftSelectorDialog,
      icon: Icon(Icons.card_giftcard),
      label: Text('SEND GIFT'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF2B5FFF),
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  void _showJoinVideoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join Live Video'),
        content: Text('Would you like to send a gift with your request to join?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _sendJoinRequest(withGift: false);
            },
            child: Text('Join Without Gift'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showGiftSelectorForJoin();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF4D00),
            ),
            child: Text('Send Gift & Join'),
          ),
        ],
      ),
    );
  }

void _showGiftSelectorForJoin() {
  // ✅ Capture refs first
  final user = ref.read(authProvider).user;
  
  showDialog(
    context: context,
    builder: (dialogContext) => GiftSendingWidget(
      livestreamId: widget.liveStreamId,
      onGiftSent: (giftType) {
        // ✅ Use captured value
        _sendJoinRequest(withGift: true, giftType: giftType);
      },
    ),
  );
}

void _showGiftSelectorDialog() {
  // ✅ Capture parent context
  final parentContext = context;
  
  showDialog(
    context: context,
    builder: (dialogContext) => GiftSendingWidget(
      livestreamId: widget.liveStreamId,
      onGiftSent: (giftType) {
        // ✅ Use parentContext instead of trying to access ref
        if (mounted) {
          ScaffoldMessenger.of(parentContext).showSnackBar(
            SnackBar(
              content: Text('Gift sent! 🎁'),
              backgroundColor: Color(0xFFFF4D00),
              duration: Duration(milliseconds: 800),
            ),
          );
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _triggerGiftAnimation(giftType, 'You', 1);
            }
          });
        }
      },
    ),
  );
}

 Future<void> _sendJoinRequest({
  bool withGift = false,
  String? giftType,
}) async {
  print('🎥 _sendJoinRequest called - withGift: $withGift, giftType: $giftType');
  
  setState(() => _hasRequestedToJoin = true);
  
  final user = ref.read(authProvider).user;
  final roomNotifier = ref.read(roomProvider.notifier);
  
  // ✅ Write join request to Firestore
  final firestoreService = ref.read(firestoreServiceProvider);
  await firestoreService.sendJoinRequest(
    livestreamId: widget.liveStreamId,
    learnerId: user?.id.toString() ?? '',
    learnerName: user?.displayName ?? user?.username ?? '',
    profilePicture: null,
  );
  
  print('🎥 Join request written to Firestore');
  
  // Also broadcast via LiveKit (backup)
  await roomNotifier.publishData({
    'type': 'join_request',
    'userId': 'learner_${user?.id}',
    'userName': user?.displayName ?? user?.username ?? '',
    'withGift': withGift,
    'giftType': giftType,
  });
  
  print('🎥 Join request data published successfully');
}

 Future<void> _handlePermissionGranted(String newToken) async {
  print('🎥 _handlePermissionGranted called - reconnecting with new token');
  
  setState(() => _isRefreshingToken = true);
  
  final roomState = ref.read(roomProvider);
  final roomNotifier = ref.read(roomProvider.notifier);
  
  await roomNotifier.disconnect();
  print('🎥 Disconnected from room');
  
  await roomNotifier.connect(newToken, roomState.room?.name ?? '');
  print('🎥 Reconnected with new token');
  
  // ADD DELAY to ensure connection is stable
  await Future.delayed(Duration(milliseconds: 500));
  
  await roomNotifier.enableCamera(true);
  await roomNotifier.enableMicrophone(true);
  print('🎥 Camera and mic enabled');
  
  // VERIFY TRACKS ARE PUBLISHING
  final room = ref.read(roomProvider).room;
  final localParticipant = room?.localParticipant;
  print('🎥 Local video tracks: ${localParticipant?.videoTrackPublications.length}');
  print('🎥 Local audio tracks: ${localParticipant?.audioTrackPublications.length}');
  
  
  // ADD THIS LINE - Re-setup listeners after reconnection
  _listenForTrainerEvents();
  
  
  setState(() {
    _isParticipating = true;
    _hasRequestedToJoin = false;
    _isRefreshingToken = false;
  });
  
  // ✅ Force immediate learner count update (with delay to ensure state is settled)
  Future.delayed(Duration(milliseconds: 100), () {
    _updateLearnerCount();
    print('🎥 Learner count updated after joining: $_learnerCount');
  });
  
  // Also update immediately
  _updateLearnerCount();
}

  void _handleKicked() {
  print('🚫 _handleKicked called - showing removal dialog');
  
  if (!mounted) return;
  
  // Set a flag to prevent review dialog from showing
  setState(() {
    _isRefreshingToken = true; // Reuse this flag to block the review dialog
  });
  
  // Disconnect from room immediately
  ref.read(roomProvider.notifier).disconnect();
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF242424),
      title: const Row(
        children: [
          Icon(Icons.block, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Text(
            'Removed from Stream',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: const Text(
        'You have been removed from this livestream by the trainer and cannot rejoin.',
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4D00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            context.go('/learner-dashboard'); // Go to dashboard
          },
          child: const Text('OK', style: TextStyle(fontSize: 16)),
        ),
      ],
    ),
  );
}



 void _requestGrade() async {
  print('⭐⭐⭐ _requestGrade called!');
  
  final user = ref.read(authProvider).user;
  final roomNotifier = ref.read(roomProvider.notifier);
  
  print('⭐ User ID: ${user?.id}');
  print('⭐ User name: ${user?.displayName ?? user?.username}');
  
  final data = {
    'type': 'grade_request',
    'userId': 'learner_${user?.id}',
    'userName': user?.displayName ?? user?.username ?? '',
  };
  
  print('⭐ About to publish data: $data');
  
  await roomNotifier.publishData(data);
  
  print('✅✅✅ Grade request published!');
}

  void _stopSharing() async {
    final roomNotifier = ref.read(roomProvider.notifier);
    
    await roomNotifier.enableCamera(false);
    await roomNotifier.enableMicrophone(false);
    


    setState(() {
      _isParticipating = false;
      _hasRequestedToJoin = false;
    });
  }

  void _showTrainerInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 400,
          height: 600,
          child: TrainerInfoPanel(
            livestreamId: widget.liveStreamId,
          ),
        ),
      ),
    );
  }

  void _showGiftRequirementDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Gift Requirement'),
        content: Text(_giftRequirementError ?? ''),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/learner-profile');  // ← Use go instead of double pop
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showGiftSelectorDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF4D00),
            ),
            child: Text('Send Gift'),
          ),
        ],
      ),
    );
  }

  void _showGradeReceivedDialog(int totalPoints, Map<String, dynamic>? pointsBreakdown) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4D00),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            '🎉 POINTS EARNED!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          const Icon(
            Icons.star,
            color: Color(0xFFFF4D00),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'You earned $totalPoints points!',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (pointsBreakdown != null) ...[
            const Divider(),
            const SizedBox(height: 8),
            ...pointsBreakdown.entries.where((e) => e.value > 0).map((entry) {
              final muscle = entry.key.substring(0, 1).toUpperCase() + 
                           entry.key.substring(1);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      muscle,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      '${entry.value} pts',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF4D00),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4D00),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'AWESOME!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  void _showPostStreamReviewDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PostStreamReviewDialog(
        livestreamId: widget.liveStreamId,
        onSubmit: () {
          Navigator.pop(context);
          context.go('/learner-dashboard');
        },
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/learner-profile');  // Navigate to safe route
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }


void _showBannedDialog() {
  if (!mounted) return;
  
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF242424),
      title: const Row(
        children: [
          Icon(Icons.block, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Text(
            'Access Denied',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: const Text(
        'You have been removed from this livestream by the trainer and cannot rejoin.',
        style: TextStyle(color: Colors.white70, fontSize: 16),
      ),
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF4D00),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog
            context.go('/learner-dashboard'); // Go back to dashboard
          },
          child: const Text('OK', style: TextStyle(fontSize: 16)),
        ),
      ],
    ),
  );
}



 void _triggerGiftAnimation(String giftType, String senderName, int quantity) {
  setState(() {
    _showGiftAnimation = true;
    _lastGiftType = giftType;
    _lastGiftSender = senderName;
    _lastGiftQuantity = quantity;
  });
  
  Timer(Duration(seconds: 4), () {  // Changed to 4 seconds
    if (mounted) {
      setState(() => _showGiftAnimation = false);
    }
  });
}



/// Mobile-specific JOIN VIDEO button
Widget _buildJoinVideoButtonMobile() {
  String buttonText = 'JOIN VIDEO';
  Color buttonColor = Color(0xFFFF4D00);
  VoidCallback? onPressed = _showJoinVideoDialog;
  
  if (_hasRequestedToJoin) {
    buttonText = 'Request Sent...';
    buttonColor = Colors.grey;
    onPressed = null;
  }
  
  return SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(Icons.videocam),
      label: Text(buttonText),
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
      ),
    ),
  );
}


void _showInfoModal() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text(
                    'Stream Info',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            const Divider(color: Colors.grey, height: 1),
            
            // Info content - TrainerInfoPanel
            Expanded(
              child: TrainerInfoPanel(
                livestreamId: widget.liveStreamId,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}




String _formatGiftMessage(String giftType, int amount) {
  String giftName;
  String emoji;
  
  switch (giftType) {
    case 'RUBY':
      giftName = amount > 1 ? 'rubies' : 'ruby';
      emoji = '💎';
      break;
    case 'PROTEIN':
      giftName = amount > 1 ? 'proteins' : 'protein';
      emoji = '💪';
      break;
    case 'PROTEIN_SHAKE':
      giftName = amount > 1 ? 'protein shakes' : 'protein shake';
      emoji = '🥤';
      break;
    case 'PROTEIN_BAR':
      giftName = amount > 1 ? 'protein bars' : 'protein bar';
      emoji = '🍫';
      break;
    default:
      giftName = 'gift';
      emoji = '🎁';
  }
  
  return 'sent $amount $giftName $emoji';
}



Future<void> _handleVideoRemoval() async {
  try {
    final room = ref.read(roomProvider).room;
    if (room == null) return;
    
    // ✅ Disable both camera AND microphone
    await room.localParticipant?.setCameraEnabled(false);
    await room.localParticipant?.setMicrophoneEnabled(false);  // ✅ ADD THIS
    print('✅ Camera and microphone disabled');
    
    // Update state
    setState(() {
      _isParticipating = false;
      _hasRequestedToJoin = false;
    });
    
    // Show notification
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trainer has removed you from video'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    print('❌ Error removing video: $e');
  }
}

}