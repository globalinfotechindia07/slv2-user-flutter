import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../auth/mpin_setup_screen.dart';
import '../services/auth_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String phone;
  const ProfileSetupScreen({super.key, required this.phone});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _aadhaarController = TextEditingController();
  // [ADDED] PAN number controller — optional field matching React's panNumber
  final _panController = TextEditingController();
  DateTime? _selectedDob;

  String? _selectedGender;
  bool _loading = false;
  bool _emailVerified = false;
  bool _aadhaarVerified = false;
  bool _emailOtpSent = false;
  bool _aadhaarOtpSent = false;
  bool _sendingEmailOtp = false;
  bool _sendingAadhaarOtp = false;

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
    _nameController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _aadhaarController.dispose();
    // [ADDED] dispose PAN controller
    _panController.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime(2000),
    firstDate: DateTime(1950),
    lastDate: DateTime.now(),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
          ),
        ),
        child: child!,
      );
    },
  );
  if (picked != null) {
    _selectedDob = picked;
    _dobController.text =
        '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
  }
}

  Future<void> _sendEmailOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !RegExp(r'\S+@\S+\.\S+').hasMatch(email)) {
      _showSnack('Please enter a valid email address first');
      return;
    }
    setState(() => _sendingEmailOtp = true);
    try {
      final result = await ApiService.sendEmailOtp(email);
      if (result['success'] == true) {
        setState(() => _emailOtpSent = true);
        _showOtpBottomSheet(
          title: 'Verify Email',
          subtitle: 'Enter the 6-digit OTP sent to\n$email',
          onVerify: (otp) => _verifyEmailOtp(email, otp),
          onResend: _sendEmailOtp,
        );
      } else {
        _showSnack(result['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      _showSnack('Error: ${e.toString()}');
    } finally {
      setState(() => _sendingEmailOtp = false);
    }
  }

  Future<void> _verifyEmailOtp(String email, String otp) async {
    final result = await ApiService.verifyEmailOtp(email, otp);
    if (result['success'] == true) {
      setState(() => _emailVerified = true);
      Navigator.pop(context);
      _showSnack('Email verified successfully!', success: true);
    } else {
      throw Exception(result['message'] ?? 'Invalid OTP');
    }
  }

  Future<void> _sendAadhaarOtp() async {
    final aadhaar = _aadhaarController.text.trim();
    if (aadhaar.length != 12) {
      _showSnack('Please enter a valid 12-digit Aadhaar number first');
      return;
    }
    setState(() => _sendingAadhaarOtp = true);
    try {
      final result = await ApiService.sendAadhaarOtp(widget.phone, aadhaar);
      if (result['success'] == true) {
        setState(() => _aadhaarOtpSent = true);
        _showOtpBottomSheet(
          title: 'Verify Aadhaar',
          subtitle:
              'Enter the 6-digit OTP sent to your\nregistered mobile +91 ${widget.phone}',
          onVerify: (otp) => _verifyAadhaarOtp(aadhaar, otp),
          onResend: _sendAadhaarOtp,
        );
      } else {
        _showSnack(result['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      _showSnack('Error: ${e.toString()}');
    } finally {
      setState(() => _sendingAadhaarOtp = false);
    }
  }

  Future<void> _verifyAadhaarOtp(String aadhaar, String otp) async {
    final result =
        await ApiService.verifyAadhaarOtp(widget.phone, aadhaar, otp);
    if (result['success'] == true) {
      setState(() => _aadhaarVerified = true);
      Navigator.pop(context);
      _showSnack('Aadhaar verified successfully!', success: true);
    } else {
      throw Exception(result['message'] ?? 'Invalid OTP');
    }
  }

  void _showOtpBottomSheet({
    required String title,
    required String subtitle,
    required Future<void> Function(String otp) onVerify,
    required VoidCallback onResend,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _OtpBottomSheet(
        title: title,
        subtitle: subtitle,
        onVerify: onVerify,
        onResend: onResend,
      ),
    );
  }

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            success ? const Color(0xFF16A34A) : AppColors.primary,
      ),
    );
  }

  // REPLACE the entire _submit method with:
void _submit() {
  if (_formKey.currentState!.validate()) {
    if (_selectedGender == null || _selectedGender!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select gender')),
      );
      return;
    }

    final profileData = {
  'name': _nameController.text.trim(),
  'email': _emailController.text.trim(),
  'phoneNumber': widget.phone,
  'dateOfBirth': _selectedDob != null
      ? "${_selectedDob!.year.toString().padLeft(4,'0')}-${_selectedDob!.month.toString().padLeft(2,'0')}-${_selectedDob!.day.toString().padLeft(2,'0')}"
      : '',
  'gender': _selectedGender,
  'address': _addressController.text.trim(),
  'aadhaarNumber': _aadhaarController.text.trim(),
  if (_panController.text.trim().isNotEmpty)
    'panNumber': _panController.text.trim().toUpperCase(),
};

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MpinSetupScreen(
          phone: widget.phone,
          profileData: profileData,
        ),
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
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
                  AppColors.iconBgRed,
                  Colors.white,
                  AppColors.iconBgBlue,
                ],
              ),
            ),
          ),

          // Grid pattern
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // Main layout
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Labh',
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
                ),

                // Scrollable form
                Expanded(
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
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFFE4E4),
                                    Color(0xFFFFF1F2),
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
                                Icons.person_outline,
                                size: 48,
                                color: AppColors.primary,
                              ),
                            ),

                            const SizedBox(height: 16),

                            const Text(
                              'Complete Your Profile',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),

                            const SizedBox(height: 6),

                            const Text(
                              'Please provide your details to continue',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textGrey,
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Full Name
                            _buildField(
                              controller: _nameController,
                              label: 'Full Name',
                              hint: 'Enter your full name',
                              icon: Icons.person_outline,
                              validator: (v) => v!.trim().isEmpty
                                  ? 'Name is required'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            // Email
                            _buildVerifiableField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'Enter your email address',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              isVerified: _emailVerified,
                              isSending: _sendingEmailOtp,
                              onSendOtp: _sendEmailOtp,
                              validator: (v) {
                                if (v!.trim().isEmpty)
                                  return 'Email is required';
                                if (!RegExp(r'\S+@\S+\.\S+').hasMatch(v))
                                  return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // [ADDED] Phone number — read-only pre-filled display
                            // Mirrors React's phoneNumber field (pre-filled, not editable)
                            _buildField(
                              controller: TextEditingController(
                                  text: '+91 ${widget.phone}'),
                              label: 'Mobile Number',
                              hint: '',
                              icon: Icons.phone_outlined,
                              readOnly: true,
                              validator: null,
                            ),
                            const SizedBox(height: 14),

                            // Date of Birth
                            GestureDetector(
                              onTap: _pickDate,
                              child: AbsorbPointer(
                                child: _buildField(
                                  controller: _dobController,
                                  label: 'Date of Birth',
                                  hint: 'DD/MM/YYYY',
                                  icon: Icons.calendar_today_outlined,
                                  validator: (v) => v!.isEmpty
                                      ? 'Date of birth is required'
                                      : null,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Gender dropdown
                            DropdownButtonFormField<String>(
                              value: _selectedGender,
                              decoration: InputDecoration(
                                labelText: 'Gender',
                                prefixIcon: const Icon(
                                    Icons.person_outline,
                                    color: Color(0xFF94A3B8),
                                    size: 20),
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: AppColors.primary, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide:
                                      const BorderSide(color: Colors.red),
                                ),
                              ),
                              hint: const Text(
                                'Select gender',
                                style:
                                    TextStyle(color: Color(0xFF94A3B8)),
                              ),
                              icon: const Icon(Icons.keyboard_arrow_down,
                                  color: Color(0xFF94A3B8)),
                              items: ['Male', 'Female', 'Other']
                                  .map((g) => DropdownMenuItem(
                                        value: g,
                                        child: Text(g),
                                      ))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedGender = val),
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Gender is required'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            // Address
                            _buildField(
                              controller: _addressController,
                              label: 'Address',
                              hint: 'Enter your address',
                              icon: Icons.location_on_outlined,
                              maxLines: 2,
                              validator: (v) => v!.trim().isEmpty
                                  ? 'Address is required'
                                  : null,
                            ),
                            const SizedBox(height: 14),

                            // Aadhaar Number
                            _buildVerifiableField(
                              controller: _aadhaarController,
                              label: 'Aadhaar Number',
                              hint: 'Enter 12-digit Aadhaar number',
                              icon: Icons.credit_card_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              maxLength: 12,
                              isVerified: _aadhaarVerified,
                              isSending: _sendingAadhaarOtp,
                              onSendOtp: _sendAadhaarOtp,
                              validator: (v) {
                                if (v!.trim().isEmpty)
                                  return 'Aadhaar number is required';
                                if (v.length != 12)
                                  return 'Enter valid 12-digit Aadhaar';
                                return null;
                              },
                            ),
                            const SizedBox(height: 14),

                            // [ADDED] PAN Number — optional field matching React
                            _buildField(
                              controller: _panController,
                              label: 'PAN Number (Optional)',
                              hint: 'Enter your PAN number (e.g. ABCDE1234F)',
                              icon: Icons.credit_card_outlined,
                              keyboardType: TextInputType.text,
                              maxLength: 10,
                              // [ADDED] Force uppercase as user types
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9]')),
                                _UpperCaseTextFormatter(),
                              ],
                              // [ADDED] PAN validation — only if filled (optional)
                              // Regex: 5 letters + 4 digits + 1 letter
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return null; // optional — skip if empty
                                }
                                if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$')
                                    .hasMatch(v.trim())) {
                                  return 'Please enter a valid PAN number';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 28),

                            // Continue button
                            _ContinueButton(
                              loading: _loading,
                              onTap: _submit,
                            ),

                            const SizedBox(height: 24),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
    int maxLines = 1,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      readOnly: readOnly,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        prefixIcon:
            Icon(icon, color: const Color(0xFF94A3B8), size: 20),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF8FAFC) : Colors.white,
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        counterText: '',
      ),
    );
  }
  Widget _buildVerifiableField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isVerified,
    required bool isSending,
    required VoidCallback onSendOtp,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return Stack(
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLength: maxLength,
          readOnly: isVerified,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            prefixIcon:
                Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            contentPadding: const EdgeInsets.only(
                left: 48, right: 110, top: 16, bottom: 16),
            filled: true,
            fillColor:
                isVerified ? const Color(0xFFF0FDF4) : Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isVerified
                    ? const Color(0xFF86EFAC)
                    : const Color(0xFFE2E8F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            counterText: '',
          ),
        ),
        Positioned(
          right: 8,
          top: 10,
          child: isVerified
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle,
                          size: 14, color: Color(0xFF16A34A)),
                      SizedBox(width: 4),
                      Text('Verified',
                          style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                )
              : GestureDetector(
                  onTap: isSending ? null : onSendOtp,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: isSending
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Text('Verify',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                  ),
                ),
        ),
      ],
    );
  }
}

