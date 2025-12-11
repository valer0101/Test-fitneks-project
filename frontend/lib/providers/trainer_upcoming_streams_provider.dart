import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

final trainerUpcomingStreamsProvider = FutureProvider.autoDispose.family<List<dynamic>, String>((ref, trainerId) async {
  if (trainerId.isEmpty) {
    return [];
  }
  
  final apiService = ref.read(apiServiceProvider);
  final token = ref.read(authProvider).token;
  
  return await apiService.getTrainerUpcomingStreams(trainerId, token);
});