import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../auth/profile_setup_screen.dart';
import '../auth/mpin_setup_screen.dart';
import '../auth/mpin_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  OtpVerificationScreen
//
//  Three visual states:
//    1. Phone entry   — user types number via intl_phone_number_input
//    2. OTP entry     — 6 boxes, 30 s countdown, resend, shake on error
//    3. Verified      — bouncing checkmark + dots → smart routing
//
//  SIM picker dialog shows EVERY TIME the phone-entry screen is displayed.
// ─────────────────────────────────────────────────────────────────────────────
class OtpVerificationScreen extends StatefulWidget {
  final String? savedPhoneNumber;
  final String? initialRequestId;
  final VoidCallback onBack;

  const OtpVerificationScreen({
    super.key,
    this.savedPhoneNumber,
    this.initialRequestId,
    required this.onBack,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

enum _ScreenState { phone, otp, verified }

class _OtpVerificationScreenState extends State<OtpVerificationScreen>
    with TickerProviderStateMixin {
  // ── App state ─────────────────────────────────────────────────────────────
  _ScreenState _screenState = _ScreenState.phone;
  String _phoneNumber = '';       // plain 10-digit local number
  final List<String> _otp = List.filled(6, '');
  String _error = '';
  String _requestId = '';
  bool _loading = false;
  int _timeLeft = 30;
  bool _canResend = false;
  Timer? _countdownTimer;

  Map<String, dynamic>? _regResult;

  // ── intl_phone_number_input ───────────────────────────────────────────────
  final _phoneController = TextEditingController();
  PhoneNumber _intlPhoneNumber = PhoneNumber(isoCode: 'IN');

  // ── OTP controllers ───────────────────────────────────────────────────────
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());
  final _phoneFocusNode = FocusNode();

  // ── Shake animation ───────────────────────────────────────────────────────
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _shakeAnim =
      Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut),
  );

