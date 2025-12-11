import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/live_stream_provider.dart';
import '../../utils/equipment_utils.dart';
import '../../models/event_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../calendar/event_detail_card.dart';
import '../../providers/trainer_upcoming_streams_provider.dart';
import '../../app_theme.dart';


/// Displays detailed trainer and workout information
/// Shows trainer profile, equipment, muscle groups, and schedule
class TrainerInfoPanel extends ConsumerWidget {
  final String livestreamId;

  const TrainerInfoPanel({
    Key? key,
    required this.livestreamId,
  }) : super(key: key);

  @override
Widget build(BuildContext context, WidgetRef ref) {
  final liveStreamState = ref.watch(liveStreamProvider(livestreamId));
  final livestream = liveStreamState.livestream;

  // Show loading while fetching data
  if (livestream == null) {
    return Container(
      color: Color(0xFF1A1A1A),
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryOrange,
        ),
      ),
    );
  }

  // Try to get trainer from livestream, or use trainerId
  final trainer = _getTrainerData(livestream);

  return Container(
    color: Color(0xFF1A1A1A),
    child: SingleChildScrollView(
    padding: EdgeInsets.only(right: 16, top: 16, bottom: 16),  // ✅ No left padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SECTION 2: Stream Description
          _buildStreamDescription(context, livestream),
          SizedBox(height: 16),

          _buildWorkoutStyleSection(context, livestream),
          SizedBox(height: 16),

          // SECTION 3: Required Equipment
          _buildEquipmentSection(context, livestream),
          SizedBox(height: 16),

          // SECTION 4: Muscle Groups & Intensity
          _buildMuscleGroupsSection(context, livestream),
          SizedBox(height: 16),

          // SECTION 5: Schedule Calendar
          _buildScheduleSection(context, trainer, ref),
        ],
      ),
    ),
  );
}



Map<String, dynamic> _getTrainerData(dynamic livestream) {
  print('🔍 DEBUG _getTrainerData - livestream type: ${livestream.runtimeType}');
  
  try {
    final trainer = livestream.trainer;
    print('🔍 DEBUG trainer object: $trainer');
    
    if (trainer != null) {
      final trainerId = (trainer as dynamic).id;
      print('🔍 DEBUG extracted trainerId: $trainerId');
      
      // Build map with only properties that exist
      final trainerMap = <String, dynamic>{
        'id': trainerId,
      };
      
      // Try to add optional properties
      try { trainerMap['displayName'] = (trainer as dynamic).displayName; } catch (e) {}
      try { trainerMap['username'] = (trainer as dynamic).username; } catch (e) {}
      try { trainerMap['xp'] = (trainer as dynamic).xp; } catch (e) {}
      try { trainerMap['profilePictureUrl'] = (trainer as dynamic).profilePictureUrl; } catch (e) {}
      
      // Set defaults for missing properties
      trainerMap['displayName'] ??= trainerMap['username'] ?? 'Trainer';
      trainerMap['xp'] ??= 0;
      trainerMap['subscriberCount'] = 0; // Not available from API
      trainerMap['profilePictureUrl'] ??= null;
      
      print('🔍 DEBUG returning trainer map: $trainerMap');
      return trainerMap;
    }
  } catch (e) {
    print('❌ DEBUG error extracting trainer: $e');
  }
  
  return {
    'id': null,
    'displayName': 'Trainer',
    'xp': 0,
    'subscriberCount': 0,
    'profilePictureUrl': null,
  };
}

  /// SECTION 1: Trainer Profile Card
Widget _buildTrainerProfile(BuildContext context, Map<String, dynamic> trainer, dynamic livestream) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Color(0xFF2C2C2E),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        // Profile picture
        CircleAvatar(
          radius: 40,
          backgroundColor: Color(0xFFFF4D00),
          backgroundImage: trainer['profilePictureUrl'] != null
              ? NetworkImage(trainer['profilePictureUrl'])
              : null,
          child: trainer['profilePictureUrl'] == null
              ? Icon(Icons.person, size: 40, color: Colors.white)
              : null,
        ),
        SizedBox(height: 12),
        
        // Trainer name - More Prominent
        Text(
          trainer['displayName'] ?? trainer['username'] ?? 'Trainer',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        
        // XP points
        Text(
          '${trainer['xp'] ?? 0} XP',
          style: TextStyle(
            color: AppTheme.primaryOrange,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        
        // Subscriber count
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 16, color: Color(0xFFA9A9A9)),
            SizedBox(width: 4),
            Text(
              '${trainer['subscriberCount'] ?? 0} subscribers',
              style: TextStyle(color: Color(0xFFA9A9A9), fontSize: 14),
            ),
          ],
        ),
        SizedBox(height: 16),
        
        // Subscribe button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Implement subscription logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Subscription coming soon!'),
                  backgroundColor: Color(0xFFFF4D00),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF4D00),
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'SUBSCRIBE',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}

  /// SECTION 2: Stream Description
  Widget _buildStreamDescription(BuildContext context, dynamic livestream) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About This Stream',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            livestream.description ?? 'No description available',
            style: TextStyle(
              color: Color(0xFFA9A9A9),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }


