import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:frontend/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/auth_provider.dart';

enum AuthState { roleSelection, formEntry }

enum Role { Trainer, Learner }

class RegistrationScreen extends ConsumerStatefulWidget {
  final String? onSuccessRedirect;
  const RegistrationScreen({super.key, this.onSuccessRedirect});
  
  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  AuthState _authState = AuthState.roleSelection;
  Role? _selectedRole;
  String _formTitle = '';

// Replace the _register method in your RegistrationScreen with this:

Future<void> _register() async {
  if (_selectedRole == null) {
    debugPrint("Error: A role must be selected.");
    return;
  }

  try {
    // Clear any old tokens first
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.delete(key: 'jwt_token');
    
    // Store redirect path if provided
    if (widget.onSuccessRedirect != null && widget.onSuccessRedirect!.isNotEmpty) {
      ref.read(authProvider.notifier).setPostAuthRedirectPath(widget.onSuccessRedirect);
    }
    
    // Use the new register method from auth provider
    final success = await ref.read(authProvider.notifier).register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _selectedRole!.name,
    );

    if (success) {
      debugPrint('✅ Registration and login successful');
      // Router will handle navigation automatically
    } else {
      debugPrint('❌ Registration failed');
      if (mounted) {
        final error = ref.read(authProvider).error ?? 'Registration failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } catch (e) {
    debugPrint('❌ An error occurred: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

  void _selectRole(Role role) {
    String title = '';
    switch (role) {
      case Role.Learner:
        title = 'Sign up as a Learner';
        break;
      case Role.Trainer:
        title = 'Sign up as a Trainer';
        break;
    }

    setState(() {
      _selectedRole = role;
      _formTitle = title;
      _authState = AuthState.formEntry;
    });
  }

  void _changeRole() {
    setState(() {
      _authState = AuthState.roleSelection;
      _selectedRole = null;
      _emailController.clear();
      _passwordController.clear();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).size.height * 0.6,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppTheme.fitneksGradient,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: 225,
                            child: Image.asset(
                              'assets/wordmark_white.png',
                              width: 240,
                              errorBuilder: (context, error, stackTrace) {
                                return const Text(
                                  'FITNEKS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 3,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const Spacer(flex: 1),
                        const Text(
                          "Train with healthy communities\nto reach your fitness goals",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.25,
                          ),
                        ),
                        const Spacer(flex: 50),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 400),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.1, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _authState == AuthState.roleSelection
                          ? _buildRoleSelection()
                          : _buildFormEntry(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          const SizedBox(height: 22),
          Image.asset(
            'assets/icon_orange.png',
            height: 70,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: AppTheme.primaryOrange,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Text(
                    'F',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          const Text(
            "What type of user are you?",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 18),
          _RoleButton(
            title: "Learner",
            subtitle: "Choose this if you will be joining\nworkouts",
            onPressed: () => _selectRole(Role.Learner),
          ),
          const SizedBox(height: 12),
          _RoleButton(
            title: "Trainer",
            subtitle: "Choose this if you will be streaming\nworkouts",
            onPressed: () => _selectRole(Role.Trainer),
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('DEV: Test Reset Password'),
            onPressed: () {
              const String yourTestToken =
                  'cb1cd70762f94cc15b51c12ef92fad806343a46a364349d799a96486b7543898';
              context.go('/reset-password?token=$yourTestToken');
            },
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: TextButton(
              onPressed: () {
                context.go('/login');
                debugPrint('Navigate to Sign In');
              },
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(fontSize: 14),
                  children: [
                    TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextSpan(
                      text: "Sign In",
                      style: TextStyle(
                        color: AppTheme.primaryOrange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormEntry() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            _formTitle,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _changeRole,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_horiz,
                  size: 18,
                  color: AppTheme.secondaryOrange,
                ),
                const SizedBox(width: 4),
                Text(
                  "Change role",
                  style: TextStyle(
                    color: AppTheme.secondaryOrange,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.email_outlined),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Create a password',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.lock_outline),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              helperText: 'Must be at least 8 characters',
              helperStyle: const TextStyle(fontSize: 12),
            ),
            obscureText: true,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            height: 46,
            decoration: BoxDecoration(
              gradient: AppTheme.fitneksGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _register,
                borderRadius: BorderRadius.circular(10),
                child: const Center(
                  child: Text(
                    'SIGN UP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey.shade400)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  "OR",
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                debugPrint('Sign up with Google');
              },
              icon: const Icon(Icons.g_mobiledata, size: 20),
              label: const Text("Continue with Google",
                  style: TextStyle(fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: () {
                debugPrint('Sign up with Facebook');
              },
              icon: const Icon(Icons.facebook,
                  color: Color(0xFF1877F2), size: 20),
              label: const Text("Continue with Facebook",
                  style: TextStyle(fontSize: 14)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              context.go('/login');
              debugPrint('Navigate to Login');
            },
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  TextSpan(
                    text: "Already have an account? ",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  TextSpan(
                    text: "Log in here",
                    style: TextStyle(
                      color: AppTheme.primaryOrange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  const _RoleButton({
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFFD35400),
          side: BorderSide(color: Colors.grey.shade300, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Color(0xFFD35400),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.15,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

