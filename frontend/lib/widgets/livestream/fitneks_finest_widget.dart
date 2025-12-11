import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';  // ✅ Add this
import '../../app_theme.dart';


/// Displays a horizontal carousel of other live streams
/// Allows learners to discover and switch to other trainers
class FitneksFinestWidget extends ConsumerStatefulWidget {
  final String currentLivestreamId;

  const FitneksFinestWidget({
    Key? key,
    required this.currentLivestreamId,
  }) : super(key: key);

  @override
  _FitneksFinestWidgetState createState() => _FitneksFinestWidgetState();
}

class _FitneksFinestWidgetState extends ConsumerState<FitneksFinestWidget> {
  List<Map<String, dynamic>> _liveStreams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLiveStreams();
  }

  /// Fetch all currently live streams except the current one
  Future<void> _fetchLiveStreams() async {
    try {
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/api/livestreams/live');  // ✅ Added /api
      
      if (mounted) {
        setState(() {
          // Filter out current stream
          final allStreams = List<Map<String, dynamic>>.from(
            response['livestreams'] ?? []
          );
          _liveStreams = allStreams
              .where((stream) => stream['id'] != widget.currentLivestreamId)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching live streams: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            border: Border(
              bottom: BorderSide(color: Colors.grey[700]!),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.whatshot, color: AppTheme.primaryOrange),
              SizedBox(width: 8),
              Text(
                'Fitneks Finest',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Content area
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryOrange,
                  ),
                )
              : _liveStreams.isEmpty
                  ? _buildEmptyState()
                  : _buildStreamCarousel(),
        ),
      ],
    );
  }

  /// Build empty state when no other streams
  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 12),
            Text(
              'No other live streams available',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build horizontal scrolling carousel of streams
  Widget _buildStreamCarousel() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.all(12),
      itemCount: _liveStreams.length,
      itemBuilder: (context, index) {
        return _buildStreamCard(_liveStreams[index]);
      },
    );
  }

  /// Build individual stream card
  Widget _buildStreamCard(Map<String, dynamic> stream) {
    return GestureDetector(
      onTap: () {
        // Navigate to this stream
        context.go('/livestream/learner/${stream['id']}');
      },
      child: Container(
        width: 150,
        margin: EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with LIVE badge and viewer count
            Expanded(
              child: Stack(
                children: [
                  // Thumbnail image
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[800],
                      image: stream['thumbnail'] != null
                          ? DecorationImage(
                              image: NetworkImage(stream['thumbnail']),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: stream['thumbnail'] == null
                        ? Center(
                            child: Icon(
                              Icons.videocam,
                              size: 40,
                              color: Colors.grey[600],
                            ),
                          )
                        : null,
                  ),
                  
                  // LIVE badge (top left)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Viewer count (bottom left)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.visibility, size: 12, color: Colors.white),
                          SizedBox(width: 2),
                          Text(
                            '${stream['viewerCount'] ?? 0}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Stream info below thumbnail
            SizedBox(height: 8),
            
            // Stream title
            Text(
              stream['title'] ?? 'Live Workout',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            
            // Trainer name
            Text(
              stream['trainer']?['displayName'] ?? 'Trainer',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2),
            
            // Points available
            Row(
              children: [
                Icon(Icons.star, size: 12, color: Color(0xFFFF4D00)),
                SizedBox(width: 2),
                Text(
                  '${stream['totalPossiblePoints'] ?? 0} pts',
                  style: TextStyle(
                    color: AppTheme.primaryOrange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}