import 'package:flutter/material.dart';
import '../models/public_profile_model.dart';
import '../strategies/user_profile_strategy.dart';
import '../widgets/trainer_stats_cards.dart';
import '../widgets/trainer_details_section.dart';

class TrainerProfileStrategy implements UserProfileStrategy {
  @override
  Widget buildStatsCards(BuildContext context, PublicProfileModel profile) {
    return TrainerStatsCards(profile: profile);
  }

  @override
  Widget buildDetailsSection(
    BuildContext context,
    PublicProfileModel profile,
    bool canViewAdvancedContent,
  ) {
    if (!canViewAdvancedContent) {
      return const SizedBox.shrink();
    }
    
    return TrainerDetailsSection(profile: profile);
  }
}