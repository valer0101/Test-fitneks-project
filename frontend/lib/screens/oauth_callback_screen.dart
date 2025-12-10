// lib/screens/oauth_callback_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../app_theme.dart';

class OAuthCallbackScreen extends ConsumerWidget {
  final String? token;

  const OAuthCallbackScreen({super.key, this.token});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Handle the OAuth callback
    if (token != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(authProvider.notifier).handleOAuthCallback(token!);
      });
    }

    // Listen for auth state changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.user != null && !next.isLoading) {
        // Navigate based on user role
        if (next.user!.role == 'Trainer') {
          context.go('/trainer-dashboard');
        } else {
          context.go('/home');
        }
      } else if (next.error != null) {
        // If there's an error, go back to login
        context.go('/login');
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryOrange),
            ),
            const SizedBox(height: 16),
            Text(
              'Completing login...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}