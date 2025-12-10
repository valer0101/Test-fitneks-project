import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/public_profile_model.dart';
import '../services/profiles_service.dart';

final profilesServiceProvider = Provider((ref) => ProfilesService(ref));

// ✅ Remove autoDispose - keep cache alive during session
final userProfileProvider = FutureProvider.family<PublicProfileModel, String>((ref, username) async {
  final service = ref.watch(profilesServiceProvider);
  return service.getProfile(username);
});