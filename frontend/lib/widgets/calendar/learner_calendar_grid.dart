import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/calendar_provider.dart';
import '../../widgets/calendar/event_summary_card.dart';

class LearnerCalendarGrid extends ConsumerWidget {
  final List<EventModel> events;
  
  const LearnerCalendarGrid({
    Key? key,
    required this.events,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final currentMonth = ref.watch(currentMonthProvider);
    final currentYear = ref.watch(currentYearProvider);

    return TableCalendar<EventModel>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: DateTime(currentYear, currentMonth),
      calendarFormat: CalendarFormat.month,
      headerVisible: false,
      selectedDayPredicate: (day) => isSameDay(selectedDate, day),
      eventLoader: (day) => events.where((event) => isSameDay(event.date, day)).toList(),
      startingDayOfWeek: StartingDayOfWeek.sunday,


      // ADD THESE TWO CALLBACKS:
     onDaySelected: (selectedDay, focusedDay) {
  ref.read(selectedDateProvider.notifier).state = selectedDay;
  _showDayEventsSheet(context, ref, selectedDay);
},
          onPageChanged: (focusedDay) {
            ref.read(currentMonthProvider.notifier).state = focusedDay.month;
            ref.read(currentYearProvider.notifier).state = focusedDay.year;
          },
  
calendarStyle: CalendarStyle(
  outsideDaysVisible: false,
  
  // Default cell decoration
  defaultDecoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8),
  ),
  
  // Weekend cell decoration
  weekendDecoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8),
  ),
  
  // Selected day decoration - ORANGE SQUARE
  selectedDecoration: BoxDecoration(
    color: Colors.orange,
    borderRadius: BorderRadius.circular(8),
  ),
  selectedTextStyle: const TextStyle(color: Colors.white),
  
  
  // Today decoration - SEMI-TRANSPARENT ORANGE
  todayDecoration: BoxDecoration(
    color: Colors.orange.withOpacity(0.3),
    borderRadius: BorderRadius.circular(8),
  ),
  todayTextStyle: const TextStyle(
    color: Colors.orange,
    fontWeight: FontWeight.bold,
  ),
  
  // Disable cell decoration
  disabledDecoration: BoxDecoration(
    borderRadius: BorderRadius.circular(8),
  ),
  
  markersMaxCount: 4,
),
      calendarBuilders: CalendarBuilders<EventModel>(
        markerBuilder: (context, date, events) {
  if (events.isEmpty) return null;
  return Container(
    margin: const EdgeInsets.only(top: 4), // ADD THIS WRAPPER
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: events.take(4).map((event) {
        // For learners, show hollow dots for attended events
        final color = event.type == EventType.CLASS ? Colors.orange : Colors.blue;
        final isFilled = !(event.attended ?? false); // Hollow if attended
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: isFilled ? color : Colors.transparent,
            border: Border.all(color: color, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }).toList(),
    ),
  );
},
      




      ),
    );
  }


void _showDayEventsSheet(BuildContext context, WidgetRef ref, DateTime date) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      pageBuilder: (context, animation, secondaryAnimation) {
        return GestureDetector(
          onVerticalDragUpdate: (details) {
            // If swiping down, close
            if (details.primaryDelta! > 10) {
              Navigator.of(context).pop();
            }
          },
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            )),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.9,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    // Drag handle - tappable to close
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                    // Date title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              DateFormat('EEEE, MMMM d').format(date),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Events list
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final eventsAsync = ref.watch(
                            learnerEventsProvider((month: date.month, year: date.year))
                          );
                          
                          return eventsAsync.when(
                            data: (events) {
                              final dayEvents = events.where((e) =>
                                e.date.year == date.year &&
                                e.date.month == date.month &&
                                e.date.day == date.day
                              ).toList();
                              
                              if (dayEvents.isEmpty) {
                                return Center(
                                  child: Text(
                                    'No events on this date',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                );
                              }
                              
                              return ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: dayEvents.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final event = dayEvents[index];
                                  return Column(
                                    children: [
                                      EventSummaryCard(event: event),
                                      if (event.attended == true)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF6B00).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFFF6B00)),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.check_circle,
                                                size: 16,
                                                color: Color(0xFFFF6B00),
                                              ),
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
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ),
  );
}
}