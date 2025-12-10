import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/payment_models.dart';
import '../config/stripe_config.dart';
import 'dart:js' as js;

class StripeWebService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String baseUrl = 'http://localhost:3000';
  late final dynamic _stripe;
  dynamic _elementsInstance;  

  StripeWebService() {
    // Initialize Stripe.js
    _stripe = js.context.callMethod('Stripe', [StripeConfig.publishableKey]);
    
    // Setup Dio interceptor
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

  // ✅ Implement all methods from LearnerPaymentService
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

  // ✅ THE KEY DIFFERENCE - Web uses Stripe.js for payment
  Future<PurchaseResponse> purchaseRubies(int rubiesAmount, String paymentMethodId) async {
    try {
      print('🌐 [WEB] Starting ruby purchase: $rubiesAmount rubies');
      
      // Step 1: Create payment intent
      final response = await _dio.post(
        '$baseUrl/api/learner/purchase-rubies',
        data: {
          'rubiesAmount': rubiesAmount,
        },
      );
      
      final purchaseResponse = PurchaseResponse.fromJson(response.data);
      
      print('💳 [WEB] Got client secret, confirming payment with Stripe.js...');
      
      // Step 2: Confirm payment with Stripe.js
      final paymentSuccessful = await _confirmPaymentWithStripeJs(
        purchaseResponse.clientSecret,
      );
      
      if (!paymentSuccessful) {
        throw Exception('Payment was cancelled or failed');
      }
      
      print('✅ [WEB] Payment confirmed');
      return purchaseResponse;
    } catch (e) {
      print('❌ [WEB] Error: $e');
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

  // ✅ Stripe.js payment confirmation
  Future<bool> _confirmPaymentWithStripeJs(String clientSecret) async {
    try {
      final paymentElement = await _createAndMountPaymentElement(clientSecret);
      final confirmed = await _showPaymentModal(paymentElement, clientSecret);
      return confirmed;
    } catch (e) {
      print('❌ Stripe.js error: $e');
      return false;
    }
  }

  Future<dynamic> _createAndMountPaymentElement(String clientSecret) async {
  _elementsInstance = _stripe.callMethod('elements', [
    js.JsObject.jsify({'clientSecret': clientSecret})
  ]);
  return _elementsInstance.callMethod('create', ['payment']);
}

  Future<bool> _showPaymentModal(dynamic paymentElement, String clientSecret) async {
  final modal = html.DivElement()
    ..id = 'stripe-modal'
    ..style.cssText = '''
      position: fixed;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      background-color: rgba(0,0,0,0.5);
      display: flex;
      align-items: center;
      justify-content: center;
      z-index: 10000;
    ''';

  final modalContent = html.DivElement()
    ..style.cssText = '''
      background-color: white;
      padding: 30px;
      border-radius: 10px;
      max-width: 500px;
      width: 90%;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    ''';

  final title = html.HeadingElement.h2()
    ..text = 'Complete Your Purchase'
    ..style.cssText = 'margin-bottom: 20px; color: #333;';

  final formContainer = html.DivElement()
    ..id = 'payment-element'
    ..style.marginBottom = '20px';

  final buttonContainer = html.DivElement()
    ..style.cssText = 'display: flex; gap: 10px; justify-content: flex-end;';

  final cancelButton = html.ButtonElement()
    ..text = 'Cancel'
    ..style.cssText = '''
      padding: 10px 20px;
      border: 1px solid #ccc;
      border-radius: 5px;
      cursor: pointer;
      background-color: white;
    ''';

  final payButton = html.ButtonElement()
    ..text = 'Pay Now'
    ..style.cssText = '''
      padding: 10px 20px;
      border: none;
      border-radius: 5px;
      cursor: pointer;
      background-color: #ff6b35;
      color: white;
      font-weight: bold;
    ''';

  final errorDiv = html.DivElement()
    ..id = 'payment-error'
    ..style.cssText = 'color: red; margin-top: 10px; display: none;';

  buttonContainer.children.addAll([cancelButton, payButton]);
  modalContent.children.addAll([title, formContainer, errorDiv, buttonContainer]);
  modal.children.add(modalContent);
  html.document.body?.children.add(modal);

  // ✅ Mount the payment element FIRST
  paymentElement.callMethod('mount', ['#payment-element']);



  bool paymentSuccessful = false;
  bool completed = false;

  cancelButton.onClick.listen((_) {
    if (!completed) {
      completed = true;
      modal.remove();
    }
  });

  payButton.onClick.listen((_) {
  if (completed) return;

  payButton.disabled = true;
  payButton.text = 'Processing...';
  errorDiv.style.display = 'none';

  print('💳 Confirming payment with Stripe...');

  // ✅ Call confirmPayment and handle the promise in JavaScript directly
  final confirmResult = _stripe.callMethod('confirmPayment', [
    js.JsObject.jsify({
      'elements': _elementsInstance,
      'redirect': 'if_required',
    })
  ]);

  // ✅ Handle the promise using JavaScript's then/catch
  confirmResult.callMethod('then', [
    js.allowInterop((result) {
      print('📦 Stripe result received');
      final dartResult = js_util.dartify(result);
      print('Result type: ${dartResult.runtimeType}');
      print('Result: $dartResult');

      if (dartResult is Map && dartResult.containsKey('error')) {
        final error = dartResult['error'] as Map;
        print('❌ Payment error: ${error['message']}');
        errorDiv.text = error['message'] as String? ?? 'Payment failed';
        errorDiv.style.display = 'block';
        payButton.disabled = false;
        payButton.text = 'Pay Now';
      } else if (dartResult is Map && dartResult.containsKey('paymentIntent')) {
        final paymentIntent = dartResult['paymentIntent'] as Map;
        final status = paymentIntent['status'];
        print('✅ Payment status: $status');
        
        if (status == 'succeeded' || status == 'processing') {
          print('✅ Payment successful!');
          paymentSuccessful = true;
          completed = true;
          modal.remove();
        } else {
          print('⚠️ Unexpected status: $status');
          errorDiv.text = 'Payment status: $status';
          errorDiv.style.display = 'block';
          payButton.disabled = false;
          payButton.text = 'Pay Now';
        }
      } else {
        print('✅ Payment successful (no error)');
        paymentSuccessful = true;
        completed = true;
        modal.remove();
      }
    }),
  ]).callMethod('catch', [
    js.allowInterop((error) {
      print('❌ Promise rejected: $error');
      final dartError = js_util.dartify(error);
      print('Error details: $dartError');
      errorDiv.text = 'Payment failed. Please try again.';
      errorDiv.style.display = 'block';
      payButton.disabled = false;
      payButton.text = 'Pay Now';
    })
  ]);
});

  while (!completed) {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  return paymentSuccessful;
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
}