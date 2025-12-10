import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gift_exchange_balances.dart';
import '../models/gift_exchange_purchase.dart';
import '../models/gift_type.dart';
import '../config/api_constants.dart';

class GiftExchangeService {
  final String? authToken; 

  // Add constructor to accept token
  GiftExchangeService({this.authToken});

  // TODO: Replace this with your actual auth token retrieval
  Future<String> _getAuthToken() async {
    if (authToken != null && authToken!.isNotEmpty) {
      return authToken!;
    }
    throw Exception('No auth token available');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getAuthToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Fetch user's current balances
  Future<GiftExchangeBalances> getBalances() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.giftExchangeBase}/balances'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return GiftExchangeBalances.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load balances: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching balances: $e');
    }
  }

  /// Exchange tokens/rubies for gifts
  Future<GiftExchangeBalances> exchangeGift({
    required GiftType giftType,
    required int quantity,
    required CurrencyType currencyUsed,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = json.encode({
        'giftType': giftType.value,
        'quantity': quantity,
        'currencyUsed': currencyUsed.value,
      });

      final response = await http.post(
        Uri.parse('${ApiConstants.giftExchangeBase}/exchange'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return GiftExchangeBalances.fromJson(json.decode(response.body));
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to exchange gift');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch purchase history
  Future<List<GiftExchangePurchase>> getHistory(String period) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${ApiConstants.giftExchangeBase}/history?period=$period'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => GiftExchangePurchase.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching history: $e');
    }
  }
}