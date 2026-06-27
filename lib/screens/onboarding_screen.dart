import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'package:permission_handler/permission_handler.dart';

// ── Constants matching React exactly ─────────────────────────────────────────
const Color _red = Color(0xFFE11D48);       // accent for pages 0,2
const Color _blue = Color(0xFF1E40AF);      // accent for pages 1,3
const Color _red600 = Color(0xFFDC2626);    // text-red-600
const Color _blue600 = Color(0xFF2563EB);   // text-blue-600
const Color _slate900 = Color(0xFF0F172A);
const Color _slate600 = Color(0xFF475569);
const Color _slate500 = Color(0xFF64748B);
const Color _slate400 = Color(0xFF94A3B8);
const Color _slate200 = Color(0xFFE2E8F0);
const Color _slate100 = Color(0xFFF1F5F9);

// Feature icon cycle — [Landmark, FileText, IndianRupee]
const List<IconData> _featureIcons = [
  Icons.account_balance,
  Icons.description_outlined,
  Icons.currency_rupee,
];

// ── Data — matches onboardingData in React exactly ────────────────────────────
class _PageData {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color accent;
  final Color secondaryAccent;
  final List<Color> bgColors; // from-via-to
  final List<String> features;

  const _PageData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.accent,
    required this.secondaryAccent,
    required this.bgColors,
    required this.features,
  });
}

