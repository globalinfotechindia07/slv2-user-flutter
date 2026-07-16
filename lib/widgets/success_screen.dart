import 'dart:math';
import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

/// Shared success screen used across the app (loan submission, EMI plan
/// selection, etc). Shows a bouncing checkmark + dual confetti cannons +
/// auto-closes after 5 seconds.

class SuccessScreen extends StatefulWidget {
  final VoidCallback onClose;
  final String title;
  final String message;
  final String subMessage;

  const SuccessScreen({
    Key? key,
    required this.onClose,
    this.title = 'Congratulations!',
    this.message = 'Your loan application form has been submitted successfully!',
    this.subMessage = 'Our executives will contact you soon.',
  }) : super(key: key);

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late ConfettiController _confettiControllerLeft;
  late ConfettiController _confettiControllerRight;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    _confettiControllerLeft =
        ConfettiController(duration: const Duration(seconds: 2));
    _confettiControllerRight =
        ConfettiController(duration: const Duration(seconds: 2));
    _confettiControllerLeft.play();
    _confettiControllerRight.play();

    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) widget.onClose();
    });
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _confettiControllerLeft.dispose();
    _confettiControllerRight.dispose();
    super.dispose();
  }

  static const _confettiColors = [
    Color(0xFF93C5FD),
    Color(0xFF86EFAC),
    Color(0xFFFCD34D),
    Color(0xFFFCA5A5),
    Color(0xFFC4B5FD),
    Color(0xFFFDBA74),
    Color(0xFFA5F3FC),
  ];

  Path _ovalParticlePath(Size size) {
    final path = Path();
    path.addOval(Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2,
    ));
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF1F2), Color(0xFFEFF6FF)],
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _bounceAnimation.value),
                        child: child,
                      ),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 40),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.subMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: MediaQuery.of(context).size.height * 0.4,
            child: ConfettiWidget(
              confettiController: _confettiControllerLeft,
              blastDirection: -pi / 6,
              blastDirectionality: BlastDirectionality.directional,
              numberOfParticles: 18,
              gravity: 0.15,
              emissionFrequency: 0.01,
              minBlastForce: 6,
              maxBlastForce: 20,
              minimumSize: const Size(3, 3),
              maximumSize: const Size(6, 6),
              colors: _confettiColors,
              createParticlePath: _ovalParticlePath,
            ),
          ),
          Positioned(
            right: 0,
            top: MediaQuery.of(context).size.height * 0.4,
            child: ConfettiWidget(
              confettiController: _confettiControllerRight,
              blastDirection: pi + pi / 6,
              blastDirectionality: BlastDirectionality.directional,
              numberOfParticles: 18,
              gravity: 0.15,
              emissionFrequency: 0.01,
              minBlastForce: 6,
              maxBlastForce: 20,
              minimumSize: const Size(3, 3),
              maximumSize: const Size(6, 6),
              colors: _confettiColors,
              createParticlePath: _ovalParticlePath,
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x05000000)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}