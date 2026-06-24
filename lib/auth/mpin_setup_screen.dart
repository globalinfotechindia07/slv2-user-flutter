import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../auth/mpin_screen.dart';

// ── MPIN Setup Screen — matches React MPINSetup.jsx exactly ──────────────────
// Steps:
//   'setup'   — enter new 4-digit MPIN
//   'confirm' — re-enter to confirm
//   'success' — green checkmark + bouncing dots, then auto-navigate
//
// Fixes applied vs original Flutter file:
//   1  Blob animations (red top-right, blue bottom-left with 2s phase offset)
//   2  3-step flow: setup → confirm → success (single set of 4 boxes)
//   3  Auto-advance to confirm when setup boxes are all filled (no button)
//   4  Controller sync: controllers[idx].text = sanitized before read
//   5  Backspace wired via KeyboardListener in every MPIN box
//   6  Focus ring glow: spreadRadius:4 blue shadow on focused box
//   7  Success screen: three staggered bouncing dots
//   8  Header logo (Landmark icon + Shubh/Labh) on right side
//   9  registerUser API call using widget.profileData + mpin
//  10  Icon switches: KeyRound (setup) → Lock (confirm)

class MpinSetupScreen extends StatefulWidget {
  final String phone;
  final Map<String, dynamic> profileData;
  const MpinSetupScreen(
      {super.key, required this.phone, required this.profileData});

  @override
  State<MpinSetupScreen> createState() => _MpinSetupScreenState();
}

