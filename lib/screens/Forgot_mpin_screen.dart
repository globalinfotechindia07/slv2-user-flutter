import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ForgotMpinScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onResetComplete;
  final String phoneNumber;

  const ForgotMpinScreen({
    super.key,
    required this.onBack,
    required this.onResetComplete,
    required this.phoneNumber,
  });

  @override
  State<ForgotMpinScreen> createState() => _ForgotMpinScreenState();
}

class _ForgotMpinScreenState extends State<ForgotMpinScreen>
    with TickerProviderStateMixin {
  int _step = 1;

  // OTP — 6 digits
  final List<TextEditingController> _otpCtrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  // New MPIN — 4 digits
  final List<TextEditingController> _mpinCtrl =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _mpinFocus = List.generate(4, (_) => FocusNode());

  // Confirm MPIN — 4 digits
  final List<TextEditingController> _confirmCtrl =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _confirmFocus = List.generate(4, (_) => FocusNode());

  String _error = '';
  bool _loading = false;
  bool _isSuccess = false;
  String _requestId = '';
  String _tempToken = '';

  // Timer — 30s countdown
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

  // Fade-up animation
  late final AnimationController _fadeUpCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..forward();
  late final Animation<double> _fadeOpacity =
      CurvedAnimation(parent: _fadeUpCtrl, curve: Curves.easeOut);
  late final Animation<double> _fadeSlide =
      Tween<double>(begin: 20, end: 0).animate(
    CurvedAnimation(parent: _fadeUpCtrl, curve: Curves.easeOut),
  );

  // Success bounce
  late final AnimationController _bounceCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  // FIX: Focus listeners to rebuild border color when focus changes.
  // Without these, otpFocus[i].hasFocus is checked only at build time
  // and the blue focused border never appears.
  @override
  void initState() {
    super.initState();
    for (final f in [..._otpFocus, ..._mpinFocus, ..._confirmFocus]) {
      f.addListener(_onFocusChange);
    }
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeCtrl.dispose();
    _fadeUpCtrl.dispose();
    _bounceCtrl.dispose();
    for (final f in [..._otpFocus, ..._mpinFocus, ..._confirmFocus]) {
      f.removeListener(_onFocusChange);
      f.dispose();
    }
    for (final c in [..._otpCtrl, ..._mpinCtrl, ..._confirmCtrl]) {
      c.dispose();
    }
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
  // FIX: Removed _isShaking bool entirely. The shake animation controller
  // alone drives the effect via _shakeAnim. Using both caused the shake
  // to cut off early when _isShaking was reset before the animation finished.

  void _shake() {
    _shakeCtrl.forward(from: 0);
  }

  // ── Step 1: Send OTP ──────────────────────────────────────────────────────

Future<void> _sendOtp() async {
  if (widget.phoneNumber.length < 10) {
    setState(() => _error = 'Please enter a valid 10-digit mobile number');
    return;
  }
  setState(() { _error = ''; _loading = true; });
  try {
    final result = await ApiService.sendOtp(widget.phoneNumber);
    debugPrint('FORGOT MPIN sendOtp response: $result');
    final statusCode = result['statusCode'] as int? ?? 0;
    if (statusCode == 429) {
      setState(() => _error = 'Too many requests. Please wait 5 minutes.');
      return;
    }
    if (result['success'] == true) {
      final data = result['data'];
      final requestId = (data is Map ? data['request_id'] : null) as String? ?? '';
      setState(() { _requestId = requestId; _step = 2; _error = ''; });
      _fadeUpCtrl.reset();
      _fadeUpCtrl.forward();
      _startTimer();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _otpFocus[0].requestFocus());
    } else {
      setState(() => _error = result['message'] ?? 'Failed to send OTP');
    }
  } catch (e) {
    setState(() => _error = 'Failed to send OTP. Please try again.');
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  // ── Step 2: OTP input ─────────────────────────────────────────────────────

  void _onOtpChanged(String val, int idx) {
    // FIX: Handle paste — distribute digits across fields from current index
    final digits = val.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty && val.isNotEmpty) {
      _otpCtrl[idx].clear();
      return;
    }

    if (digits.length > 1) {
      // Paste scenario
      for (int i = 0; i < digits.length && (idx + i) < 6; i++) {
        _otpCtrl[idx + i].text = digits[i];
      }
      final lastFilled = (idx + digits.length - 1).clamp(0, 5);
      _otpFocus[lastFilled].requestFocus();
      final allFilled = _otpCtrl.every((c) => c.text.isNotEmpty);
      if (allFilled) {
        Future.delayed(const Duration(milliseconds: 100), _verifyOtp);
      }
      return;
    }

    if (_error.isNotEmpty) setState(() => _error = '');
    if (digits.isNotEmpty && idx < 5) _otpFocus[idx + 1].requestFocus();

    final filled = _otpCtrl.every((c) => c.text.isNotEmpty);
    if (filled && idx == 5) {
      Future.delayed(const Duration(milliseconds: 100), _verifyOtp);
    }
  }

  // FIX: Backspace now actually triggers focus movement.
  // Previously _onOtpBackspace was defined but never called from the widget.
  void _onOtpBackspace(int idx, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_otpCtrl[idx].text.isNotEmpty) {
        _otpCtrl[idx].clear();
      } else if (idx > 0) {
        _otpCtrl[idx - 1].clear();
        _otpFocus[idx - 1].requestFocus();
      }
    }
  }

  Future<void> _verifyOtp() async {
  final otpVal = _otpCtrl.map((c) => c.text).join();
  setState(() => _loading = true);
  try {
    final result = await ApiService.verifyOtp(_requestId, otpVal);
    final statusCode = result['statusCode'] as int? ?? 0;

    if (statusCode == 429) {
      setState(() => _error = 'Too many attempts. Please slow down.');
      return;
    }

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>? ?? {};
      final tempToken = data['tempToken'] as String? ?? '';
      setState(() { _tempToken = tempToken; _step = 3; _error = ''; });
      _fadeUpCtrl.reset();
      _fadeUpCtrl.forward();
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _mpinFocus[0].requestFocus());
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
    if (mounted) setState(() => _loading = false);
  }
}

  // ── Step 3: Reset MPIN ────────────────────────────────────────────────────

  void _onMpinChanged(String val, int idx, bool isConfirm) {
    setState(() => _error = '');
    final focuses = isConfirm ? _confirmFocus : _mpinFocus;
    if (val.isNotEmpty && idx < 3) {
      focuses[idx + 1].requestFocus();
    } else if (val.isNotEmpty && idx == 3 && !isConfirm) {
      _confirmFocus[0].requestFocus();
    }
  }

  // FIX: Backspace now actually triggers focus movement for MPIN fields.
  // Previously _onMpinBackspace was defined but never called from _MpinRow.
  void _onMpinBackspace(int idx, bool isConfirm, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      final ctrls = isConfirm ? _confirmCtrl : _mpinCtrl;
      final focuses = isConfirm ? _confirmFocus : _mpinFocus;
      if (ctrls[idx].text.isNotEmpty) {
        ctrls[idx].clear();
      } else if (idx > 0) {
        ctrls[idx - 1].clear();
        focuses[idx - 1].requestFocus();
      }
    }
  }

