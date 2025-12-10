import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';  // ✅ ADD THIS
import '../models/public_profile_model.dart';
import '../providers/auth_provider.dart';  // ✅ ADD THIS
import 'dart:async';  // For TimeoutException

class ProfilesService {
  static const String baseUrl = 'http://localhost:3000';
  final Ref ref;  // ✅ ADD THIS

  ProfilesService(this.ref);  // ✅ CHANGE THIS (remove _secureStorage)

  // ✅ NEW METHOD - Get token from auth state instead of storage
  String? _getToken() {
    final authState = ref.read(authProvider);
    return authState.token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = _getToken();  // ✅ CHANGED
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<PublicProfileModel> getProfile(String username) async {
  try {
    print('🔍 [ProfilesService] Fetching profile for: $username');
    
    final token = _getToken();
    final headers = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    final response = await http
        .get(
          Uri.parse('$baseUrl/api/profiles/$username'),
          headers: headers,
        )
        .timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('⏰ [ProfilesService] Timeout loading profile: $username');
            throw TimeoutException('Profile request timed out after 5 seconds');
          },
        );

    print('✅ [ProfilesService] Got response for $username: ${response.statusCode}');

    if (response.statusCode == 200) {
      final profile = PublicProfileModel.fromJson(jsonDecode(response.body));
      print('✅ [ProfilesService] Profile parsed successfully: $username');
      return profile;
    } else {
      print('❌ [ProfilesService] Bad status code for $username: ${response.statusCode}');
      throw Exception('Failed to load profile: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('❌ [ProfilesService] Error loading profile $username: $e');
    rethrow;
  }
}

  Future<void> followUser(String username) async {
    final headers = await _getHeaders();
    final token = _getToken();  // ✅ CHANGED - Get from auth state

    // Decode JWT to see what user ID is in it
    if (token != null) {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
        print('🔍 [Frontend] JWT payload: $payload');
      }
    }

    final encodedUsername = Uri.encodeComponent(username);
    print('🔍 [Frontend] Following username: $username');
    print('🔍 [Frontend] Encoded username: $encodedUsername');
    print('🔍 [Frontend] Using token from auth state (not storage)');  // ✅ ADD THIS

    final response = await http.post(
      Uri.parse('$baseUrl/api/profiles/$encodedUsername/follow'),
      headers: headers,
    );

    print('🔍 [Frontend] Response status: ${response.statusCode}');
    print('🔍 [Frontend] Response body: ${response.body}');

    if (response.statusCode != 201 && response.statusCode != 200) {
      print('❌ [Frontend] Follow failed: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to follow user: ${response.body}');
    }

    print('✅ [Frontend] Follow successful!');
  }

  Future<void> unfollowUser(String username) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/profiles/$username/follow'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to unfollow user: ${response.body}');
    }
  }

  Future<void> removeFollower(String username) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/api/profiles/$username/follower'),
      headers: headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove follower: ${response.body}');
    }
  }
}