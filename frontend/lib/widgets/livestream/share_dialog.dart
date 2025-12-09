import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareDialog extends StatelessWidget {
  final String livestreamId;
  final String trainerUsername;  // ✅ ADD THIS

  const ShareDialog({
    Key? key,
    required this.livestreamId,
    required this.trainerUsername,  // ✅ ADD THIS

  }) : super(key: key);

  String get shareUrl => 'https://www.fitneks.com/@$trainerUsername/$livestreamId';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            
            // Share title
            const Text(
              'SHARE STREAM',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),
            
            // ✅ UPDATED: Scrollable social media buttons
            SizedBox(
              height: 90,  // Fixed height for scroll area
              child: ListView(
                scrollDirection: Axis.horizontal,  // ✅ Horizontal scroll
                children: [
                  _buildShareButton(
                    icon: Icons.message,
                    label: 'SMS',
                    color: const Color(0xFF4CAF50),
                    onTap: () => _shareSMS(context),
                  ),
                  _buildShareButton(
                    icon: Icons.camera_alt,
                    label: 'Instagram',
                    gradient: const LinearGradient(
                      colors: [Colors.purple, Colors.pink, Colors.orange],
                    ),
                    onTap: () => _shareInstagram(context),
                  ),
                  _buildShareButton(
                    icon: Icons.chat,
                    label: 'Whatsapp',
                    color: const Color(0xFF25D366),
                    onTap: () => _shareWhatsApp(context),
                  ),
                  _buildShareButton(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    color: const Color(0xFF1877F2),
                    onTap: () => _shareFacebook(context),
                  ),
                  _buildShareButton(
                    icon: Icons.flutter_dash,
                    label: 'Twitter',
                    color: const Color(0xFF1DA1F2),
                    onTap: () => _shareTwitter(context),
                  ),
                  _buildShareButton(
                    icon: Icons.more_horiz,
                    label: 'Other',
                    color: Colors.blue,
                    onTap: () => _shareOther(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // URL Copy section
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFFF4D00), width: 2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        shareUrl,
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _copyToClipboard(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'Copy',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton({
    required IconData icon,
    required String label,
    Color? color,
    Gradient? gradient,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),  // ✅ Added padding for spacing
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: gradient == null ? color : null,
                gradient: gradient,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: shareUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link copied to clipboard!'),
        backgroundColor: Color(0xFFFF4D00),
      ),
    );
    Navigator.of(context).pop();
  }

  void _shareSMS(BuildContext context) {
    Share.share(shareUrl);
  }

  void _shareWhatsApp(BuildContext context) {
    Share.share(shareUrl);
  }

  void _shareInstagram(BuildContext context) {
    Share.share(shareUrl);
  }

  void _shareFacebook(BuildContext context) {
    Share.share(shareUrl);
  }

  void _shareTwitter(BuildContext context) {
    Share.share('Join my live fitness class! $shareUrl');
  }

  void _shareOther(BuildContext context) {
    Share.share(shareUrl);
  }
}