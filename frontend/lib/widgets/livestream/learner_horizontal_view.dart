import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../providers/live_stream_provider.dart';
import 'learner_participant_tile.dart';

/// LearnerHorizontalView - For Learner's desktop view
/// Displays up to 4 learners in a single horizontal scrollable row
class LearnerHorizontalView extends ConsumerStatefulWidget {
  final String livestreamId;
  final bool isMobile;
  final String? selectedLearnerId;
  final Function(String)? onLearnerTap;
  final bool isHorizontalStrip;
  
  const LearnerHorizontalView({
    super.key,
    required this.livestreamId,
    this.isMobile = false,
    this.selectedLearnerId,
    this.onLearnerTap,
    this.isHorizontalStrip = false,
  });

  @override
  ConsumerState<LearnerHorizontalView> createState() => _LearnerHorizontalViewState();
}

class _LearnerHorizontalViewState extends ConsumerState<LearnerHorizontalView> {
  EventsListener<RoomEvent>? _roomListener;
  
  @override
  void initState() {
    super.initState();
    print('🎬 LearnerHorizontalView initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRoomListeners();
    });
  }
  
  @override
  void dispose() {
    print('🎬 LearnerHorizontalView disposing listeners');
    _roomListener?.dispose();
    super.dispose();
  }
  
  void _setupRoomListeners() {
    final roomState = ref.read(roomProvider);
    final room = roomState.room;
    
    if (room == null) {
      print('❌ LearnerHorizontalView: Room is null, cannot setup listeners');
      return;
    }
    
    print('✅ LearnerHorizontalView: Setting up room listeners');
    _roomListener = room.createListener();
    
    _roomListener!.on<TrackPublishedEvent>((event) {
      print('🎥 Track published: ${event.publication.kind}');
      if (mounted) setState(() {});
    });
    
    _roomListener!.on<ParticipantConnectedEvent>((event) {
      print('👤 Participant connected: ${event.participant.identity}');
      if (mounted) setState(() {});
    });
    
    _roomListener!.on<ParticipantDisconnectedEvent>((event) {
      print('👤 Participant disconnected: ${event.participant.identity}');
      if (mounted) setState(() {});
    });
    
    _roomListener!.on<TrackMutedEvent>((event) {
      print('🔇 Track muted: ${event.participant.identity} - ${event.publication.kind}');
      if (mounted) setState(() {});
    });
    
    _roomListener!.on<TrackUnmutedEvent>((event) {
      print('🔊 Track unmuted: ${event.participant.identity} - ${event.publication.kind}');
      if (mounted) setState(() {});
    });
    
    _roomListener!.on<TrackUnpublishedEvent>((event) {
      print('📹 Track unpublished: ${event.participant.identity} - ${event.publication.kind}');
      if (mounted) setState(() {});
      
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(roomProvider);
    
    // Filter for learner participants with video enabled
    final allLearners = roomState.remoteParticipants.where((participant) {
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
    }).take(4).toList();
    
    // For horizontal strip, filter out the selected learner
    final displayParticipants = widget.isHorizontalStrip && widget.selectedLearnerId != null
        ? allLearners.where((p) => p.sid != widget.selectedLearnerId).toList()
        : allLearners;
    
    if (displayParticipants.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text(
            'Waiting for learners to join...',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      );
    }

    // Horizontal strip mode for enlarged view
    if (widget.isHorizontalStrip) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = displayParticipants.length * 208;
          final needsScroll = totalWidth > constraints.maxWidth;
          
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: needsScroll ? null : const NeverScrollableScrollPhysics(),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: displayParticipants.map((participant) {
                  final index = displayParticipants.indexOf(participant);
                  return Container(
                    width: 200,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: LearnerParticipantTile(
                      participant: participant,
                      index: index,
                      livestreamId: widget.livestreamId,
                      isMobile: widget.isMobile,
                      selectedLearnerId: widget.selectedLearnerId,
                      onLearnerTap: widget.onLearnerTap,
                      showFullscreenIcon: false,
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      );
    }

    // Mobile horizontal scroll
    if (widget.isMobile) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: displayParticipants.length,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemBuilder: (context, index) {
          return Container(
            width: 180, // Increased from 100 to show ~2.5 videos
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: LearnerParticipantTile(
              participant: displayParticipants[index],
              index: index,
              livestreamId: widget.livestreamId,
              isMobile: widget.isMobile,
              selectedLearnerId: widget.selectedLearnerId,
              onLearnerTap: widget.onLearnerTap,
              showFullscreenIcon: false,
            ),
          );
        },
      );
    }

    // Desktop single-row horizontal scroll (default for learners)
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate if we need horizontal scroll
        final availableHeight = constraints.maxHeight;
        final tileWidth = (availableHeight * 16 / 9); // Maintain 16:9 aspect ratio
        final totalWidth = (displayParticipants.length * tileWidth) + 
                          ((displayParticipants.length - 1) * 8); // 8px spacing
        final needsScroll = totalWidth > constraints.maxWidth;
        
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: needsScroll 
              ? const AlwaysScrollableScrollPhysics() 
              : const NeverScrollableScrollPhysics(),
          child: Row(
            children: displayParticipants.asMap().entries.map((entry) {
              final index = entry.key;
              final participant = entry.value;
              
              return Container(
                width: tileWidth,
                height: availableHeight,
                margin: EdgeInsets.only(
                  right: index < displayParticipants.length - 1 ? 8 : 0,
                ),
                child: LearnerParticipantTile(
                  participant: participant,
                  index: index,
                  livestreamId: widget.livestreamId,
                  isMobile: widget.isMobile,
                  selectedLearnerId: widget.selectedLearnerId,
                  onLearnerTap: widget.onLearnerTap,
                  showFullscreenIcon: widget.onLearnerTap != null,
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}