import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:developer' as developer;

/// Displays an animated gift overlay with celebration effects
/// Option B: Celebrate Style - floats up from bottom with sender name
class GiftAnimationWidget extends StatefulWidget {
  final String giftType;
  final String senderName;
  final int quantity;
  final VoidCallback? onComplete;

  const GiftAnimationWidget({
    super.key,
    required this.giftType,
    required this.senderName,
    this.quantity = 1,
    this.onComplete,
  });

  @override
  _GiftAnimationWidgetState createState() => _GiftAnimationWidgetState();
}

class _GiftAnimationWidgetState extends State<GiftAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _bounceAnimation;
  
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    
    // DEBUG: Log that animation is starting
    developer.log('🎁 GiftAnimationWidget initialized for ${widget.giftType} from ${widget.senderName}');
    
    // Main animation controller (4 seconds total)
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );
    
    // Particle controller (for sparkles)
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // FIXED: Slide from bottom to center (simpler positioning)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 1.2), // Start below screen, centered
      end: const Offset(0.5, 0.4),   // End at center
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
    ));

    // Scale with bounce effect
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 60,
      ),
    ]).animate(_mainController);

    // Bounce animation (subtle)
    _bounceAnimation = Tween<double>(
      begin: 0.0,
      end: -10.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 0.6, curve: Curves.easeInOut),
    ));

    // Fade out at the end
    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    ));

    // Generate sparkle particles
    _generateParticles();

    // Start animation
    _mainController.forward().then((_) {
      developer.log('🎁 Gift animation completed');
      widget.onComplete?.call();
    });
    
    // DEBUG: Log animation start
    developer.log('🎁 Gift animation started');
  }

  void _generateParticles() {
    final random = math.Random();
    for (int i = 0; i < 15; i++) {
      _particles.add(Particle(
        dx: random.nextDouble() * 200 - 100,
        dy: random.nextDouble() * 200 - 100,
        size: random.nextDouble() * 4 + 2,
        delay: random.nextDouble() * 0.5,
      ));
    }
  }

  @override
  void dispose() {
    developer.log('🎁 GiftAnimationWidget disposed');
    _mainController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  String _getGiftEmoji() {
    switch (widget.giftType.toUpperCase()) {
      case 'RUBY':
        return '💎';
      case 'PROTEIN':
        return '💪';
      case 'PROTEIN_SHAKE':
        return '🥤';
      case 'PROTEIN_BAR':
        return '🍫';
      default:
        return '🎁';
    }
  }

  String _getGiftDisplayName() {
    switch (widget.giftType.toUpperCase()) {
      case 'RUBY':
        return widget.quantity == 1 ? 'Ruby' : 'Rubies';
      case 'PROTEIN':
        return 'Protein';
      case 'PROTEIN_SHAKE':
        return 'Protein Shake';
      case 'PROTEIN_BAR':
        return 'Protein Bar';
      default:
        return 'Gift';
    }
  }

  Color _getGiftColor() {
    switch (widget.giftType.toUpperCase()) {
      case 'RUBY':
        return Colors.red;
      case 'PROTEIN':
        return Colors.green;
      case 'PROTEIN_SHAKE':
        return const Color(0xFF2B5FFF);
      case 'PROTEIN_BAR':
        return const Color(0xFFFF4D00);
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    // DEBUG: Log build
    developer.log('🎁 GiftAnimationWidget building');
    
    return IgnorePointer(
      child: Stack(
        children: [
          // Particle effects (sparkles)
          ..._particles.map((particle) => _buildParticle(particle)),

          // Main gift card
          AnimatedBuilder(
            animation: _mainController,
            builder: (context, child) {
              final screenWidth = MediaQuery.of(context).size.width;
              final screenHeight = MediaQuery.of(context).size.height;
              
              // Calculate absolute position
              final left = screenWidth * _slideAnimation.value.dx - 125; // Center the 250px wide card
              final top = screenHeight * _slideAnimation.value.dy + _bounceAnimation.value;
              
              return Positioned(
                left: left,
                top: top,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: child!,
                  ),
                ),
              );
            },
            child: _buildGiftCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftCard() {
    final giftColor = _getGiftColor();
    
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            giftColor.withOpacity(0.95),
            giftColor.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: giftColor.withOpacity(0.6),
            blurRadius: 20,
            spreadRadius: 5,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gift emoji (large)
          Text(
            _getGiftEmoji(),
            style: const TextStyle(fontSize: 60),
          ),
          
          const SizedBox(height: 8),
          
          // Quantity (if more than 1)
          if (widget.quantity > 1)
            Text(
              'x${widget.quantity}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          
          const SizedBox(height: 8),
          
          // Gift name
          Text(
            _getGiftDisplayName(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 4),
          
          // Sender name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'from ${widget.senderName}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticle(Particle particle) {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final progress = (_particleController.value + particle.delay) % 1.0;
        final opacity = (1.0 - progress).clamp(0.0, 1.0);
        
        final screenWidth = MediaQuery.of(context).size.width;
        final screenHeight = MediaQuery.of(context).size.height;
        
        return Positioned(
          left: screenWidth * 0.5 + particle.dx * progress,
          top: screenHeight * 0.4 + particle.dy * progress,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: particle.size,
              height: particle.size,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _getGiftColor().withOpacity(0.5),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class Particle {
  final double dx;
  final double dy;
  final double size;
  final double delay;

  Particle({
    required this.dx,
    required this.dy,
    required this.size,
    required this.delay,
  });
}