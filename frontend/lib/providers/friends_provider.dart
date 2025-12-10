import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend_user_model.dart';
import '../services/friends_service.dart';

class FriendsState {
  final List<FriendUser> followers;
  final List<FriendUser> following;
  final bool isLoadingFollowers;
  final bool isLoadingFollowing;
  final String? error;

  FriendsState({
    this.followers = const [],
    this.following = const [],
    this.isLoadingFollowers = false,
    this.isLoadingFollowing = false,
    this.error,
  });

  FriendsState copyWith({
    List<FriendUser>? followers,
    List<FriendUser>? following,
    bool? isLoadingFollowers,
    bool? isLoadingFollowing,
    String? error,
  }) {
    return FriendsState(
      followers: followers ?? this.followers,
      following: following ?? this.following,
      isLoadingFollowers: isLoadingFollowers ?? this.isLoadingFollowers,
      isLoadingFollowing: isLoadingFollowing ?? this.isLoadingFollowing,
      error: error,
    );
  }
}

class FriendsNotifier extends StateNotifier<FriendsState> {
  final FriendsService _friendsService;

  FriendsNotifier(this._friendsService) : super(FriendsState());

  Future<void> loadFollowers() async {
  state = state.copyWith(isLoadingFollowers: true, error: null);
  try {
    print('📞 Calling getFollowers API...');
    final followers = await _friendsService.getFollowers();
    print('✅ Received ${followers.length} followers:');
    for (var follower in followers) {
      print('   - ${follower.username} (ID: ${follower.id})');
    }
    state = state.copyWith(
      followers: followers,
      isLoadingFollowers: false,
    );
  } catch (e) {
    print('❌ Error loading followers: $e');
    state = state.copyWith(
      isLoadingFollowers: false,
      error: e.toString(),
    );
  }
}

Future<void> loadFollowing() async {
  state = state.copyWith(isLoadingFollowing: true, error: null);
  try {
    print('📞 Calling getFollowing API...');
    final following = await _friendsService.getFollowing();
    print('✅ Received ${following.length} following:');
    for (var user in following) {
      print('   - ${user.username} (ID: ${user.id})');
    }
    state = state.copyWith(
      following: following,
      isLoadingFollowing: false,
    );
  } catch (e) {
    print('❌ Error loading following: $e');
    state = state.copyWith(
      isLoadingFollowing: false,
      error: e.toString(),
    );
  }
}



}

final friendsServiceProvider = Provider<FriendsService>((ref) {
  return FriendsService(ref);
});


final friendsProvider = StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  final friendsService = ref.watch(friendsServiceProvider);
  return FriendsNotifier(friendsService);
});