import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/live_stream_provider.dart';
import '../../widgets/livestream/trainer_self_view.dart';
import '../../widgets/livestream/learner_grid_view.dart';
import '../../widgets/livestream/chat_widget.dart';
import '../../widgets/livestream/waitlist_widget.dart';
import '../../widgets/livestream/stream_info_panel.dart';
import '../../widgets/livestream/gift_summary_widget.dart';
import '../../widgets/livestream/viewer_tally_widget.dart';
import '../../widgets/livestream/share_dialog.dart';
import '../../widgets/livestream/grade_learner_dialog.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/livestream/grade_request_notification.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../widgets/livestream/gift_animation_widget.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/livestream/video_slot_indicator.dart';


class LiveStreamPage extends ConsumerStatefulWidget {
  final String liveStreamId;
  
  const LiveStreamPage({
    Key? key,
    required this.liveStreamId,
  }) : super(key: key);

  @override
  ConsumerState<LiveStreamPage> createState() => _LiveStreamPageState();
}

class _LiveStreamPageState extends ConsumerState<LiveStreamPage> {
  bool _showChat = true;
  bool _showWaitlist = false;
  bool _showInfo = true;
  String? _selectedLearnerId; // ADD THIS LINE

// ✅ Gift animation state
  bool _showGiftAnimation = false;
  String? _lastGiftType;
  String? _lastGiftSender;
  int _lastGiftQuantity = 1;
  StreamSubscription<QuerySnapshot>? _giftSubscription;  
  Set<String> _processedGiftIds = {};                     


  @override
  Widget build(BuildContext context) {
    final streamState = ref.watch(liveStreamProvider(widget.liveStreamId));
    final roomState = ref.watch(roomProvider);
    
// ✅ ADD THIS LINE - This initializes the grade request listener
  final gradeRequests = ref.watch(gradeRequestProvider(widget.liveStreamId));
  print('👀 Trainer watching grade requests: ${gradeRequests.length}');
  

    // Handle loading state
    if (streamState.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4D00)),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading stream...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    // Handle error state
    if (streamState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Error loading stream',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                streamState.error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D00),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    // Main layout based on screen size
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 900) {
              return _buildDesktopLayout();
            } else {
              return _buildMobileLayout();
            }
          },
        ),
      ),
    );
  }


@override
  void initState() {
    super.initState();
    _setupGiftListener();
      _setupGradeRequestListener();  // ✅ ADD THIS
  }



// ✅ ADD THIS NEW METHOD after initState
void _setupGradeRequestListener() {
  // Wait for room to be connected before starting grade request listener
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future.delayed(Duration(seconds: 2), () {
      final roomState = ref.read(roomProvider);
      if (roomState.room != null && mounted) {
        print('✅ Room is connected, starting grade request listener');
        ref.read(gradeRequestProvider(widget.liveStreamId).notifier).startListening();
      }
    });
  });
}



  void _setupGiftListener() {
  print('🎁 Setting up FIRESTORE gift listener');
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _startFirestoreGiftListener();
  });
}






