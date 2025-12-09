import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/calendar_service.dart';
import '../services/api_service.dart';
import '../models/event_model.dart';
import '../providers/auth_provider.dart';

// Calendar Service Provider
final calendarServiceProvider = Provider<CalendarService>((ref) {
  return CalendarService();
});

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

// Events Provider (uses family for month/year params) - FOR TRAINERS
final eventsProvider = FutureProvider.family<List<EventModel>, (int, int)>(
  (ref, params) async {
    final service = ref.watch(calendarServiceProvider);
    return service.getEvents(params.$1, params.$2);
  },
);

// ✅ NEW: Attended Events Provider - FOR LEARNERS
final attendedEventsProvider = FutureProvider<List<EventModel>>((ref) async {
  final authState = ref.watch(authProvider);
  final token = authState.token;
  
  if (token == null) {
    return [];
  }
  
  final apiService = ref.read(apiServiceProvider);
  final data = await apiService.getAttendedEvents(token);
  
  return data.map((json) => EventModel.fromJson(json)).toList();
});

// ✅ UPDATED: Learner Events Provider - Combines scheduled and attended
// ✅ UPDATED: Learner Events Provider - Combines scheduled and attended
final learnerEventsProvider = FutureProvider.family.autoDispose<List<EventModel>, ({int month, int year})>(
  (ref, params) async {
    final apiService = ref.read(apiServiceProvider);
    final authState = ref.read(authProvider);
    final token = authState.token;
    
    if (token == null) {
      return [];
    }
    
    print('🔍 Fetching learner events for month: ${params.month}, year: ${params.year}');
    
    try {
      // Fetch attended events (past - hollow)
      final attendedEventsJson = await apiService.getAttendedEvents(token);
      final attendedEvents = attendedEventsJson
          .map((json) => EventModel.fromJson(json))
          .where((event) => event.date.month == params.month && event.date.year == params.year)
          .toList();
      
      // Try to fetch registered events (future - filled)
      List<EventModel> registeredEvents = [];
      try {
        registeredEvents = await apiService.getLearnerRegisteredEvents(
          params.month,
          params.year,
          token,
        );
        print('✅ Got ${registeredEvents.length} registered events');
      } catch (e) {
        print('⚠️ Could not fetch registered events: $e');
      }
      
      final allEvents = [...attendedEvents, ...registeredEvents];
      
      print('📊 Attended: ${attendedEvents.length}, Registered: ${registeredEvents.length}, Total: ${allEvents.length}');
      
      return allEvents;
    } catch (e) {
      print('❌ Error in learnerEventsProvider: $e');
      return [];
    }
  },
);

// Selected Date Provider
final selectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTime.now();
});

// Expanded Event ID Provider
final expandedEventIdProvider = StateProvider<String?>((ref) {
  return null;
});

// Current Month/Year Provider
final currentMonthProvider = StateProvider<int>((ref) {
  return DateTime.now().month;
});

final currentYearProvider = StateProvider<int>((ref) {
  return DateTime.now().year;
});

// ✅ UPDATED: Filtered Events Provider (for selected date) - Works for both trainers and learners
final filteredEventsProvider = Provider<List<EventModel>>((ref) {
  final selectedDate = ref.watch(selectedDateProvider);
  final currentMonth = ref.watch(currentMonthProvider);
  final currentYear = ref.watch(currentYearProvider);

  // Check user role to determine which provider to use
  final authState = ref.watch(authProvider);
  final isTrainer = authState.user?.role == 'Trainer';

  final eventsAsyncValue = isTrainer
      ? ref.watch(eventsProvider((currentMonth, currentYear)))
      : ref.watch(learnerEventsProvider((month: currentMonth, year: currentYear)));

  return eventsAsyncValue.when(
    data: (events) {
      print('📊 Calendar receiving ${events.length} events');
      return events.where((event) {
        return event.date.year == selectedDate.year &&
            event.date.month == selectedDate.month &&
            event.date.day == selectedDate.day;
      }).toList();
    },
    loading: () {
      print('📊 Calendar receiving 0 events - still loading');
      return [];
    },
    error: (error, stack) {
      print('❌ Calendar error: $error');
      return [];
    },
  );
});