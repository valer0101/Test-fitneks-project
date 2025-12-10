import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/live_stream_provider.dart';
import '../../utils/equipment_utils.dart';
import '../../models/livestream_model.dart';
import '../../app_theme.dart';

class StreamInfoPanel extends ConsumerStatefulWidget {
  final String livestreamId;

  const StreamInfoPanel({
    super.key,
    required this.livestreamId,
  });

  @override
  ConsumerState<StreamInfoPanel> createState() => _StreamInfoPanelState();
}

class _StreamInfoPanelState extends ConsumerState<StreamInfoPanel> {
  late DateTime _startTime;
  String _duration = '00:00';

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _updateDuration();
  }

  void _updateDuration() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final elapsed = DateTime.now().difference(_startTime);
        setState(() {
          _duration = '${elapsed.inMinutes.toString().padLeft(2, '0')}:'
              '${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
        });
        _updateDuration();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final streamState = ref.watch(liveStreamProvider(widget.livestreamId));
    final livestream = streamState.livestream;

    if (livestream == null) return const SizedBox.shrink();

    // Calculate total points
    final musclePoints = livestream.musclePoints;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Duration
          Row(
            children: [
              const Icon(Icons.timer, color: AppTheme.primaryOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                _duration,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

// ✅ ADD THIS ENTIRE BLOCK HERE
          const Text(
            'Workout style:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryOrange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.primaryOrange.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getWorkoutStyleIcon(livestream.workoutStyle),
                  color: AppTheme.primaryOrange,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatWorkoutStyleName(livestream.workoutStyle),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Equipment needed
          const Text(
            'What you will need:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),

// Equipment chips with icons and better spacing
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: livestream.equipmentNeeded.map((equipment) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    EquipmentUtils.getIconWidgetFromString(
                      equipment.toString(),
                      size: 14,
                      color: AppTheme.primaryOrange,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      EquipmentUtils.formatStringName(equipment.toString()),
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 14), // Added spacing after equipment

          // Points breakdown
          const Text(
            'What points you get:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),

          // Muscle group bars
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...musclePoints.entries.where((e) => e.value > 0).map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 35,
                        child: Text(
                          entry.key.substring(0, 3).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 25,
                        child: Text(
                          '${entry.value}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: entry.value / 5,
                          backgroundColor: Colors.grey[800],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppTheme.primaryOrange),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getWorkoutStyleIcon(dynamic style) {
    return EquipmentUtils.getWorkoutStyleIconFromString(style.toString());
  }

  String _formatWorkoutStyleName(dynamic style) {
    return EquipmentUtils.formatWorkoutStyleName(style.toString());
  }
}