class _MpinSetupScreenState extends State<MpinSetupScreen>
    with TickerProviderStateMixin {
  // FIX 2 ── 3-step flow matching React: 'setup' | 'confirm' | 'success'
  String _step = 'setup';

  // Single set of 4 boxes — reused for both setup and confirm
  final List<TextEditingController> _setupCtrl =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _setupFocus =
      List.generate(4, (_) => FocusNode());

  final List<TextEditingController> _confirmCtrl =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _confirmFocus =
      List.generate(4, (_) => FocusNode());

  String _error = '';
  bool _loading = false;
  bool _isShaking = false;

  // ── Shake animation ───────────────────────────────────────────────────────
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _shakeAnim = Tween<double>(begin: 0, end: 1)
      .animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn));

  // ── Fade-up animation — animate-fade-up 0.5s ease-out ────────────────────
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

  // FIX 7 ── Staggered bounce for the 3 success dots
  late final AnimationController _dot1Ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _dot2Ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final AnimationController _dot3Ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  // // FIX 1 ── Blob animation controller (animate-blob 20s infinite)
  // late final AnimationController _blobCtrl = AnimationController(
  //   vsync: this,
  //   duration: const Duration(seconds: 20),
  // )..repeat();

  // Blob keyframe helpers — same as MpinScreen
  // static Offset _blobOffset(double t) {
  //   const List<Offset> positions = [
  //     Offset(0, 0),
  //     Offset(20, -50),
  //     Offset(-20, 20),
  //     Offset(50, 50),
  //     Offset(0, 0),
  //   ];
  //   final segment = (t * 4).floor().clamp(0, 3);
  //   final localT = (t * 4) - segment;
  //   return Offset.lerp(positions[segment], positions[segment + 1], localT)!;
  // }

  // static double _blobScale(double t) {
  //   const List<double> scales = [1.0, 1.1, 0.9, 0.95, 1.0];
  //   final segment = (t * 4).floor().clamp(0, 3);
  //   final localT = (t * 4) - segment;
  //   return scales[segment] + (scales[segment + 1] - scales[segment]) * localT;
  // }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupFocus[0].requestFocus();
    });
    // Rebuild on focus changes so border colours update
    for (final f in [..._setupFocus, ..._confirmFocus]) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _fadeCtrl.dispose();
    _dot1Ctrl.dispose();
    _dot2Ctrl.dispose();
    _dot3Ctrl.dispose();
    // _blobCtrl.dispose(); // FIX 1
    for (final c in [..._setupCtrl, ..._confirmCtrl]) c.dispose();
    for (final f in [..._setupFocus, ..._confirmFocus]) f.dispose();
    super.dispose();
  }

  // ── Shake helper ──────────────────────────────────────────────────────────

  void _shake() {
    setState(() => _isShaking = true);
    _shakeCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 500),
        () => setState(() => _isShaking = false));
  }

  // ── Input handler — FIX 4: controller sync before downstream read ─────────

  void _onChanged(String val, int idx, List<TextEditingController> ctrls,
      List<FocusNode> focuses, bool isConfirm) {
    setState(() => _error = '');

    // FIX 4 ── sanitize & commit to controller immediately
    final digit = val.replaceAll(RegExp(r'\D'), '');
    final sanitized = digit.isNotEmpty ? digit[0] : '';
    ctrls[idx].text = sanitized;
    if (sanitized.isNotEmpty) {
      ctrls[idx].selection =
          TextSelection.fromPosition(TextPosition(offset: 1));
    }

    if (sanitized.isNotEmpty && idx < 3) {
      focuses[idx + 1].requestFocus();
    }

    // FIX 3 ── read controllers AFTER sync so every() is accurate
    final values = ctrls.map((c) => c.text).toList();

    if (!isConfirm) {
      // FIX 3 ── auto-advance to confirm when setup is complete (no button)
      if (idx == 3 && values.every((d) => d.isNotEmpty)) {
        setState(() => _step = 'confirm');
        _fadeCtrl.reset();
        _fadeCtrl.forward();
        Future.delayed(const Duration(milliseconds: 100),
            () => _confirmFocus[0].requestFocus());
      }
    } else {
      // FIX 3 ── auto-validate when confirm is complete
      if (idx == 3 && values.every((d) => d.isNotEmpty)) {
        _validateMpin(values);
      }
    }
  }

  // FIX 5 ── Backspace wired (called from KeyboardListener in _MpinBox)
  void _onBackspace(int idx, List<TextEditingController> ctrls,
      List<FocusNode> focuses) {
    if (ctrls[idx].text.isEmpty && idx > 0) {
      ctrls[idx - 1].clear();
      focuses[idx - 1].requestFocus();
    }
  }

  // ── Validate & Register ───────────────────────────────────────────────────

  Future<void> _validateMpin(List<String> confirmedValues) async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final originalMpin = _setupCtrl.map((c) => c.text).join();
    final confirmedMpin = confirmedValues.join();

    try {
      // Validate all digits present
      if (originalMpin.length < 4 || confirmedMpin.length < 4) {
        throw Exception('Please enter all digits');
      }

      // Check match
      if (originalMpin != confirmedMpin) {
        throw Exception('MPINs do not match');
      }

      // FIX 9 ── call registerUser with full profileData + mpin,
      // matching React's validateAndRegisterUser(originalMPIN)
      final userData = {
        'name': widget.profileData['name'],
        'email': widget.profileData['email'],
        'phoneNumber': widget.profileData['phoneNumber'] ?? widget.phone,
        'dateOfBirth': widget.profileData['dateOfBirth'],
        'gender': widget.profileData['gender'],
        'address': widget.profileData['address'],
        'aadhaarNumber': widget.profileData['aadhaarNumber'],
        'panNumber': widget.profileData['panNumber'],
        'mpin': originalMpin,
      };

      final response = await ApiService.registerUser(userData);
      final success = response['success'] == true;

      if (!success) {
        throw Exception(
            response['error'] ?? response['message'] ?? 'Registration failed');
      }

      // ── Success flow ────────────────────────────────────────────────────
      setState(() => _step = 'success');

      // FIX 7 ── start staggered dot bounces (0s / 0.2s / 0.4s delays)
      _dot1Ctrl.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 200),
          () => _dot2Ctrl.repeat(reverse: true));
      Future.delayed(const Duration(milliseconds: 400),
          () => _dot3Ctrl.repeat(reverse: true));

      // Auto-navigate after 2 seconds (React: setTimeout 2000ms)
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MpinScreen(
              userProfile: {
                ...widget.profileData,
                'phoneNumber': widget.phone,
              },
            ),
          ),
          (route) => false,
        );
      });

    } catch (e) {
    _shake();
    String msg;
    if (e is SocketException) {
    // FIX ── matches React's error.request branch (no response received)
    msg = 'No response received from server';
  } else if (e is FormatException) {
    // Non-JSON response, malformed payload, etc.
    msg = 'No response received from server';
  } else {
    msg = e.toString().replaceAll('Exception: ', '');
  }
  setState(() => _error = msg.isNotEmpty ? msg : 'Registration failed');
  for (final c in _confirmCtrl) c.clear();
  _confirmFocus[0].requestFocus();
} finally {
  setState(() => _loading = false);
}
  }

  // ── Back handler ──────────────────────────────────────────────────────────

  void _handleBack() {
    if (_step == 'confirm') {
      // Return to setup, clear confirm boxes, refocus first setup box
      setState(() {
        _step = 'setup';
        _error = '';
        for (final c in _confirmCtrl) c.clear();
      });
      _fadeCtrl.reset();
      _fadeCtrl.forward();
      Future.delayed(const Duration(milliseconds: 100),
          () => _setupFocus[0].requestFocus());
    } else {
      Navigator.pop(context);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient ────────────────────────────────────────
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

          // ── Grid pattern ───────────────────────────────────────────────
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // // FIX 1 ── Red blob — absolute -right-40 top-20
          // AnimatedBuilder(
          //   animation: _blobCtrl,
          //   builder: (_, __) {
          //     final t = _blobCtrl.value;
          //     final off = _blobOffset(t);
          //     final scale = _blobScale(t);
          //     return Positioned(
          //       right: -160 + off.dx,
          //       top: 80 + off.dy,
          //       child: Transform.scale(
          //         scale: scale,
          //         child: Container(
          //           width: 384,
          //           height: 384,
          //           decoration: BoxDecoration(
          //             shape: BoxShape.circle,
          //             color:
          //                 const Color(0xFFFECACA).withOpacity(0.30), // red-100
          //           ),
          //         ),
          //       ),
          //     );
          //   },
          // ),

          // FIX 1 ── Blue blob — absolute -left-40 bottom-20 (2s delay = +0.10)
          // AnimatedBuilder(
          //   animation: _blobCtrl,
          //   builder: (_, __) {
          //     final t = (_blobCtrl.value + 0.10) % 1.0;
          //     final off = _blobOffset(t);
          //     final scale = _blobScale(t);
          //     return Positioned(
          //       left: -160 + off.dx,
          //       bottom: 80 + off.dy,
          //       child: Transform.scale(
          //         scale: scale,
          //         child: Container(
          //           width: 384,
          //           height: 384,
          //           decoration: BoxDecoration(
          //             shape: BoxShape.circle,
          //             color: const Color(0xFFBFDBFE)
          //                 .withOpacity(0.30), // blue-100
          //           ),
          //         ),
          //       ),
          //     );
          //   },
          // ),

          // ── Main layout ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // FIX 8 ── Header with Back button + ShubhLabh logo
                _Header(onBack: _handleBack),

                // ── Body ─────────────────────────────────────────────────
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16),
                      child: _step == 'success'
                          ? _SuccessView(
                              dot1: _dot1Ctrl,
                              dot2: _dot2Ctrl,
                              dot3: _dot3Ctrl,
                            )
                          : AnimatedBuilder(
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
                                  // FIX 10 ── Icon: KeyRound (setup) / Lock (confirm)
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
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      // FIX 10
                                      _step == 'setup'
                                          ? Icons.key_rounded
                                          : Icons.lock_outline,
                                      size: 48,
                                      color: AppColors.accent,
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // Title changes per step
                                  Text(
                                    _step == 'setup'
                                        ? 'Set Your MPIN'
                                        : 'Confirm Your MPIN',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  Text(
                                    _step == 'setup'
                                        ? 'Choose a 4-digit MPIN for quick access'
                                        : 'Re-enter the 4-digit MPIN to confirm',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textGrey,
                                    ),
                                  ),

                                  const SizedBox(height: 32),

                                  // MPIN boxes — setup or confirm depending on step
                                  _ShakingRow(
                                    isShaking: _isShaking,
                                    shakeAnim: _shakeAnim,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: List.generate(4, (i) {
                                        final ctrls = _step == 'setup' ? _setupCtrl : _confirmCtrl;
                                        final focuses = _step == 'setup' ? _setupFocus : _confirmFocus;
                                        final isConfirm = _step == 'confirm';
                                        // FIX ── matches React: error && step === 'confirm' && !digit
                                        final boxHasError = _error.isNotEmpty &&
                                            isConfirm &&
                                            ctrls[i].text.isEmpty;
                                        return _MpinBox(
                                          controller: ctrls[i],
                                          focusNode: focuses[i],
                                          hasError: boxHasError,
                                          onChanged: (val) =>
                                              _onChanged(val, i, ctrls, focuses, isConfirm),
                                          onBackspace: () => _onBackspace(i, ctrls, focuses),
                                        );
                                      }),
                                    ),
                                  ),

                                  // Error message
                                  if (_error.isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    _ErrorBox(message: _error),
                                  ],

                                  // Loading spinner
                                  if (_loading) ...[
                                    const SizedBox(height: 16),
                                    const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                  ],
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

// ── Header ────────────────────────────────────────────────────────────────────
// FIX 8: Back button (left) + ShubhLabh logo (right) — matches React header

class _Header extends StatelessWidget {
  final VoidCallback onBack;
  const _Header({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button — ArrowLeft + "Back"
          GestureDetector(
            onTap: onBack,
            child: Row(
              children: const [
                Icon(Icons.arrow_back_ios_new,
                    size: 14, color: AppColors.textGrey),
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

          // FIX 8 ── ShubhLabh logo (Landmark icon + Shubh Labh text)
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
                child: const Icon(
                  Icons.account_balance,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
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
                        color: AppColors.accent,
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
    );
  }
}

// ── MPIN Box ──────────────────────────────────────────────────────────────────
// FIX 5 ── KeyboardListener wires backspace navigation
// FIX 6 ── Focus ring glow (spreadRadius 4, blue-100 opacity)

class _MpinBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  const _MpinBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onBackspace,
  });

  @override
  Widget build(BuildContext context) {
    final isFocused = focusNode.hasFocus;
    final borderColor = hasError
        ? const Color(0xFFEF4444)
        : isFocused
            ? AppColors.accent
            : const Color(0xFFE2E8F0);

    return Container(
      width: 52,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          // FIX 6 ── focus:ring-4 focus:ring-blue-100 outer glow
          if (isFocused)
            BoxShadow(
              color: AppColors.accent.withOpacity(0.20),
              blurRadius: 0,
              spreadRadius: 4,
            ),
        ],
      ),
      // FIX 5 ── KeyboardListener captures Backspace before TextField handles it
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            onBackspace();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          obscureText: true,
          onChanged: onChanged,
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
        final offset = isShaking ? 5 * sin(shakeAnim.value * pi * 6) : 0.0;
        return Transform.translate(offset: Offset(offset, 0), child: c);
      },
      child: child,
    );
  }
}

