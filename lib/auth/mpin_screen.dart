import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../screens/home_screen.dart';
import '../screens/Forgot_mpin_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
// ─────────────────────────────────────────────────────────────────────────────
//  MpinScreen
// ─────────────────────────────────────────────────────────────────────────────
class MpinScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final VoidCallback? onForgotMPIN;

  const MpinScreen({
    super.key,
    required this.userProfile,
    this.onForgotMPIN,
  });

  @override
  State<MpinScreen> createState() => _MpinScreenState();
}

class _MpinScreenState extends State<MpinScreen> with TickerProviderStateMixin {
  // ── Controllers & nodes ───────────────────────────────────────────────────
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  // ── State ─────────────────────────────────────────────────────────────────
  String _error = '';
  bool _loading = false;
  bool _isShaking = false;

  // ── Shake animation — animate-shake 0.5s ──────────────────────────────────
  late final AnimationController _shakeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  late final Animation<double> _shakeAnim =
      Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
  );

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

  // // ── Blob animation — animate-blob 20s infinite ───────────────────────────
  // late final AnimationController _blobCtrl = AnimationController(
  //   vsync: this,
  //   duration: const Duration(seconds: 20),
  // )..repeat();

  // Piecewise keyframes matching @keyframes blob exactly:
  // 0%→(0,0)s1  25%→(20,-50)s1.1  50%→(-20,20)s0.9  75%→(50,50)s0.95  100%→(0,0)s1
  // static Offset _blobOffset(double t) {
  //   const List<Offset> positions = [
  //     Offset(0, 0),
  //     Offset(20, -50),
  //     Offset(-20, 20),
  //     Offset(50, 50),
  //     Offset(0, 0),
  //   ];
  //   final seg = (t * 4).floor().clamp(0, 3);
  //   final lt = (t * 4) - seg;
  //   return Offset.lerp(positions[seg], positions[seg + 1], lt)!;
  // }

  // static double _blobScale(double t) {
  //   const List<double> scales = [1.0, 1.1, 0.9, 0.95, 1.0];
  //   final seg = (t * 4).floor().clamp(0, 3);
  //   final lt = (t * 4) - seg;
  //   return scales[seg] + (scales[seg + 1] - scales[seg]) * lt;
  // }

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
    for (final f in _focusNodes) {
      f.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _fadeCtrl.dispose();
    // _blobCtrl.dispose();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  // ── Input handler — mirrors React's handleMPINChange ──────────────────────
  void _onChanged(String val, int idx) {
    setState(() => _error = '');

    final digit = val.replaceAll(RegExp(r'\D'), '');
    final sanitized = digit.isNotEmpty ? digit[0] : '';

    _controllers[idx].text = sanitized;
    if (sanitized.isNotEmpty) {
      _controllers[idx].selection = TextSelection.fromPosition(
        TextPosition(offset: _controllers[idx].text.length),
      );
    }

    if (sanitized.isNotEmpty && idx < 3) {
      _focusNodes[idx + 1].requestFocus();
    }

    final newMpin = _controllers.map((c) => c.text).toList();
    if (idx == 3 && newMpin.every((d) => d.isNotEmpty)) {
      _validateMpin(newMpin);
    }
  }

  // ── Backspace — mirrors React's handleKeyDown ─────────────────────────────
  void _onBackspace(int idx) {
    if (_controllers[idx].text.isEmpty && idx > 0) {
      _controllers[idx - 1].clear();
      _focusNodes[idx - 1].requestFocus();
    }
  }

  // ── Validate MPIN — mirrors React's validateMPIN ──────────────────────────
  Future<void> _validateMpin(List<String> mpinArray) async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final enteredMpin = mpinArray.join();
      final phone = (widget.userProfile['phoneNumber'] ??
              widget.userProfile['phone'] ??
              '') as String;

      // Mirrors: const response = await verifyMPIN(userProfile.phoneNumber, enteredMPIN)
      final response = await ApiService.verifyMpin(phone, enteredMpin);
      print('verifyMpin response: $response');

      if (response['success'] == true) {
        final user = response['user'] as Map<String, dynamic>? ?? {};

        // Save session so AuthService.getUserId() works throughout the app
        await AuthService.saveSession(
          userId: (user['id'] ?? user['user_id'] ?? '').toString(),
          phone: phone,
          user: user,
        );

        // Save token if present
        final token = response['token'] ?? response['access_token'] ?? user['token'];
        if (token != null) {
          await AuthService.saveToken(token.toString());
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => HomeScreen(userProfile: user),
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Incorrect MPIN');
      }
    } catch (e) {
      setState(() => _isShaking = true);

      // Mirrors React: 401 check → 'Invalid MPIN', else error.message, else 'Login failed'
      final message = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _error = message.toLowerCase().contains('invalid mpin') ||
                message.toLowerCase().contains('401')
            ? 'Invalid MPIN'
            : message.isNotEmpty
                ? message
                : 'Login failed';
      });

      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
      _shakeCtrl.forward(from: 0);
      Future.delayed(
        const Duration(milliseconds: 500),
        () {
          if (mounted) setState(() => _isShaking = false);
        },
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Forgot MPIN — mirrors React's onForgotMPIN prop ──────────────────────
  void _forgotMpin() {
    if (widget.onForgotMPIN != null) {
      widget.onForgotMPIN!();
      return;
    }
    // Default navigation fallback when no callback is provided
    final phone = (widget.userProfile['phoneNumber'] ??
        widget.userProfile['phone'] ??
        '') as String;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ForgotMpinScreen(
          phoneNumber: phone,
          onBack: () => Navigator.pop(context),
          onResetComplete: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MpinScreen(userProfile: widget.userProfile),
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient — from-red-50 via-white to-blue-50 ────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.iconBgRed,   // 0xFFFFEBEE ≈ red-50
                  Colors.white,
                  AppColors.iconBgBlue,  // 0xFFE3F2FD ≈ blue-50
                ],
              ),
            ),
          ),

          // ── Grid pattern — bg-[size:32px_32px] rgba(0,0,0,0.02) ──────────
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // ── Red blob — -right-40 top-20 w-96 h-96 opacity-30 blur-3xl ────
          // AnimatedBuilder(
          //   animation: _blobCtrl,
          //   builder: (_, __) {
          //     final off = _blobOffset(_blobCtrl.value);
          //     final scale = _blobScale(_blobCtrl.value);
          //     return Positioned(
          //       right: -160 + off.dx,
          //       top: 80 + off.dy,
          //       child: Transform.scale(
          //         scale: scale,
          //         child: ImageFiltered(
          //           imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          //           child: Container(
          //             width: 384,
          //             height: 384,
          //             decoration: BoxDecoration(
          //               shape: BoxShape.circle,
          //               color: const Color(0xFFFECACA).withOpacity(0.30),
          //             ),
          //           ),
          //         ),
          //       ),
          //     );
          //   },
          // ),

          // ── Blue blob — -left-40 bottom-20 animation-delay-2000 blur-3xl ─
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
          //         child: ImageFiltered(
          //           imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
          //           child: Container(
          //             width: 384,
          //             height: 384,
          //             decoration: BoxDecoration(
          //               shape: BoxShape.circle,
          //               color: const Color(0xFFBFDBFE).withOpacity(0.30),
          //             ),
          //           ),
          //         ),
          //       ),
          //     );
          //   },
          // ),

          // ── Main layout — max-w-lg mx-auto flex flex-col px-4 ─────────────
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 512),
                child: Column(
                  children: [
                    // ── Header — pt-4 flex justify-between items-center ─────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              // p-2 rounded-lg bg-white/80 backdrop-blur-sm shadow-sm
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                      sigmaX: 4, sigmaY: 4),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.80),
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withOpacity(0.06),
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
                                ),
                              ),
                              const SizedBox(width: 12),
                              // <span class="text-red-600">Shubh</span> <span class="text-blue-600">Labh</span>
                              const Text(
                                'Shubh',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Labh',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── Main content — flex-1 flex items-center justify-center -mt-20
                    Expanded(
                      child: Transform.translate(
                        offset: const Offset(0, -40),
                        child: Center(
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24),
                              child: ConstrainedBox(
                                // max-w-sm on inner card
                                constraints:
                                    const BoxConstraints(maxWidth: 384),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // ── Lock icon circle ───────────────────
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Color(0xFFDBEAFE), // blue-100
                                            Color(0xFFEFF6FF), // blue-50
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.06),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.lock_outline,
                                        size: 48,
                                        color: AppColors.accent,
                                      ),
                                    ),

                                    const SizedBox(height: 24),

                                    const Text(
                                      'Enter Your MPIN',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    const Text(
                                      'Securely access your Shubh Labh account',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF475569),
                                      ),
                                    ),

                                    const SizedBox(height: 32),

                                    // ── MPIN input row with shake ──────────
                                    _ShakingRow(
                                      isShaking: _isShaking,
                                      shakeAnim: _shakeAnim,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(4, (i) {
                                          return _MpinBox(
                                            controller: _controllers[i],
                                            focusNode: _focusNodes[i],
                                            hasError: _error.isNotEmpty,
                                            onChanged: (val) =>
                                                _onChanged(val, i),
                                            onBackspace: () =>
                                                _onBackspace(i),
                                          );
                                        }),
                                      ),
                                    ),

                                    // ── Error message ──────────────────────
                                    if (_error.isNotEmpty) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.error_outline,
                                            size: 16,
                                            color: Color(0xFFEF4444),
                                          ),
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

                                    // ── Loading spinner ────────────────────
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

                                    const SizedBox(height: 20),

                                    // ── Forgot MPIN? ───────────────────────
                                    _ForgotMpinButton(onTap: _forgotMpin),
                                  ],
                                ),
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
}

