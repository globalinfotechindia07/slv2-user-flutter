import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

// - Header: Back + service title + Help/FAQ icon
// - Image carousel (auto-slide) per service type
// - Personal details form: name, email, phone, address, aadhaar, pan (required/optional)
// - Fixed bottom Submit button
// - Success screen with green checkmark + confetti animation
// - FAQ sidebar via help icon

class OtherLoanServiceDetailScreen extends StatefulWidget {
  final Map<String, dynamic> serviceDetails;
  final Map<String, dynamic> userProfile;

  const OtherLoanServiceDetailScreen({
    super.key,
    required this.serviceDetails,
    required this.userProfile,
  });

  @override
  State<OtherLoanServiceDetailScreen> createState() =>
      _OtherLoanServiceDetailScreenState();
}

class _OtherLoanServiceDetailScreenState
    extends State<OtherLoanServiceDetailScreen>
    with TickerProviderStateMixin {
  // Form controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _aadhaarCtrl = TextEditingController();
  final _panCtrl = TextEditingController();

  Map<String, String> _errors = {};
  bool _loading = false;
  bool _isSubmitted = false;
  bool _isFaqOpen = false;

  // Carousel
  final PageController _pageController = PageController();
  int _currentSlide = 0;

  // Confetti animation
  late final AnimationController _confettiCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void initState() {
    super.initState();
    // Auto-advance carousel every 3s
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return false;
      final slides = _getSlides();
      if (slides.isNotEmpty && _pageController.hasClients) {
        final next = (_currentSlide + 1) % slides.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
      return mounted && !_isSubmitted;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _aadhaarCtrl.dispose();
    _panCtrl.dispose();
    _pageController.dispose();
    _confettiCtrl.dispose();
    super.dispose();
  }

  // ── Slides data — matches React slidess object ────────────────────────────

  List<_SlideData> _getSlides() {
    final title = widget.serviceDetails['pstitle']?.toString() ?? '';
    final isLoan = title.toLowerCase().contains('loan');
    final key = isLoan ? 'Loan' : title;

    final Map<String, List<_SlideData>> slidess = {
  'FD Scheme': [
    _SlideData('Fixed Deposit Plans',
        'Secure your future with our high-interest FD schemes',
        'assets/images/fd1.png'),
    _SlideData('Guaranteed Returns',
        'Get assured returns up to 7.5% per annum',
        'assets/images/fd22.png'),
    _SlideData('Flexible Tenure',
        'Choose tenure from 7 days to 10 years',
        'assets/images/fd33.png'),
  ],
  'Savings Account': [
    _SlideData('Savings Account',
        'Start your savings journey with zero balance account',
        'assets/images/s1.png'),
    _SlideData('Digital Banking',
        '24/7 access to your account with our mobile banking',
        'assets/images/s2.png'),
    _SlideData('Additional Benefits',
        'Free ATM card and unlimited transactions',
        'assets/images/s3.png'),
  ],
  'Daily Account': [
    _SlideData('Convenient Deposits',
        'Deposit your daily earnings with ease',
        'assets/images/d1.png'),
    _SlideData('No Minimum Balance',
        'Maintain your account without worrying about a minimum balance',
        'assets/images/d2.png'),
    _SlideData('Instant Access',
        'Get immediate access to your funds anytime',
        'assets/images/d3.png'),
  ],
  'Current Account': [
    _SlideData('Business-Friendly Features',
        'Manage your business transactions seamlessly',
        'assets/images/d1.png'),
    _SlideData('Overdraft Facility',
        'Enjoy an overdraft facility for smooth operations',
        'assets/images/d2.png'),
    _SlideData('Unlimited Transactions',
        'Conduct unlimited transactions without extra fees',
        'assets/images/d3.png'),
  ],
  'Insurance Services': [
    _SlideData('Vehicle Insurance',
        'Protect your vehicle with comprehensive insurance',
        'assets/images/i3.png'),
    _SlideData('Health Insurance',
        'Secure your health with affordable medical coverage',
        'assets/images/i1.png'),
    _SlideData('Life Insurance',
        'Enjoy life worry-free with life insurance',
        'assets/images/i2.png'),
  ],
  'Loan': [
    _SlideData('Hassle-free Loan Process',
        'Quick approval with competitive interest rates',
        'assets/images/l1.png'),
    _SlideData('Flexible Repayment',
        'Make your dream home a reality with flexible EMIs',
        'assets/images/fd33.png'),
    _SlideData('Quick Approvals',
        'Drive your dream car with our vehicle loan offers',
        'assets/images/l2.png'),
  ],
  'RD Scheme': [
    _SlideData('Regular Savings',
        'Save a fixed amount every month with attractive interest rates',
        'assets/images/fd1.png'),
    _SlideData('Flexible Deposit Plans',
        'Choose plans that suit your savings needs',
        'assets/images/fd22.png'),
    _SlideData('Higher Returns',
        'Earn higher returns compared to a savings account',
        'assets/images/fd33.png'),
  ],
  'Sukanya yojana': [
    _SlideData("Secure Girl's Future",
        "A government-backed scheme to support girl child education",
        'assets/images/sk1.png'),
    _SlideData('High Returns',
        'Earn up to 8% interest with tax benefits',
        'assets/images/fd33.png'),
    _SlideData('Flexible Deposits',
        'Start with a minimum deposit and save regularly',
        'assets/images/sk2.png'),
  ],
};

    return slidess[key] ?? [];
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool _validateForm() {
    final e = <String, String>{};
    if (_nameCtrl.text.trim().isEmpty) e['names'] = 'Name is required';
    if (_phoneCtrl.text.trim().isEmpty) {
      e['phone'] = 'Phone number is required';
    } else if (!RegExp(r'^\d{10}$').hasMatch(_phoneCtrl.text.trim())) {
      e['phone'] = 'Invalid phone number';
    }
    if (_addressCtrl.text.trim().isEmpty) e['address'] = 'Address is required';
    setState(() => _errors = e);
    return e.isEmpty;
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _handleSubmit() async {
    if (!_validateForm()) return;
    setState(() => _loading = true);
    try {
      final formData = {
        'names': _nameCtrl.text,
        'email': _emailCtrl.text,
        'phone': _phoneCtrl.text,
        'address': _addressCtrl.text,
        'adhar': _aadhaarCtrl.text,
        'pan': _panCtrl.text,
      };

      // TODO: await ApiService.addForm(formData);
      await Future.delayed(const Duration(milliseconds: 800)); // mock

      // Send notification
      // TODO: await ApiService.sendNotification(...)
      setState(() => _isSubmitted = true);
      _confettiCtrl.forward();

      // Auto-navigate after 5s
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      setState(() => _errors = {'submit': e.toString()});
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) return _SuccessScreen(onClose: () => Navigator.pop(context));

    final slides = _getSlides();
    final title = widget.serviceDetails['pstitle']?.toString() ??
        'Loan Application';

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF1F2),
                  Colors.white,
                  Color(0xFFEFF6FF),
                ],
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.80),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          children: const [
                            Icon(Icons.arrow_back,
                                size: 16, color: Color(0xFF475569)),
                            SizedBox(width: 6),
                            Text('Back',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF475569))),
                          ],
                        ),
                      ),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _isFaqOpen = true),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Icon(Icons.help_outline,
                              size: 24, color: Color(0xFF475569)),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Scrollable content ───────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Carousel ─────────────────────────────────────
                        if (slides.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                16, 16, 16, 0),
                            child: Column(
                              children: [
                                SizedBox(
                                  height: 200,
                                  child: PageView.builder(
                                    controller: _pageController,
                                    itemCount: slides.length,
                                    onPageChanged: (i) => setState(
                                        () => _currentSlide = i),
                                    itemBuilder: (_, i) {
                                      final slide = slides[i];
                                      return Column(
                                        children: [
                                          Text(
                                            slide.title,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.asset(
                                              slide.image,
                                              height: 120,
                                              width: double.infinity,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Dots indicator
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: List.generate(
                                      slides.length, (i) {
                                    return AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 300),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      width:
                                          i == _currentSlide ? 20 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: i == _currentSlide
                                            ? const Color(0xFFDC2626)
                                            : const Color(0xFFE2E8F0),
                                        borderRadius:
                                            BorderRadius.circular(4),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          ),

                        // ── Section header ───────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                              16, 20, 16, 4),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Personal Details',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Please enter the following details and we will fetch your personal information.',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF475569)),
                              ),
                            ],
                          ),
                        ),

                        // ── Form fields ──────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16),
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              _InputField(
                                label: 'Name',
                                controller: _nameCtrl,
                                hint: 'Enter your full name',
                                error: _errors['names'],
                                onChanged: (_) => setState(
                                    () => _errors.remove('names')),
                              ),
                              const SizedBox(height: 14),
                              _InputField(
                                label: 'Email',
                                controller: _emailCtrl,
                                hint: 'Enter your email',
                                optional: true,
                                keyboardType:
                                    TextInputType.emailAddress,
                                error: _errors['email'],
                                onChanged: (_) => setState(
                                    () => _errors.remove('email')),
                              ),
                              const SizedBox(height: 14),
                              _InputField(
                                label: 'Phone',
                                controller: _phoneCtrl,
                                hint: 'Enter your phone number',
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                error: _errors['phone'],
                                onChanged: (_) => setState(
                                    () => _errors.remove('phone')),
                              ),
                              const SizedBox(height: 14),
                              _InputField(
                                label: 'Address',
                                controller: _addressCtrl,
                                hint: 'Enter your full address',
                                maxLines: 3,
                                error: _errors['address'],
                                onChanged: (_) => setState(
                                    () => _errors.remove('address')),
                              ),
                              const SizedBox(height: 14),
                              _InputField(
                                label: 'Aadhaar Number',
                                controller: _aadhaarCtrl,
                                hint: 'Enter Aadhaar number',
                                optional: true,
                                keyboardType: TextInputType.number,
                                maxLength: 12,
                                error: _errors['adhar'],
                                onChanged: (_) => setState(
                                    () => _errors.remove('adhar')),
                              ),
                              const SizedBox(height: 14),
                              _InputField(
                                label: 'PAN Card Number',
                                controller: _panCtrl,
                                hint: 'Enter PAN card number',
                                optional: true,
                                textCapitalization:
                                    TextCapitalization.characters,
                                maxLength: 10,
                                error: _errors['pan'],
                                onChanged: (_) => setState(
                                    () => _errors.remove('pan')),
                              ),
                              const SizedBox(height: 16),

                              // Submit error
                              if (_errors['submit'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: 12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.error_outline,
                                          size: 16,
                                          color: Color(0xFFEF4444)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          _errors['submit']!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFFEF4444),
                                          ),
                                        ),
                                      ),
                                    ],
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

          // ── Fixed bottom Submit button ─────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                border: const Border(
                    top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: _SubmitButton(
                    loading: _loading, onTap: _handleSubmit),
              ),
            ),
          ),

          // ── FAQ Sidebar overlay ────────────────────────────────────────
          if (_isFaqOpen)
            _FaqSidebar(
              title: widget.serviceDetails['pstitle']?.toString() ??
                  'FAQ',
              onClose: () =>
                  setState(() => _isFaqOpen = false),
            ),
        ],
      ),
    );
  }
}

