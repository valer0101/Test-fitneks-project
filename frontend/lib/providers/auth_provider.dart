// lib/providers/auth_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/providers/trainer_onboarding_provider.dart';
import 'package:frontend/providers/learner_onboarding_provider.dart';


// Auth State Model
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  // FIX: Add this property to store the redirect path
  final String? postAuthRedirectPath; 
  final String? token; 

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.postAuthRedirectPath, // FIX: Add to constructor
    this.token, 
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? postAuthRedirectPath, // FIX: Add to copyWith
    bool clearRedirectPath = false, // FIX: Add a way to clear the path
    String? token, 
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      // FIX: Handle updating and clearing the redirect path
      postAuthRedirectPath: clearRedirectPath 
          ? null 
          : postAuthRedirectPath ?? this.postAuthRedirectPath,
        token: token ?? this.token, 
    );
  }
}

// Auth Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage;

  AuthNotifier(this._apiService, this._secureStorage) : super(AuthState()) {
    _checkAuthStatus();
  }


  // Check if user is already logged in
Future<void> _checkAuthStatus() async {
  try {
    final token = await _secureStorage.read(key: 'jwt_token');
if (token != null && !JwtDecoder.isExpired(token)) {
    final decodedToken = JwtDecoder.decode(token);
    final user = User.fromJwt(decodedToken);
    state = state.copyWith(user: user, token: token); // ADD token here
    print('🔄 Auth status checked - Onboarding: ${user.onboardingCompleted}');
}
  } catch (e) {
    await _secureStorage.delete(key: 'jwt_token');
  }
}

// Add this new method to save the user's location

void setPostAuthRedirectPath(String? path) {
    if (path != null && path.isNotEmpty) {
      state = state.copyWith(postAuthRedirectPath: path);
    }
  }


  // Local login
 // Replace your login method in auth_provider.dart with this version:

// Local login
Future<bool> login(String emailOrUsername, String password) async {
  state = state.copyWith(isLoading: true, clearError: true);
  print('🔐 Starting login process...');

  try {
    final response = await _apiService.post('/auth/login', {
      'email': emailOrUsername,
      'password': password,
    });

    print('🔍 API Response: $response');
    final token = response['access_token'];
    print('🎫 Token extracted: ${token?.substring(0, 20)}...');

    // Store JWT securely
    await _secureStorage.write(key: 'jwt_token', value: token);
    print('💾 Token stored in secure storage');

    // Decode JWT to get user info
    final decodedToken = JwtDecoder.decode(token);
    print('🔓 Token decoded: $decodedToken');
    
    final user = User.fromJwt(decodedToken);
    print('👤 User object created: ${user.email}, Role: ${user.role}, Onboarding: ${user.onboardingCompleted}');

    state = state.copyWith(
      user: user,
      isLoading: false,
      postAuthRedirectPath: null,
      token: token,
    );
    
    print('✅ Auth state updated with user');
    print('📊 Current state - User: ${state.user?.email}, Loading: ${state.isLoading}');
    
    return true;
  } catch (e) {
    print('❌ Login error: $e');
    String errorMessage = 'An unexpected error occurred. Please try again.';
    
    if (e is ApiException) {
      if (e.statusCode == 401) {
        errorMessage = 'Incorrect login details. Try again or create an account.';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
    }
    
    state = state.copyWith(
      isLoading: false,
      error: errorMessage,
    );
    return false;
  }
}
  // Google OAuth login
  Future<void> loginWithGoogle() async {
    try {
      final url = Uri.parse('${_apiService.baseUrl}/auth/google');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to launch Google login',
      );
    }
  }

  // Facebook OAuth login
  Future<void> loginWithFacebook() async {
    try {
      final url = Uri.parse('${_apiService.baseUrl}/auth/facebook');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to launch Facebook login',
      );
    }
  }

  // Handle OAuth callback
  Future<void> handleOAuthCallback(String token) async {
    try {
      // Store JWT securely
      await _secureStorage.write(key: 'jwt_token', value: token);

      // Decode JWT to get user info
      final decodedToken = JwtDecoder.decode(token);
      final user = User.fromJwt(decodedToken);

      state = state.copyWith(user: user);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to process login',
      );
    }
  }

  // Logout
  Future<void> logout(BuildContext context) async { // <-- Add BuildContext
  await _secureStorage.delete(key: 'jwt_token');
  state = AuthState();
  if (context.mounted) context.go('/'); // <-- Add this line to navigate home
  }

  // Forgot Password Flow 
  Future<void> forgotPassword(String email) async {
      state = state.copyWith(isLoading: true, clearError: true);
      try {
        await _apiService.post('/auth/forgot-password', {'email': email});
        state = state.copyWith(isLoading: false);
      } catch (e) {
        state = state.copyWith(isLoading: false, error: 'Failed to send reset link.');
      }
    }

