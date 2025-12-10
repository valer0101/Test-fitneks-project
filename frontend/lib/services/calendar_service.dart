import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/event_model.dart';

class CalendarService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  static const String _baseUrl = 'http://localhost:3000/api/calendar';

  CalendarService({
    Dio? dio,
    FlutterSecureStorage? storage,
  })  : _dio = dio ?? Dio(),
        _storage = storage ?? const FlutterSecureStorage() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Handle token refresh or logout
          await _storage.delete(key: 'jwt_token');
        }
        handler.next(error);
      },
    ));
  }

  Future<List<EventModel>> getEvents(int month, int year) async {
    try {
      final response = await _dio.get(
        _baseUrl,
        queryParameters: {
          'month': month,
          'year': year,
        },
      );

      final List<dynamic> data = response.data;
      return data.map((json) => EventModel.fromJson(json)).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<EventModel> getEvent(String id) async {
    try {
      final response = await _dio.get('$_baseUrl/$id');
      return EventModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<EventModel> createEvent(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post(
        _baseUrl,
        data: json.encode(data),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      return EventModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<EventModel> updateEvent(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        '$_baseUrl/$id',
        data: json.encode(data),
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );
      return EventModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteEvent(String id) async {
    try {
      await _dio.delete('$_baseUrl/$id');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final message = error.response?.data['message'] ?? 'An error occurred';
      return Exception(message);
    }
    return Exception('Network error: ${error.message}');
  }
}