import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/live_stream_provider.dart';
import '../../services/api_service.dart';

/// Modal dialog that prompts users to send a gift with their question
/// Shows after 3 messages or every 15 minutes during a stream
class ChatGiftPromptWidget extends ConsumerStatefulWidget {
  final String livestreamId;
  final String pendingMessage; // The message they were about to send
  final Function(String? giftType) onComplete; // Called when user sends (with or without gift)
  
  const ChatGiftPromptWidget({
    super.key,
    required this.livestreamId,
    required this.pendingMessage,
    required this.onComplete,
  });

  @override
  ConsumerState<ChatGiftPromptWidget> createState() => _ChatGiftPromptWidgetState();
}

class _ChatGiftPromptWidgetState extends ConsumerState<ChatGiftPromptWidget> {
  String? _selectedGiftType;
  int _selectedQuantity = 1;  // ✅ ADD THIS for quantity
  bool _isSending = false;
  int _userRubyBalance = 0;
  bool _isLoadingBalance = true;

  // Define the 4 gift types with their properties
  final List<Map<String, dynamic>> _gifts = [
    {
      'name': 'Ruby',
      'type': 'RUBY',
      'cost': 1,
      'icon': Icons.diamond,
      'color': Colors.red,
    },
    {
      'name': 'Protein',
      'type': 'PROTEIN',
      'cost': 3,
      'icon': Icons.fitness_center,
      'color': Colors.green,
    },
    {
      'name': 'Protein Shake',
      'type': 'PROTEIN_SHAKE',
      'cost': 9,
      'icon': Icons.local_drink,
      'color': const Color(0xFF2B5FFF),
    },
    {
      'name': 'Protein Bar',
      'type': 'PROTEIN_BAR',
      'cost': 15,
      'icon': Icons.restaurant,
      'color': const Color(0xFFFF4D00),
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserBalance();
  }

  Future<void> _fetchUserBalance() async {
    try {
      final authState = ref.read(authProvider);
      final token = authState.token;
      
      if (token == null) {
        print('❌ No auth token available');
        if (mounted) {
          setState(() => _isLoadingBalance = false);
        }
        return;
      }
      
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.get('/auth/profile/balance', token: token);
      
      if (mounted) {
        setState(() {
          _userRubyBalance = response['rubies'] ?? 0;
          _isLoadingBalance = false;
        });
      }
    } catch (e) {
      print('Error fetching balance: $e');
      if (mounted) {
        setState(() => _isLoadingBalance = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.stars,
                  color: Color(0xFFFF4D00),
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Make your question stand out',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => _handleSendWithoutGift(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Subtitle
            Text(
              'Send a small gift with your question',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Your question preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.pendingMessage,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Balance display
            if (!_isLoadingBalance)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4D00).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.diamond, size: 16, color: Color(0xFFFF4D00)),
                    const SizedBox(width: 4),
                    Text(
                      'Balance: $_userRubyBalance',
                      style: const TextStyle(
                        color: Color(0xFFFF4D00),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Gift options (2x2 grid)
            _isLoadingBalance
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF4D00)))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _gifts.length,
                    itemBuilder: (context, index) {
                      final gift = _gifts[index];
                      final isSelected = _selectedGiftType == gift['type'];
                      final canAfford = _userRubyBalance >= gift['cost'];
                      
                      return InkWell(
                        onTap: !_isSending
                            ? () {
                                setState(() {
                                  // Toggle selection
                                  if (_selectedGiftType == gift['type']) {
                                    _selectedGiftType = null;
                                    _selectedQuantity = 1;
                                  } else {
                                    _selectedGiftType = gift['type'];
                                    _selectedQuantity = 1;  // ✅ Reset to 1 on new selection
                                  }
                                });
                              }
                            : null,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFFF4D00).withOpacity(0.1)
                                : (canAfford ? Colors.grey[200] : Colors.grey[100]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFFFF4D00)
                                  : (canAfford ? Colors.grey[400]! : Colors.grey[300]!),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                gift['icon'],
                                size: 32,
                                color: isSelected
                                    ? const Color(0xFFFF4D00)
                                    : (canAfford ? gift['color'] : Colors.grey[400]),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                gift['name'],
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isSelected
                                      ? const Color(0xFFFF4D00)
                                      : (canAfford ? Colors.black : Colors.grey[400]),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.diamond,
                                    size: 12,
                                    color: isSelected
                                        ? const Color(0xFFFF4D00)
                                        : (canAfford ? const Color(0xFFFF4D00) : Colors.grey[400]),
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${gift['cost']}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? const Color(0xFFFF4D00)
                                          : (canAfford ? const Color(0xFFFF4D00) : Colors.grey[400]),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            
            // ✅ ADD: Quantity selector when gift selected
            if (_selectedGiftType != null) ...[
              const SizedBox(height: 16),
              _buildQuantitySelector(),
            ],
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: !_isSending ? _handleSendWithoutGift : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Send Without Gift',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: !_isSending ? _handleSendWithGift : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4D00),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Send',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build quantity selector (appears when gift is selected)
  Widget _buildQuantitySelector() {
    final selectedGift = _gifts.firstWhere((g) => g['type'] == _selectedGiftType);
    final unitCost = selectedGift['cost'] as int;
    final totalCost = unitCost * _selectedQuantity;
    final canAfford = _userRubyBalance >= totalCost;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4D00).withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF4D00).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Quantity label
          Text(
            'Quantity',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Quantity controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minus button
              IconButton(
                onPressed: _selectedQuantity > 1
                    ? () => setState(() => _selectedQuantity--)
                    : null,
                icon: const Icon(Icons.remove_circle),
                color: _selectedQuantity > 1 
                    ? const Color(0xFFFF4D00) 
                    : Colors.grey[300],
                iconSize: 32,
                padding: const EdgeInsets.all(8),
              ),
              
              // Quantity display
              Container(
                width: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFFF4D00),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$_selectedQuantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF4D00),
                  ),
                ),
              ),
              