final List<_PageData> _pages = [
  _PageData(
    title: 'Shubh Labh',
    subtitle: 'Trusted Banking Partner',
    description:
        'Your trusted financial institution offering secure banking, smart investments, and personalized loan services',
    icon: Icons.account_balance,        // Landmark
    accent: _red,
    secondaryAccent: _blue,
    bgColors: [Color(0xFFFFE4E4), Color(0xFFFFF0F0), Color(0xFFE0E8FF)],
    features: ['Digital Banking', 'Secure Platform', '24/7 Support'],
  ),
  _PageData(
    title: 'Smart Savings',
    subtitle: 'Grow Your Wealth',
    description:
        'Experience premium savings accounts, fixed deposits, and innovative investment schemes for your financial growth',
    icon: Icons.savings,                // PiggyBank
    accent: _blue,
    secondaryAccent: _red,
    bgColors: [Color(0xFFE0E8FF), Color(0xFFEEF2FF), Color(0xFFFFE4E4)],
    features: ['High Interest Rates', 'Fixed Deposits', 'Recurring Deposits'],
  ),
  _PageData(
    title: 'Digital Loans',
    subtitle: 'Quick & Hassle-free',
    description:
        'Access personal and business loans with competitive interest rates and flexible repayment options',
    icon: Icons.currency_rupee,         // IndianRupee
    accent: _red,
    secondaryAccent: _blue,
    bgColors: [Color(0xFFFFE4E4), Color(0xFFFFF0F0), Color(0xFFE0E8FF)],
    features: ['Personal Loans', 'Business Loans', 'Quick Approval'],
  ),
  _PageData(
    title: 'Member Benefits',
    subtitle: 'Exclusive Advantages',
    description:
        'Join our community of successful investors and enjoy premium banking benefits with personalized service',
    icon: Icons.group,                  // Users
    accent: _blue,
    secondaryAccent: _red,
    bgColors: [Color(0xFFE0E8FF), Color(0xFFEEF2FF), Color(0xFFFFE4E4)],
    features: ['Premium Services', 'Community Events', 'Financial Advisory'],
  ),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToLogin() => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );

  // nextStep — matches React nextStep with isAnimating guard
  void _nextStep() {
    if (_currentPage < _pages.length - 1 && !_isAnimating) {
      setState(() => _isAnimating = true);
      _pageController
          .nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          )
          .then((_) => setState(() => _isAnimating = false));
    }
  }

  // previousStep — matches React previousStep, logo tap
  void _previousStep() {
    if (_currentPage > 0 && !_isAnimating) {
      setState(() => _isAnimating = true);
      _pageController
          .previousPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          )
          .then((_) => setState(() => _isAnimating = false));
    }
  }
  Future<void> _requestPermissionsAndProceed() async {
  // Request all permissions at once
  final statuses = await [
    Permission.phone,
    Permission.sms,
    Permission.contacts,
    Permission.camera,
  ].request();

  final allGranted = statuses.values.every(
    (s) => s.isGranted || s.isPermanentlyDenied,
  );

  if (!allGranted) {
    // Show a gentle nudge — don't block, just inform
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Some permissions were denied. You can enable them in Settings.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Always proceed regardless
  _goToLogin();
}

  // Blob keyframe: translate(x,y) scale — approximated with sin/cos
  // 0%: (0,0) scale(1)  25%: (20,-50) scale(1.1)
  // 50%: (-20,20) scale(0.9)  75%: (50,50) scale(0.95)
  // Offset _blobOffset(double t) {
  //   if (t < 0.25) {
  //     final p = t / 0.25;
  //     return Offset(lerpDouble(0, 20, p)!, lerpDouble(0, -50, p)!);
  //   } else if (t < 0.5) {
  //     final p = (t - 0.25) / 0.25;
  //     return Offset(lerpDouble(20, -20, p)!, lerpDouble(-50, 20, p)!);
  //   } else if (t < 0.75) {
  //     final p = (t - 0.5) / 0.25;
  //     return Offset(lerpDouble(-20, 50, p)!, lerpDouble(20, 50, p)!);
  //   } else {
  //     final p = (t - 0.75) / 0.25;
  //     return Offset(lerpDouble(50, 0, p)!, lerpDouble(50, 0, p)!);
  //   }
  // }

  // double lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        // bg-gradient-to-b transition-colors duration-700
        duration: const Duration(milliseconds: 700),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: page.bgColors,
          ),
        ),
        child: Stack(
          children: [
            // ── Grid — bg-[size:32px_32px] rgba(0,0,0,0.02) ──────────────
            Positioned.fill(child: CustomPaint(painter: _GridPainter())),

            // ── Main layout ───────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  // ── Header — pt-4 flex justify-between items-center ────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Logo button — disabled+opacity-50 on page 0
                        GestureDetector(
                          onTap: _previousStep,
                          child: AnimatedOpacity(
                            duration: const Duration(milliseconds: 300),
                            opacity: _currentPage == 0 ? 0.5 : 1.0,
                            child: Row(
                              children: [
                                // p-2 rounded-xl bg-white shadow-sm
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.account_balance, // Landmark
                                    color: page.accent,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // text-base font-semibold
                                // Shubh = text-red-600, Labh = text-blue-600
                                RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Shubh',
                                        style: TextStyle(
                                          color: _red600,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                      TextSpan(
                                        text: ' Labh',
                                        style: TextStyle(
                                          color: _blue600,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // text-sm font-medium text-slate-500
                        Row(
                          children: [
                            Text(
                              '${_currentPage + 1}/${_pages.length}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _slate500,
                              ),
                            ),
                            // h-6 w-[1px] bg-slate-200
                            Container(
                              height: 24,
                              width: 1,
                              color: _slate200,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                            ),
                            GestureDetector(
                              onTap: _requestPermissionsAndProceed,
                              child: const Text(
                                'Skip',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: _slate500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Progress bar — pt-3 flex space-x-1 ────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: List.generate(_pages.length, (i) {
                        // index%2==0 → accent, odd → secondaryAccent
                        final barColor =
                            i % 2 == 0 ? page.accent : page.secondaryAccent;
                        return Expanded(
                          child: Container(
                            height: 4, // sm:h-1
                            margin:
                                const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: _slate100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: AnimatedFractionallySizedBox(
                              // transition-all duration-700 ease-out
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOut,
                              widthFactor: i <= _currentPage ? 1.0 : 0.0,
                              alignment: Alignment.centerLeft,
                              child: Container(color: barColor),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // ── Main content — flex-1 items-center justify-center ──
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _pages.length,
                      onPageChanged: (i) =>
                          setState(() => _currentPage = i),
                      itemBuilder: (_, i) =>
                          _PageContent(data: _pages[i]),
                    ),
                  ),

                  // ── Footer — py-4, single full-width button ────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: isLast
                        ? _GetStartedButton(
                            accent: page.accent,
                            onTap: _requestPermissionsAndProceed,  // ← changed
                          )
                        : _ContinueButton(
                            onTap: _nextStep,
                            isAnimating: _isAnimating,
                          ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Blob — w-96 h-96 rounded-full ────────────────────────────────────────────

// class _Blob extends StatelessWidget {
//   final Color color;
//   final double opacity;
//   const _Blob({required this.color, required this.opacity});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: 260,
//       height: 260,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: color.withOpacity(opacity),
//       ),
//     );
//   }
// }

// ── Page Content ──────────────────────────────────────────────────────────────
// flex-1 flex items-center justify-center text-center

class _PageContent extends StatefulWidget {
  final _PageData data;
  const _PageContent({required this.data});

  @override
  State<_PageContent> createState() => _PageContentState();
}

class _PageContentState extends State<_PageContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 700))
        ..forward();

  // animate-fade-in for title
  late final Animation<double> _titleFade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

  // slideIn 0.5s ease-out forwards ${delay}s for feature cards
  // delay = idx * 0.1 (React uses 0.1, we use 0.15 for smoother feel)
  late final List<Animation<double>> _cardSlide = List.generate(3, (i) {
    final start = (i * 0.15).clamp(0.0, 0.85);
    final end = (start + 0.55).clamp(0.0, 1.0);
    return Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOut)),
    );
  });

  late final List<Animation<double>> _cardFade = List.generate(3, (i) {
    final start = (i * 0.15).clamp(0.0, 0.85);
    final end = (start + 0.55).clamp(0.0, 1.0);
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _ctrl,
          curve: Interval(start, end, curve: Curves.easeOut)),
    );
  });

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;

    // Centered vertically — matches flex-1 items-center justify-center
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Icon box — w-20 h-20 rounded-3xl bg-white shadow-lg ─────
            _IconBox(data: d),

            const SizedBox(height: 24), // space-y-6

            // ── Title — text-4xl font-bold tracking-tight text-slate-900 ─
            // animate-fade-in
            FadeTransition(
              opacity: _titleFade,
              child: Text(
                d.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 38,       // text-4xl
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5, // tracking-tight
                  color: _slate900,
                ),
              ),
            ),

            const SizedBox(height: 12), // space-y-3

            // ── Subtitle — text-lg font-medium color=accent transition-all ─
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 500),
              style: TextStyle(
                fontSize: 18,         // text-lg
                fontWeight: FontWeight.w500,
                color: d.accent,
              ),
              child: Text(d.subtitle, textAlign: TextAlign.center),
            ),

            const SizedBox(height: 8),

            // ── Description — text-base text-slate-600 leading-relaxed ───
            Text(
              d.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,         // text-base
                color: _slate600,
                height: 1.6,          // leading-relaxed
              ),
            ),

            const SizedBox(height: 20),

            // ── Feature cards — flex flex-wrap justify-center gap-2 ──────
            // On mobile: w-full stacked. slideIn with delay idx*0.1
            ...List.generate(d.features.length, (i) {
              return AnimatedBuilder(
                animation: _ctrl,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _cardSlide[i].value),
                  child: Opacity(
                      opacity: _cardFade[i].value, child: child),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _FeatureCard(
                    icon: _featureIcons[i % 3],
                    label: d.features[i],
                    // idx%2==0 → accent, else secondaryAccent
                    accent: i % 2 == 0 ? d.accent : d.secondaryAccent,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Icon Box ──────────────────────────────────────────────────────────────────
// inline-flex w-20 h-20 rounded-3xl bg-white shadow-lg overflow-hidden
// hover:scale-105 transition-all duration-500
// overlay gradient: opacity-0 → opacity-100 on hover
// icon: w-10 h-10 hover:scale-110

class _IconBox extends StatefulWidget {
  final _PageData data;
  const _IconBox({required this.data});

  @override
  State<_IconBox> createState() => _IconBoxState();
}

class _IconBoxState extends State<_IconBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 500)); // duration-500
  bool _pressed = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _ctrl.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _ctrl.reverse();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _ctrl.reverse();
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(
          scale: 1.0 + _ctrl.value * 0.05, // hover:scale-105
          child: child,
        ),
        child: Container(
          width: 80,  // w-20
          height: 80, // h-20
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24), // rounded-3xl
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(
            children: [
              // Overlay: absolute inset-0 opacity-0 group-hover:opacity-100
              // linear-gradient(45deg, accent*20%, secondaryAccent*20%)
              AnimatedOpacity(
                opacity: _pressed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        d.accent.withOpacity(0.125),       // accent + "20" hex
                        d.secondaryAccent.withOpacity(0.125),
                      ],
                    ),
                  ),
                ),
              ),
              // Icon — w-10 h-10 hover:scale-110
              Center(
                child: AnimatedBuilder(
                  animation: _ctrl,
                  builder: (_, child) => Transform.scale(
                    scale: 1.0 + _ctrl.value * 0.10, // hover:scale-110
                    child: child,
                  ),
                  child: Icon(d.icon, color: d.accent, size: 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Feature Card ──────────────────────────────────────────────────────────────
// bg-white/90 backdrop-blur px-3 py-1.5 rounded-xl shadow-sm
// w-full (mobile), hover:scale-105 hover:shadow-md
// border: 1px solid accent+"10" (hex opacity)

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color accent;
  const _FeatureCard(
      {required this.icon, required this.label, required this.accent});

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300), // duration-500 → 300 on mobile
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scale(_pressed ? 1.05 : 1.0), // hover:scale-105
        transformAlignment: Alignment.center,
        width: double.infinity,           // w-full on mobile
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 10), // px-3 py-1.5
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9), // bg-white/90
          borderRadius: BorderRadius.circular(12), // rounded-xl
          border: Border.all(
            color: widget.accent.withOpacity(0.0627), // accent+"10" in hex = 6.27%
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(_pressed ? 0.10 : 0.05),
              blurRadius: _pressed ? 12 : 6, // hover:shadow-md
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: widget.accent, size: 16), // w-4 h-4
            const SizedBox(width: 8), // space-x-2
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,               // text-sm
                fontWeight: FontWeight.w500, // font-medium
                color: Color(0xFF334155),   // text-slate-700
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Continue Button ───────────────────────────────────────────────────────────
// w-full group hover:scale-[1.02] transition-all duration-300
// inner: p-4 bg-white rounded-xl shadow-sm border-slate-100
//   flex justify-between:
//     "Continue" text-base font-semibold text-slate-900
//     "Next" + ChevronRight text-slate-400, chevron translates on hover

class _ContinueButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isAnimating;
  const _ContinueButton(
      {required this.onTap, required this.isAnimating});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isAnimating
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.isAnimating
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scale(_pressed ? 1.02 : 1.0), // hover:scale-[1.02]
        transformAlignment: Alignment.center,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // p-4 sm:p-6
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // rounded-xl
          border: Border.all(
            // hover:border-slate-200, default border-slate-100
            color: _pressed ? _slate200 : _slate100,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withOpacity(_pressed ? 0.08 : 0.04), // hover:shadow-md
              blurRadius: _pressed ? 12 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // "Continue" — text-base font-semibold text-slate-900
            const Text(
              'Continue',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _slate900,
              ),
            ),
            Row(
              children: [
                // "Next" text-sm font-medium text-slate-400
                const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _slate400,
                  ),
                ),
                const SizedBox(width: 8),
                // ChevronRight — group-hover:translate-x-1
                AnimatedSlide(
                  offset: _pressed
                      ? const Offset(0.15, 0)
                      : Offset.zero,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: _slate400,
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

// ── Get Started Button ────────────────────────────────────────────────────────
// w-full hover:scale-[1.02] transition-all duration-300
// inner: p-4 rounded-xl flex justify-center space-x-2
//   bg=accent boxShadow: 0 8px 32px accent*40%
//   "Get Started" text-base font-semibold text-white
//   ArrowRight — group-hover:translate-x-1

class _GetStartedButton extends StatefulWidget {
  final Color accent;
  final VoidCallback onTap;
  const _GetStartedButton({required this.accent, required this.onTap});

  @override
  State<_GetStartedButton> createState() => _GetStartedButtonState();
}

class _GetStartedButtonState extends State<_GetStartedButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..scale(_pressed ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 20), // p-4 sm:p-6
        decoration: BoxDecoration(
          color: widget.accent,
          borderRadius: BorderRadius.circular(12), // rounded-xl
          boxShadow: [
            // 0 8px 32px accent*40%
            BoxShadow(
              color: widget.accent.withOpacity(0.40),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // justify-center
          children: [
            // "Get Started" text-base font-semibold text-white
            const Text(
              'Get Started',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8), // space-x-2
            // ArrowRight — group-hover:translate-x-1
            AnimatedSlide(
              offset: _pressed ? const Offset(0.2, 0) : Offset.zero,
              duration: const Duration(milliseconds: 300),
              child: const Icon(
                Icons.arrow_forward,
                size: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Grid Painter ──────────────────────────────────────────────────────────────
// bg-[linear-gradient(rgba(0,0,0,0.02)_1px,...)] bg-[size:32px_32px]

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.02)
      ..strokeWidth = 1;
    const spacing = 32.0;
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