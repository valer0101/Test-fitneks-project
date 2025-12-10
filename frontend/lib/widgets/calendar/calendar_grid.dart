import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app_theme.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/event_model.dart';
import '../../providers/calendar_provider.dart';

class CalendarGrid extends ConsumerWidget {
  final List<EventModel> events;

  const CalendarGrid({
    super.key,
    required this.events,
  });

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
      selectedDayPredicate: (day) {
        return isSameDay(selectedDate, day);
      },
      eventLoader: (day) {
        final dayEvents =
            events.where((event) => isSameDay(event.date, day)).toList();
        if (dayEvents.isNotEmpty) {
          print('📅 Events on ${day.day}/${day.month}: ${dayEvents.length}');
        }
        return dayEvents;
      },
      startingDayOfWeek: StartingDayOfWeek.sunday,
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
          color: AppTheme.primaryOrange,
          borderRadius: BorderRadius.circular(8),
        ),
        selectedTextStyle: const TextStyle(color: Colors.white),

        // Today decoration - SEMI-TRANSPARENT ORANGE
        todayDecoration: BoxDecoration(
          color: AppTheme.primaryOrange.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        todayTextStyle: const TextStyle(
          color: AppTheme.primaryOrange,
          fontWeight: FontWeight.bold,
        ),

        // Disable cell decoration
        disabledDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),

        markersMaxCount: 4,
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        leftChevronVisible: false,
        rightChevronVisible: false,
      ),
      onDaySelected: (selectedDay, focusedDay) {
        ref.read(selectedDateProvider.notifier).state = selectedDay;
      },
      onPageChanged: (focusedDay) {
        ref.read(currentMonthProvider.notifier).state = focusedDay.month;
        ref.read(currentYearProvider.notifier).state = focusedDay.year;
      },
      calendarBuilders: CalendarBuilders<EventModel>(
        markerBuilder: (context, date, events) {
          if (events.isEmpty) return null;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: events.take(4).map((event) {
              Color color;
              bool isFilled;

              final isPast = date
                  .isBefore(DateTime.now().subtract(const Duration(days: 1)));
              final isCompleted = event.status == EventStatus.COMPLETED;

              // Determine color based on event type
              if (event.type == EventType.CLASS) {
                color = AppTheme.primaryOrange;
              } else {
                color = Colors.blue;
              }

              // Trainer logic: filled for upcoming, hollow for completed
              if (isPast && isCompleted) {
                isFilled = false;
              } else if (event.status == EventStatus.UPCOMING) {
                isFilled = true;
              } else {
                isFilled = false;
              }

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
          );
        },
      ),
    );
  }
}
