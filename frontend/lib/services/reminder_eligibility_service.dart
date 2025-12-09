import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/follow_status_provider.dart';
import 'chat_reminder_service.dart';

/// Service to check if a user is eligible to see specific reminder types
/// This centralizes all eligibility logic in one place for maintainability
class ReminderEligibilityService {
  final Ref ref;
  final String trainerUsername;
  final int trainerId;
  
  ReminderEligibilityService({
    required this.ref,
    required this.trainerUsername,
    required this.trainerId,
  });
  
  /// Check if user is eligible for a specific reminder type
  /// Returns true if they should see it, false if they shouldn't
  bool isEligibleFor(ReminderType type) {
    switch (type) {
      case ReminderType.follow:
        return _isEligibleForFollowReminder();
      
      case ReminderType.gift:
        return _isEligibleForGiftReminder();
      
      case ReminderType.payment:
        return _isEligibleForPaymentReminder();
    }
  }
  
  /// Private eligibility checks for each reminder type
  
  bool _isEligibleForFollowReminder() {
    // Check if user is already following
    final followStatusAsync = ref.read(isFollowingTrainerProvider(trainerUsername));
    
    if (followStatusAsync.hasValue) {
      final isFollowing = followStatusAsync.value ?? false;
      
      if (isFollowing) {
        print('⏭️ [Eligibility] User already following - NOT eligible for follow reminder');
        return false;
      }
    }
    
    // Check if user IS the trainer (trainers shouldn't see their own follow reminders)
    // This is already checked in ChatReminderService._sendReminderToChat, but we can add here too
    
    print('✅ [Eligibility] User IS eligible for follow reminder');
    return true;
  }
  
  bool _isEligibleForGiftReminder() {
    // Future enhancement ideas:
    // - Check if user has sufficient rubies
    // - Check if user has sent gifts recently
    // - Check if user has payment method on file
    
    print('✅ [Eligibility] User IS eligible for gift reminder');
    return true;
  }
  
  bool _isEligibleForPaymentReminder() {
    // Future enhancement ideas:
    // - Check current ruby balance (don't show if they have lots)
    // - Check if they've made a purchase recently
    // - Check if they've dismissed this too many times
    
    print('✅ [Eligibility] User IS eligible for payment reminder');
    return true;
  }
  
  /// Get all eligible reminder types in priority order
  List<ReminderType> getEligibleReminderTypes() {
    final allTypes = [
      ReminderType.follow,
      ReminderType.gift,
      ReminderType.payment,
    ];
    
    return allTypes.where((type) => isEligibleFor(type)).toList();
  }
}