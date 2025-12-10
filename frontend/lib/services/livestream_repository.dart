import '../models/livestream_model.dart';
import '../providers/create_stream_provider.dart';
import 'api_service.dart';

class LivestreamRepository {
  final ApiService _apiService;
  
  LivestreamRepository({ApiService? apiService}) 
    : _apiService = apiService ?? ApiService();

  Future<LiveStream> createLiveStream(
  CreateStreamState state,
  String token,
) async {
  try {
    // Convert state to JSON matching backend DTO
    final payload = {
  "title": state.title,
  "description": state.description,
  "visibility": state.visibility.name,
  "scheduledAt": (state.goLiveNow 
      ? DateTime.now() 
      : state.scheduledAt!).toIso8601String(),
  "maxParticipants": state.maxParticipants,
  "isRecurring": state.isRecurring,
  "goLiveNow": state.goLiveNow,  // ✅ ADD THIS LINE
  "equipmentNeeded": state.equipmentNeeded
      .map((e) => e.name)
      .toList(),
  "workoutStyle": state.workoutStyle!.name,
  "giftRequirement": state.giftRequirement,
  "musclePoints": state.musclePoints,
};

    print('📤 Sending payload to backend:');
    print(payload);
    print('🔑 Token length: ${token.length}');
    print('🌐 Calling: ${_apiService.baseUrl}/api/livestreams');

    // Use your existing API service
    final responseData = await _apiService.post(
      '/api/livestreams',
      payload,
      token: token,
    );

    print('✅ Backend response received:');
    print(responseData);

    // Extract livestream from response
    final data = responseData['data'];
    return LiveStream.fromJson(data);
    
  } on ApiException catch (e) {
    print('❌ ApiException caught:');
    print('   Status Code: ${e.statusCode}');
    print('   Message: ${e.message}');
    
    if (e.statusCode == 400) {
      throw Exception('Invalid stream data: ${e.message}');
    } else if (e.statusCode == 401 || e.statusCode == 403) {
      throw Exception('Authentication required. Please log in again.');
    } else {
      throw Exception('Failed to create stream: ${e.message}');
    }
  } catch (e) {
    print('❌ Unexpected error caught:');
    print('   Error type: ${e.runtimeType}');
    print('   Error: $e');
    throw Exception('An unexpected error occurred: $e');
  }
}



Future<LiveStream> getLivestream(String id, String token) async {
  try {
    final responseData = await _apiService.get(
      '/api/livestreams/$id',
      token: token,
    );

    final data = responseData['data'];
    return LiveStream.fromJson(data);
    
  } on ApiException catch (e) {
    if (e.statusCode == 404) {
      throw Exception('Stream not found');
    } else if (e.statusCode == 401 || e.statusCode == 403) {
      throw Exception('Authentication required. Please log in again.');
    } else {
      throw Exception('Failed to load stream: ${e.message}');
    }
  } catch (e) {
    throw Exception('An unexpected error occurred: $e');
  }
}

Future<LiveStream> updateLivestream(
  String id,
  CreateStreamState state,
  String token,
) async {
  try {
    final payload = {
      "title": state.title,
      "description": state.description,
      "visibility": state.visibility.name,
      "scheduledAt": (state.goLiveNow 
          ? DateTime.now() 
          : state.scheduledAt!).toIso8601String(),
      "maxParticipants": state.maxParticipants,
      "equipmentNeeded": state.equipmentNeeded.map((e) => e.name).toList(),
      "workoutStyle": state.workoutStyle!.name,
      "giftRequirement": state.giftRequirement,
      "musclePoints": state.musclePoints,
    };

    final responseData = await _apiService.patch(
      '/api/livestreams/$id',
      payload,
      token,
    );

    final data = responseData['data'];
    return LiveStream.fromJson(data);
    
  } on ApiException catch (e) {
    if (e.statusCode == 400) {
      throw Exception('Invalid stream data: ${e.message}');
    } else if (e.statusCode == 401 || e.statusCode == 403) {
      throw Exception('Authentication required. Please log in again.');
    } else if (e.statusCode == 404) {
      throw Exception('Stream not found');
    } else {
      throw Exception('Failed to update stream: ${e.message}');
    }
  } catch (e) {
    throw Exception('An unexpected error occurred: $e');
  }
}




Future<LiveStream> getLivestreamByEventId(String eventId, String token) async {
  try {
    final responseData = await _apiService.get(
      '/api/livestreams/by-event/$eventId',
      token: token,
    );

    final data = responseData['data'];
    return LiveStream.fromJson(data);
    
  } on ApiException catch (e) {
    if (e.statusCode == 404) {
      throw Exception('Livestream not found for this event');
    } else if (e.statusCode == 401 || e.statusCode == 403) {
      throw Exception('Authentication required. Please log in again.');
    } else {
      throw Exception('Failed to load stream: ${e.message}');
    }
  } catch (e) {
    throw Exception('An unexpected error occurred: $e');
  }
}




}