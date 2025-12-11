import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/payment_models.dart';
import 'i_payment_service.dart';

class LearnerPaymentService implements IPaymentService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://localhost:3000'; // Update for production

  LearnerPaymentService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  Future<SetupIntentResponse> createSetupIntent() async {
    try {
      final response = await _dio.post('$baseUrl/api/learner/payment-methods/setup-intent');
      return SetupIntentResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<PaymentMethod>> getPaymentMethods() async {
    try {
      final response = await _dio.get('$baseUrl/api/learner/payment-methods');
      return (response.data as List)
          .map((json) => PaymentMethod.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PaymentMethod> addPaymentMethod(String paymentMethodId, bool setAsDefault) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/learner/payment-methods',
        data: {
          'paymentMethodId': paymentMethodId,
          'setAsDefault': setAsDefault,
        },
      );
      return PaymentMethod.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> removePaymentMethod(String methodId) async {
    try {
      await _dio.delete('$baseUrl/api/learner/payment-methods/$methodId');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> setDefaultPaymentMethod(String methodId) async {
    try {
      await _dio.patch('$baseUrl/api/learner/payment-methods/$methodId/default');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PurchaseHistoryResponse> getPurchaseHistory(String period, int page) async {
    try {
      final response = await _dio.get(
        '$baseUrl/api/learner/purchase-history',
        queryParameters: {
          'period': period,
          'page': page,
          'limit': 20,
        },
      );
      return PurchaseHistoryResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<PurchaseResponse> purchaseRubies(int rubiesAmount, String paymentMethodId) async {
    try {
      final response = await _dio.post(
        '$baseUrl/api/learner/purchase-rubies',
        data: {
          'rubiesAmount': rubiesAmount,
          'paymentMethodId': paymentMethodId,
        },
      );
      return PurchaseResponse.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> confirmPurchase(String purchaseId) async {
    try {
      await _dio.post('$baseUrl/api/learner/purchase-rubies/$purchaseId/confirm');
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<int> getRubiesBalance() async {
    try {
      final response = await _dio.get('$baseUrl/api/learner/rubies/balance');
      return response.data['balance'] ?? 0;
    } catch (e) {
      throw _handleError(e);
    }
  }

  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final message = error.response?.data['message'] ?? 'An error occurred';
        return message;
      }
      return 'Network error: ${error.message}';
    }
    return error.toString();
  }


@override
Future<String?> setupCardWithStripeJs(String clientSecret) async {
  // Mobile doesn't use Stripe.js, return null
  // Mobile uses Flutter Stripe SDK directly in the UI layer
  return null;
}


}