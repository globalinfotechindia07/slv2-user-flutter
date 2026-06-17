import 'dart:math';
import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import '../services/api_service.dart';
import '../auth/mpin_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  bool _showContent = false;

  // Content scale+fade — transition-all duration-1000
  late final AnimationController _contentCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  late final Animation<double> _contentFade =
      CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
  late final Animation<double> _contentScale = Tween<double>(
    begin: 0.9, // scale-90
    end: 1.0,   // scale-100
  ).animate(CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut));

  // Gradient shift — animate-gradient-shift 15s infinite
  late final AnimationController _gradientCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 15),
  )..repeat();

  // Float animation — animate-float 6s ease-in-out infinite
  late final AnimationController _floatCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);
  late final Animation<double> _floatAnim = Tween<double>(
    begin: 0.0,
    end: -10.0, // translateY(-10px)
  ).animate(CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut));

  // Reveal animation for title — animate-reveal 0.5s ease-out forwards
  late final AnimationController _revealCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _revealFade =
      CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut);
  late final Animation<double> _revealSlide = Tween<double>(
    begin: 20.0, // translateY(20px)
    end: 0.0,
  ).animate(CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut));

  // Reveal delayed — animate-reveal-delayed 0.5s ease-out 0.2s forwards
  late final AnimationController _revealDelayedCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _revealDelayedFade =
      CurvedAnimation(parent: _revealDelayedCtrl, curve: Curves.easeOut);
  late final Animation<double> _revealDelayedSlide = Tween<double>(
    begin: 20.0,
    end: 0.0,
  ).animate(
      CurvedAnimation(parent: _revealDelayedCtrl, curve: Curves.easeOut));

  // 3 bounce controllers for dots — staggered 0s, 0.2s, 0.4s
  late final List<AnimationController> _bounceCtrl = List.generate(3, (i) {
    return AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  });

  // 50 random star positions, sizes, animation durations/delays
  late final List<_StarData> _stars = List.generate(50, (_) {
    final rng = Random();
    return _StarData(
      top: rng.nextDouble() * 100,
      left: rng.nextDouble() * 100,
      size: rng.nextDouble() * 4 + 1,
      duration: (rng.nextDouble() * 3 + 2) * 1000, // 2s–5s
      delay: rng.nextDouble() * 2000,               // 0s–2s
    );
  });

  @override
  void initState() {
    super.initState();

    // showContent after 500ms
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _showContent = true);
        _contentCtrl.forward();
        _revealCtrl.forward();
        // reveal-delayed: 0.2s after reveal
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _revealDelayedCtrl.forward();
        });
      }
    });

    // Start bounce controllers staggered
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _bounceCtrl[i].repeat(reverse: true);
      });
    }

    // Navigate after 2500ms — check login state first
