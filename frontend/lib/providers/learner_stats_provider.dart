import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ADD THIS LINE


// Data Models
class LearnerStats {
  final double totalPoints;
  final int rubies;
  final int weeklyGoal;
  final Map<String, int> muscleGroupPoints;
  final List<dynamic> completedSessions;
  final List<dynamic> completedChallenges;
  final Map<String, List<double>> chartData;

  LearnerStats({
    required this.totalPoints,
    required this.rubies,
    required this.weeklyGoal,
    required this.muscleGroupPoints,
    required this.completedSessions,
    required this.completedChallenges,
    required this.chartData,
  });

  factory LearnerStats.fromJson(Map<String, dynamic> json) {
  // Process chart data for muscle groups
  final chartData = <String, List<double>>{};
  if (json['chartData'] != null) {
    (json['chartData'] as Map).forEach((key, value) {
      chartData[key.toString()] = (value as List)
          .map((e) => (e as num).toDouble())
          .toList();
    });
  } else {
    // Default chart data
    chartData['arms'] = [3.5, 4.2, 5.0, 3.8, 4.5, 5.2, 4.0];
    chartData['chest'] = [2.8, 3.5, 4.0, 3.2, 3.8, 4.2, 3.5];
    chartData['back'] = [2.5, 3.0, 3.5, 2.8, 3.2, 3.8, 3.0];
    chartData['abs'] = [2.0, 2.5, 3.0, 2.2, 2.8, 3.2, 2.5];
    chartData['legs'] = [3.0, 3.5, 4.0, 3.2, 3.8, 4.2, 3.5];
  }

  return LearnerStats(
    totalPoints: ((json['totalPoints'] ?? 58200) as num).toDouble(),
    rubies: ((json['rubies'] ?? 24) as num).toInt(),
    weeklyGoal: ((json['weeklyGoal'] ?? 616) as num).toInt(),
    muscleGroupPoints: (json['muscleGroupPoints'] as Map?)?.map(
      (key, value) => MapEntry(key.toString(), (value as num).toInt()),
    ) ?? {
      'arms': 105,
      'chest': 75,
      'back': 67,
      'abs': 54,
      'legs': 67,
      'chlng': 0,
    },
    completedSessions: json['completedSessions'] ?? _mockSessions(),
    completedChallenges: json['completedChallenges'] ?? _mockChallenges(),
    chartData: chartData,
  );
}

  static List<Map<String, dynamic>> _mockSessions() {
    return [
      {
        'points': 45,
        'name': 'HIIT Cardio Blast',
        'trainer': 'Sarah Johnson',
        'date': 'Oct 5, 2025',
        'equipment': 'Dumbbells',
        'trainingType': 'HIIT',
        'duration': 30,
        'questions': 5,
        'gifts': 2,
        'rubies': 3,
        'muscleGroups': {
          'Arms': 30,
          'Chest': 20,
          'Legs': 50,
        },
      },
      {
        'points': 38,
        'name': 'Core Power',
        'trainer': 'Mike Chen',
        'date': 'Oct 4, 2025',
        'equipment': 'Mat',
        'trainingType': 'Strength',
        'duration': 25,
        'questions': 3,
        'gifts': 1,
        'rubies': 2,
        'muscleGroups': {
          'Abs': 70,
          'Back': 30,
        },
      },
      {
        'points': 52,
        'name': 'Full Body Flow',
        'trainer': 'Emma Davis',
        'date': 'Oct 3, 2025',
        'equipment': 'Resistance Bands',
        'trainingType': 'Functional',
        'duration': 40,
        'questions': 7,
        'gifts': 3,
        'rubies': 4,
        'muscleGroups': {
          'Arms': 25,
          'Chest': 25,
          'Back': 25,
          'Legs': 25,
        },
      },
    ];
  }

  static List<Map<String, dynamic>> _mockChallenges() {
    return [
      {
        'points': 75,
        'name': '30-Day Plank Challenge',
        'trainer': 'Team FITNEKS',
        'date': 'Oct 2, 2025',
        'equipment': 'None',
        'trainingType': 'Challenge',
        'duration': 5,
        'questions': 0,
        'gifts': 0,
        'rubies': 5,
        'muscleGroups': {
          'Abs': 100,
        },
      },
      {
        'points': 100,
        'name': 'October Push-up Challenge',
        'trainer': 'Community',
        'date': 'Oct 1, 2025',
        'equipment': 'None',
        'trainingType': 'Challenge',
        'duration': 10,
        'questions': 0,
        'gifts': 0,
        'rubies': 8,
        'muscleGroups': {
          'Arms': 40,
          'Chest': 60,
        },
      },
    ];
  }

  LearnerStats copyWith({
    double? totalPoints,
    int? rubies,
    int? weeklyGoal,
    Map<String, int>? muscleGroupPoints,
    List<dynamic>? completedSessions,
    List<dynamic>? completedChallenges,
    Map<String, List<double>>? chartData,
  }) {
    return LearnerStats(
      totalPoints: totalPoints ?? this.totalPoints,
      rubies: rubies ?? this.rubies,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      muscleGroupPoints: muscleGroupPoints ?? this.muscleGroupPoints,
      completedSessions: completedSessions ?? this.completedSessions,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      chartData: chartData ?? this.chartData,
    );
  }
}

// Provider
class LearnerStatsNotifier extends StateNotifier<AsyncValue<LearnerStats>> {
  final ApiService _apiService;

  LearnerStatsNotifier(this._apiService) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
  try {
    state = const AsyncValue.loading();
    
    // Get token from secure storage (revert to original approach)
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');
    
    if (token == null) {
      throw Exception('No auth token found');
    }
    
    // Call backend API
    final response = await _apiService.get(
      '/auth/profile/learner/stats',
      token: token,
    );
    
    final stats = LearnerStats.fromJson(response);
    state = AsyncValue.data(stats);
  } catch (e, stack) {
    state = AsyncValue.error(e, stack);
  }
}

void updateWeeklyGoal(int newGoal) async {
  state.whenData((stats) async {
    state = AsyncValue.data(stats.copyWith(weeklyGoal: newGoal));
    
    // Get token from secure storage
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');
    
    if (token != null) {
      await _apiService.patch(
        '/auth/profile/learner/goal',
        {'weeklyGoal': newGoal},
        token,
      );
    }
  });
}

  void addRubies(int amount) {
    state.whenData((stats) {
      state = AsyncValue.data(stats.copyWith(
        rubies: stats.rubies + amount,
      ));
    });
  }

  Future<void> refresh() async {
    await loadStats();
  }
}

// Provider definition
final learnerStatsProvider = 
    StateNotifierProvider<LearnerStatsNotifier, AsyncValue<LearnerStats>>((ref) {
  final apiService = ApiService();
  return LearnerStatsNotifier(apiService); // Pass ref here
});