import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/live_stream_provider.dart';
import '../../services/api_service.dart';
import '../learner_ruby_purchase_modal.dart';  // ✅ Correct path
import '../../app_theme.dart';


/// Dialog for sending gifts to the trainer during livestream
/// Shows 4 gift types with ruby costs and user's balance
class GiftSendingWidget extends ConsumerStatefulWidget {
  final String livestreamId;
  final Function(String giftType)? onGiftSent;  // Called after gift sent

  const GiftSendingWidget({
    Key? key,
    required this.livestreamId,
    this.onGiftSent,
  }) : super(key: key);

  @override
  _GiftSendingWidgetState createState() => _GiftSendingWidgetState();
}

class _GiftSendingWidgetState extends ConsumerState<GiftSendingWidget> {
  int _userRubyBalance = 0;  // User's current ruby balance
  bool _isSending = false;   // Prevents double-sending
  bool _isLoading = true;    // Loading state


// ✅ Add these new state variables:
  int? _selectedGiftIndex;
  int _selectedQuantity = 1;

  // Define the 4 gift types with their properties
  // Define the 4 gift types with their properties
  final List<Map<String, dynamic>> _gifts = [
    {
      'name': 'Ruby',
      'type': 'RUBY',  // Currency transfer
      'cost': 1,
      'icon': Icons.diamond,
      'color': Colors.red,
    },
    {
      'name': 'Protein',
      'type': 'PROTEIN',  // ✅ Matches database enum
      'cost': 3,
      'icon': Icons.fitness_center,
      'color': AppTheme.proteinColor,
    },
    {
      'name': 'Protein Shake',
      'type': 'PROTEIN_SHAKE',  // ✅ Matches database enum
      'cost': 9,
      'icon': Icons.local_drink,
      'color': AppTheme.challengeColor,
    },
    {
      'name': 'Protein Bar',
      'type': 'PROTEIN_BAR',  // ✅ Matches database enum
      'cost': 15,
      'icon': Icons.restaurant,
      'color': AppTheme.primaryOrange,
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchUserBalance();
  }

  /// Fetch user's ruby balance from API
 /// Fetch user's ruby balance from API
/// Fetch user's ruby balance from API
Future<void> _fetchUserBalance() async {
  try {
    // Get the auth token
    final authState = ref.read(authProvider);
    final token = authState.token;
    
    if (token == null) {
      print('❌ No auth token available');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      return;
    }
    
    final apiService = ref.read(apiServiceProvider);
    // ✅ Pass the token to the API call
    final response = await apiService.get('/auth/profile/balance', token: token);
    
    if (mounted) {
      setState(() {
        _userRubyBalance = response['rubies'] ?? 0;
        _isLoading = false;
      });
    }
  } catch (e) {
    print('Error fetching balance: $e');
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  /// Send a gift via API and broadcast to room
  Future<void> _sendGift(String giftType, int unitCost, int quantity) async {
  final totalCost = unitCost * quantity;
  if (_isSending) return;
  
  if (_userRubyBalance < totalCost) {
    _showPurchaseRubiesDialog();
    return;
  }

  // ✅ CAPTURE ALL REFS AND VALUES FIRST - before any async work or setState
  final authState = ref.read(authProvider);
  final token = authState.token;
  final user = authState.user;
  final apiService = ref.read(apiServiceProvider);
  final firestoreService = ref.read(firestoreServiceProvider);
  final roomNotifier = ref.read(roomProvider.notifier);
  
  if (token == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
    }
    return;
  }

  // ✅ Set sending state ONCE at the start
  if (!mounted) return;
  setState(() => _isSending = true);

  try {
    print('📤 Sending gift: $giftType (cost: $totalCost, quantity: $quantity)');
    
    final response = await apiService.post(
      '/api/gifts/send',
      {
        'livestreamId': widget.livestreamId,
        'giftType': giftType,
        'cost': totalCost,
        'quantity': quantity,
      },
      token: token,
    );
    
    print('✅ Gift sent successfully: ${response['gift']}');
    print('💰 New balance: ${response['newBalance']}');
    
    // Write to Firestore
    await firestoreService.sendGift(
      livestreamId: widget.livestreamId,
      senderId: user?.id.toString() ?? '',
      senderName: user?.displayName ?? user?.username ?? 'Anonymous',
      giftType: giftType,
      amount: totalCost.toDouble(),
      quantity: quantity,
    );
    
    print('🎁 Gift written to Firestore successfully');

    // Broadcast to LiveKit
    await roomNotifier.publishData({
      'type': 'gift',
      'sender': user?.displayName ?? user?.username ?? 'Anonymous',
      'gift': giftType,
      'cost': totalCost,
      'quantity': quantity,
    });

    print('🎁 Gift event broadcasted successfully');
    
    // ✅ Update state ONE FINAL TIME before callback
    final serverBalance = response?['newBalance'];
    
    if (mounted) {
      setState(() {
        if (serverBalance != null) {
          _userRubyBalance = serverBalance;
          print('💰 Updated balance from server: $_userRubyBalance');
        } else {
          _userRubyBalance -= totalCost;
          print('💰 Calculated balance locally: $_userRubyBalance');
        }
        _selectedGiftIndex = null;
        _isSending = false; // ✅ Reset before closing
      });
    }
    
    // ✅ Close dialog BEFORE callback
    if (mounted) {
      Navigator.of(context).pop();
    }
    
    // ✅ Call callback AFTER dialog is closed
    // Widget is now disposed, so callback can't use this widget's context
    widget.onGiftSent?.call(giftType);
    
  } catch (e) {
    print('❌ Error sending gift: $e');
    
    // ✅ Only update state if still mounted
    if (mounted) {
      setState(() => _isSending = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // ✅ NO finally block
}

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 400,
        padding: EdgeInsets.all(20),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFFF4D00),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with ruby balance
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Send Gift',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Ruby balance display
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF4D00).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.diamond, size: 16, color: Color(0xFFFF4D00)),
                            SizedBox(width: 4),
                            Text(
                              '$_userRubyBalance',
                              style: TextStyle(
                                color: Color(0xFFFF4D00),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  
                  // 2x2 Grid of gifts
                  GridView.builder(
                    shrinkWrap: true,  // Don't expand infinitely
                    physics: NeverScrollableScrollPhysics(),  // No scrolling
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,  // 2 columns
                      childAspectRatio: 1.2,  // Width/height ratio
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _gifts.length,
                    itemBuilder: (context, index) {
                      final gift = _gifts[index];
                      final canAfford = _userRubyBalance >= gift['cost'];
                      
                      return InkWell(
                        onTap: !_isSending
                              ? () {
                                  setState(() {
                                    _selectedGiftIndex = _selectedGiftIndex == index ? null : index;
                                    _selectedQuantity = 1;
                                  });
                                }
                              : null,
                        child: Container(
                         decoration: BoxDecoration(
                                color: gift['color'].withOpacity(_selectedGiftIndex == index ? 0.2 : 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: gift['color'],
                                  width: _selectedGiftIndex == index ? 3 : 2,
                                ),
                              ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                gift['icon'],
                                size: 40,
                                color: gift['color'],
                              ),
                              SizedBox(height: 8),
                              Text(
                                gift['name'],
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: null,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                Icon(
                                  Icons.diamond,
                                  size: 14,
                                  color: Color(0xFFFF4D00),
                                ),
                                SizedBox(width: 2),
                                Text(
                                  '${gift['cost']}',
                                  style: TextStyle(
                                    color: Color(0xFFFF4D00),
                                    fontWeight: FontWeight.bold,
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
                  SizedBox(height: 20),
                  
                  // ✅ Add slide-down quantity selector
                  if (_selectedGiftIndex != null) _buildQuantitySelector(),

                  // Bottom buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showPurchaseRubiesDialog,
                        icon: Icon(Icons.add),
                        label: Text('Get Rubies'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.challengeColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }




Widget _buildQuantitySelector() {
  final selectedGift = _gifts[_selectedGiftIndex!];
  final totalCost = selectedGift['cost'] * _selectedQuantity;
  final canAfford = _userRubyBalance >= totalCost;
  
  return AnimatedContainer(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    margin: EdgeInsets.only(bottom: 20),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: selectedGift['color'].withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: selectedGift['color'], width: 2),
    ),
    child: Column(
      children: [
        // Gift info
        Row(
          children: [
            Icon(selectedGift['icon'], color: selectedGift['color'], size: 24),
            SizedBox(width: 8),
            Text(
              selectedGift['name'],
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            IconButton(
              icon: Icon(Icons.close, size: 20),
              onPressed: () => setState(() => _selectedGiftIndex = null),
            ),
          ],
        ),
        
        SizedBox(height: 12),
        
        // Quantity selector
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: _selectedQuantity > 1
                  ? () => setState(() => _selectedQuantity--)
                  : null,
              icon: Icon(Icons.remove_circle_outline),
              color: _selectedQuantity > 1 ? selectedGift['color'] : Colors.grey,
            ),
            
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: selectedGift['color']),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_selectedQuantity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            
            IconButton(
              onPressed: _selectedQuantity < 10 // Max quantity limit
                  ? () => setState(() => _selectedQuantity++)
                  : null,
              icon: Icon(Icons.add_circle_outline),
              color: _selectedQuantity < 10 ? selectedGift['color'] : Colors.grey,
            ),
          ],
        ),
        
        SizedBox(height: 12),
        
        // Total cost
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.diamond, color: Color(0xFFFF4D00), size: 16),
            SizedBox(width: 4),
            Text(
              '${selectedGift['cost']} × $_selectedQuantity = $totalCost',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: canAfford ? Color(0xFFFF4D00) : Colors.red,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 16),
        
        // Send button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: !_isSending
                  ? () {
                      if (canAfford) {
                        _sendGift(selectedGift['type'], selectedGift['cost'], _selectedQuantity);
                      } else {
                        _showPurchaseRubiesDialog();
                      }
                    }
                  : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedGift['color'],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSending
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Send Gift',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
          ),
        ),
      ],
    ),
  );
}

String _formatGiftMessage(String giftType, int amount) {
  String giftName;
  String emoji;
  
  switch (giftType) {
    case 'RUBY':
      giftName = amount > 1 ? 'rubies' : 'ruby';
      emoji = '💎';
      break;
    case 'PROTEIN':
      giftName = amount > 1 ? 'proteins' : 'protein';
      emoji = '💪';
      break;
    case 'PROTEIN_SHAKE':
      giftName = amount > 1 ? 'protein shakes' : 'protein shake';
      emoji = '🥤';
      break;
    case 'PROTEIN_BAR':
      giftName = amount > 1 ? 'protein bars' : 'protein bar';
      emoji = '🍫';
      break;
    default:
      giftName = 'gift';
      emoji = '🎁';
  }
  
  return 'sent $amount $giftName $emoji';
}


  /// Show dialog when user doesn't have enough rubies
  void _showInsufficientFundsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Insufficient Rubies'),
        content: Text('You don\'t have enough rubies for this gift.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showPurchaseRubiesDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFFF4D00),
            ),
            child: Text('Get Rubies'),
          ),
        ],
      ),
    );
  }

  /// Placeholder for ruby purchase flow
  /// Show the ruby purchase modal
  /// Show the ruby purchase modal
void _showPurchaseRubiesDialog() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.card_giftcard, color: Color(0xFFFF4D00), size: 28),
          SizedBox(width: 12),
          Text('Send Gifts'),
        ],
      ),
      content: Text(
        'You need more rubies to send gifts to this trainer. Use your rubies to get gifts.',
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context); // Close confirmation dialog
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => RubyPurchaseModal(
                defaultPaymentMethodId: '',
              ),
            ).then((_) => _fetchUserBalance());
          },
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF4D00)),
          child: Text('Buy Rubies', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

}