Future.delayed(const Duration(milliseconds: 2500), () async {
  if (!mounted) return;
  try {
    final result = await ApiService.verifyUserToken();
    if (!mounted) return;
    if (result['success'] == true) {
      final userProfile = Map<String, dynamic>.from(result['user'] ?? {});
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MpinScreen(userProfile: userProfile),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  } catch (_) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
    );
  }
});  
}

  @override
  void dispose() {
    _contentCtrl.dispose();
    _gradientCtrl.dispose();
    _floatCtrl.dispose();
    _revealCtrl.dispose();
    _revealDelayedCtrl.dispose();
    for (final c in _bounceCtrl) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Base background: from-slate-900 to-slate-800 ──────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F172A), // slate-900
                  Color(0xFF1E293B), // slate-800
                ],
              ),
            ),
          ),

          // ── Animated gradient overlay: red/blue shift ─────────────────
          // animate-gradient-shift 15s ease infinite
          AnimatedBuilder(
            animation: _gradientCtrl,
            builder: (_, __) {
              // Simulates background-position shift 0%→100%→0%
              final t = _gradientCtrl.value;
              final shift = sin(t * 2 * pi);
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(shift, -1),
                    end: Alignment(-shift, 1),
                    colors: const [
                      Color(0x33EF4444), // red-500/20
                      Color(0x333B82F6), // blue-500/20
                      Color(0x33EF4444), // red-500/20
                    ],
                  ),
                ),
              );
            },
          ),

          // ── 50 twinkling stars ────────────────────────────────────────
          ..._stars.map((star) => _TwinklingStar(star: star, screenSize: size)),

          // ── Grid pattern: 48px, rgba(255,255,255,0.05) ────────────────
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // ── Main content — scale+fade on showContent ──────────────────
          Center(
            child: AnimatedBuilder(
              animation: _contentCtrl,
              builder: (_, child) => Opacity(
                opacity: _showContent ? _contentFade.value : 0.0,
                child: Transform.scale(
                  scale: _showContent ? _contentScale.value : 0.9,
                  child: child,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Logo with float + glow ──────────────────────────
                  AnimatedBuilder(
                    animation: _floatCtrl,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(0, _floatAnim.value),
                      child: child,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow: bg-red-500/20 blur-2xl rounded-full animate-pulse
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0x33EF4444),
                          ),
                        ),
                        // Logo container: p-3 rounded-3xl bg-white/10
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.png',
                              width: 112, // w-28
                              height: 112, // h-28
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Title — animate-reveal ──────────────────────────
                  AnimatedBuilder(
                    animation: _revealCtrl,
                    builder: (_, child) => Opacity(
                      opacity: _revealFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _revealSlide.value),
                        child: child,
                      ),
                    ),
                    child: RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Shubh',
                            style: TextStyle(
                              color: Color(0xFFEF4444), // red-500
                              fontSize: 48,             // text-5xl
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: ' Labh',
                            style: TextStyle(
                              color: Color(0xFF3B82F6), // blue-500
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Subtitle — animate-reveal-delayed ──────────────
                  AnimatedBuilder(
                    animation: _revealDelayedCtrl,
                    builder: (_, child) => Opacity(
                      opacity: _revealDelayedFade.value,
                      child: Transform.translate(
                        offset: Offset(0, _revealDelayedSlide.value),
                        child: child,
                      ),
                    ),
                    child: const Text(
                      'PATSANSTHA',
                      style: TextStyle(
                        color: Colors.white,   // text-white
                        fontSize: 20,          // text-xl
                        letterSpacing: 4,      // tracking-wider
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Bouncing dots: red, white, blue ────────────────
                  // animate-bounce staggered 0s, 0.2s, 0.4s
                  AnimatedBuilder(
                    animation: _revealDelayedCtrl,
                    builder: (_, child) => Opacity(
                      opacity: _revealDelayedFade.value,
                      child: child,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _BounceDot(
                            controller: _bounceCtrl[0],
                            color: const Color(0xFFEF4444)), // red-500
                        const SizedBox(width: 8),
                        _BounceDot(
                            controller: _bounceCtrl[1],
                            color: Colors.white),             // white
                        const SizedBox(width: 8),
                        _BounceDot(
                            controller: _bounceCtrl[2],
                            color: const Color(0xFF3B82F6)), // blue-500
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Twinkling Star ────────────────────────────────────────────────────────────
// rounded-full bg-white/10
// twinkle: opacity 0.2→1, scale 1→1.2, random duration 2s–5s, random delay

class _StarData {
  final double top;
  final double left;
  final double size;
  final double duration;
  final double delay;
  const _StarData({
    required this.top,
    required this.left,
    required this.size,
    required this.duration,
    required this.delay,
  });
}

class _TwinklingStar extends StatefulWidget {
  final _StarData star;
  final Size screenSize;
  const _TwinklingStar({required this.star, required this.screenSize});

  @override
  State<_TwinklingStar> createState() => _TwinklingStarState();
}

class _TwinklingStarState extends State<_TwinklingStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.star.duration.round()),
    );
    _opacity = Tween<double>(begin: 0.2, end: 1.0).animate(_ctrl);
    _scale = Tween<double>(begin: 1.0, end: 1.2).animate(_ctrl);

    Future.delayed(Duration(milliseconds: widget.star.delay.round()), () {
      if (mounted) _ctrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.star;
    final screen = widget.screenSize;
    return Positioned(
      top: s.top / 100 * screen.height,
      left: s.left / 100 * screen.width,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: _scale.value,
            child: Container(
              width: s.size,
              height: s.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.10),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Bounce Dot ────────────────────────────────────────────────────────────────
// w-2 h-2 rounded-full animate-bounce

class _BounceDot extends StatelessWidget {
  final AnimationController controller;
  final Color color;
  const _BounceDot({required this.controller, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Transform.translate(
        // animate-bounce: translateY 0 → -8px → 0
        offset: Offset(0, -8 * controller.value),
        child: Container(
          width: 8,  // w-2
          height: 8, // h-2
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ── Grid Painter ──────────────────────────────────────────────────────────────
// bg-[size:48px_48px] rgba(255,255,255,0.05)

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    const spacing = 48.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