Future<void> _resetMpin() async {
  final mpinVal = _mpinCtrl.map((c) => c.text).join();
  final confirmVal = _confirmCtrl.map((c) => c.text).join();

  if (mpinVal.length < 4 || confirmVal.length < 4) {
    setState(() => _error = 'Please enter all digits');
    return;
  }
  if (mpinVal != confirmVal) {
    setState(() => _error = 'MPINs do not match');
    _shake();
    for (final c in _confirmCtrl) c.clear();
    _confirmFocus[0].requestFocus();
    return;
  }
  if (_tempToken.isEmpty) {
    setState(() => _error = 'Session expired. Please start over.');
    return;
  }

  setState(() { _loading = true; _error = ''; });
  try {
    final response = await ApiService.resetMpinWithToken(
      mpin: mpinVal,
      confirmMpin: confirmVal,
      tempToken: _tempToken,
    );
    final statusCode = response['statusCode'] as int? ?? 0;

    if (statusCode == 200 && response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final accessToken = data['accessToken'] as String? ?? '';
      final user = data['user'] as Map<String, dynamic>? ?? {};

      if (accessToken.isNotEmpty) await AuthService.saveAccessToken(accessToken);
      if (user.isNotEmpty) await AuthService.saveCustomer(user);
      await AuthService.clearTempToken();

      setState(() => _isSuccess = true);
      _fadeUpCtrl.reset();
      _fadeUpCtrl.forward();
      _bounceCtrl.repeat(reverse: true);

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) widget.onResetComplete();
      });

    } else if (statusCode == 401) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please start over.')),
        );
        setState(() => _step = 1);
      }
    } else {
      setState(() => _error = response['message'] as String? ?? 'Failed to reset MPIN');
      _shake();
      for (final c in _confirmCtrl) c.clear();
      _confirmFocus[0].requestFocus();
    }
  } catch (e) {
    setState(() => _error = 'Failed to reset MPIN. Please try again.');
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  // ── Step icon / title / subtitle ──────────────────────────────────────────

  IconData get _stepIcon {
    if (_step == 2) return Icons.shield_outlined;
    return Icons.key_rounded;
  }

  String get _stepTitle {
    switch (_step) {
      case 1:
        return 'Reset MPIN';
      case 2:
        return 'Verify OTP';
      default:
        return 'Set New MPIN';
    }
  }

  String get _stepSubtitle {
    switch (_step) {
      case 1:
        return "We'll send an OTP to your registered mobile number";
      case 2:
        return 'Enter the 6-digit verification code sent to\n+91 ${widget.phoneNumber}';
      default:
        return 'Create your new 4-digit MPIN';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ───────────────────────────────────────
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

          // ── Grid pattern ──────────────────────────────────────────────
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // ── Main layout ───────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: widget.onBack,
                        child: const Row(
                          children: [
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.80),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.account_balance,
                                size: 20, color: Color(0xFFDC2626)),
                          ),
                          const SizedBox(width: 8),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'Shubh',
                                  style: TextStyle(
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                                TextSpan(
                                  text: ' Labh',
                                  style: TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Body ──────────────────────────────────────────────────
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: AnimatedBuilder(
                        animation: _fadeUpCtrl,
                        builder: (_, child) => Opacity(
                          opacity: _fadeOpacity.value,
                          child: Transform.translate(
                            offset: Offset(0, _fadeSlide.value),
                            child: child,
                          ),
                        ),
                        child: _isSuccess
                            ? _SuccessView(bounceCtrl: _bounceCtrl)
                            : Column(
                                children: [
                                  // Icon box
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFDBEAFE),
                                          Color(0xFFEFF6FF),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              Colors.black.withOpacity(0.06),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(_stepIcon,
                                        size: 48,
                                        color: const Color(0xFF3B82F6)),
                                  ),

                                  const SizedBox(height: 20),

                                  Text(_stepTitle,
                                      style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A))),

                                  const SizedBox(height: 8),

                                  Text(_stepSubtitle,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF475569),
                                          height: 1.5)),

                                  const SizedBox(height: 32),

                                  if (_step == 1)
                                    _Step1(
                                        onSend: _sendOtp,
                                        loading: _loading),
                                  if (_step == 2)
                                    _Step2(
                                      otpCtrl: _otpCtrl,
                                      otpFocus: _otpFocus,
                                      shakeAnim: _shakeAnim,
                                      loading: _loading,
                                      timeLeft: _timeLeft,
                                      canResend: _canResend,
                                      onChanged: _onOtpChanged,
                                      onBackspace: _onOtpBackspace,
                                      onResend: _sendOtp,
                                    ),
                                  if (_step == 3)
                                    _Step3(
                                      mpinCtrl: _mpinCtrl,
                                      mpinFocus: _mpinFocus,
                                      confirmCtrl: _confirmCtrl,
                                      confirmFocus: _confirmFocus,
                                      shakeAnim: _shakeAnim,
                                      loading: _loading,
                                      onMpinChanged: _onMpinChanged,
                                      onMpinBackspace: _onMpinBackspace,
                                      onReset: _resetMpin,
                                    ),

                                  if (_error.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    _ErrorBox(message: _error),
                                  ],

                                  const SizedBox(height: 24),

                                  Text(
                                    '© ${DateTime.now().year} Shubh Labh. All rights reserved.',
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8)),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 1 ────────────────────────────────────────────────────────────────────

