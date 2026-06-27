import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../auth/otp_success_screen.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'package:sim_card_info/sim_card_info.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  bool _isValid = false;
  bool _loading = false;
  String _error = '';

  // Fade-up animation
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
    _phoneController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String val) {
    setState(() {
      _isValid = val.length == 10;
      _error = '';
    });
  }

Future<void> _getVerificationCode() async {
  if (!_isValid) return;
  setState(() { _loading = true; _error = ''; });
  try {
    final result = await ApiService.sendOtp(_phoneController.text);
    debugPrint('DEBUG OTP → $result');
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'];
      final requestId = (data is Map ? data['request_id'] : null) as String? ?? '';
      debugPrint('PASSING requestId: "$requestId"');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OtpVerificationScreen(
            savedPhoneNumber: _phoneController.text,
            initialRequestId: requestId.isEmpty ? null : requestId,
            onBack: () => Navigator.pop(context),
          ),
        ),
      );
    } else {
      setState(() => _error = result['message'] ?? 'Failed to send OTP');
    }
  } catch (e) {
    setState(() => _error = e.toString().replaceAll('Exception: ', ''));
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

// ── SIM card state ─────────────────────────────────────────────────────
List<Map<String, String>> _simCards = [];

String _toLocal(String raw) {
  final cleaned = raw.replaceAll(RegExp(r'\D'), '');
  return cleaned.length > 10 ? cleaned.substring(cleaned.length - 10) : cleaned;
}

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _fetchAndShowSimDialog();
  });
}

Future<void> _fetchAndShowSimDialog() async {
  if (!Platform.isAndroid) return;
  try {
    final simCards = await SimCardInfo().getSimInfo() ?? [];
    final filtered = simCards
        .where((s) => s.number != null && s.number!.isNotEmpty)
        .map((s) => <String, String>{
              'number': s.number ?? '',
              'slot': s.slotIndex ?? '1',
              'carrier': s.carrierName ?? '',
            })
        .toList();
    if (mounted) setState(() => _simCards = filtered);
  } catch (e) {
    debugPrint('SIM fetch error: $e');
  }
  if (mounted) {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _showSimPickerDialog();
    });
  }
}

void _showSimPickerDialog() {
  FocusScope.of(context).unfocus();
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    backgroundColor: Colors.white,
    isDismissible: true,
    enableDrag: true,
    builder: (_) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Select Phone Number',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              const SizedBox(height: 4),
              Text('Choose a SIM to auto-fill, or add manually',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
              const SizedBox(height: 16),
              if (_simCards.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('No SIM numbers detected.',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                )
              else
                ..._simCards.map((sim) {
                  final local = _toLocal(sim['number'] ?? '');
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _phoneController.text = local;
                      _onPhoneChanged(local);
                    },
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFDC2626).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.sim_card, size: 20, color: Color(0xFFDC2626)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('+91 $local',
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                if ((sim['carrier'] ?? '').isNotEmpty)
                                  Text('${sim['carrier']} • SIM ${sim['slot']}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFDC2626)),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Add Manually'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Background gradient — same as onboarding ──────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF1F2), // red-50
                  Colors.white,
                  Color(0xFFEFF6FF), // blue-50
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
                // ── Header: Back (left) + ShubhLabh logo (right) ───────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Row(
                          children: const [
                            Icon(Icons.arrow_back,
                                size: 16, color: Color(0xFF475569)),
                            SizedBox(width: 6),
                            Text(
                              'Back',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Logo — icon + Shubh red + Labh blue
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
                              color: Color(0xFFDC2626),
                            ),
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
                                    fontSize: 16,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Labh',
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
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

                // ── Content — centered vertically ─────────────────────
                Expanded(
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
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ── Phone icon — no rings ─────────────────
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFFE4E4), // light red
                                    Color(0xFFFFF1F2), // red-50
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
                                Icons.phone_in_talk_rounded,
                                size: 48,
                                color: Color(0xFFDC2626),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // ── Title ────────────────────────────────
                            const Text(
                              'Welcome to Digital Banking',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // ── Subtitle ─────────────────────────────
                            const Text(
                              'Enter your mobile number to begin your secure banking journey',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF475569),
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 32),

                            // ── Phone input ───────────────────────────
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _error.isNotEmpty
                                      ? const Color(0xFFEF4444)
                                      : _isValid
                                          ? const Color(0xFFDC2626)
                                          : const Color(0xFFE2E8F0),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 16),
                                    child: const Text(
                                      '+91',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF0F172A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      onChanged: _onPhoneChanged,
                                      keyboardType: TextInputType.phone,
                                      maxLength: 10,
                                      inputFormatters: [
                                        FilteringTextInputFormatter
                                            .digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding:
                                            EdgeInsets.symmetric(
                                                horizontal: 14),
                                        counterText: '',
                                        hintText: 'Enter mobile number',
                                        hintStyle: TextStyle(
                                            color: Color(0xFF94A3B8)),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (_isValid)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 12),
                                      child: Icon(Icons.check_circle,
                                          color: Color(0xFFDC2626),
                                          size: 20),
                                    ),
                                ],
                              ),
                            ),

                            // Error
                            if (_error.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      size: 14,
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

                            const SizedBox(height: 24),

                            // ── Get Verification Code button ──────────
                            _PrimaryButton(
                              label: 'Get Verification Code',
                              loadingLabel: 'Sending Code...',
                              loading: _loading,
                              showArrow: true,
                              enabled: _isValid,
                              onTap: _getVerificationCode,
                            ),

                            const SizedBox(height: 20),

                            // ── Terms ─────────────────────────────────
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                ),
                                children: const [
                                  TextSpan(
                                      text:
                                          'By continuing, you agree to our '),
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: TextStyle(
                                      color: Color(0xFFDC2626),
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFFDC2626),
                                    ),
                                  ),
                                  TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: Color(0xFFDC2626),
                                      decoration: TextDecoration.underline,
                                      decorationColor: Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
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

// ── Primary Button ────────────────────────────────────────────────────────────

class _PrimaryButton extends StatefulWidget {
  final String label;
  final String loadingLabel;
  final bool loading;
  final bool showArrow;
  final bool enabled;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.loadingLabel,
    required this.loading,
    required this.onTap,
    this.showArrow = false,
    this.enabled = true,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled && !widget.loading
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.enabled && !widget.loading
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()
          ..scale(_pressed ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: !widget.enabled
              ? const Color(0xFFCBD5E1)
              : _pressed
                  ? const Color(0xFFB91C1C)
                  : const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(12),
          boxShadow: widget.enabled
              ? [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withOpacity(0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.enabled
                          ? Colors.white
                          : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (widget.showArrow) ...[
                    const SizedBox(width: 8),
                    AnimatedSlide(
                      offset: _pressed
                          ? const Offset(0.2, 0)
                          : Offset.zero,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 18,
                        color: widget.enabled
                            ? Colors.white
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
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