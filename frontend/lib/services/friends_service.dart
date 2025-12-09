import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend_user_model.dart';
import '../providers/auth_provider.dart';

class FriendsService {
  static const String baseUrl = 'http://localhost:3000/api';
  final Ref ref;

  FriendsService(this.ref);

  String? _getToken() {
    final authState = ref.read(authProvider);
    return authState.token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetch list of followers
  Future<List<FriendUser>> getFollowers() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/friends/followers'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FriendUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load followers: ${response.body}');
    }
  }

  /// Fetch list of users you're following
  Future<List<FriendUser>> getFollowing() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/friends/following'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => FriendUser.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load following: ${response.body}');
    }
  }

  /// ✅ REMOVED removeFollower - use ProfilesService instead
  /// ✅ REMOVED unfollowUser - use ProfilesService instead
}