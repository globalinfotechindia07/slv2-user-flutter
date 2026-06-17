import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
// import '../auth/otp_success_screen.dart';
import '../auth/profile_setup_screen.dart';
import '../services/auth_service.dart';
import '../auth/mpin_setup_screen.dart';
import '../auth/mpin_screen.dart';


class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with TickerProviderStateMixin {
  // showOTP: false = phone input view, true = OTP input view
  bool _showOtp = false;
  bool _isVerified = false;

  final List<TextEditingController> _otpCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  String _error = '';
  bool _loading = false;
  bool _isShaking = false;

  // Timer
  int _timeLeft = 30;
  bool _canResend = false;
  Timer? _timer;

  // Shake animation
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _shakeAnim =
      Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
  );

  // Fade-up animation — animate-fade-up 0.5s ease-out
  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();
  late final Animation<double> _fadeOpacity =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  late final Animation<double> _fadeSlide =
      Tween<double>(begin: 20, end: 0).animate(
    CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    _fadeCtrl.dispose();
    for (final c in _otpCtrl) c.dispose();
    for (final f in _otpFocus) f.dispose();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = 30;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_timeLeft <= 1) {
          _timeLeft = 0;
          _canResend = true;
          t.cancel();
        } else {
          _timeLeft--;
        }
      });
    });
  }

  // ── Shake helper ──────────────────────────────────────────────────────────

  void _shake() {
    setState(() => _isShaking = true);
    _shakeCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 500),
        () => setState(() => _isShaking = false));
  }

  // ── Step 1: Send OTP ──────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (widget.phone.length < 10) {
      setState(
          () => _error = 'Please enter a valid 10-digit mobile number');
      return;
    }
    setState(() {
      _error = '';
      _loading = true;
    });
    try {
      // TODO: final result = await sendOTPToServer(widget.phone);
      final result = await ApiService.sendOtp(widget.phone);
      debugPrint('DEBUG sendOtp result: $result');
      debugPrint('DEBUG OTP sent to ${widget.phone}: ${result['otp'] ?? result['data']?['otp'] ?? 'OTP not returned by server'}');
      final success = result['success'] == true;
      if (!success) throw Exception(result['message'] ?? 'Failed to send OTP');

      if (success) {
        setState(() => _showOtp = true);
        _fadeCtrl.reset();
        _fadeCtrl.forward();
        _startTimer();
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _otpFocus[0].requestFocus());
      } else {
        setState(() => _error = 'Failed to send OTP');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Step 2: Resend OTP ────────────────────────────────────────────────────

  Future<void> _resendOtp() async {
    if (!_canResend) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    _startTimer();
    try {
      final result = await ApiService.sendOtp(widget.phone);
      if (result['success'] != true) {
        throw Exception(result['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Step 2: OTP changed ───────────────────────────────────────────────────

  void _onOtpChanged(String val, int idx) {
    if (_error.isNotEmpty) setState(() => _error = '');

    final digit = val.replaceAll(RegExp(r'\D'), '');
    if (digit.isNotEmpty && idx < 5) _otpFocus[idx + 1].requestFocus();

    // Auto-verify when all 6 filled
    final allFilled = _otpCtrl.every((c) => c.text.isNotEmpty);
    if (allFilled && idx == 5) {
      Future.delayed(const Duration(milliseconds: 100), _verifyOtp);
    }
  }

  void _onOtpBackspace(int idx) {
    if (_otpCtrl[idx].text.isEmpty && idx > 0) {
      _otpFocus[idx - 1].requestFocus();
    }
  }

Future<void> _verifyOtp() async {
  final otpVal = _otpCtrl.map((c) => c.text).join();
  setState(() => _loading = true);
  try {
    final result = await ApiService.verifyOtp(widget.phone, otpVal);
    final success = result['success'] == true;

    if (success) {
      setState(() => _isVerified = true);
      _fadeCtrl.reset();
      _fadeCtrl.forward();

      final userId = result['user_id']?.toString() ?? '';
      await AuthService.saveSession(userId: userId, phone: widget.phone);
      final token = result['token']?.toString() ?? '';
      if (token.isNotEmpty) await AuthService.saveToken(token);

      // Check registration status instead of relying on isNewUser
      final regResult = await ApiService.checkUserRegistration(widget.phone);
      final isRegistered = regResult['isRegistered'] == true;
      final hasMpin = regResult['hasMPIN'] == true;

      if (!mounted) return;

      if (!isRegistered) {
        // New user → profile setup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileSetupScreen(phone: widget.phone),
          ),
        );
      } else if (isRegistered && !hasMpin) {
        // Registered but no MPIN yet → go straight to MPIN setup
        final userProfile = Map<String, dynamic>.from(
          regResult['userProfile'] ?? regResult['user'] ?? {},
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MpinSetupScreen(
              phone: widget.phone,
              profileData: userProfile,
            ),
          ),
        );
      } else {
        // Existing user with MPIN → go directly to MpinScreen with full userProfile
        final userProfile = Map<String, dynamic>.from(
          regResult['userProfile'] ?? regResult['user'] ?? {},
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MpinScreen(userProfile: userProfile),
          ),
        );
      }
    } else {
      setState(() => _error = 'Invalid OTP. Please try again.');
      _shake();
      for (final c in _otpCtrl) c.clear();
      _otpFocus[0].requestFocus();
    }
  } catch (e) {
    setState(() => _error = 'Verification failed. Please try again.');
    for (final c in _otpCtrl) c.clear();
    _otpFocus[0].requestFocus();
  } finally {
    setState(() => _loading = false);
  }
}
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: _showOtp ? _buildOtpView() : _buildPhoneView(),
  );
}

  // ── Phone View ────────────────────────────────────────────────────────────
  // "Phone Verification" + disabled phone field + Get Verification Code button

  Widget _buildPhoneView() {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _fadeCtrl,
        builder: (_, child) => Opacity(
          opacity: _fadeOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _fadeSlide.value),
            child: child,
          ),
        ),
        child: Column(
          children: [
            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    const Text(
                      'Phone Verification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Please verify your phone number',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Phone Number label
                    const Text(
                      'Phone Number',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Phone input field (disabled — pre-filled)
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _error.isNotEmpty
                                ? const Color(0xFFEF4444).withOpacity(0.10)
                                : const Color(0xFFEF4444).withOpacity(0.04),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: TextField(
                        enabled: false,
                        controller: TextEditingController(
                            text: widget.phone),
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: 'Enter 10-digit number',
                          hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _error.isNotEmpty
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFE2E8F0),
                              width: 2,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: _error.isNotEmpty
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFE2E8F0),
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFEF4444),
                              width: 2,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),

                    // Error
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.error_outline,
                              size: 16,
                              color: Color(0xFFEF4444)),
                          const SizedBox(width: 4),
                          Text(
                            _error,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Sticky bottom button
            // sticky bottom-0 bg-white/80 backdrop-blur border-t border-slate-200
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.80),
                border: const Border(
                  top: BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: _PrimaryButton(
                label: 'Get Verification Code',
                loadingLabel: 'Sending Code...',
                loading: _loading,
                showArrow: true,
                onTap: _sendOtp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── OTP View ──────────────────────────────────────────────────────────────
  // "OTP Verification" + 6-digit boxes + timer/resend

  Widget _buildOtpView() {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _fadeCtrl,
        builder: (_, child) => Opacity(
          opacity: _fadeOpacity.value,
          child: Transform.translate(
            offset: Offset(0, _fadeSlide.value),
            child: child,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                'OTP Verification',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle with phone
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                      fontSize: 14, color: Color(0xFF475569)),
                  children: [
                    const TextSpan(
                        text:
                            'Enter the 6-digit verification code sent to\n'),
                    TextSpan(
                      text: '+91 ${widget.phone}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // OTP boxes with shake
              _ShakingRow(
                isShaking: _isShaking,
                shakeAnim: _shakeAnim,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(6, (i) {
                    return Container(
                      width: 44,
                      height: 52,
                      margin:
                          const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _otpFocus[i].hasFocus
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFFE2E8F0),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _otpCtrl[i],
                        focusNode: _otpFocus[i],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        onChanged: (val) => _onOtpChanged(val, i),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Error box — inline below OTP boxes
              if (_error.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _error,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Timer / Resend — text-center
              Center(
                child: _loading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2563EB)),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Sending...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      )
                    : !_canResend
                        ? RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Request new code in ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF475569),
                                  ),
                                ),
                                TextSpan(
                                  text: '${_timeLeft}s',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GestureDetector(
                            onTap: _resendOtp,
                            child: const Text(
                              'Resend Verification Code',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shaking Row ───────────────────────────────────────────────────────────────

class _ShakingRow extends StatelessWidget {
  final bool isShaking;
  final Animation<double> shakeAnim;
  final Widget child;
  const _ShakingRow(
      {required this.isShaking,
      required this.shakeAnim,
      required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnim,
      builder: (_, c) {
        final offset =
            isShaking ? 5 * sin(shakeAnim.value * pi * 6) : 0.0;
        return Transform.translate(
            offset: Offset(offset, 0), child: c);
      },
      child: child,
    );
  }
}

// ── Primary Button ────────────────────────────────────────────────────────────
// w-full py-4 bg-red-600 rounded-xl gradient blur overlay
// showArrow: shows ArrowRight icon like React's rotated ArrowLeft

class _PrimaryButton extends StatefulWidget {
  final String label;
  final String loadingLabel;
  final bool loading;
  final bool showArrow;
  final VoidCallback onTap;
  const _PrimaryButton({
    required this.label,
    required this.loadingLabel,
    required this.loading,
    required this.onTap,
    this.showArrow = false,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
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
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()..scale(_pressed ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        child: Stack(
          children: [
            // Gradient blur overlay
            Positioned(
  top: -4,
  left: -4,
  right: -4,
  bottom: -4,
  child: Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        colors: [
          Color(0xFFEF4444),
          Color(0xFF3B82F6),
        ],
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(color: Colors.white.withOpacity(0.75)),
    ),
  ),
),
            // Button body
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _pressed
                    ? const Color(0xFFB91C1C) // red-700
                    : const Color(0xFFDC2626), // red-600
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.loading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Text(widget.loadingLabel,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.label,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
                        ),
                        if (widget.showArrow) ...[
                          const SizedBox(width: 8),
                          AnimatedSlide(
                            offset: _pressed
                                ? const Offset(0.2, 0)
                                : Offset.zero,
                            duration: const Duration(milliseconds: 300),
                            child: const Icon(Icons.arrow_forward,
                                size: 18, color: Colors.white),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}