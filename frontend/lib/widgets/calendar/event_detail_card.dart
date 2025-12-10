import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../../models/event_model.dart';
import '../../providers/calendar_provider.dart';
import '../../services/calendar_service.dart';
import 'package:frontend/app_theme.dart';

class EventDetailCard extends ConsumerWidget {
  final EventModel event;
  final bool showEditButton;

  const EventDetailCard({
    super.key,
    required this.event,
    this.showEditButton = true, // ✅ Default to true for backwards compatibility
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetrics(),
          const SizedBox(height: 20),
          _buildEquipmentSection(),
          const SizedBox(height: 20),
          _buildTrainingTypeSection(),
          const SizedBox(height: 20),
          _buildPointsBreakdown(),
          const SizedBox(height: 20),
          _buildBodyHeatmap(),
          const SizedBox(height: 20),
          _buildActionButtons(context, ref),
        ],
      ),
    );
  }

  Widget _buildMetrics() {
    if (event.status == EventStatus.COMPLETED) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            'Duration',
            '${event.duration} min',
            Icons.timer,
          ),
          _buildMetricItem(
            'Gifts',
            event.giftsReceived != null
                ? '\$${event.giftsReceived!.toStringAsFixed(2)}'
                : 'N/A',
            Icons.card_giftcard,
          ),
          _buildMetricItem(
            'XP Earned',
            '${event.xpEarned ?? 0} PTS',
            Icons.star,
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            'Duration',
            '${event.duration} min',
            Icons.timer,
          ),
          _buildMetricItem(
            'Participants',
            '${event.maxParticipants ?? 'Unlimited'}',
            Icons.people,
          ),
          _buildMetricItem(
            'Ticket Value',
            event.ticketValue != null
                ? '\$${event.ticketValue!.toStringAsFixed(2)}'
                : 'Free',
            Icons.confirmation_number,
          ),
        ],
      );
    }
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600], size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildEquipmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Equipment:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: event.equipment.map((equip) {
            // ✅ Variable is 'equip'
            final formattedName = equip
                .replaceAll('_', ' ')
                .toLowerCase()
                .split(' ')
                .map((word) => word.isNotEmpty
                    ? word[0].toUpperCase() + word.substring(1)
                    : '')
                .join(' ');

            return Chip(
              avatar: _getEquipmentIcon(equip), // ✅ Use your method!
              label: Text(
                formattedName,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: Colors.grey[200],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTrainingTypeSection() {
    return Row(
      children: [
        const Text(
          'Training Type: ',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            event.trainingType,
            style: const TextStyle(
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPointsBreakdown() {
    if (event.pointsBreakdown == null) return const SizedBox();

    final points = event.pointsBreakdown!;

    // Find max points to calculate relative intensity
    final maxPoints =
        points.values.map((v) => v as int).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.status == EventStatus.COMPLETED
              ? 'Points you earned:'
              : 'What points you get:',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...points.entries.map((entry) {
          final pointValue = entry.value as int;
          final percentage = (pointValue / 5) * 100; // 5 is max per muscle

          // ✅ Calculate orange intensity based on points
          final orangeColor = _getOrangeIntensity(pointValue, maxPoints);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${entry.value} points',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: orangeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(orangeColor),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

// ✅ Add this new helper method right after _buildPointsBreakdown
  Color _getOrangeIntensity(int points, int maxPoints) {
    if (points == 0) {
      return Colors.grey[300]!;
    }

    // Brand orange base: #FF4D00
    const brandOrange = Color(0xFFFF4D00);

    // Calculate intensity (0.0 - 1.0)
    final intensity = points / 5.0; // 5 is max points per muscle

    // Create gradient from light to dark orange
    if (intensity <= 0.2) {
      // Very light: #FFD4C0
      return const Color(0xFFFFD4C0);
    } else if (intensity <= 0.4) {
      // Light: #FFB088
      return const Color(0xFFFFB088);
    } else if (intensity <= 0.6) {
      // Medium: #FF8C50
      return const Color(0xFFFF8C50);
    } else if (intensity <= 0.8) {
      // Medium-dark: #FF6D28
      return const Color(0xFFFF6D28);
    } else {
      // Full intensity: Brand orange
      return brandOrange;
    }
  }

  Widget _buildBodyHeatmap() {
    if (event.pointsBreakdown == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Muscle Groups:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMannequin(true), // Front view
            _buildMannequin(false), // Back view
          ],
        ),
      ],
    );
  }

  Widget _buildMannequin(bool isFront) {
    final points = event.pointsBreakdown;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // ✅ Icon-based mannequin instead of missing image
          Container(
            width: 120,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Stack(
              children: [
                // Body outline
                Center(
                  child: Icon(
                    Icons.accessibility_new,
                    size: 160,
                    color: Colors.grey[300],
                  ),
                ),
                // Muscle group highlights
                if (points != null) ..._buildMuscleHighlights(points, isFront),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFront ? 'Front' : 'Back',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

// ✅ Add this helper method right after _buildMannequin
  List<Widget> _buildMuscleHighlights(
      Map<String, dynamic> points, bool isFront) {
    List<Widget> highlights = [];

    points.forEach((muscle, value) {
      if (value == 0) return;

      final pointValue = value as int;
      final intensity = pointValue / 5.0; //

      final color = _getOrangeIntensity(pointValue, 5).withOpacity(0.6);

      // Position highlights based on muscle group and view
      Widget? highlight;

      if (isFront) {
        switch (muscle.toLowerCase()) {
          case 'chest':
            highlight = Positioned(
              top: 50,
              left: 30,
              right: 30,
              child: Container(
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            );
            break;
          case 'arms':
            highlight = Positioned(
              top: 45,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 20,
                    height: 50,
                    margin: const EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Container(
                    width: 20,
                    height: 50,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            );
            break;
          case 'abs':
          case 'core':
            highlight = Positioned(
              top: 85,
              left: 35,
              right: 35,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
            break;
          case 'legs':
            highlight = Positioned(
              bottom: 30,
              left: 25,
              right: 25,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 22,
                    height: 70,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 70,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ],
              ),
            );
            break;
        }
      } else {
        // Back view
        switch (muscle.toLowerCase()) {
          case 'back':
            highlight = Positioned(
              top: 45,
              left: 30,
              right: 30,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            );
            break;
          case 'legs':
            highlight = Positioned(
              bottom: 30,
              left: 25,
              right: 25,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 22,
                    height: 70,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                  Container(
                    width: 22,
                    height: 70,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ],
              ),
            );
            break;
        }
      }

      if (highlight != null) {
        highlights.add(highlight);
      }
    });

    return highlights;
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    if (event.status == EventStatus.UPCOMING) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _shareEvent(context),
              icon: const Icon(Icons.share),
              label: const Text('SHARE'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // ✅ Only show edit button if showEditButton is true
          if (showEditButton) ...[
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _editEvent(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('EDIT SESSION'),
              ),
            ),
          ],
        ],
      );
    }
    return const SizedBox();
  }

  void _shareEvent(BuildContext context) {
    // Assuming we have access to username somehow (could be from a provider)
    final shareUrl = 'https://fitneks.com/profile/trainer?event=${event.id}';
    Share.share(
      'Join my ${event.title} session on ${event.date.toString()}! $shareUrl',
      subject: 'Fitness Session Invitation',
    );
  }

  void _editEvent(BuildContext context) {
    // ✅ Need to get the livestream ID, not event ID
    // For now, we need to fetch the event's linked livestream

    // TODO: This is a temporary solution - ideally the EventModel should include livestreamId
    context.go('/trainer-dashboard/calendar/edit/${event.id}');
  }

  void _deleteEvent(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text(
          'Are you sure you want to delete this event? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final service = ref.read(calendarServiceProvider);
        await service.deleteEvent(event.id);

        // Refresh the events
        ref.invalidate(eventsProvider);

        // Close expanded card
        ref.read(expandedEventIdProvider.notifier).state = null;

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Event deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete event: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Icon _getEquipmentIcon(String equipment) {
    final normalizedEquip = equipment.toLowerCase().replaceAll(' ', '');

    switch (normalizedEquip) {
      case 'pullupbar':
      case 'pull_up_bar':
        return const Icon(Icons.horizontal_rule,
            size: 20, color: Color(0xFFFF4D00)); // Horizontal bar

      case 'resistanceband':
      case 'resistance_band':
        return const Icon(Icons.remove,
            size: 20, color: Color(0xFFFF4D00)); // Stretchy line

      case 'yogamat':
      case 'yoga_mat':
      case 'mat':
        return const Icon(Icons.crop_square,
            size: 20, color: Color(0xFFFF4D00)); // Mat/square

      case 'plates':
        return const Icon(Icons.album,
            size: 20, color: Color(0xFFFF4D00)); // Circle/disc for plates

      case 'kettlebell':
        return const Icon(Icons.sports_kabaddi,
            size: 20, color: Color(0xFFFF4D00)); // Kettlebell shape

      case 'dumbbells':
      case 'weights':
      case 'dumbbell':
        return const Icon(Icons.fitness_center,
            size: 20, color: Color(0xFFFF4D00)); // Classic dumbbell

      case 'jumprope':
      case 'jump_rope':
        return const Icon(Icons.trip_origin,
            size: 20, color: Color(0xFFFF4D00)); // Circle for rope

      case 'foamroller':
      case 'foam_roller':
        return const Icon(Icons.straighten,
            size: 20, color: Color(0xFFFF4D00)); // Ruler/roller shape

      case 'medicineball':
      case 'medicine_ball':
        return const Icon(Icons.sports_basketball,
            size: 20, color: Color(0xFFFF4D00)); // Ball

      case 'barbells':
      case 'barbell':
        return const Icon(Icons.remove_circle_outline,
            size: 20, color: Color(0xFFFF4D00)); // Barbell

      default:
        return const Icon(Icons.sports,
            size: 20, color: Color(0xFFFF4D00)); // Generic fallback
    }
  }

  Color _getColorForMuscleGroup(String group) {
    switch (group.toLowerCase()) {
      case 'legs':
        return Colors.orange;
      case 'back':
        return Colors.blue;
      case 'arms':
        return Colors.green;
      case 'abs':
      case 'core':
        return Colors.purple;
      case 'chest':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
