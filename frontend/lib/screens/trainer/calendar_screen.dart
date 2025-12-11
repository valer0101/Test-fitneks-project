import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../providers/calendar_provider.dart';
import '../../../widgets/calendar/month_navigation.dart';
import '../../../widgets/calendar/calendar_grid.dart';
import '../../../widgets/calendar/event_summary_card.dart';
import '../../../widgets/calendar/event_legend.dart';

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
    final filteredEvents = ref.watch(filteredEventsProvider);
    
    final eventsAsyncValue = ref.watch(
      eventsProvider((currentMonth, currentYear))
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
            // Desktop layout unchanged
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
                  child: _buildEventsSection(filteredEvents),
                ),
              ],
            );
          } else {
            // ✅ Mobile layout with draggable bottom sheet
            return Stack(
              children: [
                // Calendar at top (scrollable)
                SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height * 0.25,
                    ),
                    child: _buildCalendarSection(eventsAsyncValue),
                  ),
                ),
                
                // ✅ Draggable events bottom sheet
                DraggableScrollableSheet(
                  initialChildSize: 0.3,
                  minChildSize: 0.15,
                  maxChildSize: 0.85,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // ✅ Drag handle
                          Container(
                            margin: const EdgeInsets.symmetric(vertical: 12),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          
                          // Date header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              DateFormat('EEEE, MMMM d').format(selectedDate),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // ✅ Scrollable events list
                          Expanded(
                            child: filteredEvents.isEmpty
                                ? Center(
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
                                  )
                                : ListView.separated(
                                    controller: scrollController,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    itemCount: filteredEvents.length,
                                    separatorBuilder: (context, index) => 
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      return EventSummaryCard(
                                        event: filteredEvents[index],
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
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
            data: (events) => CalendarGrid(
              events: events,
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Center(
              child: Column(
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 8),
                  Text(
                    'Error loading calendar: ${error.toString()}',
                    style: const TextStyle(color: Colors.red),
                  ),
                  TextButton(
                    onPressed: () => ref.refresh(
                      eventsProvider((
                        ref.read(currentMonthProvider),
                        ref.read(currentYearProvider)
                      ))
                    ),
                    child: const Text('Retry'),
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

  Widget _buildEventsSection(List<EventModel> events) {
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
            child: events.isEmpty
                ? Center(
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
                  )
                : ListView.separated(
                    itemCount: events.length,
                    separatorBuilder: (context, index) => 
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return EventSummaryCard(event: events[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}