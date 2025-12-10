import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';

class LearnerProfileHeader extends ConsumerWidget {
  const LearnerProfileHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Edit button positioned at top right
          Align(
            alignment: Alignment.topRight,
            child: IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                // Navigate to edit profile/settings
              },
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Profile Picture
          // Profile Picture
              const CircleAvatar(
                radius: 50,
                backgroundImage: AssetImage('assets/images/default_avatar.png'),
                backgroundColor: Colors.white,
              ),
          
          const SizedBox(height: 15),
          
          // Display Name
          Text(
            user.displayName ?? 'User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 5),
          
          // Username
          Text(
            '@${user.username}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}