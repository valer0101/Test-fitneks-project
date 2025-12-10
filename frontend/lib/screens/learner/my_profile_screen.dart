import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/profile_header.dart';
import '../../widgets/calendar/month_navigation.dart';
import '../../widgets/calendar/event_legend.dart';
import '../../widgets/learner_stats_row.dart';
import '../../widgets/learner_goal_progress.dart';
import '../../widgets/learner_muscle_group_selector.dart';
import '../../widgets/learner_mannequin_heatmap.dart';
import '../../widgets/learner_points_bar_chart.dart';
import '../../widgets/learner_completed_session_card.dart';
import '../../widgets/learner_ruby_purchase_modal.dart';
import '../../providers/learner_stats_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/learner_payment_provider.dart'; // ADDED
import 'dart:ui'; // For ImageFilter
import '../../widgets/learner_profile_header.dart';
import 'package:go_router/go_router.dart'; // ← Add this if not already there
import '../../models/event_model.dart';
import '../../widgets/calendar/learner_calendar_grid.dart';
import '../../widgets/gradient_elevated_button.dart';
import '../../app_theme.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen>
    with SingleTickerProviderStateMixin {
  String _timeframe = 'month';
  final List<String> _selectedMuscleGroups = ['arms', 'chest'];

  @override
  void initState() {
    super.initState();
  }

  void _toggleMuscleGroup(String group) {
    setState(() {
      if (_selectedMuscleGroups.contains(group)) {
        _selectedMuscleGroups.remove(group);
      } else {
        _selectedMuscleGroups.add(group);
      }
    });
  }

  // UPDATED METHOD - removed parameters and uses class context/ref
  void _showRubyPurchaseModal() {
    final methods = ref.read(learnerPaymentProvider).paymentMethods;
    final defaultMethod = methods.where((m) => m.isDefault).firstOrNull;

    if (defaultMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please add a payment method first. Go to Payment settings.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RubyPurchaseModal(
        defaultPaymentMethodId: defaultMethod.id,
      ),
    );
  }

  void _showSetGoalModal() {
    final currentGoal = ref.read(learnerStatsProvider).value?.weeklyGoal ?? 50;
    int newGoal = currentGoal;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Set Your Weekly Points Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'What would you like to set as your weekly points goal? You could try starting with 50 points.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              keyboardType: TextInputType.number,
              maxLength: 3,
              decoration: InputDecoration(
                hintText: 'Max: 999 points',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onChanged: (value) {
                newGoal = int.tryParse(value) ?? currentGoal;
                if (newGoal > 999) newGoal = 999;
              },
              controller: TextEditingController(text: currentGoal.toString()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          GradientElevatedButton(
            onPressed: () {
              ref.read(learnerStatsProvider.notifier).updateWeeklyGoal(newGoal);
              Navigator.pop(context);
            },
            child: const Text('Set Goal'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 1200;
    final stats = ref.watch(learnerStatsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // 🧪 TEMPORARY TEST BUTTON - Remove after testing
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // 🎯 PASTE YOUR STREAM ID HERE from Postman
          const testStreamId =
              'cmi3wkk7k00058o1xdbnpamgs'; // ← Replace with your actual ID
          context.go('/livestream/learner/$testStreamId');
        },
        backgroundColor: Colors.red,
        icon: const Icon(Icons.videocam),
        label: const Text('TEST STREAM'),
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient Header with Profile
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFFF6B00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const SafeArea(
                bottom: false,
                child: LearnerProfileHeader(),
              ),
            ),

            // Main Content
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Row
                  stats.when(
                    data: (data) => Column(
                      children: [
                        StatsRow(
                          points: data.totalPoints / 100,
                          tokens: data.totalPoints ~/ 1000,
                          rubies: data.rubies,
                          onRubyTap: _showRubyPurchaseModal,
                        ),
                        const SizedBox(height: 10),
                        GoalProgress(
                          currentPoints: (data.totalPoints / 100).round(),
                          goalPoints: data.weeklyGoal,
                        ),
                      ],
                    ),
                    loading: () => const CircularProgressIndicator(),
                    error: (e, s) => Text('Error: $e'),
                  ),

                  const SizedBox(height: 30),

                  // Muscle Group Tracking Section
                  _buildMuscleGroupSection(isDesktop),

                  const SizedBox(height: 30),

                  // Calendar Section
                  _buildCalendarSection(),

                  const SizedBox(height: 30),

                  // Summary Cards
                  _buildSummaryCards(),

                  const SizedBox(height: 30),

                  // Completed Lists
                  _buildCompletedLists(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleGroupSection(bool isDesktop) {
    final stats = ref.watch(learnerStatsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your FITNEKS Points',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: SegmentedButton<String>(
                  style: ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return AppTheme.primaryOrange;
                        }
                        return Colors.transparent;
                      },
                    ),
                    foregroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                        if (states.contains(MaterialState.selected)) {
                          return Colors.white;
                        }
                        return Colors.black;
                      },
                    ),
                  ),
                  segments: const [
                    ButtonSegment(value: 'week', label: Text('Week')),
                    ButtonSegment(value: 'month', label: Text('Month')),
                  ],
                  selected: {_timeframe},
                  onSelectionChanged: (val) =>
                      setState(() => _timeframe = val.first),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          stats.when(
            data: (data) {
              final hasPoints = data.muscleGroupPoints.values.any((v) => v > 0);

              if (!hasPoints) {
                return _buildEmptyState();
              }

              return isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Muscle Group Pills
                        Expanded(
                          flex: 2,
                          child: MuscleGroupSelector(
                            muscleGroups: data.muscleGroupPoints,
                            selectedGroups: _selectedMuscleGroups,
                            onToggle: _toggleMuscleGroup,
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Mannequin
                        Expanded(
                          flex: 2,
                          child: MannequinHeatmap(
                            selectedGroups: _selectedMuscleGroups,
                            muscleGroupPoints: data.muscleGroupPoints,
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Bar Chart
                        Expanded(
                          flex: 3,
                          child: PointsBarChart(
                            timeframe: _timeframe,
                            selectedGroups: _selectedMuscleGroups,
                            data: data.chartData,
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        MuscleGroupSelector(
                          muscleGroups: data.muscleGroupPoints,
                          selectedGroups: _selectedMuscleGroups,
                          onToggle: _toggleMuscleGroup,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: MannequinHeatmap(
                                selectedGroups: _selectedMuscleGroups,
                                muscleGroupPoints: data.muscleGroupPoints,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: PointsBarChart(
                                timeframe: _timeframe,
                                selectedGroups: _selectedMuscleGroups,
                                data: data.chartData,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
            },
            loading: () => const CircularProgressIndicator(),
            error: (e, s) => Text('Error loading data: $e'),
          ),

          const SizedBox(height: 20),

          // Set Goal Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: GradientElevatedButton(
              onPressed: _showSetGoalModal,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Set Goal', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          // Blurred placeholder chart
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Opacity(
              opacity: 0.3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Looks like you don\'t have any points!',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 20),
                GradientElevatedButton(
                  onPressed: () {
                    // Navigate to live streams
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 12),
                  ),
                  child: const Text('JOIN A LIVE STREAM'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarSection() {
    final currentMonth = ref.watch(currentMonthProvider);
    final currentYear = ref.watch(currentYearProvider);
    final eventsAsyncValue = ref
        .watch(learnerEventsProvider((month: currentMonth, year: currentYear)));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const MonthNavigation(),
          const SizedBox(height: 20),
          eventsAsyncValue.when(
            data: (events) => LearnerCalendarGrid(events: events),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const LearnerCalendarGrid(events: []),
          ),
          const SizedBox(height: 20),
          const EventLegend(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final stats = ref.watch(learnerStatsProvider);

    return stats.when(
      data: (data) => Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              '${data.completedSessions.length} Sessions Completed',
              AppTheme.primaryOrange,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildSummaryCard(
              '${data.completedChallenges.length} Challenges Completed',
              AppTheme.challengeColor,
            ),
          ),
        ],
      ),
      loading: () => const SizedBox(),
      error: (e, s) => const SizedBox(),
    );
  }

  Widget _buildSummaryCard(String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedLists() {
    final stats = ref.watch(learnerStatsProvider);

    return stats.when(
      data: (data) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildCompletedList(
              'Live Sessions Completed',
              data.completedSessions,
              const Color(0xFFFF6B00),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _buildCompletedList(
              'Live Challenges Completed',
              data.completedChallenges,
              Colors.blue,
            ),
          ),
        ],
      ),
      loading: () => const CircularProgressIndicator(),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Widget _buildCompletedList(
      String title, List<dynamic> items, Color badgeColor) {
    // ✅ NEW: Get attended events for learners
    final attendedEventsAsync = ref.watch(attendedEventsProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),

          // ✅ NEW: Show attended events for "Live Sessions Completed"
          if (title.contains('Sessions'))
            attendedEventsAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No completed sessions yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final totalPoints = event.pointsEarned?['total'] ?? 0;
                    final trainerName = event.trainer?['displayName'] ??
                        event.trainer?['username'] ??
                        'Unknown Trainer';

                    return CompletedSessionCard(
                      points: totalPoints,
                      workoutName: event.title,
                      trainerName: trainerName,
                      date: event.date.toString().split(' ')[0],
                      badgeColor: badgeColor,
                      onTap: () => _showAttendedSessionDetails(event),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(
                child: Text('Error loading sessions: $e'),
              ),
            )
          else
          // Keep existing challenges display
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  'No completed challenges yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return CompletedSessionCard(
                  points: item['points'],
                  workoutName: item['name'],
                  trainerName: item['trainer'],
                  date: item['date'],
                  badgeColor: badgeColor,
                  onTap: () => _showSessionDetails(item),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showSessionDetails(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session['name'],
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text('Trainer: ${session['trainer']}'),
              Text('Date: ${session['date']}'),
              const SizedBox(height: 20),

              // Equipment, Training Type, Muscle Groups
              Wrap(
                spacing: 10,
                children: [
                  Chip(label: Text(session['equipment'] ?? 'No Equipment')),
                  Chip(label: Text(session['trainingType'] ?? 'General')),
                ],
              ),
              const SizedBox(height: 20),

              // Muscle Group Breakdown
              const Text('Muscle Groups:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...((session['muscleGroups'] as Map<String, dynamic>? ?? {})
                  .entries
                  .map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key),
                            Text('${e.value}%'),
                          ],
                        ),
                      ))),

              const SizedBox(height: 20),

              // Additional Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Duration: ${session['duration'] ?? '0'} min'),
                      Text('Questions: ${session['questions'] ?? '0'}'),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Gifts: ${session['gifts'] ?? '0'}'),
                      Text('Rubies: ${session['rubies'] ?? '0'}'),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Close Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttendedSessionDetails(EventModel event) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text('Trainer: ${event.trainer?['displayName'] ?? 'Unknown'}'),
              Text('Date: ${event.date.toString().split(' ')[0]}'),
              const SizedBox(height: 20),

              // Equipment
              Wrap(
                spacing: 10,
                children:
                    event.equipment.map((eq) => Chip(label: Text(eq))).toList(),
              ),
              const SizedBox(height: 20),

              // Points Earned Breakdown
              const Text('Points Earned:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ...(event.pointsEarned?.entries
                      .where((e) => e.key != 'total')
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                    '${e.key[0].toUpperCase()}${e.key.substring(1)}:'),
                                Text(
                                  '${e.value} pts',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF6B00),
                                  ),
                                ),
                              ],
                            ),
                          )) ??
                  []),

              const Divider(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Points:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${event.pointsEarned?['total'] ?? 0} pts',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B00),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Close Button
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
