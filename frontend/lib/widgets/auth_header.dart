// lib/widgets/auth_header.dart

import 'package:flutter/material.dart';

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(flex: 2),
        // Wordmark
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
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            height: 1.25,
          ),
        ),
        const Spacer(flex: 2), // Adjust flex to control spacing
      ],
    );
  }
}