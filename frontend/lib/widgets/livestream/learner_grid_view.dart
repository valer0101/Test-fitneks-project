import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import '../../providers/live_stream_provider.dart';
import 'learner_participant_tile.dart';

/// LearnerGridView - For Trainer's desktop view
/// Displays learners in a 2x2 grid layout
class LearnerGridView extends ConsumerStatefulWidget {
  final String livestreamId;
  final bool isMobile;
  final String? selectedLearnerId;
  final Function(String)? onLearnerTap;
  final bool isHorizontalStrip;
  final bool showRoundedCorners;  
  final bool showTrainerControls;
  final double? stripTileWidth;
  
  const LearnerGridView({
    Key? key,
    required this.livestreamId,
    this.isMobile = false,
    this.selectedLearnerId,
    this.onLearnerTap,
    this.isHorizontalStrip = false,
    this.showRoundedCorners = true,
    this.showTrainerControls = false,
    this.stripTileWidth,
  }) : super(key: key);

  @override
  ConsumerState<LearnerGridView> createState() => _LearnerGridViewState();
}

class _LearnerGridViewState extends ConsumerState<LearnerGridView> {
  EventsListener<RoomEvent>? _roomListener;
  
  @override
  void initState() {
    super.initState();
    print('🎬 LearnerGridView initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRoomListeners();
    });
  }
  
  @override
  void dispose() {
    print('🎬 LearnerGridView disposing listeners');
    _roomListener?.dispose();
    super.dispose();
  }
  
  void _setupRoomListeners() {
    final roomState = ref.read(roomProvider);
    final room = roomState.room;
    
    if (room == null) {
      print('❌ LearnerGridView: Room is null, cannot setup listeners');
      return;
    }
    
    print('✅ LearnerGridView: Setting up room listeners');
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
      borderRadius: widget.showRoundedCorners  // ✅ Conditional
          ? BorderRadius.circular(12) 
          : null,
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
      // Use dynamic width if provided, otherwise default to 450
      final tileWidth = widget.stripTileWidth ?? 450.0;
      final totalWidth = displayParticipants.length * (tileWidth + 12);
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
                width: tileWidth,  // Use dynamic width  // Was 200, now 300 (50% bigger)
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: LearnerParticipantTile(
                      participant: participant,
                      index: index,
                      livestreamId: widget.livestreamId,
                      isMobile: widget.isMobile,
                      selectedLearnerId: widget.selectedLearnerId,
                      onLearnerTap: widget.onLearnerTap,
                      showFullscreenIcon: false,
                      showTrainerControls: widget.showTrainerControls,
                    ),
                  );
                }).toList(),
              ),
            ),
          );
        },
      );
    }

    // Mobile 2x2 grid for trainers, horizontal scroll for learners