              // Plus button
              IconButton(
                onPressed: _selectedQuantity < 10  // Max 10 (same as main widget)
                    ? () => setState(() => _selectedQuantity++)
                    : null,
                icon: const Icon(Icons.add_circle),
                color: _selectedQuantity < 10 
                    ? const Color(0xFFFF4D00) 
                    : Colors.grey[300],
                iconSize: 32,
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Total cost display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.diamond, color: Color(0xFFFF4D00), size: 14),
              const SizedBox(width: 4),
              Text(
                '$unitCost × $_selectedQuantity = ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '$totalCost',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: canAfford ? const Color(0xFFFF4D00) : Colors.red,
                ),
              ),
            ],
          ),
          
          // Insufficient rubies warning
          if (!canAfford) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Need ${totalCost - _userRubyBalance} more rubies',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleSendWithoutGift() {
  if (_isSending) return;
  
  print('📤 Sending message without gift - dismissing prompt');
  
  // Don't call dismissPrompt here - it's handled in chat_widget's onComplete callback
  
  Navigator.of(context).pop();
  widget.onComplete(null); // null = no gift selected
}

  Future<void> _handleSendWithGift() async {
    if (_isSending) return;
    
    if (_selectedGiftType == null) {
      // No gift selected, just send the message
      _handleSendWithoutGift();
      return;
    }
    
    final selectedGift = _gifts.firstWhere((g) => g['type'] == _selectedGiftType);
    final unitCost = selectedGift['cost'] as int;
    final totalCost = unitCost * _selectedQuantity;  // ✅ Use quantity
    
    // Check if user can afford
    if (_userRubyBalance < totalCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient rubies. You need $totalCost rubies.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Capture refs before async work
    final authState = ref.read(authProvider);
    final token = authState.token;
    final user = authState.user;
    final apiService = ref.read(apiServiceProvider);
    final firestoreService = ref.read(firestoreServiceProvider);
    final roomNotifier = ref.read(roomProvider.notifier);
    
    if (token == null || user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isSending = true);
    
    try {
      print('📤 Sending gift with message: ${selectedGift['name']} x$_selectedQuantity');
      
      // Send gift via API
      final response = await apiService.post(
        '/api/gifts/send',
        {
          'livestreamId': widget.livestreamId,
          'giftType': _selectedGiftType,
          'cost': totalCost,
          'quantity': _selectedQuantity,  // ✅ Send quantity
        },
        token: token,
      );
      
      print('✅ Gift sent successfully');
      
      // Write to Firestore
      await firestoreService.sendGift(
        livestreamId: widget.livestreamId,
        senderId: user.id.toString(),
        senderName: user.displayName ?? user.username ?? 'Anonymous',
        giftType: _selectedGiftType!,
        amount: totalCost.toDouble(),
        quantity: _selectedQuantity,  // ✅ Include quantity
      );
      
      // Broadcast to LiveKit
      await roomNotifier.publishData({
        'type': 'gift',
        'sender': user.displayName ?? user.username ?? 'Anonymous',
        'gift': _selectedGiftType,
        'cost': totalCost,
        'quantity': _selectedQuantity,  // ✅ Include quantity
      });
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onComplete(_selectedGiftType); // Pass gift type
      }
      
    } catch (e) {
      print('❌ Error sending gift: $e');
      
      if (mounted) {
        setState(() => _isSending = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send gift: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}