Widget _buildWorkoutStyleSection(BuildContext context, dynamic livestream) {
  final workoutStyle = livestream.workoutStyle;
  
  if (workoutStyle == null) {
    return SizedBox.shrink();
  }

  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Color(0xFF2C2C2E),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Workout Style',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12),
        Container(
  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),  // ✅ Changed from 16, 12
  decoration: BoxDecoration(
    color: Color(0xFFFF4D00).withOpacity(0.2),
    borderRadius: BorderRadius.circular(20),  // ✅ Changed from 16
    border: Border.all(
      color: Color(0xFFFF4D00).withOpacity(0.3),
    ),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        _getWorkoutStyleIcon(workoutStyle),
        color: Color(0xFFFF4D00),
        size: 16,  // ✅ Changed from 24
      ),
      SizedBox(width: 6),  // ✅ Changed from 12
      Text(
        _formatWorkoutStyleName(workoutStyle),
        style: TextStyle(
          fontSize: 12,  // ✅ Changed from 16
          color: Colors.white,
          fontWeight: FontWeight.w500,  // ✅ Changed from w600
        ),
      ),
    ],
  ),
),
      ],
    ),
  );
}



  /// SECTION 3: Required Equipment
  Widget _buildEquipmentSection(BuildContext context, dynamic livestream) {
    final equipment = livestream.equipmentNeeded ?? [];
    
    if (equipment.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Required Equipment',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _buildEquipmentChips(equipment),
          ),
        ],
      ),
    );
  }

/// Build equipment chips (badges)
List<Widget> _buildEquipmentChips(List<dynamic> equipment) {
  return equipment.map((item) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFFFF4D00).withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFFFF4D00).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          EquipmentUtils.getIconWidgetFromString(
            item.toString(),
            size: 16,
            color: AppTheme.primaryOrange,
          ),
          SizedBox(width: 6),
          Text(
            EquipmentUtils.formatStringName(item.toString()),
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }).toList();
}

  /// SECTION 4: Muscle Groups with Intensity Bars
  Widget _buildMuscleGroupsSection(BuildContext context, dynamic livestream) {
    final musclePoints = livestream.musclePoints;
    
    if (musclePoints == null) {
      return SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Workout Focus',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          _buildIntensityBars(musclePoints),
        ],
      ),
    );
  }

  /// Build intensity bars for each muscle group
  Widget _buildIntensityBars(Map<String, dynamic> musclePoints) {
    // Muscle groups to display
    final muscleGroups = ['arms', 'chest', 'back', 'abs', 'legs'];
    
    return Column(
      children: muscleGroups.map((group) {
        // Get the points value (0-5 scale)
        final points = musclePoints[group] ?? 0;
        final percentage = (points / 5.0).clamp(0.0, 1.0);
        
        // Format name: arms -> Arms
        final displayName = group[0].toUpperCase() + group.substring(1);
        
        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '$points/5',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFA9A9A9),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Color(0xFF3A3A3C),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF4D00)),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// SECTION 5: Upcoming Schedule Calendar with Event Details
Widget _buildScheduleSection(BuildContext context, Map<String, dynamic> trainer, WidgetRef ref) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Color(0xFF2C2C2E),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Streams',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 12),
      _buildInteractiveCalendar(context, trainer, ref),
      ],
    ),
  );
}


