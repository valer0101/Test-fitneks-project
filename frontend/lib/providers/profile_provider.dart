import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/profile_model.dart';
import 'auth_provider.dart'; // ADD THIS IMPORT

class ProfileNotifier extends AsyncNotifier<ProfileModel> {
  @override
  Future<ProfileModel> build() async {
    // Listen to auth state changes
    final authState = ref.watch(authProvider);
    
    // If no user or no token, throw error
    if (authState.user == null || authState.token == null) {
      throw Exception('Not authenticated');
    }
    
    // Fetch profile with current user's token
    return await fetchProfile();
  }

  Future<ProfileModel> fetchProfile() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/auth/profile/me');
      
      if (response.statusCode == 200) {
        return ProfileModel.fromJson(response.data);
      } else {
        throw Exception('Failed to load profile');
      }
    } on DioException catch (e) {
      print('DioException: ${e.response?.statusCode} - ${e.response?.data}');
      throw Exception('Error fetching profile: ${e.message}');
    } catch (e) {
      print('Error fetching profile: $e');
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<void> refreshProfile() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => fetchProfile());
  }

  void updateGiftCount(String giftType, int delta) {
    state.whenData((profile) {
      final updatedProfile = profile.copyWith(
        proteinShakes: giftType == 'shakes'
            ? profile.proteinShakes + delta
            : profile.proteinShakes,
        proteinBars: giftType == 'bars'
            ? profile.proteinBars + delta
            : profile.proteinBars,
      );
      state = AsyncValue.data(updatedProfile);
    });
  }

  void updateBoostCount(String boostType, int delta) {
    state.whenData((profile) {
      final updatedProfile = profile.copyWith(
        profileBoosts: boostType == 'profile'
            ? profile.profileBoosts + delta
            : profile.profileBoosts,
        notifyBoosts: boostType == 'notify'
            ? profile.notifyBoosts + delta
            : profile.notifyBoosts,
      );
      state = AsyncValue.data(updatedProfile);
    });
  }
}

final profileProvider = AsyncNotifierProvider<ProfileNotifier, ProfileModel>(() {
  return ProfileNotifier();
});

// Provider for secure storage instance
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Properly configured Dio provider with auth interceptor
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 3),
    headers: {
      'Content-Type': 'application/json',
    },
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      try {
        final storage = ref.read(secureStorageProvider);
        final token = await storage.read(key: 'jwt_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      } catch (e) {
        print('Error reading token from secure storage: $e');
      }
      handler.next(options);
    },
    onError: (error, handler) {
      print('DIO Error: ${error.response?.statusCode} - ${error.response?.data}');
      handler.next(error);
    },
  ));

  return dio;
});