// ── Success Screen ────────────────────────────────────────────────────────────

class _SuccessScreen extends StatefulWidget {
  final VoidCallback onClose;
  const _SuccessScreen({required this.onClose});

  @override
  State<_SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<_SuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bounceCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  late final Animation<double> _bounce =
      Tween<double>(begin: 0, end: -12).animate(
    CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
  );

  // Confetti particles
  late final List<_Particle> _particles = List.generate(80, (_) {
    final rng = DateTime.now().microsecondsSinceEpoch % 1000;
    return _Particle(rng);
  });

  late final AnimationController _confettiCtrl = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) widget.onClose();
    });
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _confettiCtrl.dispose();
    super.dispose();
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
                colors: [
                  Color(0xFFFFF1F2),
                  Colors.white,
                  Color(0xFFEFF6FF),
                ],
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // Confetti
          AnimatedBuilder(
            animation: _confettiCtrl,
            builder: (_, __) => CustomPaint(
              painter: _ConfettiPainter(
                  progress: _confettiCtrl.value,
                  particles: _particles),
              child: const SizedBox.expand(),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bouncing green checkmark
                AnimatedBuilder(
                  animation: _bounceCtrl,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _bounce.value),
                    child: child,
                  ),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        size: 40, color: Colors.white),
                  ),
                ),

                const SizedBox(height: 28),

                const Text(
                  'Congratulations!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Your application form has been submitted successfully!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: Color(0xFF475569)),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Our executives will contact you soon.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14, color: Color(0xFF475569)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Confetti Painter ──────────────────────────────────────────────────────────

class _Particle {
  final double x;
  final double startY;
  final double speed;
  final Color color;
  final double size;

  _Particle(int seed)
      : x = (seed * 7 % 100) / 100.0,
        startY = -(seed * 13 % 30) / 100.0,
        speed = 0.3 + (seed * 3 % 7) / 10.0,
        color = [
          const Color(0xFFEF4444),
          const Color(0xFF3B82F6),
          const Color(0xFF22C55E),
          const Color(0xFFF59E0B),
          const Color(0xFF8B5CF6),
        ][(seed * 11) % 5],
        size = 6.0 + (seed * 5 % 8);

  Offset position(double progress) {
    return Offset(x, startY + progress * speed);
  }
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<_Particle> particles;

  _ConfettiPainter({required this.progress, required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in particles) {
      final pos = p.position(progress);
      if (pos.dy > 1.1) continue;
      paint.color = p.color.withOpacity(1 - progress * 0.5);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(pos.dx * size.width, pos.dy * size.height),
            width: p.size,
            height: p.size * 0.6,
          ),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) =>
      old.progress != progress;
}

// ── FAQ Sidebar ───────────────────────────────────────────────────────────────

class _FaqSidebar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;
  const _FaqSidebar({required this.title, required this.onClose});

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'What documents are required?',
      'a':
          'You need Aadhaar card, PAN card, address proof, and income documents.'
    },
    {
      'q': 'How long does approval take?',
      'a':
          'Applications are typically processed within 2-3 business days.'
    },
    {
      'q': 'What is the interest rate?',
      'a':
          'Interest rates vary by product. Our executives will provide exact rates on contact.'
    },
    {
      'q': 'Can I apply online?',
      'a':
          'Yes, you can submit your application through this form and our team will follow up.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.40),
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: MediaQuery.of(context).size.width * 0.82,
              height: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                          16, 16, 16, 0),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FAQ - $title',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          GestureDetector(
                            onTap: onClose,
                            child: const Icon(Icons.close,
                                size: 24,
                                color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: _faqs
                            .map((faq) => ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: Text(faq['q']!,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight:
                                              FontWeight.w600)),
                                  children: [
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(
                                              bottom: 8),
                                      child: Text(faq['a']!,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(
                                                  0xFF475569))),
                                    ),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Input Field ───────────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? error;
  final bool optional;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.label,
    required this.controller,
    this.hint,
    this.error,
    this.optional = false,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF334155))),
            if (optional)
              const Text(' (Optional)',
                  style: TextStyle(
                      fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          maxLength: maxLength,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFF94A3B8)),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFDC2626), width: 2),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline,
                  size: 14, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Text(error!,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFEF4444))),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Submit Button ─────────────────────────────────────────────────────────────

class _SubmitButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;
  const _SubmitButton({required this.loading, required this.onTap});

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        if (!widget.loading) widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0xFFB91C1C)
              : const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFDC2626).withOpacity(0.30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: widget.loading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text('Submitting...',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ],
              )
            : const Text(
                'Submit Application',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15),
              ),
      ),
    );
  }
}

// ── Slide Data ────────────────────────────────────────────────────────────────

class _SlideData {
  final String title;
  final String description;
  final String image;
  const _SlideData(this.title, this.description, this.image);
}

// ── Grid Painter ──────────────────────────────────────────────────────────────

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