Widget _buildInteractiveCalendar(BuildContext context, Map<String, dynamic> trainer, WidgetRef ref) {
  final trainerId = trainer['id']?.toString() ?? '';
  
  if (trainerId.isEmpty) {
    return Center(
      child: Text(
        'Trainer information unavailable',
        style: TextStyle(color: Color(0xFFA9A9A9)),
      ),
    );
  }

  final upcomingStreamsAsync = ref.watch(trainerUpcomingStreamsProvider(trainerId));

  return upcomingStreamsAsync.when(
    data: (upcomingStreams) {
      if (upcomingStreams.isEmpty) {
        return Center(
          child: Text(
            'No upcoming streams scheduled',
            style: TextStyle(color: Color(0xFFA9A9A9)),
          ),
        );
      }

      return Container(
        height: 100,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: upcomingStreams.length > 7 ? 7 : upcomingStreams.length,
          itemBuilder: (context, index) {
            final stream = upcomingStreams[index];
            final date = DateTime.parse(stream['scheduledAt']);
            final now = DateTime.now();
            final isToday = date.year == now.year && 
                            date.month == now.month && 
                            date.day == now.day;
            
            return GestureDetector(
              onTap: () => _showStreamDetailModal(context, stream, ref),
              child: Container(
                width: 70,
                margin: EdgeInsets.only(right: 8),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFFFF4D00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isToday ? Color(0xFFFF4D00) : Color(0xFFFF4D00).withOpacity(0.3),
                    width: isToday ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getDayName(date.weekday),
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryOrange,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      _formatTime(date),
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFFA9A9A9),
                      ),
                    ),
                    SizedBox(height: 4),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
    loading: () => Center(
      child: CircularProgressIndicator(color: Color(0xFFFF4D00)),
    ),
    error: (error, stack) => Center(
      child: Text(
        'No upcoming streams',
        style: TextStyle(color: Color(0xFFA9A9A9)),
      ),
    ),
  );
}

String _getDayName(int weekday) {
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return days[weekday - 1];
}

String _formatTime(DateTime date) {
  final hour = date.hour > 12 ? date.hour - 12 : date.hour;
  final period = date.hour >= 12 ? 'PM' : 'AM';
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute$period';
}

void _showStreamDetailModal(BuildContext context, dynamic streamData, WidgetRef ref) {
  final event = _convertStreamToEvent(streamData);
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      EventDetailCard(
                        event: event,
                        showEditButton: false, // ✅ Hide edit button for learners
                      ),
                      SizedBox(height: 16),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _addToCalendar(context, event, ref),
                          icon: Icon(Icons.calendar_today),
                          label: Text('Add to My Calendar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFFF4D00),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

EventModel _convertStreamToEvent(dynamic streamData) {
  final event = streamData['event'];
  
  return EventModel(
    id: event['id'],
    trainerId: streamData['trainerId'],
    type: EventType.CLASS,
    status: EventStatus.UPCOMING,
    title: streamData['title'],
    date: DateTime.parse(streamData['scheduledAt']),
    maxParticipants: streamData['maxParticipants'],
    ticketValue: streamData['giftRequirement']?.toDouble(),
    equipment: List<String>.from(streamData['equipmentNeeded'] ?? []),
    trainingType: streamData['workoutStyle'],
    pointsBreakdown: Map<String, dynamic>.from(streamData['musclePoints'] ?? {}),
    duration: 60,
    createdAt: DateTime.parse(event['createdAt']),
    updatedAt: DateTime.parse(event['updatedAt']),
  );
}



Future<void> _addToCalendar(BuildContext context, EventModel event, WidgetRef ref) async {
  try {
    final apiService = ref.read(apiServiceProvider);
    final authState = ref.read(authProvider);
    final token = authState.token;
    
    print('🎯 Adding event to calendar: ${event.id}');
    print('🎯 Token exists: ${token != null}');
    
    if (token == null) {
      throw Exception('Not authenticated');
    }
    
    // Actually call the API to register for the event
    await apiService.addEventToLearnerCalendar(event.id, token);
    
    if (context.mounted) {
      Navigator.of(context).pop(); // Close modal
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stream added to your calendar! You\'ll receive a notification before it starts.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    print('❌ Error adding to calendar: $e');
    print('❌ Error type: ${e.runtimeType}');
    if (e is ApiException) {
      print('❌ API Exception - Status: ${e.statusCode}, Message: ${e.message}');
    }
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add to calendar. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}



IconData _getWorkoutStyleIcon(dynamic workoutStyle) {
  return EquipmentUtils.getWorkoutStyleIconFromString(workoutStyle.toString());
}

String _formatWorkoutStyleName(dynamic workoutStyle) {
  return EquipmentUtils.formatWorkoutStyleName(workoutStyle.toString());
}
}