// [ADDED] TextInputFormatter that auto-uppercases PAN input as user types
class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

// ── OTP Bottom Sheet ──────────────────────────────────────────────────────────

class _OtpBottomSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final Future<void> Function(String otp) onVerify;
  final VoidCallback onResend;

  const _OtpBottomSheet({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.onVerify,
    required this.onResend,
  }) : super(key: key);

  @override
  State<_OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<_OtpBottomSheet> {
  final List<TextEditingController> _ctrl =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focus = List.generate(6, (_) => FocusNode());
  bool _loading = false;
  String _error = '';
  int _timeLeft = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _focus[0].requestFocus());
  }

  @override
  void dispose() {
    for (final c in _ctrl) c.dispose();
    for (final f in _focus) f.dispose();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _timeLeft = 30;
      _canResend = false;
    });
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _timeLeft--;
        if (_timeLeft <= 0) _canResend = true;
      });
      return _timeLeft > 0;
    });
  }

  void _onChanged(String val, int idx) {
    setState(() => _error = '');
    if (val.isNotEmpty && idx < 5) _focus[idx + 1].requestFocus();
    final allFilled = _ctrl.every((c) => c.text.isNotEmpty);
    if (allFilled && idx == 5) {
      Future.delayed(const Duration(milliseconds: 100), _verify);
    }
  }

  Future<void> _verify() async {
    final otp = _ctrl.map((c) => c.text).join();
    if (otp.length < 6) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await widget.onVerify(otp);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        for (final c in _ctrl) c.clear();
      });
      _focus[0].requestFocus();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(widget.subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                return Container(
                  width: 42,
                  height: 48,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _error.isNotEmpty
                          ? const Color(0xFFEF4444)
                          : _focus[i].hasFocus
                              ? AppColors.accent
                              : const Color(0xFFE2E8F0),
                      width: 2,
                    ),
                  ),
                  child: TextField(
                    controller: _ctrl[i],
                    focusNode: _focus[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    onChanged: (val) => _onChanged(val, i),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                );
              }),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_error,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFFEF4444))),
            ],
            const SizedBox(height: 16),
            _canResend
                ? GestureDetector(
                    onTap: () {
                      widget.onResend();
                      _startTimer();
                    },
                    child: const Text('Resend OTP',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w500)),
                  )
                : Text('Resend in ${_timeLeft}s',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _verify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Verify',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Continue Button ───────────────────────────────────────────────────────────

class _ContinueButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;
  const _ContinueButton({required this.loading, required this.onTap});

  @override
  State<_ContinueButton> createState() => _ContinueButtonState();
}

class _ContinueButtonState extends State<_ContinueButton> {
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
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _pressed
              ? AppColors.primary.withOpacity(0.85)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: widget.loading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text('Please wait...',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedSlide(
                    offset:
                        _pressed ? const Offset(0.2, 0) : Offset.zero,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.arrow_forward,
                        size: 18, color: Colors.white),
                  ),
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