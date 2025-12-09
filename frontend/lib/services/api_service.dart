import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';  // ✅ Add this import
import '../models/event_model.dart'; // ✅ Add this import

class ApiException implements Exception {
  final int? statusCode;
  final String? message;
  
  ApiException({this.statusCode, this.message});
}

class ApiService {
  static const String _baseUrl = 'http://localhost:3000';
  
  String get baseUrl => _baseUrl;
  
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
    {String? token}
  ) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };
      
      final url = '$_baseUrl$endpoint';
      print('📍 POST Request:');
      print('   URL: $url');
      print('   Headers: $headers');
      print('   Body: ${jsonEncode(body)}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('❌ Request timeout after 10 seconds');
          throw ApiException(message: 'Connection timeout - check if backend is reachable');
        },
      );
      
      print('✅ Response received:');
      print('   Status Code: ${response.statusCode}');
      print('   Body: ${response.body}');
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        // ✅ Handle both string and array error messages
        final message = responseData['message'];
        final errorMessage = message is List 
            ? message.join(', ')
            : (message?.toString() ?? 'Request failed');
        
        throw ApiException(
          statusCode: response.statusCode,
          message: errorMessage,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      print('❌ Network error details:');
      print('   Error type: ${e.runtimeType}');
      print('   Error: $e');
      throw ApiException(message: 'Network error: $e');
    }
  }
  
 Future<dynamic> get(String endpoint, {String? token}) async {
  try {
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    final url = '$_baseUrl$endpoint';
    print('📍 GET Request:');
    print('   URL: $url');
    print('   Headers: ${token != null ? "Bearer token present" : "No token"}');
    
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('❌ GET Request timeout');
        throw ApiException(message: 'Connection timeout');
      },
    );
    
    print('✅ GET Response received:');
    print('   Status Code: ${response.statusCode}');
    print('   Body: ${response.body}');
    
    final responseData = jsonDecode(response.body);
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseData;
    } else {
      final message = responseData['message'];
      final errorMessage = message is List 
          ? message.join(', ')
          : (message?.toString() ?? 'Request failed');
      
      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
      );
    }
  } catch (e) {
    print('❌ GET Error:');
    print('   Error type: ${e.runtimeType}');
    print('   Error: $e');
    
    if (e is ApiException) {
      rethrow;
    }
    throw ApiException(message: 'Network error occurred');
  }
}
  
  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> body,
    String token,
  ) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return responseData;
      } else {
        // ✅ Handle both string and array error messages
        final message = responseData['message'];
        final errorMessage = message is List 
            ? message.join(', ')
            : (message?.toString() ?? 'Request failed');
        
        throw ApiException(
          statusCode: response.statusCode,
          message: errorMessage,
        );
      }
    } catch (e) {
      if (e is ApiException) { 
        rethrow; 
      }
      throw ApiException(message: 'Network error occurred');
    }
  }





Future<List<Map<String, dynamic>>> getAttendedEvents(String token) async {
  print('🔍 API: getAttendedEvents called');
  try {
    final response = await get('/api/calendar/attended-events', token: token);
    print('✅ API: Got ${response['data'].length} attended events');
    return List<Map<String, dynamic>>.from(response['data']);
  } catch (e) {
    print('❌ Error fetching attended events: $e');
    rethrow;
  }
}



Future<Map<String, dynamic>> submitStreamReview(
  String livestreamId,
  int rating,
  String? feedback,
  String token,
) async {
  try {
    final response = await post(
      '/api/livestreams/$livestreamId/review',
      {
        'rating': rating,
        if (feedback != null && feedback.isNotEmpty) 'feedback': feedback,
      },
      token: token,
    );
    return response;
  } catch (e) {
    print('❌ Error submitting review: $e');
    rethrow;
  }
}


Future<List<dynamic>> getTrainerUpcomingStreams(String trainerId, String? token) async {
  print('🔍 API: getTrainerUpcomingStreams called for trainer $trainerId');
  try {
    final response = await get('/api/livestreams/trainer/$trainerId/upcoming', token: token);  // ✅ Pass token
    
    if (response is! List) {
      throw ApiException(
        message: 'API contract violation: expected List, got ${response.runtimeType}',
      );
    }
    
    print('✅ API: Got ${response.length} upcoming streams');
    return response;
  } catch (e) {
    print('❌ Error fetching trainer upcoming streams: $e');
    rethrow;
  }
}

// ✅ Add this provider at the bottom of the file
final apiServiceProvider = Provider<ApiService>((ref) => ApiService());


Future<void> addEventToLearnerCalendar(String eventId, String? token) async {
  final url = Uri.parse('$baseUrl/api/livestreams/event/$eventId/register'); // ✅ Added /api/
  
  print('📍 POST Request:');
  print('   URL: $url');
  print('   Headers: ${token != null ? "Has token" : "No token"}');

  final response = await http.post(
    url,
    headers: {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    },
  );

  print('✅ Response received:');
  print('   Status Code: ${response.statusCode}');
  print('   Body: ${response.body}');

  if (response.statusCode != 200 && response.statusCode != 201) {
    throw ApiException(
      message: 'Failed to add event to calendar',
      statusCode: response.statusCode,
    );
  }
}



Future<List<EventModel>> getLearnerRegisteredEvents(
  int month,
  int year,
  String token,
) async {
    print('🚨 getLearnerRegisteredEvents CALLED - month: $month, year: $year');

  final url = Uri.parse('$baseUrl/api/calendar/registered-events?month=$month&year=$year');
  
  print('📍 GET Request:');
  print('   URL: $url');
  
  final response = await http.get(
    url,
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );
  
  print('✅ Response received:');
  print('   Status Code: ${response.statusCode}');
  print('   Body: ${response.body}');
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    final List<dynamic> eventsJson = data['data'] ?? [];
    return eventsJson.map((json) => EventModel.fromJson(json)).toList();
  }
  
  throw ApiException(
    message: 'Failed to fetch registered events',
    statusCode: response.statusCode,
  );
}




}