void _startFirestoreGiftListener() {
  print('🎁 ════════════════════════════════════════');
  print('🎁 _startFirestoreGiftListener CALLED');
  print('🎁 Stream ID: ${widget.liveStreamId}');
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


 Widget _buildSideBySideView() {
  final roomState = ref.watch(roomProvider);
  RemoteParticipant? selectedParticipant;
  try {
    selectedParticipant = roomState.remoteParticipants
        .firstWhere((p) => p.sid == _selectedLearnerId);
  } catch (e) {
    selectedParticipant = null;
  }
  
  if (selectedParticipant == null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _selectedLearnerId = null);
    });
    return const SizedBox();
  }
  
  final participant = selectedParticipant!;
  
  return LayoutBuilder(
    builder: (context, constraints) {
      final availableHeight = constraints.maxHeight;
      final availableWidth = constraints.maxWidth;
      final spacing = 16.0;
      
      // Calculate number of remaining learners (excluding the selected one)
      final remainingLearnerCount = roomState.remoteParticipants.length - 1;
      
      // DYNAMIC TILE WIDTH CALCULATION
      double learnerTileWidth;
      if (remainingLearnerCount == 0) {
        // No other learners, use default
        learnerTileWidth = 450.0;
      } else {
        // Calculate width to fit all learners if possible
        final idealWidth = 450.0;
        final totalIdealWidth = remainingLearnerCount * (idealWidth + 12); // Include spacing
        
        if (availableWidth >= 1800 && totalIdealWidth <= availableWidth) {
          // Wide screen: use ideal width (450px)
          learnerTileWidth = idealWidth;
        } else {
          // Shrink to fit all visible, but maintain minimum readable size
          final calculatedWidth = (availableWidth - (remainingLearnerCount + 1) * 12) / remainingLearnerCount;
          learnerTileWidth = calculatedWidth.clamp(250.0, 450.0); // Min 250px, max 450px
        }
      }
      
      // Calculate strip height based on 16:9 ratio
      final learnerTileHeight = learnerTileWidth / (16 / 9);
      final stripPadding = 16.0;
      final learnerStripHeight = learnerTileHeight + stripPadding;
      
      // Calculate remaining space for trainer + enlarged learner
      final videoAreaHeight = availableHeight - learnerStripHeight - spacing;
      
      return Column(
        children: [
          // Side-by-side trainer and enlarged learner
          SizedBox(
            height: videoAreaHeight,
            child: Row(
              children: [
                // Trainer view (left side)
                Expanded(
                  child: TrainerSelfView(
                    livestreamId: widget.liveStreamId,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Enlarged learner view (right side)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedLearnerId = null),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF4D00),
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildLearnerVideo(participant),
                          ),
                          
                          // Exit button
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.fullscreen_exit, color: Colors.white, size: 20),
                                  SizedBox(width: 4),
                                  Text('Click to exit', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                          
                          // Learner name
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                participant.name ?? 'Learner',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: spacing),
          
          // Learner strip with DYNAMIC tile width
          Container(
            height: learnerStripHeight,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: LearnerGridView(
              livestreamId: widget.liveStreamId,
              selectedLearnerId: _selectedLearnerId,
              onLearnerTap: (learnerId) {
                setState(() => _selectedLearnerId = learnerId);
              },
              isHorizontalStrip: true,
              showTrainerControls: true,
              stripTileWidth: learnerTileWidth, // PASS DYNAMIC WIDTH
            ),
          ),
        ],
      );
    },
  );
}

