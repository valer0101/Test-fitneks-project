import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app_theme.dart';
import '../../../providers/create_stream_provider.dart';

class MuscleFocusPage extends ConsumerWidget {
  final PageController pageController;

  const MuscleFocusPage({
    super.key,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createStreamProvider);
    final notifier = ref.read(createStreamProvider.notifier);

    final muscleGroups = [
      {'key': 'arms', 'label': 'Arms', 'icon': Icons.sports_handball},
      {'key': 'chest', 'label': 'Chest', 'icon': Icons.favorite},
      {'key': 'back', 'label': 'Back', 'icon': Icons.straighten},
      {'key': 'abs', 'label': 'Abs', 'icon': Icons.grid_on},
      {'key': 'legs', 'label': 'Legs', 'icon': Icons.directions_walk},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Muscle Focus & Points',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Set intensity (0-5) for each muscle group. Learners can earn these points during the stream.',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Total points indicator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF4D00).withOpacity(0.1),
                  const Color(0xFFFF4D00).withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppTheme.primaryOrange.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Points Available',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Maximum points learners can earn',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryOrange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${state.totalPossiblePoints}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Muscle group sliders
          Text(
            'Set Points per Muscle Group',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: muscleGroups.length,
            separatorBuilder: (context, index) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final group = muscleGroups[index];
              final key = group['key'] as String;
              final label = group['label'] as String;
              final icon = group['icon'] as IconData;
              final value = state.musclePoints[key] ?? 0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: value > 0
                              ? AppTheme.primaryOrange.withOpacity(0.1)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          icon,
                          size: 24,
                          color: value > 0
                              ? AppTheme.primaryOrange
                              : Colors.grey[400],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              value == 0
                                  ? 'No focus'
                                  : '${_getIntensityLabel(value)} intensity',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: value > 0
                              ? AppTheme.primaryOrange
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stars,
                              size: 16,
                              color:
                                  value > 0 ? Colors.white : Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$value pts',
                              style: TextStyle(
                                color:
                                    value > 0 ? Colors.white : Colors.black54,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppTheme.primaryOrange,
                      inactiveTrackColor: Colors.grey[300],
                      thumbColor: AppTheme.primaryOrange,
                      overlayColor: AppTheme.primaryOrange.withOpacity(0.2),
                      trackHeight: 8,
                      thumbShape:
                          const RoundSliderThumbShape(enabledThumbRadius: 12),
                      tickMarkShape:
                          const RoundSliderTickMarkShape(tickMarkRadius: 4),
                      activeTickMarkColor: Colors.white,
                      inactiveTickMarkColor: Colors.grey[400],
                    ),
                    child: Slider(
                      value: value.toDouble(),
                      min: 0,
                      max: 5,
                      divisions: 5,
                      label: '$value',
                      onChanged: (newValue) {
                        notifier.updateMusclePoint(key, newValue.round());
                      },
                    ),
                  ),
                  // Visual point indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(6, (i) {
                      return Text(
                        '$i',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              i == value ? FontWeight.bold : FontWeight.normal,
                          color: i <= value
                              ? AppTheme.primaryOrange
                              : Colors.grey[400],
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 32),

          // Points explanation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: Colors.amber[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'How Points Work',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• Learners earn points based on participation time\n'
                  '• 100% participation = full points for each muscle group\n'
                  '• Points are added to their muscle group totals',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber[800],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getIntensityLabel(int value) {
    switch (value) {
      case 1:
        return 'Light';
      case 2:
        return 'Moderate';
      case 3:
        return 'Medium';
      case 4:
        return 'Intense';
      case 5:
        return 'Maximum';
      default:
        return 'None';
    }
  }
}
