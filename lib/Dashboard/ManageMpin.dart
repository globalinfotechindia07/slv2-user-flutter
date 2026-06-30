import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../screens/Forgot_mpin_screen.dart';
import '../../services/auth_service.dart';

// ─── ManageMPIN Screen ─────────────────────────────────────────────────────────

class ManageMPINScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;

  const ManageMPINScreen({super.key, required this.userProfile});

  @override
  State<ManageMPINScreen> createState() => _ManageMPINScreenState();
}

class _ManageMPINScreenState extends State<ManageMPINScreen>
    with TickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  int _step = 1;
  String _phoneNumber = '';
  String _verifiedOldMpin = '';
  final List<String> _currentMPIN = ['', '', '', ''];
  final List<String> _newMPIN = ['', '', '', ''];
  final List<String> _confirmMPIN = ['', '', '', ''];
  String _error = '';
  bool _loading = false;
  bool _showForgotMPIN = false;
  bool _isShaking = false;
  bool _isSuccess = false;

  // ── Focus Nodes ────────────────────────────────────────────────────────────
  final List<FocusNode> _currentFocus = List.generate(4, (_) => FocusNode());
  final List<FocusNode> _newFocus = List.generate(4, (_) => FocusNode());
  final List<FocusNode> _confirmFocus = List.generate(4, (_) => FocusNode());

  // ── RawKeyboard FocusNodes (one per pin field, properly disposed) ──────────
  final List<FocusNode> _currentKeyFocus =
      List.generate(4, (_) => FocusNode());
  final List<FocusNode> _newKeyFocus = List.generate(4, (_) => FocusNode());
  final List<FocusNode> _confirmKeyFocus =
      List.generate(4, (_) => FocusNode());

  // ── Controllers ────────────────────────────────────────────────────────────
  final List<TextEditingController> _currentControllers =
      List.generate(4, (_) => TextEditingController());
  final List<TextEditingController> _newControllers =
      List.generate(4, (_) => TextEditingController());
  final List<TextEditingController> _confirmControllers =
      List.generate(4, (_) => TextEditingController());

  // ── Animation Controllers ──────────────────────────────────────────────────
  // late AnimationController _blobController;
  // late Animation<double> _blobAnimation;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  late AnimationController _fadeUpController;
  late Animation<double> _fadeUpOpacity;
  late Animation<Offset> _fadeUpOffset;
  late AnimationController _successBounceController;

  @override
  void initState() {
    super.initState();
    _loadPhoneNumber();
    // Blob animation
    // _blobController = AnimationController(
    //   vsync: this,
    //   duration: const Duration(seconds: 20),
    // )..repeat(reverse: true);
    // _blobAnimation = Tween<double>(begin: 0.25, end: 0.40).animate(
    //   CurvedAnimation(parent: _blobController, curve: Curves.easeInOut),
    // );

    // Shake animation
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -5), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5, end: -5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -5, end: 5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 5, end: 0), weight: 1),
    ]).animate(
        CurvedAnimation(parent: _shakeController, curve: Curves.linear));

    // Fade-up animation
    _fadeUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeUpOpacity =
        Tween<double>(begin: 0, end: 1).animate(_fadeUpController);
    _fadeUpOffset =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _fadeUpController, curve: Curves.easeOut));

    // Success bounce animation
    _successBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }
  Future<void> _loadPhoneNumber() async {
    final phone = await AuthService.getPhone();
    if (mounted) {
      setState(() {
        _phoneNumber = phone;
      });
    }
  }

  @override
  void dispose() {
    // _blobController.dispose();
    _shakeController.dispose();
    _fadeUpController.dispose();
    _successBounceController.dispose();
    for (final f in [
      ..._currentFocus,
      ..._newFocus,
      ..._confirmFocus,
      // FIX: Dispose the keyboard focus nodes too (was a memory leak before)
      ..._currentKeyFocus,
      ..._newKeyFocus,
      ..._confirmKeyFocus,
    ]) {
      f.dispose();
    }
    for (final c in [
      ..._currentControllers,
      ..._newControllers,
      ..._confirmControllers,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<String> _getPins(String type) {
    switch (type) {
      case 'current':
        return _currentMPIN;
      case 'new':
        return _newMPIN;
      case 'confirm':
        return _confirmMPIN;
      default:
        return [];
    }
  }

  List<FocusNode> _getFocusNodes(String type) {
    switch (type) {
      case 'current':
        return _currentFocus;
      case 'new':
        return _newFocus;
      case 'confirm':
        return _confirmFocus;
      default:
        return [];
    }
  }

  // FIX: Added getter for keyboard focus nodes (was missing before)
  List<FocusNode> _getKeyFocusNodes(String type) {
    switch (type) {
      case 'current':
        return _currentKeyFocus;
      case 'new':
        return _newKeyFocus;
      case 'confirm':
        return _confirmKeyFocus;
      default:
        return [];
    }
  }

  List<TextEditingController> _getControllers(String type) {
    switch (type) {
      case 'current':
        return _currentControllers;
      case 'new':
        return _newControllers;
      case 'confirm':
        return _confirmControllers;
      default:
        return [];
    }
  }

  void _triggerShake() {
    setState(() => _isShaking = true);
    _shakeController.forward(from: 0).then((_) {
      setState(() => _isShaking = false);
    });
  }

  void _clearPins(String type) {
    final pins = _getPins(type);
    final controllers = _getControllers(type);
    final focusNodes = _getFocusNodes(type);
    setState(() {
      for (int i = 0; i < 4; i++) {
        pins[i] = '';
        controllers[i].clear();
      }
    });
    focusNodes[0].requestFocus();
  }

  // FIX: Clear all pin sets when transitioning between steps
  void _clearAllPins() {
    for (final type in ['current', 'new', 'confirm']) {
      final pins = _getPins(type);
      final controllers = _getControllers(type);
      setState(() {
        for (int i = 0; i < 4; i++) {
          pins[i] = '';
          controllers[i].clear();
        }
      });
    }
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  void _handleBack() {
    if (_showForgotMPIN) {
      setState(() => _showForgotMPIN = false);
      return;
    }
    Navigator.of(context).pop();
  }

  void _handleMPINChange(int index, String value, String type) {
    final pins = _getPins(type);
    final focusNodes = _getFocusNodes(type);

    // FIX: Handle paste — if more than 1 digit is pasted, distribute across fields
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length > 1) {
      // Paste scenario: fill as many fields as possible from current index
      setState(() {
        _error = '';
        for (int i = 0; i < digitsOnly.length && (index + i) < 4; i++) {
          pins[index + i] = digitsOnly[i];
          _getControllers(type)[index + i].text = digitsOnly[i];
        }
      });
      // Move focus to last filled field or end
      final lastIndex =
          (index + digitsOnly.length - 1).clamp(0, 3);
      focusNodes[lastIndex].requestFocus();
      return;
    }

    setState(() {
      _error = '';
      pins[index] = digitsOnly.isEmpty ? '' : digitsOnly[digitsOnly.length - 1];
    });

    if (digitsOnly.isNotEmpty && index < 3) {
      focusNodes[index + 1].requestFocus();
    }
  }

  // FIX: Corrected backspace logic — clears current field first if filled,
  // then moves back. Previously it only moved back if the field was already empty,
  // skipping clearing the filled digit.
  void _handleKeyDown(int index, String type, KeyEvent event) {
    if (event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      final pins = _getPins(type);
      final focusNodes = _getFocusNodes(type);
      final controllers = _getControllers(type);

      if (pins[index].isNotEmpty) {
        // First backspace: clear current field
        setState(() {
          pins[index] = '';
          controllers[index].clear();
        });
      } else if (index > 0) {
        // Second backspace (or field already empty): move back and clear previous
        setState(() {
          pins[index - 1] = '';
          controllers[index - 1].clear();
        });
        focusNodes[index - 1].requestFocus();
      }
    }
  }


Future<void> _verifyCurrentMPIN() async {
    if (_currentMPIN.contains('')) {
      setState(() => _error = 'Please enter all digits');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final enteredMPIN = _currentMPIN.join('');
      final token = await AuthService.getAccessToken();

      if (token == null || token.isEmpty) {
        setState(() => _error = 'Session expired. Please login again.');
        return;
      }

      final response = await ApiService.verifyCurrentMpin(
        mpin: enteredMPIN,
        accessToken: token,
      );

      if (response['statusCode'] == 200 && response['success'] == true) {
        _verifiedOldMpin = enteredMPIN;
        setState(() {
          _step = 2;
          _error = '';
        });
        _clearPins('new');
        _clearPins('confirm');
        _fadeUpController.forward(from: 0);
      } else {
        final msg = response['message']?.toString() ?? 'Incorrect MPIN';
        throw Exception(msg);
      }
    } catch (error) {
      _triggerShake();
      String errMsg = error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : error.toString();
      setState(() => _error = errMsg.isNotEmpty ? errMsg : 'Verification failed');
      _clearPins('current');
    } finally {
      setState(() => _loading = false);
    }
  }


Future<void> _handleSetupMPIN() async {
    if (_newMPIN.contains('') || _confirmMPIN.contains('')) {
      setState(() => _error = 'Please enter all digits');
      return;
    }

    final newMPINValue = _newMPIN.join('');
    final confirmMPINValue = _confirmMPIN.join('');

    if (newMPINValue != confirmMPINValue) {
      setState(() => _error = 'MPINs do not match');
      _triggerShake();
      _clearPins('confirm');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final token = await AuthService.getAccessToken();

      if (token == null || token.isEmpty) {
        setState(() => _error = 'Session expired. Please login again.');
        return;
      }

      final response = await ApiService.changeMpin(
        oldMpin: _verifiedOldMpin,
        newMpin: newMPINValue,
        confirmNewMpin: confirmMPINValue,
        accessToken: token,
      );

      if (response['statusCode'] == 200 && response['success'] == true) {
        setState(() => _isSuccess = true);
        _fadeUpController.forward(from: 0);
        _successBounceController.repeat(reverse: true);
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.of(context).pop();
      } else {
        final msg = response['message']?.toString() ?? 'Failed to update MPIN';
        setState(() => _error = msg);
      }
    } catch (_) {
      setState(() => _error = 'Failed to update MPIN. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_showForgotMPIN) {
      return ForgotMpinScreen(
        onBack: () => setState(() => _showForgotMPIN = false),
        // FIX: Added mounted check before popping (was missing, could crash
        // if widget unmounts before the callback fires)
        onResetComplete: () {
          if (mounted) Navigator.of(context).pop();
        },
        phoneNumber: widget.userProfile['phoneNumber'] ?? '',
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 24),
                      child: _isSuccess
                          ? _buildSuccessView()
                          : _buildMainContent(),
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

  // ── Background ─────────────────────────────────────────────────────────────

  Widget _buildBackground() {
  return Container(
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
    child: CustomPaint(painter: _GridPainter(), size: Size.infinite),
  );
}

  // ── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _handleBack,
            child: const Row(
              children: [
                Icon(Icons.arrow_back, size: 18, color: Color(0xFF475569)),
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
          const Text(
            'Manage mPIN',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  // ── Success View ───────────────────────────────────────────────────────────

  Widget _buildSuccessView() {
    return FadeTransition(
      opacity: _fadeUpOpacity,
      child: SlideTransition(
        position: _fadeUpOffset,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _successBounceController,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, -8 * _successBounceController.value),
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFDCFCE7), Color(0xFFF0FDF4)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.15),
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
              'MPIN Reset Successful!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can now use your new MPIN to access your account',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main Content ───────────────────────────────────────────────────────────

  Widget _buildMainContent() {
    return FadeTransition(
      opacity: _fadeUpOpacity,
      child: SlideTransition(
        position: _fadeUpOffset,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 384),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon + Title + Subtitle
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFDBEAFE), Color(0xFFEFF6FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.key_rounded,
                      size: 48,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _step == 1 ? 'Renew/Reset MPIN' : 'Setup MPIN',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _step == 1
                        ? 'Kindly enter the current MPIN for verification'
                        : 'A 4-digit MPIN is required to safely access all important products and related services',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Step content
              _step == 1 ? _buildStep1() : _buildStep2(),

              const SizedBox(height: 16),

              // Error message
              if (_error.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          size: 20, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _error,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 1 ─────────────────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (_, child) => Transform.translate(
            offset: _isShaking
                ? Offset(_shakeAnimation.value, 0)
                : Offset.zero,
            child: child,
          ),
          child: _buildPinRow('current'),
        ),
        const SizedBox(height: 16),
        // FIX: Wrapped in Center so "Forgot MPIN?" is centered, not left-aligned
        Center(
          child: GestureDetector(
            onTap: () => setState(() => _showForgotMPIN = true),
            child: const Text(
              'Forgot MPIN?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          label: 'Continue',
          loadingLabel: 'Verifying...',
          onPressed: _verifyCurrentMPIN,
          disabled: _loading || _currentMPIN.contains(''),
        ),
      ],
    );
  }

  // ── Step 2 ─────────────────────────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Your Unique MPIN',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 8),
        _buildPinRow('new'),
        const SizedBox(height: 16),
        const Text(
          'Confirm MPIN',
          style: TextStyle(fontSize: 14, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (_, child) => Transform.translate(
            offset: _isShaking
                ? Offset(_shakeAnimation.value, 0)
                : Offset.zero,
            child: child,
          ),
          child: _buildPinRow('confirm'),
        ),
        const SizedBox(height: 24),
        _buildActionButton(
          label: 'Set MPIN',
          loadingLabel: 'Setting up MPIN...',
          onPressed: _handleSetupMPIN,
          disabled: _loading ||
              _newMPIN.contains('') ||
              _confirmMPIN.contains(''),
        ),
      ],
    );
  }

  // ── PIN Row ────────────────────────────────────────────────────────────────

  Widget _buildPinRow(String type) {
    final pins = _getPins(type);
    final focusNodes = _getFocusNodes(type);
    final controllers = _getControllers(type);
    // FIX: Use the properly tracked key focus nodes instead of inline FocusNode()
    final keyFocusNodes = _getKeyFocusNodes(type);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          width: 48,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: Focus(
            // FIX: Use Focus + onKeyEvent instead of deprecated RawKeyboardListener
            focusNode: keyFocusNodes[index],
            onKeyEvent: (_, event) {
              _handleKeyDown(index, type, event);
              return KeyEventResult.ignored;
            },
            child: TextFormField(
              controller: controllers[index],
              focusNode: focusNodes[index],
              obscureText: true,
              obscuringCharacter: '•',
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                counterText: '',
                contentPadding: EdgeInsets.zero,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFFE2E8F0), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: Color(0xFF3B82F6), width: 2),
                ),
              ),
              onChanged: (value) => _handleMPINChange(index, value, type),
            ),
          ),
        );
      }),
    );
  }

  // ── Action Button ──────────────────────────────────────────────────────────

  Widget _buildActionButton({
    required String label,
    required String loadingLabel,
    required VoidCallback onPressed,
    required bool disabled,
  }) {
    // FIX: Wrap gradient border in AnimatedOpacity so the entire button
    // (including the gradient border) dims when disabled, matching React behaviour
    return AnimatedOpacity(
      opacity: disabled ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFF3B82F6)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.all(2),
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFDC2626),
            // FIX: Use the base color without opacity here; AnimatedOpacity
            // on the parent handles the disabled visual instead
            disabledBackgroundColor: const Color(0xFFDC2626),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _loading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(loadingLabel,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ],
                )
              : Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

// ─── API Exception (for typed 401 handling) ────────────────────────────────────
// Add this class if not already defined in your api_service.dart.
// It allows _verifyCurrentMPIN to detect 401 errors specifically.
class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException({required this.statusCode, required this.message});
}

// ─── Grid Painter ──────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.02)
      ..strokeWidth = 1;

    const step = 32.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}