import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/friend_user_model.dart';  // ✅ Your FriendUser model
import '../../providers/friends_provider.dart';  // ✅ FIXED
import '../../providers/auth_provider.dart';  // ✅ FIXED
import '../../services/api_service.dart';  // ✅ FIXED


class InviteFriendsDialog extends ConsumerStatefulWidget {
  final String livestreamId;
  final String livestreamTitle;

  const InviteFriendsDialog({
    super.key,
    required this.livestreamId,
    required this.livestreamTitle,
  });

  @override
  ConsumerState<InviteFriendsDialog> createState() => _InviteFriendsDialogState();
}

class _InviteFriendsDialogState extends ConsumerState<InviteFriendsDialog> {
  final Set<int> _selectedFriendIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendsProvider.notifier).loadFollowing();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FriendUser> _getFilteredFriends(List<FriendUser> friends) {
    if (_searchQuery.isEmpty) return friends;
    
    return friends.where((friend) {
      final query = _searchQuery.toLowerCase();
      return friend.username.toLowerCase().contains(query) ||
             friend.displayName.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _sendInvites() async {
    if (_selectedFriendIds.isEmpty) return;
    
    setState(() => _isSending = true);
    
    try {
      final authState = ref.read(authProvider);
      final token = authState.token;
      
      if (token == null) {
        throw Exception('Authentication required');
      }
      
      await ref.read(apiServiceProvider).post(
        '/api/livestreams/${widget.livestreamId}/invite',
        {
          'recipientIds': _selectedFriendIds.toList(),
        },
        token: token,
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invited ${_selectedFriendIds.length} friend${_selectedFriendIds.length > 1 ? 's' : ''}!'),
            backgroundColor: const Color(0xFFFF4D00),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Error sending invites: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending invites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final friendsState = ref.watch(friendsProvider);
    final following = _getFilteredFriends(friendsState.following);
    
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 450,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'INVITE FRIENDS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            if (_selectedFriendIds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${_selectedFriendIds.length} of 7 selected',
                  style: TextStyle(
                    color: _selectedFriendIds.length >= 7 
                        ? Colors.red 
                        : const Color(0xFFFF4D00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
              decoration: InputDecoration(
                hintText: 'Search friends...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFFFF4D00)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFFFF4D00)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFFFF4D00)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFFFF4D00), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: _buildFriendsList(friendsState, following),
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedFriendIds.isEmpty || _isSending
                    ? null
                    : _sendInvites,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4D00),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _selectedFriendIds.isEmpty
                            ? 'SELECT FRIENDS TO INVITE'
                            : 'SEND INVITE${_selectedFriendIds.length > 1 ? 'S' : ''}',
                        style: TextStyle(
                          color: _selectedFriendIds.isEmpty ? Colors.grey : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(FriendsState friendsState, List<FriendUser> filteredFriends) {
    if (friendsState.isLoadingFollowing) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFFF4D00),
        ),
      );
    }
    
    if (friendsState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading friends',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.read(friendsProvider.notifier).loadFollowing();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    if (filteredFriends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No friends yet'
                  : 'No friends found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isEmpty)
              Text(
                'Follow some trainers to invite them!',
                style: TextStyle(color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: filteredFriends.length,
      itemBuilder: (context, index) {
        final friend = filteredFriends[index];
        final isSelected = _selectedFriendIds.contains(friend.id);
        final canSelect = _selectedFriendIds.length < 7 || isSelected;
        
        return InkWell(
          onTap: canSelect
              ? () {
                  setState(() {
                    if (isSelected) {
                      _selectedFriendIds.remove(friend.id);
                    } else {
                      _selectedFriendIds.add(friend.id);
                    }
                  });
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected 
                  ? const Color(0xFFFF4D00).withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? const Color(0xFFFF4D00)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFFF4D00),
                  backgroundImage: friend.imageUrl != null 
                      ? NetworkImage(friend.imageUrl!)
                      : null,
                  child: friend.imageUrl == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${friend.username} • ${friend.points} XP',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                Checkbox(
                  value: isSelected,
                  onChanged: canSelect
                      ? (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedFriendIds.add(friend.id);
                            } else {
                              _selectedFriendIds.remove(friend.id);
                            }
                          });
                        }
                      : null,
                  activeColor: const Color(0xFFFF4D00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}