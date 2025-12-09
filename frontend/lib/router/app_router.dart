// lib/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/screens/trainer/trainer_dashboard_shell.dart';
import 'package:frontend/screens/trainer/my_profile_screen.dart' as trainer;
import '../screens/login_screen.dart';
import '../screens/oauth_callback_screen.dart';
import '../screens/registration_screen.dart' hide AuthState;
import '../screens/home_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/reset_password_screen.dart';
import '../screens/trainer_onboarding_screen.dart';
import '../screens/learner_onboarding_screen.dart';
import '../screens/trainer/payment_screen.dart' as trainer;
import '../screens/trainer/friends_screen.dart';
import '../screens/trainer/calendar_screen.dart';
import '../screens/user_profile_screen.dart';
import 'package:frontend/screens/trainer/gift_exchange_screen.dart' as trainer_gift;
import 'package:frontend/screens/learner/learner_dashboard_shell.dart';
import '../screens/learner/my_profile_screen.dart' as learner;
import '../screens/learner/payment_screen.dart' as learner;
import '../screens/learner/gift_exchange_screen.dart' as learner_gift;
import '../screens/learner/gift_exchange_screen.dart';
import '../screens/livestream/create_stream_screen.dart';
import '../screens/livestream/live_stream_page.dart';
import '../screens/livestream/live_stream_learner_page.dart';
import '../screens/learner/calendar_screen.dart' as learner_calendar;




