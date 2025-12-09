import 'package:flutter/material.dart';
import '../models/public_profile_model.dart';
import '../strategies/user_profile_strategy.dart';
import '../widgets/learner_stats_cards.dart';
import '../widgets/learner_details_section.dart';

class LearnerProfileStrategy implements UserProfileStrategy {
  @override
  Widget buildStatsCards(BuildContext context, PublicProfileModel profile) {
    return LearnerStatsCards(profile: profile);
  }

  @override
  Widget buildDetailsSection(
    BuildContext context,
    PublicProfileModel profile,
    bool canViewAdvancedContent,
  ) {
    return LearnerDetailsSection(
      profile: profile,
      canViewAdvancedContent: canViewAdvancedContent,
    );
  }
}