// Reset Password 
Future<void> resetPassword(
    String token,
    String newPassword,
    BuildContext context,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _apiService.post('/auth/reset-password', {
        'token': token,
        'newPassword': newPassword,
      });
      state = state.copyWith(isLoading: false);
      
      // Show a success message and navigate to the login screen
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset successfully! Please log in.')),
        );
        context.go('/login');
      }

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to reset password. The token may be invalid or expired.',
      );
    }
  }

//linking onboarding info with backend
Future<bool> updateTrainerProfile(TrainerOnboardingState profileData) async {
  state = state.copyWith(isLoading: true, clearError: true);
  debugPrint('--- 1. Starting profile update ---');
  try {
    final token = await _secureStorage.read(key: 'jwt_token');
    debugPrint('--- 2. Read token from storage ---');
    
    if (token == null) {
      debugPrint('--- ERROR: TOKEN IS NULL! ---');
      throw Exception('User not authenticated');
    }
    debugPrint('--- 3. Token found. Preparing to send request... ---');
    
    final jsonData = profileData.toJson();
    debugPrint('--- 4. Sending this data: $jsonData ---');

    final response = await _apiService.patch(
      '/auth/profile',
      jsonData,
      token,
    );
    debugPrint('--- 5. API call was sent successfully! ---');
    debugPrint('--- 6. Response received: $response ---');

    // Backend should return new token
    if (response['access_token'] != null) {
      final newToken = response['access_token'];
      await _secureStorage.write(key: 'jwt_token', value: newToken);
      debugPrint('--- 7. New token stored ---');
      
      final decodedToken = JwtDecoder.decode(newToken);
      final user = User.fromJwt(decodedToken);
      debugPrint('--- 8. New user created - Onboarding: ${user.onboardingCompleted} ---');
      
      state = state.copyWith(user: user, isLoading: false);
    } else {
      debugPrint('--- 7. No token in response, refreshing auth ---');
      await _checkAuthStatus();
      state = state.copyWith(isLoading: false);
    }

    debugPrint('--- 9. Profile update complete. ---');
    return true;
  } catch (e) {
    debugPrint('--- ERROR CAUGHT: ${e.toString()} ---');
    if (e is ApiException) {
      debugPrint('--- API Error Status: ${e.statusCode} ---');
      debugPrint('--- API Error Message: ${e.message} ---');
    }
    state = state.copyWith(
      isLoading: false,
      error: 'Failed to update profile. Please try again.',
    );
    return false;
  }
}




// Update Learner Profile
Future<bool> updateLearnerProfile(LearnerOnboardingState profileData) async {
  state = state.copyWith(isLoading: true, clearError: true);
  debugPrint('--- LEARNER 1. Starting profile update ---');
  try {
    final token = await _secureStorage.read(key: 'jwt_token');
    debugPrint('--- LEARNER 2. Token found ---');
    
    if (token == null) throw Exception('User not authenticated');

    final response = await _apiService.patch(
      '/auth/profile/learner',
      profileData.toJson(),
      token,
    );
    
    debugPrint('--- LEARNER 3. Response received: $response ---'); // ADD THIS

    if (response['access_token'] != null) {
      debugPrint('--- LEARNER 4. New token found in response ---');
      final newToken = response['access_token'];
      await _secureStorage.write(key: 'jwt_token', value: newToken);
      
      final decodedToken = JwtDecoder.decode(newToken);
      final user = User.fromJwt(decodedToken);
      debugPrint('--- LEARNER 5. New user - Onboarding: ${user.onboardingCompleted} ---');
      
      state = state.copyWith(user: user, isLoading: false);
    } else {
      debugPrint('--- LEARNER 4. No token in response ---');
      await _checkAuthStatus();
      state = state.copyWith(isLoading: false);
    }

    return true;
  } catch (e) {
    debugPrint('--- LEARNER ERROR: $e ---');
    state = state.copyWith(
      isLoading: false,
      error: 'Failed to update profile. Please try again.',
    );
    return false;
  }
}


// Add this method to AuthNotifier class
// Register new user
Future<bool> register(String email, String password, String role) async {
  print('📝 Starting registration process...');
  
  try {
    // CRITICAL: Clear auth state AND token FIRST
    state = AuthState(); // Reset to empty state
    await _secureStorage.delete(key: 'jwt_token');
    print('🗑️ Cleared old auth state and token');

    state = state.copyWith(isLoading: true, clearError: true);

    final response = await _apiService.post('/auth/register', {
      'email': email,
      'password': password,
      'role': role,
    });

    print('✅ Registration successful');
    print('📧 New user: ${response['email']}, Role: ${response['role']}');

    // Now automatically log in with the new credentials
    return await login(email, password);
  } catch (e) {
    print('❌ Registration error: $e');
    String errorMessage = 'Failed to create account. Please try again.';
    
    if (e is ApiException) {
      if (e.statusCode == 403) {
        errorMessage = 'An account with this email already exists.';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
    }
    
    state = state.copyWith(
      isLoading: false,
      error: errorMessage,
    );
    return false;
  }
}








}

// Providers
final apiServiceProvider = Provider((ref) => ApiService());

final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthNotifier(apiService, secureStorage);
});