if (widget.isMobile) {
  // If trainer controls enabled, show 2x2 grid
  if (widget.showTrainerControls) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;
        final availableWidth = constraints.maxWidth;
        
        // Calculate tile size - 2 columns, maintain 16:9 ratio
        final spacing = 8.0;
        final tileWidth = (availableWidth - spacing - 16) / 2;  // 2 tiles per row, minus spacing and padding
        final tileHeight = tileWidth / (16 / 9);
        
        // Split participants into rows of 2
        final List<List<RemoteParticipant>> rows = [];
        for (var i = 0; i < displayParticipants.length; i += 2) {
          rows.add(displayParticipants.sublist(
            i, 
            i + 2 > displayParticipants.length ? displayParticipants.length : i + 2
          ));
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: rows.asMap().entries.map((rowEntry) {
              final rowIndex = rowEntry.key;
              final rowParticipants = rowEntry.value;
              
              return Container(
                height: tileHeight,
                margin: EdgeInsets.only(
                  bottom: rowIndex < rows.length - 1 ? spacing : 0,
                ),
                child: Row(
                  children: rowParticipants.asMap().entries.map((entry) {
                    final index = entry.key + (rowIndex * 2);
                    final participant = entry.value;
                    
                    return Container(
                      width: tileWidth,
                      height: tileHeight,
                      margin: EdgeInsets.only(
                        right: entry.key < rowParticipants.length - 1 ? spacing : 0,
                      ),
                      child: LearnerParticipantTile(
                        participant: participant,
                        index: index,
                        livestreamId: widget.livestreamId,
                        isMobile: widget.isMobile,
                        selectedLearnerId: widget.selectedLearnerId,
                        onLearnerTap: widget.onLearnerTap,
                        showFullscreenIcon: false,
                        showTrainerControls: widget.showTrainerControls,
                      ),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
  
  // Otherwise, horizontal scroll for learners
  return ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: displayParticipants.length,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    itemBuilder: (context, index) {
      return Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: LearnerParticipantTile(
          participant: displayParticipants[index],
          index: index,
          livestreamId: widget.livestreamId,
          isMobile: widget.isMobile,
          selectedLearnerId: widget.selectedLearnerId,
          onLearnerTap: widget.onLearnerTap,
          showFullscreenIcon: false,
          showTrainerControls: widget.showTrainerControls,  
        ),
      );
    },
  );
}

    // Desktop 2x2 grid (default for trainers)
    // Desktop 2x2 grid (default for trainers) - vertically scrollable
  // Desktop 2x2 grid (default for trainers) - vertically scrollable
return LayoutBuilder(
  builder: (context, constraints) {
    final availableHeight = constraints.maxHeight;
    final availableWidth = constraints.maxWidth;
    
    final spacing = 8.0;
    final padding = 8.0;
    
    // Determine how many rows we need based on participant count
    final rowsNeeded = displayParticipants.length <= 2 ? 1 : 2;
    
    // Calculate tile dimensions that fit both width AND height constraints
    // Option 1: Size based on height (conditional on rows needed)
    final heightBasedTileHeight = rowsNeeded == 1 
        ? (availableHeight - (padding * 2)) // Full height for 1 row
        : ((availableHeight - (padding * 2) - spacing) / 2); // Half height for 2 rows
    final heightBasedTileWidth = heightBasedTileHeight * (16 / 9);
    
    // Option 2: Size based on width (2 tiles + spacing must fit)
    final widthBasedTileWidth = (availableWidth - (padding * 2) - spacing) / 2;
    final widthBasedTileHeight = widthBasedTileWidth / (16 / 9);
    
    // Use whichever is SMALLER to ensure no overflow
    final calculatedTileWidth = heightBasedTileWidth <= widthBasedTileWidth 
        ? heightBasedTileWidth 
        : widthBasedTileWidth;
    
    // Cap at 450px max to prevent tiles from being too large
    final maxTileWidth = 450.0;
    final tileWidth = calculatedTileWidth < maxTileWidth ? calculatedTileWidth : maxTileWidth;
    final tileHeight = tileWidth / (16 / 9);
    
    // 2 tiles per row with spacing
    final totalRowWidth = (tileWidth * 2) + spacing;
    
    // Center horizontally if row doesn't fill width
    final horizontalPadding = totalRowWidth < availableWidth 
        ? (availableWidth - totalRowWidth) / 2 
        : 8.0;
    
    // Split participants into rows of 2
    final List<List<RemoteParticipant>> rows = [];
    for (var i = 0; i < displayParticipants.length; i += 2) {
      rows.add(displayParticipants.sublist(
        i, 
        i + 2 > displayParticipants.length ? displayParticipants.length : i + 2
      ));
    }
    
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
      child: Column(
        children: rows.asMap().entries.map((rowEntry) {
          final rowIndex = rowEntry.key;
          final rowParticipants = rowEntry.value;
          
          return Container(
            height: tileHeight,
            margin: EdgeInsets.only(
              bottom: rowIndex < rows.length - 1 ? 8 : 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: rowParticipants.asMap().entries.map((entry) {
                final index = entry.key + (rowIndex * 2);
                final participant = entry.value;
                
                return Container(
                  width: tileWidth,
                  height: tileHeight,
                  margin: EdgeInsets.only(
                    right: entry.key < rowParticipants.length - 1 ? 8 : 0,
                  ),
                  child: LearnerParticipantTile(
                    participant: participant,
                    index: index,
                    livestreamId: widget.livestreamId,
                    isMobile: widget.isMobile,
                    selectedLearnerId: widget.selectedLearnerId,
                    onLearnerTap: widget.onLearnerTap,
                    showFullscreenIcon: widget.onLearnerTap != null,
                    showTrainerControls: widget.showTrainerControls,
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  },
);
  }
}