Widget _buildDefaultGridView() {
  final roomState = ref.watch(roomProvider);
  
  // Count learners with video (same logic as LearnerGridView)
  final learnersWithVideo = roomState.remoteParticipants.where((participant) {
    final metadata = participant.metadata;
    if (metadata == null || metadata.isEmpty) return false;
    
    try {
      final meta = json.decode(metadata);
      final role = meta['role'];
      if (role == 'learner') {
        final videoPublication = participant.videoTrackPublications.firstOrNull;
        return videoPublication != null && 
               videoPublication.track != null &&
               !(videoPublication.muted ?? true);
      }
      return false;
    } catch (e) {
      return false;
    }
  }).length;
  
  // If 3+ learners with video, use calculated heights for 2 rows
  if (learnersWithVideo >= 3) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;
        final spacing = 16.0;
        
        // Calculate number of rows needed (3-4 learners = 2 rows)
        final rowsNeeded = (learnersWithVideo / 2).ceil();
        
        // Cap learner video width at 450px max
        final maxVideoWidth = 450.0;
        final calculatedVideoWidth = (availableWidth - spacing) / 2;
        final videoWidth = calculatedVideoWidth < maxVideoWidth ? calculatedVideoWidth : maxVideoWidth;
        
        // Calculate video height based on 16:9 ratio
        final videoHeight = videoWidth / (16 / 9);
        final slotIndicatorHeight = 44.0;
        final gridPadding = 16.0;
        
        // Calculate learner section height for ACTUAL rows needed
        final learnerSectionHeight = slotIndicatorHeight + 
                                     (rowsNeeded * videoHeight) + 
                                     ((rowsNeeded - 1) * spacing) + 
                                     gridPadding;
        
        // Trainer gets remaining space
        final trainerHeight = availableHeight - learnerSectionHeight - spacing;
        
        // Ensure trainer doesn't get too small (min 30%)
        final minTrainerHeight = availableHeight * 0.30;
        
        if (trainerHeight < minTrainerHeight) {
          final adjustedTrainerHeight = minTrainerHeight;
          final adjustedLearnerHeight = availableHeight - adjustedTrainerHeight - spacing;
          
          return Column(
            children: [
              SizedBox(
                height: adjustedTrainerHeight,
                child: TrainerSelfView(
                  livestreamId: widget.liveStreamId,
                ),
              ),
              
              SizedBox(height: spacing),
              
              SizedBox(
                height: adjustedLearnerHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      VideoSlotIndicator(
                        livestreamId: widget.liveStreamId,
                        isMobile: false,
                        isTrainer: true,
                        backgroundColor: Colors.grey[900],
                      ),
                      
                      Expanded(
                        child: LearnerGridView(
                          livestreamId: widget.liveStreamId,
                          showTrainerControls: true,
                          onLearnerTap: (learnerId) {
                            setState(() {
                              _selectedLearnerId = learnerId;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        
        // Normal case: both fit comfortably
        return Column(
          children: [
            SizedBox(
              height: trainerHeight,
              child: TrainerSelfView(
                livestreamId: widget.liveStreamId,
              ),
            ),
            
            SizedBox(height: spacing),
            
            SizedBox(
              height: learnerSectionHeight,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    VideoSlotIndicator(
                      livestreamId: widget.liveStreamId,
                      isMobile: false,
                      isTrainer: true,
                      backgroundColor: Colors.grey[900],
                    ),
                    
                    Expanded(
                      child: LearnerGridView(
                        livestreamId: widget.liveStreamId,
                        showTrainerControls: true,
                        onLearnerTap: (learnerId) {
                          setState(() {
                            _selectedLearnerId = learnerId;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // For 1-2 learners, use flexible layout (only 1 row needed)
  return Column(
    children: [
      Expanded(
        flex: 3,
        child: TrainerSelfView(
          livestreamId: widget.liveStreamId,
        ),
      ),
      const SizedBox(height: 16),
      
      Expanded(
        flex: 2,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(12),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              VideoSlotIndicator(
                livestreamId: widget.liveStreamId,
                isMobile: false,
                isTrainer: true,
                backgroundColor: Colors.grey[900],
              ),
              
              Expanded(
                child: LearnerGridView(
                  livestreamId: widget.liveStreamId,
                  showTrainerControls: true,
                  onLearnerTap: (learnerId) {
                    setState(() {
                      _selectedLearnerId = learnerId;
                    });
                  },
                ),
              ),
            ],
          ),
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
          // Left side - Video area
          Expanded(
            flex: 7,
            child: Column(
              children: [
                // Header
                _buildHeader(),
                
                // Main video area with overlay
                Expanded(
                  child: Stack(
                    children: [
                      // Video content
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _selectedLearnerId != null
                            ? _buildSideBySideView()
                            : _buildDefaultGridView(),
                      ),
                      
                      // Gift summary overlay (top left of trainer video)
                      Positioned(
                        top: 24,
                        left: 24,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: GiftSummaryWidget(
                            livestreamId: widget.liveStreamId,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Waitlist - Only show if there are learners waiting
                if (ref.watch(waitlistProvider(widget.liveStreamId)).isNotEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      border: Border(
                        top: BorderSide(color: Colors.grey[800]!),
                      ),
                    ),
                    child: WaitlistWidget(livestreamId: widget.liveStreamId),
                  ),
              
              ],
            ),
          ),
          
          // Right side - Info panels
          Container(
            width: 380,
            decoration: BoxDecoration(
              color: const Color(0xFF242424),
              border: Border(
                left: BorderSide(color: Colors.grey[800]!),
              ),
            ),
            child: Column(
              children: [
                // Stream info
                if (_showInfo)
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[800]!),
                      ),
                    ),
                    child: StreamInfoPanel(livestreamId: widget.liveStreamId),
                  ),
                
                // Chat - expanded to fill remaining space
                Expanded(
                  child: ChatWidget(livestreamId: widget.liveStreamId),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // Grade request notification
      GradeRequestNotification(livestreamId: widget.liveStreamId),

       // Gift animation overlay
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




Widget _buildMobileLayout() {
  final waitlistCount = ref.watch(waitlistProvider(widget.liveStreamId)).length;
  
  return Stack(
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,  // Ensures content fills screen
              ),
              child: Column(
                children: [
                  // Header
                  _buildHeader(isMobile: true),
                  
                 // Trainer video with viewer tally overlay
LayoutBuilder(
  builder: (context, constraints) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Calculate width-based height
    final baseHeight = screenWidth / (16 / 9);
    final widthBasedHeight = baseHeight * 1.4;
    
    // Calculate minimum learner section height (for one row of 2x2 grid)
    final tileWidth = (screenWidth - 16 - 8) / 2;  // 2 columns with spacing
    final tileHeight = tileWidth / (16 / 9);
    final minLearnerSectionHeight = 28 + tileHeight + 16;  // slot indicator + tile + padding
    
    // Calculate max available height for trainer video
    // Reserve space for: header (60) + learner section + collapsed chat (60) + spacing (20)
    final maxAvailableHeight = screenHeight - 60 - minLearnerSectionHeight - 60 - 20;
    
    // Use the smaller of width-based or max available
    final videoHeight = widthBasedHeight < maxAvailableHeight 
        ? widthBasedHeight 
        : maxAvailableHeight;
    
    return SizedBox(
  height: videoHeight,
  child: Stack(
    children: [
      TrainerSelfView(
        livestreamId: widget.liveStreamId,
      ),
      
      // Gift summary overlay (top left)
      Positioned(
        top: 12,
        left: 12,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(10),
          ),
          child: GiftSummaryWidget(
            livestreamId: widget.liveStreamId,
          ),
        ),
      ),
      
      // Viewer tally overlay (top right)
      Positioned(
        top: 12,
        right: 12,
        child: ViewerTallyWidget(livestreamId: widget.liveStreamId, isMobile: true),
      ),
    ],
  ),
);
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Learner grid - dynamic height based on learner count
                  Builder(
                    builder: (context) {
                      final roomState = ref.watch(roomProvider);
                      
                      // Count learners with video
                      final learnerCount = roomState.remoteParticipants.where((participant) {
                        final metadata = participant.metadata;
                        if (metadata == null || metadata.isEmpty) return false;
                        
                        try {
                          final meta = json.decode(metadata);
                          final role = meta['role'];
                          if (role == 'learner') {
                            final videoPublication = participant.videoTrackPublications.firstOrNull;
                            return videoPublication != null && 
                                   videoPublication.track != null &&
                                   !(videoPublication.muted ?? true);
                          }
                          return false;
                        } catch (e) {
                          return false;
                        }
                      }).length;
                      
                      // Calculate dynamic height
                      final slotIndicatorHeight = 28.0;
                      final screenWidth = MediaQuery.of(context).size.width;
                      final tileWidth = (screenWidth - 24) / 2;
                      final tileHeight = tileWidth / (16 / 9);
                      final spacing = 8.0;
                      
                      double gridHeight;
                      if (learnerCount == 0) {
                        gridHeight = tileHeight + 16;
                      } else if (learnerCount <= 2) {
                        gridHeight = tileHeight + 16;
                      } else {
                        gridHeight = (tileHeight * 2) + spacing + 16;
                      }
                      
                      final totalHeight = slotIndicatorHeight + gridHeight;
                      
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                          height: totalHeight,
                          decoration: BoxDecoration(
                            color: Colors.grey[900],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              VideoSlotIndicator(
                                livestreamId: widget.liveStreamId,
                                isMobile: true,
                                isTrainer: true,
                                backgroundColor: Colors.grey[900],
                              ),
                              
                              SizedBox(
                                height: gridHeight,
                                child: learnerCount > 0
                                    ? LearnerGridView(
                                        livestreamId: widget.liveStreamId,
                                        isMobile: true,
                                        showRoundedCorners: false,
                                        showTrainerControls: true,
                                      )
                                    : const Center(
                                        child: Text(
                                          'Waiting for learners to join...',
                                          style: TextStyle(color: Colors.white54),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  
                  // Spacer to push content above chat
                  SizedBox(height: _showChat ? 330 : 60),
                ],
              ),
            ),
          );
        },
      ),
      
      // Chat panel - semi-transparent gradient, overlays bottom of learner grid
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          height: _showChat ? 330 : 60,
          decoration: BoxDecoration(
            color: _showChat 
                ? Colors.transparent
                : const Color(0xFF242424),
          ),
          child: Column(
            children: [
              GestureDetector(
                onTap: () => setState(() => _showChat = !_showChat),
                child: Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  color: _showChat ? Colors.transparent : null,
                  child: Row(
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
                      const Spacer(),
                      Icon(
                        _showChat ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
              
              if (_showChat)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          const Color(0xFF242424).withOpacity(0.95),
                          const Color(0xFF242424).withOpacity(0.85),
                          const Color(0xFF242424).withOpacity(0.60),
                          const Color(0xFF242424).withOpacity(0.30),
                        ],
                        stops: const [0.0, 0.3, 0.7, 1.0],
                      ),
                    ),
                    child: ChatWidget(
                      livestreamId: widget.liveStreamId,
                      isMobile: true,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      
      GradeRequestNotification(livestreamId: widget.liveStreamId),
      
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


      if (ref.watch(waitlistProvider(widget.liveStreamId)).length > 0)
        Positioned(
          bottom: _showChat ? 350 : 80,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _showWaitlistDialog(),
            backgroundColor: const Color(0xFFFF4D00),
            icon: const Icon(Icons.people),
            label: Text('Waitlist ($waitlistCount)'),
          ),
        ),
    ],
  );
}

  Widget _buildHeader({bool isMobile = false}) {  // ✅ Add parameter
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
            streamState.livestream?.title ?? '60min Leg Workout',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        
        // Viewer count - only show on desktop
        if (!isMobile) ViewerTallyWidget(livestreamId: widget.liveStreamId),  // ✅ Conditional
        if (!isMobile) const SizedBox(width: 8),  // ✅ Conditional
        
        // Action buttons
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: () => _showShareDialog(streamState.livestream?.trainer?.username),
          padding: EdgeInsets.zero,  // ✅ Remove padding
          constraints: const BoxConstraints(),  // ✅ Remove constraints
        ),
        const SizedBox(width: 8),
        
        // End live button
        if (streamState.isOwner)
          ElevatedButton(
            onPressed: () => _confirmEndStream(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),  // ✅ Reduce padding
            ),
            child: const Text(
              'END LIVE',
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold,
                fontSize: 12,  // ✅ Reduce font size
              ),
            ),
          ),
      ],
    ),
  );
}

 void _showShareDialog(String? trainerUsername) {
  final username = trainerUsername ?? 'live';
  
  print('🔍 DEBUG - trainerUsername: $username');
  
  showDialog(
    context: context,
    builder: (context) => ShareDialog(
      livestreamId: widget.liveStreamId,
      trainerUsername: username,
    ),
  );
}

  void _showWaitlistDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF242424),
        child: Container(
          width: 400,
          height: 500,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Live Waitlist',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(color: Colors.grey),
              Expanded(
                child: WaitlistWidget(
                  livestreamId: widget.liveStreamId,
                  isDialog: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmEndStream() {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF242424),
      title: const Text(
        'End Live Stream?',
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        'Are you sure you want to end this live stream? This action cannot be undone.',
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
        ),
        ElevatedButton(
          onPressed: () async {
            // ✅ Capture the navigator BEFORE closing dialog
            final navigator = Navigator.of(context);
            final router = GoRouter.of(context);
            
            // Close the confirmation dialog
            navigator.pop();
            
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => WillPopScope(
                onWillPop: () async => false,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4D00)),
                  ),
                ),
              ),
            );
            
            try {
              print('🛑 Starting end stream process');
              
              // STEP 1: Notify participants FIRST
              print('🛑 Step 1: Notifying participants');
              try {
                await ref.read(roomProvider.notifier).publishData({
                  'event': 'stream_ended',
                  'livestreamId': widget.liveStreamId,
                  'timestamp': DateTime.now().toIso8601String(),
                });
                print('✅ Notification sent');
              } catch (e) {
                print('⚠️ Failed to send notification (non-critical): $e');
              }
              
              // STEP 2: Small delay to ensure message is sent
              await Future.delayed(const Duration(milliseconds: 500));
              
              // STEP 3: Call backend to end stream
              print('🛑 Step 2: Calling backend API');
              await ref.read(liveStreamProvider(widget.liveStreamId).notifier).endStream();
              print('✅ Backend call successful');
              
              // STEP 4: Force close loading dialog
              print('🛑 Step 3: Closing dialogs and navigating');
              if (mounted) {
                navigator.pop(); // Close loading dialog
              }
              
              // STEP 5: Navigate using the captured router
              print('🛑 Step 4: Navigating to dashboard');
              router.go('/trainer-dashboard');
              print('✅ Navigation complete');
              
            } catch (e, stackTrace) {
              print('❌ Error ending stream: $e');
              print('❌ Stack trace: $stackTrace');
              
              // Force close loading dialog
              if (mounted) {
                try {
                  navigator.pop();
                } catch (e) {
                  print('⚠️ Could not pop loading dialog: $e');
                }
              }
              
              // Show error and navigate anyway
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Stream ended but with errors: $e'),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
              
              // Navigate anyway after a short delay
              await Future.delayed(const Duration(milliseconds: 500));
              router.go('/trainer-dashboard');
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('End Stream', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}



// Add this helper method to build learner video
Widget _buildLearnerVideo(RemoteParticipant participant) {
  VideoTrack? videoTrack;
  final videoPublication = participant.videoTrackPublications.firstOrNull;
  
  if (videoPublication != null && videoPublication.track != null) {
    videoTrack = videoPublication.track as VideoTrack;
  }
  
  if (videoTrack != null) {
    return VideoTrackRenderer(
  videoTrack,
  fit: VideoViewFit.contain,
);
  }
  
  // No video - show placeholder
  return Container(
    color: Colors.grey[900],
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey[800],
            child: Text(
              participant.name?.substring(0, 1).toUpperCase() ?? 'L',
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            participant.name ?? 'Learner',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
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
    
    Timer(Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showGiftAnimation = false);
      }
    });
  }



@override
void dispose() {
  _giftSubscription?.cancel();
  super.dispose();
}



}