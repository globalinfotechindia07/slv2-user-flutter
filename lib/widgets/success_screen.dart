import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Flutter equivalent of React's <SuccessScreen> component.
/// Shows a bouncing checkmark + confetti particles + auto-closes after 5 seconds.

class SuccessScreen extends StatefulWidget {
  final VoidCallback onClose;

  const SuccessScreen({Key? key, required this.onClose}) : super(key: key);

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _confettiController;
  late AnimationController _fadeController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _fadeAnimation;
  late List<_ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();

    // Bounce animation for checkmark
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _bounceAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(
        CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));
    _bounceController.forward().then((_) {
      _bounceController.repeat(reverse: true);
    });

    // Confetti
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    final rng = math.Random();
    _particles = List.generate(30, (_) => _ConfettiParticle(rng));
    _confettiController.forward();

    // Fade in text
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _fadeController.forward();
    });

    // Auto close after 5 seconds — mirrors React's useEffect timer
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) widget.onClose();
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _confettiController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF1F2), Color(0xFFEFF6FF)],
          ),
        ),
        child: Stack(
          children: [
            // Confetti layer
            AnimatedBuilder(
              animation: _confettiController,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ConfettiPainter(
                    particles: _particles,
                    progress: _confettiController.value,
                  ),
                  size: MediaQuery.of(context).size,
                );
              },
            ),
            // Content
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Bouncing green checkmark
                    AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (context, child) => Transform.scale(
                        scale: _bounceAnimation.value,
                        child: child,
                      ),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Fade-in text
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        children: [
                          const Text(
                            'Congratulations!',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your loan application form has been submitted successfully!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Our executives will contact you soon.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Confetti Painter ─────────────────────────────────────────────────────────

class _ConfettiParticle {
  final double x;
  final double speedY;
  final double speedX;
  final double size;
  final Color color;
  final double rotation;

  _ConfettiParticle(math.Random rng)
      : x = rng.nextDouble(),
        speedY = 0.2 + rng.nextDouble() * 0.5,
        speedX = (rng.nextDouble() - 0.5) * 0.1,
        size = 6 + rng.nextDouble() * 8,
        rotation = rng.nextDouble() * math.pi * 2,
        color = [
          const Color(0xFFDC2626),
          const Color(0xFF2563EB),
          const Color(0xFF22C55E),
          const Color(0xFFF59E0B),
          const Color(0xFFEC4899),
        ][rng.nextInt(5)];
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  const _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color.withOpacity(1 - progress * 0.5);
      final cx = p.x * size.width + p.speedX * progress * size.width;
      final cy = -20 + p.speedY * progress * (size.height + 40);
      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rotation + progress * math.pi * 2);
      canvas.drawRect(
        Rect.fromCenter(
            center: Offset.zero, width: p.size, height: p.size * 0.6),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}