final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: GoRouterRefreshStream(ref),
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authProvider);
      final user = authState.user;
      final isLoading = authState.isLoading;
      final currentPath = state.matchedLocation;
      
      print('Router Debug - Path: $currentPath, User: ${user?.email}, Loading: $isLoading, Onboarding: ${user?.onboardingCompleted}');
      
      final publicRoutes = [
        '/',
        '/login',
        '/forgot-password',
        '/reset-password',
        '/oauth-callback',
      ];
      
      final isPublicRoute = publicRoutes.any((route) => currentPath.startsWith(route));
      
      if (isLoading) {
        print('Auth is loading, staying on current page');
        return null;
      }
      
      if (user == null) {
        print('No user, checking if on public route');
        if (isPublicRoute) {
          return null;
        }
        print('Redirecting to signup from: $currentPath');
        return '/?from=${Uri.encodeComponent(currentPath)}';
      }
      
      print('User authenticated: ${user.email}, Role: ${user.role}');
      
      final onboardingComplete = user.onboardingCompleted ?? false;
      final userRole = user.role;
      
      if (!onboardingComplete) {
        print('Onboarding incomplete');
        
        final trainerOnboarding = '/trainer-onboarding';
        final learnerOnboarding = '/learner-onboarding';
        final targetOnboarding = userRole == 'Trainer' ? trainerOnboarding : learnerOnboarding;
        
        if (currentPath == targetOnboarding) {
          print('Already on correct onboarding page');
          return null;
        }
        
        print('Redirecting to onboarding: $targetOnboarding');
        return targetOnboarding;
      }
      
      print('Onboarding complete');
      
      final postAuthRedirect = authState.postAuthRedirectPath;
      if (postAuthRedirect != null && 
          postAuthRedirect.isNotEmpty && 
          postAuthRedirect != '/' &&
          postAuthRedirect != '/login') {
        print('Post-auth redirect to: $postAuthRedirect');
        Future.microtask(() {
          ref.read(authProvider.notifier).setPostAuthRedirectPath(null);
        });
        return postAuthRedirect;
      }
      
      if ((isPublicRoute || 
          currentPath == '/trainer-onboarding' || 
          currentPath == '/learner-onboarding') &&
          !currentPath.startsWith('/trainer-dashboard') &&
          !currentPath.startsWith('/learner-dashboard') &&
          !currentPath.startsWith('/home') &&
          !currentPath.startsWith('/profile/') &&
          !currentPath.startsWith('/@') &&  // ✅ ADD THIS LINE

          !currentPath.startsWith('/livestream/')) {
        final dashboard = userRole == 'Trainer' 
            ? '/trainer-dashboard' 
            : '/learner-dashboard';
        print('🔄 Redirecting to dashboard: $dashboard');
        return dashboard;
      }
      
      print('Staying on current page');
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final from = state.uri.queryParameters['from'];
          return RegistrationScreen(onSuccessRedirect: from);
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/oauth-callback',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return OAuthCallbackScreen(token: token);
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'];
          return ResetPasswordScreen(token: token);
        },
      ),
      GoRoute(
        path: '/trainer-onboarding',
        builder: (context, state) => const TrainerOnboardingScreen(),
      ),
      GoRoute(
        path: '/learner-onboarding',
        builder: (context, state) => const LearnerOnboardingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return TrainerDashboardShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/trainer-dashboard',
            builder: (context, state) => const trainer.MyProfileScreen(),
          ),
          GoRoute(
            path: '/trainer-dashboard/payment',
            builder: (context, state) => const trainer.PaymentScreen(),
          ),
          GoRoute(
            path: '/trainer-dashboard/friends',
            builder: (context, state) => const FriendsScreen(),
          ),
          GoRoute(
            path: '/trainer-dashboard/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          
          GoRoute(
            path: '/trainer-dashboard/gift-exchange',
            builder: (context, state) {
              final initialTab = state.extra as int? ?? 0;
              return trainer_gift.GiftExchangeScreen(initialTab: initialTab);
            },
          ),


            GoRoute(
                  path: '/trainer-dashboard/create-class',
                  name: 'create-class',
                  builder: (context, state) => const CreateStreamScreen(),
                ),
            GoRoute(
            path: '/trainer-dashboard/calendar/edit/:id',
            name: 'edit-stream',
            builder: (context, state) {
              final streamId = state.pathParameters['id']!;
             return CreateStreamScreen(livestreamId: streamId);  // ✅ Pass ID for editing
                  },
                ),
         

        ],
      ),

      GoRoute(
            path: '/livestream/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              return LiveStreamPage(liveStreamId: id);
            },
            // ✅ No redirect - trainers should access this
          ),




      ShellRoute(
        builder: (context, state, child) {
          return LearnerDashboardShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/learner-dashboard',
            builder: (context, state) => const learner.MyProfileScreen(),
          ),
          GoRoute(
            path: '/learner-dashboard/friends',
            builder: (context, state) => const FriendsScreen(),
          ),
          GoRoute(
            path: '/learner-dashboard/payment',
            builder: (context, state) => const learner.PaymentScreen(),
          ),
          GoRoute(
  path: '/learner-dashboard/calendar',
  builder: (context, state) => const learner_calendar.CalendarScreen(),
),



        GoRoute(
            path: '/learner-dashboard/gift-exchange', // ✅ Correct
            name: 'learner-gift-exchange',
            builder: (context, state) {
              final initialTab = state.uri.queryParameters['tab'];
              return GiftExchangeScreen(
                initialTab: initialTab == 'rubies' ? 1 : 0,
              );
            },
          ),
        ],
      ),

      GoRoute(
        path: '/profile/:username',
        builder: (context, state) {
          final username = state.pathParameters['username']!;
          return UserProfileScreen(username: username);
        },
      ),




GoRoute(
  path: '/profile/:username',
  builder: (context, state) {
    final username = state.pathParameters['username']!;
    return UserProfileScreen(username: username);
  },
),

// ✅ ADD THIS NEW ROUTE HERE
GoRoute(
  path: '/@:username/:streamId',
  builder: (context, state) {
    final username = state.pathParameters['username']!;
    final streamId = state.pathParameters['streamId']!;
    // Username is for SEO/display only, we only use streamId
    return LiveStreamLearnerPage(liveStreamId: streamId);
  },
),

// Keep the old route for backward compatibility (optional)
GoRoute(
  path: '/livestream/learner/:id',
  builder: (context, state) {
    final streamId = state.pathParameters['id']!;
    return LiveStreamLearnerPage(liveStreamId: streamId);
  },
),





// Add this route for learners
GoRoute(
  path: '/livestream/learner/:id',
  builder: (context, state) {
    final streamId = state.pathParameters['id']!;
    return LiveStreamLearnerPage(liveStreamId: streamId);
  },
),



    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  final Ref _ref;
  late final ProviderSubscription<AuthState> _subscription;

  GoRouterRefreshStream(this._ref) {
    _subscription = _ref.listen(authProvider, (_, __) {
      print('Auth state changed, triggering router refresh');
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}