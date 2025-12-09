import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/calendar_provider.dart';
import '../../../widgets/calendar/month_navigation.dart';
import '../../../widgets/calendar/learner_calendar_grid.dart';
import '../../../widgets/calendar/event_summary_card.dart';
import '../../../widgets/calendar/event_legend.dart';
import '../../../widgets/calendar/calendar_grid.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final currentMonth = ref.watch(currentMonthProvider);
    final currentYear = ref.watch(currentYearProvider);
    
    final eventsAsyncValue = ref.watch(
      learnerEventsProvider((month: currentMonth, year: currentYear)) 
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Your Calendar',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 768;
          
          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    child: _buildCalendarSection(eventsAsyncValue),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: _buildEventsSection(eventsAsyncValue),
                ),
              ],
            );
          } else {
  return SingleChildScrollView(
    child: Column(
      children: [
        _buildCalendarSection(eventsAsyncValue),
        const SizedBox(height: 16),
        _buildUpcomingEventsOrStats(eventsAsyncValue),
      ],
    ),
  );
}
        },
      ),
    );
  }

  Widget _buildCalendarSection(AsyncValue<List<EventModel>> eventsAsyncValue) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MonthNavigation(),
          const SizedBox(height: 16),
          eventsAsyncValue.when(
            data: (events) {
              print('📊 Calendar receiving ${events.length} events');
              return LearnerCalendarGrid(events: events);
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${error.toString()}',
                    style: const TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const EventLegend(),
        ],
      ),
    );
  }

  Widget _buildEventsSection(AsyncValue<List<EventModel>> eventsAsyncValue) {
    final selectedDate = ref.watch(selectedDateProvider);
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(selectedDate),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: eventsAsyncValue.when(
              data: (events) {
                final filteredEvents = events.where((event) {
                  return event.date.year == selectedDate.year &&
                         event.date.month == selectedDate.month &&
                         event.date.day == selectedDate.day;
                }).toList();
                
                if (filteredEvents.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No events on this date',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return ListView.separated(
                  itemCount: filteredEvents.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
                    return Column(
                      children: [
                        EventSummaryCard(event: event),
                        if (event.attended == true)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B00).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFF6B00)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check_circle, size: 16, color: Color(0xFFFF6B00)),
                                const SizedBox(width: 6),
                                Text(
                                  'Attended • ${event.pointsEarned?['total'] ?? 0} pts earned',
                                  style: const TextStyle(
                                    color: Color(0xFFFF6B00),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Center(child: Text('Error loading events')),
            ),
          ),
        ],
      ),
    );
  }



Widget _buildUpcomingEventsOrStats(AsyncValue<List<EventModel>> eventsAsyncValue) {
  return Padding(
    padding: const EdgeInsets.all(16),
    child: eventsAsyncValue.when(
      data: (events) {
        final now = DateTime.now();
        final upcomingEvents = events.where((e) {
          return e.date.isAfter(now) || 
                 (e.date.year == now.year && 
                  e.date.month == now.month && 
                  e.date.day == now.day);
        }).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
        
        final displayEvents = upcomingEvents.take(5).toList();
        
        if (displayEvents.isEmpty) {
          final attendedCount = events.where((e) => e.attended == true).length;
          final totalPoints = events
              .where((e) => e.attended == true)
              .fold(0, (sum, e) => sum + (e.pointsEarned?['total'] ?? 0));
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This Month',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF6B00).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          '$attendedCount',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B00),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Classes\nAttended',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.grey[300],
                    ),
                    Column(
                      children: [
                        Text(
                          '$totalPoints',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF6B00),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Points\nEarned',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Upcoming Classes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...displayEvents.map((event) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: EventSummaryCard(event: event),
              );
            }).toList(),
          ],
        );
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    ),
  );
}



}