class _Step1 extends StatelessWidget {
  final VoidCallback onSend;
  final bool loading;
  const _Step1({required this.onSend, required this.loading});

  @override
  Widget build(BuildContext context) {
    return _PrimaryButton(
      label: 'Send OTP',
      loadingLabel: 'Sending Code...',
      loading: loading,
      onTap: onSend,
    );
  }
}

// ── Step 2 ────────────────────────────────────────────────────────────────────
// FIX: Removed isShaking param (no longer needed — shakeAnim drives it alone).
// FIX: onBackspace now typed as Function(int, KeyEvent) and wired into Focus.

class _Step2 extends StatelessWidget {
  final List<TextEditingController> otpCtrl;
  final List<FocusNode> otpFocus;
  final Animation<double> shakeAnim;
  final bool loading;
  final int timeLeft;
  final bool canResend;
  final Function(String, int) onChanged;
  final Function(int, KeyEvent) onBackspace;
  final VoidCallback onResend;

  const _Step2({
    required this.otpCtrl,
    required this.otpFocus,
    required this.shakeAnim,
    required this.loading,
    required this.timeLeft,
    required this.canResend,
    required this.onChanged,
    required this.onBackspace,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ShakingRow(
          shakeAnim: shakeAnim,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(6, (i) {
              return Container(
                width: 44,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  // FIX: Focus listener in initState now triggers rebuilds,
                  // so this border color correctly switches to blue on focus.
                  border: Border.all(
                    color: otpFocus[i].hasFocus
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
                // FIX: Wrap in Focus with onKeyEvent to handle backspace.
                // Previously onBackspace was defined but never called.
                child: Focus(
                  onKeyEvent: (_, event) {
                    onBackspace(i, event);
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: otpCtrl[i],
                    focusNode: otpFocus[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    onChanged: (val) => onChanged(val, i),
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
                ),
              );
            }),
          ),
        ),

        const SizedBox(height: 16),

        if (!canResend)
          RichText(
            text: TextSpan(
              children: [
                const TextSpan(
                  text: 'Request new code in ',
                  style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
                ),
                TextSpan(
                  text: '${timeLeft}s',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: loading ? null : onResend,
            child: const Text(
              'Resend Verification Code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2563EB),
              ),
            ),
          ),

        if (loading) ...[
          const SizedBox(height: 16),
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: Color(0xFF3B82F6)),
          ),
        ],
      ],
    );
  }
}

// ── Step 3 ────────────────────────────────────────────────────────────────────
// FIX: Removed isShaking param. onMpinBackspace now typed as
// Function(int, bool, KeyEvent) to carry the key event through.

class _Step3 extends StatelessWidget {
  final List<TextEditingController> mpinCtrl;
  final List<FocusNode> mpinFocus;
  final List<TextEditingController> confirmCtrl;
  final List<FocusNode> confirmFocus;
  final Animation<double> shakeAnim;
  final bool loading;
  final Function(String, int, bool) onMpinChanged;
  final Function(int, bool, KeyEvent) onMpinBackspace;
  final VoidCallback onReset;