  // ── Fade-up ───────────────────────────────────────────────────────────────
  late final AnimationController _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _fadeAnim =
      CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  late final Animation<Offset> _slideAnim = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut));

  // ── Verified checkmark bounce ─────────────────────────────────────────────
  late final AnimationController _bounceController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _bounceAnim =
      Tween<double>(begin: 0, end: -12).animate(
    CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
  );

  late final AnimationController _dot1Controller = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 600));
  late final AnimationController _dot2Controller = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 600));
  late final AnimationController _dot3Controller = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 600));

  late final Animation<double> _dot1Anim = Tween<double>(begin: 0, end: -10)
      .animate(CurvedAnimation(parent: _dot1Controller, curve: Curves.easeInOut));
  late final Animation<double> _dot2Anim = Tween<double>(begin: 0, end: -10)
      .animate(CurvedAnimation(parent: _dot2Controller, curve: Curves.easeInOut));
  late final Animation<double> _dot3Anim = Tween<double>(begin: 0, end: -10)
      .animate(CurvedAnimation(parent: _dot3Controller, curve: Curves.easeInOut));

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    debugPrint('OTP SCREEN initState — savedPhone: "${widget.savedPhoneNumber}"');
    debugPrint(
        'initState — savedPhone: "${widget.savedPhoneNumber}", '
        'initialRequestId: "${widget.initialRequestId}"');

    if (widget.savedPhoneNumber != null &&
        widget.savedPhoneNumber!.isNotEmpty) {
      _phoneNumber = widget.savedPhoneNumber!;
      _phoneController.text = _phoneNumber;
      _intlPhoneNumber =
          PhoneNumber(isoCode: 'IN', phoneNumber: _phoneNumber);
      if (widget.initialRequestId != null &&
          widget.initialRequestId!.isNotEmpty) {
        _requestId = widget.initialRequestId!;
      }
    }

    for (final f in _otpFocusNodes) {
      f.addListener(() => setState(() {}));
    }
    _phoneFocusNode.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.savedPhoneNumber != null &&
          widget.savedPhoneNumber!.isNotEmpty) {
        _switchTo(_ScreenState.otp);
      } else {
        _fadeCtrl.forward();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _shakeCtrl.dispose();
    _fadeCtrl.dispose();
    _bounceController.dispose();
    _dot1Controller.dispose();
    _dot2Controller.dispose();
    _dot3Controller.dispose();
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    super.dispose();
  }

  // ── State switcher ────────────────────────────────────────────────────────
  void _switchTo(_ScreenState next, {String requestId = ''}) {
    debugPrint(
        '_switchTo called — requestId param: "$requestId", '
        'current _requestId: "$_requestId"');
    setState(() {
      _screenState = next;
      _error = '';
      if (requestId.isNotEmpty) _requestId = requestId;
    });
    debugPrint('_switchTo after setState — _requestId: "$_requestId"');
    _fadeCtrl.forward(from: 0);

    if (next == _ScreenState.otp) {
      _startCountdown();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _otpFocusNodes[0].requestFocus());
    }

    if (next == _ScreenState.verified) {
      _bounceController.repeat(reverse: true);
      _dot1Controller.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _dot2Controller.repeat(reverse: true);
      });
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) _dot3Controller.repeat(reverse: true);
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) _navigateAfterVerify();
      });
    }
  }

  // ── Smart routing ─────────────────────────────────────────────────────────
  void _navigateAfterVerify() {
    if (_regResult == null) return;

    final isRegistered = _regResult!['isRegistered'] == true;
    final hasMpin = _regResult!['hasMPIN'] == true;

    if (!isRegistered) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => ProfileSetupScreen(phone: _phoneNumber)));
    } else if (!hasMpin) {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  MpinSetupScreen(phone: _phoneNumber, profileData: const {})));
    } else {
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => MpinScreen(
                    userProfile: {'phoneNumber': _phoneNumber},
                  )));
    }
  }

  // ── Countdown timer ───────────────────────────────────────────────────────
  void _startCountdown() {
    _countdownTimer?.cancel();
    setState(() {
      _timeLeft = 30;
      _canResend = false;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
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

  // ── Phone submit ──────────────────────────────────────────────────────────
  Future<void> _handlePhoneSubmit() async {
    if (_phoneNumber.length < 10) {
      setState(
          () => _error = 'Please enter a valid 10-digit mobile number');
      return;
    }
    if (_requestId.isNotEmpty) {
      _switchTo(_ScreenState.otp);
      return;
    }
    setState(() {
      _error = '';
      _loading = true;
    });
    try {
      final result = await ApiService.sendOtp(_phoneNumber);
      debugPrint('SEND OTP response: $result');
      final statusCode = result['statusCode'] as int? ?? 0;
      if (statusCode == 429) {
        _showRateLimitDialog();
        return;
      }
      if (result['success'] == true) {
        final data = result['data'];
        final requestId =
            (data is Map ? data['request_id'] : null) as String? ?? '';
        debugPrint('EXTRACTED requestId: "$requestId"');
        _switchTo(_ScreenState.otp, requestId: requestId);
      } else {
        setState(() => _error = result['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      setState(() => _error = 'Failed to send OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;
    setState(() => _loading = true);
    try {
      final result = await ApiService.resendOtp(_requestId);
      debugPrint('RESEND OTP response: $result');
      final statusCode = result['statusCode'] as int? ?? 0;

      if (statusCode == 429) {
        _showRateLimitDialog();
        return;
      }
      if (result['success'] == true) {
        final newId = result['data']?['request_id'] as String? ?? '';
        if (newId.isNotEmpty) setState(() => _requestId = newId);
        _startCountdown();
      } else if (statusCode == 400) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Session expired. Please start over.')),
          );
          _handleChangeNumber();
        }
      } else {
        setState(
            () => _error = result['message'] ?? 'Failed to resend OTP');
      }
    } catch (e) {
      setState(() => _error = 'Failed to resend OTP.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showRateLimitDialog() {
    int secondsLeft = 300;
    Timer? dialogTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            dialogTimer ??=
                Timer.periodic(const Duration(seconds: 1), (t) {
              if (!mounted) {
                t.cancel();
                return;
              }
              if (secondsLeft <= 1) {
                t.cancel();
                Navigator.of(ctx).pop();
              } else {
                setDialogState(() => secondsLeft--);
              }
            });

            final minutes =
                (secondsLeft ~/ 60).toString().padLeft(2, '0');
            final seconds =
                (secondsLeft % 60).toString().padLeft(2, '0');

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.timer_outlined, color: Color(0xFFEF4444)),
                  SizedBox(width: 8),
                  Text('Too Many Attempts'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You have made too many OTP requests. '
                    'Please wait before trying again.',
                    style: TextStyle(
                        fontSize: 14, color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$minutes:$seconds',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: null,
                  child: Text(
                    'Please wait ($minutes:$seconds)',
                    style: const TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => dialogTimer?.cancel());
  }

  // ── OTP digit change ──────────────────────────────────────────────────────
  Future<void> _handleOtpChange(String val, int idx) async {
    final digit = val.replaceAll(RegExp(r'\D'), '');
    final sanitized = digit.isNotEmpty ? digit[0] : '';

    _otpControllers[idx].text = sanitized;
    if (sanitized.isNotEmpty) {
      _otpControllers[idx].selection =
          const TextSelection.collapsed(offset: 1);
    }
    setState(() {
      _otp[idx] = sanitized;
      if (_error.isNotEmpty) _error = '';
    });

    if (sanitized.isNotEmpty && idx < 5) {
      _otpFocusNodes[idx + 1].requestFocus();
    }

    final newOtp = _otpControllers.map((c) => c.text).toList();
    if (idx == 5 && newOtp.every((d) => d.isNotEmpty)) {
      await _verifyOtp(newOtp.join());
    }
  }

  void _handleBackspace(int idx) {
    if (_otpControllers[idx].text.isEmpty && idx > 0) {
      _otpFocusNodes[idx - 1].requestFocus();
    }
  }

  // ── Verify OTP ────────────────────────────────────────────────────────────
  Future<void> _verifyOtp(String enteredOtp) async {
    setState(() => _loading = true);
    debugPrint('VERIFY → requestId: $_requestId, otp: $enteredOtp');
    try {
      final result = await ApiService.verifyOtp(_requestId, enteredOtp);
      final statusCode = result['statusCode'] as int? ?? 0;

      if (statusCode == 429) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Too many attempts. Please slow down.')),
        );
        return;
      }

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>? ?? {};
        debugPrint('VERIFY RESULT data: $data');
        final tempToken = data['tempToken'] as String? ?? '';
        if (tempToken.isNotEmpty) await AuthService.saveTempToken(tempToken);

        _regResult = data;
        if (mounted) _switchTo(_ScreenState.verified);
      } else {
        setState(() => _error = 'Invalid OTP or OTP has expired.');
        _triggerShake();
        _clearOtp();
      }
    } catch (e) {
      setState(() => _error = 'Verification failed. Please try again.');
      _triggerShake();
      _clearOtp();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _triggerShake() =>
      _shakeCtrl.forward(from: 0).then((_) => _shakeCtrl.reset());

  void _clearOtp() {
    for (final c in _otpControllers) c.clear();
    for (int i = 0; i < 6; i++) _otp[i] = '';
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _otpFocusNodes[0].requestFocus());
  }

  // ── Navigation helpers ────────────────────────────────────────────────────
  void _handleBack() {
    if (_screenState == _ScreenState.otp) {
      _countdownTimer?.cancel();
      _clearOtp();
    } else {
      widget.onBack();
    }
  }

  void _handleChangeNumber() {
    _countdownTimer?.cancel();
    _clearOtp();
    _phoneController.clear();
    setState(() {
      _phoneNumber = '';
      _intlPhoneNumber = PhoneNumber(isoCode: 'IN');
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.iconBgRed,
                  Colors.white,
                  AppColors.iconBgBlue,
                ],
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 512),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: _handleBack,
                            child: Row(
                              children: const [
                                Icon(Icons.arrow_back,
                                    size: 16, color: AppColors.textGrey),
                                SizedBox(width: 6),
                                Text(
                                  'Back',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.80),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withOpacity(0.06),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.account_balance,
                                  size: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Shubh',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    TextSpan(
                                      text: ' Labh',
                                      style: TextStyle(
                                        color: AppColors.secondary,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnim,
                        child: SlideTransition(
                          position: _slideAnim,
                          child: Center(
                            child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 384),
                                child: _buildBody(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_screenState) {
      case _ScreenState.verified:
        return _buildVerified();
      case _ScreenState.otp:
        return _buildOtpStep();
      case _ScreenState.phone:
        return _buildPhoneStep();
    }
  }

  // ── STATE 3 — Verified ────────────────────────────────────────────────────
  Widget _buildVerified() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _bounceAnim,
          builder: (_, __) => Transform.translate(
            offset: Offset(0, _bounceAnim.value),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFDCFCE7), Color(0xFFF0FDF4)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF22C55E),
                size: 48,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Welcome to Shubh Labh!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Your trusted banking partner for a prosperous future',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textGrey, fontSize: 14),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BouncingDot(animation: _dot1Anim, color: AppColors.primary),
            const SizedBox(width: 6),
            _BouncingDot(
                animation: _dot2Anim, color: const Color(0xFF22C55E)),
            const SizedBox(width: 6),
            _BouncingDot(
                animation: _dot3Anim, color: AppColors.secondary),
          ],
        ),
      ],
    );
  }

  // ── STATE 2 — OTP Entry ───────────────────────────────────────────────────
  Widget _buildOtpStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFDBEAFE), Color(0xFFEFF6FF)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_outlined,
            size: 48,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Security Verification',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
                fontSize: 14, color: AppColors.textGrey, height: 1.5),
            children: [
              const TextSpan(
                  text: 'Enter the 6-digit verification code sent to\n'),
              TextSpan(
                text: '+91 $_phoneNumber',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155),
                ),
              ),
              const TextSpan(text: '  '),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: GestureDetector(
                  onTap: _handleChangeNumber,
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (_, child) {
            final offset =
                5 * sin(_shakeAnim.value * pi * 6) * (1 - _shakeAnim.value);
            return Transform.translate(
                offset: Offset(offset, 0), child: child);
          },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              return _OtpBox(
                controller: _otpControllers[i],
                focusNode: _otpFocusNodes[i],
                onChanged: (val) => _handleOtpChange(val, i),
                onBackspace: () => _handleBackspace(i),
              );
            }),
          ),
        ),
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(_error,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFEF4444))),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        if (!_canResend)
          RichText(
            text: TextSpan(
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textGrey),
              children: [
                const TextSpan(text: 'Request new code in '),
                TextSpan(
                  text: '${_timeLeft}s',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: _loading ? null : _handleResendOtp,
            child: _loading
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.secondary),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Sending...',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  )
                : const Text(
                    'Resend Verification Code',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondary,
                    ),
                  ),
          ),
      ],
    );
  }

  // ── STATE 1 — Phone Entry (with intl_phone_number_input) ──────────────────
  Widget _buildPhoneStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFEE2E2), Color(0xFFFEF2F2)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.phone_outlined,
            size: 48,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Welcome to Digital Banking',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Enter your mobile number to begin your secure banking journey',
          style: TextStyle(fontSize: 14, color: AppColors.textGrey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // ── intl_phone_number_input field ──────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _phoneFocusNode.hasFocus
                  ? AppColors.primary
                  : const Color(0xFFE2E8F0),
              width: 2,
            ),
            boxShadow: _phoneFocusNode.hasFocus
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.15),
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: InternationalPhoneNumberInput(
            // Lock to India only — remove `countries` to allow all countries
            countries: const ['IN'],
            onInputChanged: (PhoneNumber number) {
              final raw = number.phoneNumber ?? '';
              final cleaned = raw.replaceAll(RegExp(r'\D'), '');
              final local = cleaned.length > 10
                  ? cleaned.substring(cleaned.length - 10)
                  : cleaned;
              setState(() {
                _phoneNumber = local;
                _intlPhoneNumber = number;
              });
            },
            onInputValidated: (bool isValid) {
              // Optionally surface validation state
            },
            selectorConfig: const SelectorConfig(
              selectorType: PhoneInputSelectorType.DROPDOWN,
              showFlags: true,
              useEmoji: false,
              setSelectorButtonAsPrefixIcon: true,
            ),
            ignoreBlank: false,
            autoValidateMode: AutovalidateMode.disabled,
            initialValue: _intlPhoneNumber,
            textFieldController: _phoneController,
            focusNode: _phoneFocusNode,
            formatInput: false, // keep raw digits
            keyboardType: const TextInputType.numberWithOptions(
                signed: true, decimal: true),
            inputDecoration: const InputDecoration(
              hintText: 'Enter mobile number',
              hintStyle:
                  TextStyle(color: Color(0xFFCBD5E1), fontSize: 16),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            ),
            textStyle: const TextStyle(
                fontSize: 17, color: AppColors.textDark),
            onSubmit: _handlePhoneSubmit,
          ),
        ),

        if (_error.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error_outline,
                  size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(_error,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFFEF4444))),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),

        // Submit button
        Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: -4,
              left: -4,
              right: -4,
              bottom: -4,
              child: Opacity(
                opacity: 0.25,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _handlePhoneSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor:
                      AppColors.primary.withOpacity(0.7),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 10),
                          Text('Sending Code...',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Get Verification Code',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 18),
                        ],
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'By continuing, you agree to our Terms of Service and Privacy Policy',
          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _OtpBox
// ─────────────────────────────────────────────────────────────────────────────
class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;
    final borderColor =
        isFocused ? AppColors.secondary : const Color(0xFFE2E8F0);

    return Container(
      width: 44,
      height: 52,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          if (isFocused)
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.20),
              blurRadius: 0,
              spreadRadius: 4,
            ),
        ],
      ),
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            onBackspace();
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _BouncingDot
// ─────────────────────────────────────────────────────────────────────────────
class _BouncingDot extends StatelessWidget {
  final Animation<double> animation;
  final Color color;

  const _BouncingDot({required this.animation, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, animation.value),
        child: Container(
          width: 10,
          height: 10,
          decoration:
              BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _GridPainter
// ─────────────────────────────────────────────────────────────────────────────
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