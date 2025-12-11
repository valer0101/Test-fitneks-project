import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../app_theme.dart';

/// Dialog shown after stream ends to collect user feedback
/// Allows rating (1-5 stars) and optional text feedback
class PostStreamReviewDialog extends ConsumerStatefulWidget {
  final String livestreamId;
  final VoidCallback onSubmit;

  const PostStreamReviewDialog({
    super.key,
    required this.livestreamId,
    required this.onSubmit,
  });

  @override
  ConsumerState<PostStreamReviewDialog> createState() => _PostStreamReviewDialogState();
}

class _PostStreamReviewDialogState extends ConsumerState<PostStreamReviewDialog> {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  /// Submit review to backend
  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authState = ref.read(authProvider);
      final token = authState.token;
      
      if (token == null) {
        throw Exception('Not authenticated');
      }
      
      // ✅ Create ApiService directly instead of using provider
      final apiService = ApiService();
      
      await apiService.submitStreamReview(
        widget.livestreamId,
        _rating,
        _feedbackController.text.trim().isEmpty ? null : _feedbackController.text.trim(),
        token,
      );
      
      if (mounted) {
        widget.onSubmit();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Review submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit review: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'How was the stream?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starNumber = index + 1;
                return IconButton(
                  iconSize: 40,
                  icon: Icon(
                    starNumber <= _rating ? Icons.star : Icons.star_border,
                    color: AppTheme.primaryOrange,
                  ),
                  onPressed: () {
                    setState(() => _rating = starNumber);
                  },
                );
              }),
            ),
            const SizedBox(height: 24),
            
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Share your feedback (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppTheme.primaryOrange),
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _isSubmitting ? null : widget.onSubmit,
                  child: const Text('Skip'),
                ),
                
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryOrange,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}