  const _Step3({
    required this.mpinCtrl,
    required this.mpinFocus,
    required this.confirmCtrl,
    required this.confirmFocus,
    required this.shakeAnim,
    required this.loading,
    required this.onMpinChanged,
    required this.onMpinBackspace,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Enter New MPIN',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        _MpinRow(
          controllers: mpinCtrl,
          focuses: mpinFocus,
          onChanged: (val, idx) => onMpinChanged(val, idx, false),
          onBackspace: (idx, event) => onMpinBackspace(idx, false, event),
        ),

        const SizedBox(height: 20),

        const Text('Confirm New MPIN',
            style: TextStyle(fontSize: 14, color: Color(0xFF475569))),
        const SizedBox(height: 8),
        _ShakingRow(
          shakeAnim: shakeAnim,
          child: _MpinRow(
            controllers: confirmCtrl,
            focuses: confirmFocus,
            onChanged: (val, idx) => onMpinChanged(val, idx, true),
            onBackspace: (idx, event) => onMpinBackspace(idx, true, event),
          ),
        ),

        const SizedBox(height: 24),

        _PrimaryButton(
          label: 'Reset MPIN',
          loadingLabel: 'Resetting MPIN...',
          loading: loading,
          onTap: onReset,
        ),
      ],
    );
  }
}

