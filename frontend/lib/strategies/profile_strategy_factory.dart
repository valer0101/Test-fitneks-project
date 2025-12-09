import '../strategies/user_profile_strategy.dart';
import '../strategies/trainer_profile_strategy.dart';
import '../strategies/learner_profile_strategy.dart';

class ProfileStrategyFactory {
  static UserProfileStrategy getStrategy(String userType) {
    switch (userType) {
      case 'Trainer':
        return TrainerProfileStrategy();
      case 'Learner':
        return LearnerProfileStrategy();
      default:
        throw Exception('Unknown user type: $userType');
    }
  }
}