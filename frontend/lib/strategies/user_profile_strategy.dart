import 'package:flutter/material.dart';
import '../models/public_profile_model.dart';

abstract class UserProfileStrategy {
  Widget buildDetailsSection(
    BuildContext context,
    PublicProfileModel profile,
    bool canViewAdvancedContent,
  );
  
  Widget buildStatsCards(BuildContext context, PublicProfileModel profile);
}