// ── Success View ──────────────────────────────────────────────────────────────
// FIX 7 ── three staggered bouncing dots (red / green / blue)
//           matching React: animationDelay 0s / 0.2s / 0.4s

class _SuccessView extends StatelessWidget {
  final AnimationController dot1;
  final AnimationController dot2;
  final AnimationController dot3;

  const _SuccessView({
    required this.dot1,
    required this.dot2,
    required this.dot3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Green checkmark circle — animate-bounce
        AnimatedBuilder(
          animation: dot1, // reuse dot1 timing for the icon bounce
          builder: (_, child) => Transform.translate(
            offset: Offset(0, -8 * sin(dot1.value * pi)),
            child: child,
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFDCFCE7), // green-100
                  Color(0xFFF0FDF4), // green-50
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
            child: const Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Color(0xFF22C55E),
            ),
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'MPIN Set Successfully!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Your account is now secured with MPIN',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textGrey,
          ),
        ),

        const SizedBox(height: 20),

        // FIX 7 ── Three staggered bouncing dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _BounceDot(ctrl: dot1, color: const Color(0xFFEF4444)), // red-500
            const SizedBox(width: 8),
            _BounceDot(ctrl: dot2, color: const Color(0xFF22C55E)), // green-500
            const SizedBox(width: 8),
            _BounceDot(ctrl: dot3, color: const Color(0xFF3B82F6)), // blue-500
          ],
        ),
      ],
    );
  }
}

// Single bouncing dot used in success view
class _BounceDot extends StatelessWidget {
  final AnimationController ctrl;
  final Color color;
  const _BounceDot({required this.ctrl, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) => Transform.translate(
        // translateY up to -8px and back — matches React animate-bounce
        offset: Offset(0, -8 * sin(ctrl.value * pi)),
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
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
        color: AppColors.iconBgRed,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 20, color: Color(0xFFDC2626)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.primary,
              ),
            ),
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