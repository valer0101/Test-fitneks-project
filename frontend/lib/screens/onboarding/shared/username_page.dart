// lib/screens/onboarding/shared/username_page.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/providers/learner_onboarding_provider.dart';
import 'package:frontend/providers/trainer_onboarding_provider.dart';

class UsernamePage extends ConsumerStatefulWidget {
  final String userRole; // 'Trainer' or 'Learner'
  const UsernamePage({super.key, required this.userRole});

  @override
  ConsumerState<UsernamePage> createState() => _UsernamePageState();
}

// lib/screens/onboarding/shared/username_page.dart -> inside UsernamePage

// lib/screens/onboarding/shared/username_page.dart

class _UsernamePageState extends ConsumerState<UsernamePage> {
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();

  final _adjectives = [
  'Agile', 'Cardio', 'Core', 'Fast', 'Fit', 'Flex', 'Ill', 'Iron',
  'Peak', 'Rapid', 'Sick', 'Sly', 'Strong', 'Tall', 'Zen',
  'Lean', 'Sharp', 'Tough', 'Swift', 'Solid', 'Bold', 'Prime',
  'Vital', 'True', 'Dope', 'Lit', 'Fresh', 'Chill', 'Savage',
  'Wicked', 'Beast', 'Rizz'

];
final _nouns = [
  'Bear', 'Cobra', 'Dancer', 'Elephant', 'Giraffe', 'Goat', 'Gorilla', 
  'King', 'Leopard', 'Lifter', 'Lion', 'Monkey', 'Muse', 'Prince', 
  'Princess', 'Puma', 'Python', 'Quest', 'Queen', 'Runner', 'Sage', 
  'Spirit', 'Tiger', 'Titan', 'Track', 'Warrior', 'Wolf', 'Yogi'
];


  @override
  void initState() {
    super.initState();
    // Use a simple 'if' statement to get the correctly typed state
    if (widget.userRole == 'Trainer') {
      final initialState = ref.read(trainerOnboardingProvider);
      _usernameController.text = initialState.username;
      _displayNameController.text = initialState.displayName;
    } else {
      final initialState = ref.read(learnerOnboardingProvider);
      _usernameController.text = initialState.username;
      _displayNameController.text = initialState.displayName;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _usernameController.text.isEmpty) {
        _generateAndSetUsername();
      }
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  void _generateAndSetUsername() {
    final adj = _adjectives[Random().nextInt(_adjectives.length)];
    final noun = _nouns[Random().nextInt(_nouns.length)];
    final randomNumbers = Random().nextInt(900) + 100;
    final newUsername = '$adj$noun$randomNumbers';

    setState(() {
      _usernameController.text = newUsername;
      _displayNameController.text = newUsername;
    });

    // Use the same 'if' statement to get the correctly typed notifier
    if (widget.userRole == 'Trainer') {
      ref.read(trainerOnboardingProvider.notifier).updateUsername(newUsername);
      ref.read(trainerOnboardingProvider.notifier).updateDisplayName(newUsername);
    } else {
      ref.read(learnerOnboardingProvider.notifier).updateUsername(newUsername);
      ref.read(learnerOnboardingProvider.notifier).updateDisplayName(newUsername);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Text('Create Your Profile', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        const Text('Choose a unique username and a display name to represent you in the community.'),
        const SizedBox(height: 32),
        TextFormField(
          controller: _usernameController,
          decoration: InputDecoration(
            labelText: 'Username',
            helperText: 'Unique, no spaces, max 30 characters.',
            suffixIcon: IconButton(
              icon: const Icon(Icons.casino_outlined),
              tooltip: 'Suggest a username',
              onPressed: _generateAndSetUsername,
            ),
          ),
          onChanged: (value) {
            if (widget.userRole == 'Trainer') {
              ref.read(trainerOnboardingProvider.notifier).updateUsername(value);
            } else {
              ref.read(learnerOnboardingProvider.notifier).updateUsername(value);
            }
          },
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _displayNameController,
          decoration: const InputDecoration(
            labelText: 'Display Name',
            helperText: 'Your public name. Spaces are okay.',
          ),
          onChanged: (value) {
            if (widget.userRole == 'Trainer') {
              ref.read(trainerOnboardingProvider.notifier).updateDisplayName(value);
            } else {
              ref.read(learnerOnboardingProvider.notifier).updateDisplayName(value);
            }
          },
        ),
      ],
    );
  }
}