import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/friends_provider.dart';
import '../../providers/public_profile_provider.dart';
import '../../widgets/friend_user_card.dart';
import '../../models/friend_user_model.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(friendsProvider.notifier).loadFollowers();
      ref.read(friendsProvider.notifier).loadFollowing();
    });
  }

  @override
  Widget build(BuildContext context) {
    final friendsState = ref.watch(friendsProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Friends',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          bottom: TabBar(
            indicatorColor: const Color(0xFFFF6B00),
            indicatorWeight: 3,
            labelColor: const Color(0xFFFF6B00),
            unselectedLabelColor: Colors.grey,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            tabs: const [
              Tab(text: 'Followers'),
              Tab(text: 'Following'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildFollowersTab(friendsState),
            _buildFollowingTab(friendsState),
          ],
        ),
      ),
    );
  }

  Widget _buildFollowersTab(FriendsState state) {
    if (state.isLoadingFollowers) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(friendsProvider.notifier).loadFollowers();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.followers.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No followers yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(friendsProvider.notifier).loadFollowers();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.followers.length,
        itemBuilder: (context, index) {
          final user = state.followers[index];
          return FriendUserCard(
            user: user,
            isFollowing: false,
            onActionPressed: () {
              _showRemoveFollowerDialog(user);
            },
          );
        },
      ),
    );
  }

  Widget _buildFollowingTab(FriendsState state) {
    if (state.isLoadingFollowing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(friendsProvider.notifier).loadFollowing();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.following.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Not following anyone yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(friendsProvider.notifier).loadFollowing();
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: state.following.length,
        itemBuilder: (context, index) {
          final user = state.following[index];
          return FriendUserCard(
            user: user,
            isFollowing: true,
            onActionPressed: () {
              _showUnfollowDialog(user);
            },
          );
        },
      ),
    );
  }

  void _showRemoveFollowerDialog(FriendUser user) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Remove Follower'),
      content: Text('Are you sure you want to remove ${user.displayName} from your followers?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            
            try {
              // ✅ Use ProfilesService instead of FriendsService
              final profilesService = ref.read(profilesServiceProvider);
              await profilesService.removeFollower(user.username);  // ✅ Use username, not ID
              
              // ✅ Invalidate caches
              ref.invalidate(userProfileProvider(user.username));
              ref.invalidate(friendsProvider);
              
              // ✅ Refresh followers list
              await ref.read(friendsProvider.notifier).loadFollowers();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Removed ${user.displayName}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to remove follower: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Remove'),
        ),
      ],
    ),
  );
}

 void _showUnfollowDialog(FriendUser user) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Unfollow User'),
      content: Text('Are you sure you want to unfollow ${user.displayName}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            
            try {
              print('🔍 UNFOLLOW: user.id=${user.id}, user.username=${user.username}');  // ✅ ADD THIS
              
              final profilesService = ref.read(profilesServiceProvider);
              print('🔍 Calling profilesService.unfollowUser(${user.username})');  // ✅ ADD THIS
              
              await profilesService.unfollowUser(user.username);
              
              print('✅ Unfollow successful');  // ✅ ADD THIS
              
              ref.invalidate(userProfileProvider(user.username));
              ref.invalidate(friendsProvider);
              
              await ref.read(friendsProvider.notifier).loadFollowers();
              await ref.read(friendsProvider.notifier).loadFollowing();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Unfollowed ${user.displayName}'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              print('❌ Unfollow error: $e');  // ✅ ADD THIS
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to unfollow: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B00),
          ),
          child: const Text('Unfollow'),
        ),
      ],
    ),
  );
}
}