// ─────────────────────────────────────────────────────────────────────────────
//  _ForgotMpinButton
//  Mirrors: hover:text-blue-800 + focus:ring-2 focus:ring-blue-200 rounded-md
// ─────────────────────────────────────────────────────────────────────────────
class _ForgotMpinButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ForgotMpinButton({required this.onTap});

  @override
  State<_ForgotMpinButton> createState() => _ForgotMpinButtonState();
}

class _ForgotMpinButtonState extends State<_ForgotMpinButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6), // rounded-md
              border: _focused
                  ? Border.all(
                      color: AppColors.accent.withOpacity(0.3), width: 2) // focus:ring-blue-200
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: Text(
              'Forgot MPIN?',
              style: TextStyle(
                fontSize: 14,
                color: _hovered
                    ? AppColors.secondary     // deep navy on hover
                    : AppColors.accent,
                decoration: TextDecoration.underline,
                decorationColor: _hovered
                    ? AppColors.secondary
                    : AppColors.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _MpinBox — single digit input with AnimatedContainer (transition-all 300ms)
// ─────────────────────────────────────────────────────────────────────────────
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
        ? const Color(0xFFEF4444)  // border-red-500
        : isFocused
            ? AppColors.accent // focus:border-blue-500
            : const Color(0xFFE2E8F0); // default border

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300), // transition-all duration-300
      width: 52,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          // focus:ring-4 focus:ring-blue-100
          if (isFocused)
            BoxShadow(
              color: AppColors.accent.withOpacity(0.15),
              blurRadius: 0,
              spreadRadius: 4,
            ),
        ],
      ),
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

// ─────────────────────────────────────────────────────────────────────────────
//  _ShakingRow — animate-shake: ±5px oscillation over 0.5s
// ─────────────────────────────────────────────────────────────────────────────
class _ShakingRow extends StatelessWidget {
  final bool isShaking;
  final Animation<double> shakeAnim;
  final Widget child;

  const _ShakingRow({
    required this.isShaking,
    required this.shakeAnim,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeAnim,
      builder: (_, c) {
        final offset =
            isShaking ? 5 * sin(shakeAnim.value * pi * 6) : 0.0;
        return Transform.translate(
          offset: Offset(offset, 0),
          child: c,
        );
      },
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _GridPainter — bg-[size:32px_32px] rgba(0,0,0,0.02)
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