// ── MPIN Row ──────────────────────────────────────────────────────────────────
// FIX: onBackspace now typed as Function(int, KeyEvent) and wired into
// a Focus widget wrapping each TextField so backspace is actually received.

class _MpinRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focuses;
  final Function(String, int) onChanged;
  final Function(int, KeyEvent) onBackspace;

  const _MpinRow({
    required this.controllers,
    required this.focuses,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (i) {
        return Container(
          width: 52,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            // FIX: Focus listener registered in initState triggers rebuilds
            // so this border correctly switches to blue when focused.
            border: Border.all(
              color: focuses[i].hasFocus
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
          // FIX: Wrap in Focus with onKeyEvent so backspace is detected.
          // Previously onBackspace was defined but never called anywhere.
          child: Focus(
            onKeyEvent: (_, event) {
              onBackspace(i, event);
              return KeyEventResult.ignored;
            },
            child: TextField(
              controller: controllers[i],
              focusNode: focuses[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              obscureText: true,
              onChanged: (val) {
                final digit = val.replaceAll(RegExp(r'\D'), '');
                onChanged(digit, i);
              },
              decoration: const InputDecoration(
                border: InputBorder.none,
                counterText: '',
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ── Shaking Row ───────────────────────────────────────────────────────────────
// FIX: Removed isShaking parameter. The shake offset is derived purely
// from shakeAnim.value so the animation runs its full duration without
// being cut short by a boolean flag reset.

class _ShakingRow extends StatelessWidget {
  final Animation<double> shakeAnim;
  final Widget child;

  const _ShakingRow({
    required this.shakeAnim,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnim,
      builder: (_, c) {
        final offset = 5 * sin(shakeAnim.value * pi * 6);
        return Transform.translate(offset: Offset(offset, 0), child: c);
      },
      child: child,
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final String loadingLabel;
  final bool loading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.loadingLabel,
    required this.loading,
    required this.onTap,
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
        child: Column(
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444)
                        .withOpacity(_pressed ? 0.45 : 0.25),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: const Color(0xFF3B82F6)
                        .withOpacity(_pressed ? 0.35 : 0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: _pressed
                      ? const Color(0xFFB91C1C)
                      : const Color(0xFFDC2626),
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
                                strokeWidth: 2, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Text(widget.loadingLabel,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15)),
                        ],
                      )
                    : Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error Box ─────────────────────────────────────────────────────────────────

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 20, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );
  }
}

// ── Success View ──────────────────────────────────────────────────────────────
// FIX: The parent AnimatedBuilder now wraps both success and main content,
// so this view gets the fade-up entry animation automatically when
// _isSuccess becomes true and _fadeUpCtrl is reset+forwarded.

class _SuccessView extends StatelessWidget {
  final AnimationController bounceCtrl;
  const _SuccessView({required this.bounceCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: bounceCtrl,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, -12 * bounceCtrl.value),
        child: child,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFDCFCE7),
                  Color(0xFFF0FDF4),
                ],
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
            child: const Icon(Icons.check_circle_outline,
                size: 48, color: Color(0xFF22C55E)),
          ),
          const SizedBox(height: 24),
          const Text('MPIN Reset Successful!',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A))),
          const SizedBox(height: 8),
          const Text(
            'You can now use your new MPIN to access your account',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
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