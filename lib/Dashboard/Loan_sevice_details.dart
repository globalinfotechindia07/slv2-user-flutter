import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../widgets/select_field_popup.dart';
import '../auth/otp_success_screen.dart';

// ── Mobile Loan Form Screen — matches React MobileLoanForm.jsx exactly ────────
// Flow:
//   1 — OTP Verification (phone pre-filled, disabled)
//   2 — After verification, 4-step form:
//       Step 0: Personal Details
//       Step 1: Documents
//       Step 2: Employment Details
//       Step 3: Product Details
// Header: Back + service title + Help icon
// StepIndicator shown only after phone verified
// Footer: sticky Continue/Submit button (red)
// Success screen: green checkmark + confetti effect + auto-navigate after 5s

class MobileLoanFormScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final Map<String, dynamic>? serviceDetails;

  const MobileLoanFormScreen({
    super.key,
    required this.userProfile,
    this.serviceDetails,
  });

  @override
  State<MobileLoanFormScreen> createState() =>
      _MobileLoanFormScreenState();
}

class _MobileLoanFormScreenState extends State<MobileLoanFormScreen>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _loading = false;
  bool _isPhoneVerified = false;
  bool _isSubmitted = false;
  Map<String, String> _errors = {};

  // Categories and shops from API
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _shops = [];

  static const List<String> _stepTitles = [
    'Personal Details of Applicant',
    'Documents',
    'Employment Details',
    'Product Details',
  ];
  static const List<String> _stepSubtitles = [
    'Kindly enter your personal information below',
    'Upload your identity documents',
    'Share your work information',
    'What would you like to purchase?',
  ];

  // ── Form controllers ───────────────────────────────────────────────────────
  late final _fullNameCtrl = TextEditingController(
      text: widget.userProfile['name']?.toString() ?? '');
  late final _emailCtrl = TextEditingController(
      text: widget.userProfile['email']?.toString() ?? '');
  late final _dobCtrl = TextEditingController(
      text: widget.userProfile['dob']?.toString() ?? '');
  late final _addressCtrl = TextEditingController(
      text: widget.userProfile['address']?.toString() ?? '');
  final _aadharNumberCtrl = TextEditingController();
  final _panNumberCtrl = TextEditingController();
  final _companyNameCtrl = TextEditingController();
  final _monthlyIncomeCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _productPriceCtrl = TextEditingController();
  final _downPaymentCtrl = TextEditingController();

  // Select field values
  String? _gender;
  String? _employmentType;
  String? _workExperience;
  String? _shopName;

  // File fields (mock — use file_picker in production)
  String? _aadharDoc;
  String? _aadharDocBack;
  String? _panDoc;

  // Success animation
  late final AnimationController _bounceCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadShops();
    // Pre-fill gender from userProfile
    _gender = widget.userProfile['gender']?.toString();
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    _aadharNumberCtrl.dispose();
    _panNumberCtrl.dispose();
    _companyNameCtrl.dispose();
    _monthlyIncomeCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _productPriceCtrl.dispose();
    _downPaymentCtrl.dispose();
    _bounceCtrl.dispose();
    super.dispose();
  }

  // ── API calls ──────────────────────────────────────────────────────────────

  Future<void> _loadCategories() async {
    try {
      final result = await ApiService.fetchCategories();
      if (result['data'] != null) {
        setState(() => _categories =
            List<Map<String, dynamic>>.from(result['data']));
      }
    } catch (_) {}
  }

  Future<void> _loadShops() async {
    try {
      final result = await ApiService.listShop();
      final allShops =
          List<Map<String, dynamic>>.from(result['list'] ?? []);
      final category =
          widget.serviceDetails?['psLcategory']?.toString() ?? '';
      final filtered = category.isEmpty
          ? allShops
          : allShops.where((shop) {
              final cats = shop['categories'] as List? ?? [];
              return cats.any((c) => c['name'] == category);
            }).toList();
      setState(() => _shops = filtered);
    } catch (_) {}
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  bool _validateStep() {
    final e = <String, String>{};

    switch (_currentStep) {
      case 0: // Personal
        if (_fullNameCtrl.text.trim().isEmpty) {
          e['fullName'] = 'Full name is required';
        }
        if (_emailCtrl.text.trim().isEmpty) {
          e['email'] = 'Email is required';
        } else if (!RegExp(r'\S+@\S+\.\S+')
            .hasMatch(_emailCtrl.text)) {
          e['email'] = 'Enter valid email';
        }
        if (_dobCtrl.text.trim().isEmpty) {
          e['dob'] = 'Date of birth is required';
        }
        if (_gender == null || _gender!.isEmpty) {
          e['gender'] = 'Gender is required';
        }
        if (_addressCtrl.text.trim().isEmpty) {
          e['address'] = 'Address is required';
        }
        break;

      case 1: // Documents
        if (_aadharNumberCtrl.text.trim().isEmpty) {
          e['aadharNumber'] = 'Aadhar number is required';
        } else if (!RegExp(r'^\d{12}$')
            .hasMatch(_aadharNumberCtrl.text)) {
          e['aadharNumber'] = 'Enter valid 12-digit Aadhar number';
        }
        if (_aadharDoc == null) {
          e['aadharDoc'] = 'Aadhar Front Side document is required';
        }
        if (_aadharDocBack == null) {
          e['aadharDocBack'] = 'Aadhar Back Side document is required';
        }
        break;

      case 2: // Employment
        if (_employmentType == null || _employmentType!.isEmpty) {
          e['employmentType'] = 'Employment type is required';
        }
        if (_companyNameCtrl.text.trim().isEmpty) {
          e['companyName'] = 'Company name is required';
        }
        if (_monthlyIncomeCtrl.text.trim().isEmpty) {
          e['monthlyIncome'] = 'Monthly income is required';
        } else if ((double.tryParse(_monthlyIncomeCtrl.text) ?? 0) <
            10000) {
          e['monthlyIncome'] =
              'Monthly income must be at least ₹10,000';
        }
        if (_workExperience == null || _workExperience!.isEmpty) {
          e['workExperience'] = 'Work experience is required';
        }
        break;

      case 3: // Product
        if (_brandCtrl.text.trim().isEmpty) {
          e['brand'] = 'Brand is required';
        }
        if (_modelCtrl.text.trim().isEmpty) {
          e['model'] = 'Model is required';
        }
        if (_shopName == null || _shopName!.isEmpty) {
          e['shopName'] = 'Shop name is required';
        }
        if (_productPriceCtrl.text.trim().isEmpty) {
          e['productPrice'] = 'Product price is required';
        } else if ((double.tryParse(_productPriceCtrl.text) ?? 0) <
            1000) {
          e['productPrice'] =
              'Product price must be at least ₹1,000';
        }
        final dp =
            double.tryParse(_downPaymentCtrl.text) ?? 0;
        final pp =
            double.tryParse(_productPriceCtrl.text) ?? 0;
        if (dp < 0) {
          e['downPayment'] = 'Down payment cannot be negative';
        } else if (_downPaymentCtrl.text.isNotEmpty && dp > pp) {
          e['downPayment'] =
              'Down payment cannot be more than product price';
        }
        break;
    }

    setState(() => _errors = e);
    return e.isEmpty;
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  Future<void> _handleNext() async {
    if (!_validateStep()) return;

    setState(() => _loading = true);
    try {
      if (_currentStep == _stepTitles.length - 1) {
        // Submit form
        final formData = {
          'phoneNumber': widget.userProfile['phoneNumber'] ?? '',
          'fullName': _fullNameCtrl.text,
          'email': _emailCtrl.text,
          'dob': _dobCtrl.text,
          'gender': _gender ?? '',
          'address': _addressCtrl.text,
          'aadharNumber': _aadharNumberCtrl.text,
          'panNumber': _panNumberCtrl.text,
          'employmentType': _employmentType ?? '',
          'companyName': _companyNameCtrl.text,
          'monthlyIncome': _monthlyIncomeCtrl.text,
          'workExperience': _workExperience ?? '',
          'productType':
              widget.serviceDetails?['psLcategory'] ?? '',
          'brand': _brandCtrl.text,
          'model': _modelCtrl.text,
          'productPrice': _productPriceCtrl.text,
          'downPayment': _downPaymentCtrl.text,
          'shopName': _shopName ?? '',
        };

        // TODO: await ApiService.addForm(formData);
        await Future.delayed(const Duration(milliseconds: 800));

        // Send notification
        // TODO: await ApiService.notifyUser(userId, message)

        setState(() => _isSubmitted = true);
        _bounceCtrl.repeat(reverse: true);

        // Auto-navigate after 5 seconds
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) Navigator.pop(context);
        });
      } else {
        setState(() => _currentStep++);
      }
    } catch (e) {
      setState(
          () => _errors = {'submit': e.toString()});
    } finally {
      setState(() => _loading = false);
    }
  }

  void _handleBack() {
    if (_currentStep == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _currentStep--);
    }
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (_, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
              primary: Color(0xFFDC2626)),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dobCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show success screen
    if (_isSubmitted) return _buildSuccessScreen();

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
          Positioned.fill(
              child: CustomPaint(painter: _GridPainter())),

          SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.80),
                    border: const Border(
                      bottom:
                          BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _handleBack,
                              child: Row(
                                children: const [
                                  Icon(Icons.arrow_back,
                                      size: 16,
                                      color: Color(0xFF475569)),
                                  SizedBox(width: 6),
                                  Text('Back',
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight:
                                              FontWeight.w500,
                                          color:
                                              Color(0xFF475569))),
                                ],
                              ),
                            ),
                            Text(
                              widget.serviceDetails?['pstitle']
                                      ?.toString() ??
                                  'Loan Service',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            GestureDetector(
                              onTap: () {},
                              child: const Icon(
                                  Icons.help_outline,
                                  size: 24,
                                  color: Color(0xFF475569)),
                            ),
                          ],
                        ),
                      ),
                      // Step indicator — shown only after phone verified
                      if (_isPhoneVerified)
                        _StepIndicator(
                          currentStep: _currentStep,
                          totalSteps: _stepTitles.length,
                        ),
                    ],
                  ),
                ),

                // ── Body ──────────────────────────────────────────────
                Expanded(
                  child: _isPhoneVerified
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(
                              24, 24, 24, 16),
                          child: _buildCurrentStep(),
                        )
                      : _buildOtpView(),
                ),

                // ── Footer — shown only after phone verified ──────────
                if (_isPhoneVerified)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.80),
                      border: const Border(
                        top: BorderSide(
                            color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: _NextButton(
                      loading: _loading,
                      text: _currentStep ==
                              _stepTitles.length - 1
                          ? 'Submit Application'
                          : 'Continue',
                      onTap: _handleNext,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── OTP View (before phone verified) ──────────────────────────────────────

  Widget _buildOtpView() {
    // Reuse OtpScreen logic as an embedded widget
    // Since OtpScreen is a full screen, we show an inline OTP form here
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Phone Verification',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please verify your phone number to continue',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 32),
            _PrimaryButton(
              label: 'Verify Phone Number',
              loadingLabel: 'Verifying...',
              loading: false,
              onTap: () async {
                // Navigate to OTP screen and wait for result
                final verified = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OtpScreen(
                      phone: widget.userProfile['phoneNumber']
                              ?.toString() ??
                          '',
                      isNewUser: false,
                    ),
                  ),
                );
                if (verified == true || verified == null) {
                  // If user came back (verified or skipped)
                  setState(() => _isPhoneVerified = true);
                }
              },
            ),
            const SizedBox(height: 16),
            // Or skip verification for demo
            GestureDetector(
              onTap: () => setState(() => _isPhoneVerified = true),
              child: const Text(
                'Skip for now',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF2563EB),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF2563EB),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step builders ──────────────────────────────────────────────────────────

  Widget _buildCurrentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_stepTitles[_currentStep],
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text(_stepSubtitles[_currentStep],
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF475569))),
        const SizedBox(height: 24),
        _buildStepContent(),
      ],
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      case 3:
        return _buildStep3();
      default:
        return const SizedBox();
    }
  }

  // ── Step 0: Personal Details ───────────────────────────────────────────────

  Widget _buildStep0() {
    return Column(
      children: [
        _InputField(
          label: 'Full Name',
          controller: _fullNameCtrl,
          hint: 'Enter your full name',
          error: _errors['fullName'],
          onChanged: (_) =>
              setState(() => _errors.remove('fullName')),
        ),
        const SizedBox(height: 16),
        _InputField(
          label: 'Email',
          controller: _emailCtrl,
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          error: _errors['email'],
          onChanged: (_) =>
              setState(() => _errors.remove('email')),
        ),
        const SizedBox(height: 16),
        // Date of Birth
        GestureDetector(
          onTap: _pickDate,
          child: AbsorbPointer(
            child: _InputField(
              label: 'Date of Birth',
              controller: _dobCtrl,
              hint: 'YYYY-MM-DD',
              error: _errors['dob'],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Gender dropdown
        SelectFieldPopup(
          label: 'Gender',
          value: _gender,
          error: _errors['gender'],
          options: const [
            SelectOption(value: 'male', label: 'Male'),
            SelectOption(value: 'female', label: 'Female'),
            SelectOption(value: 'other', label: 'Other'),
          ],
          onChange: (val) {
            setState(() {
              _gender = val;
              _errors.remove('gender');
            });
          },
        ),
        const SizedBox(height: 16),
        _InputField(
          label: 'Address',
          controller: _addressCtrl,
          hint: 'Enter your address',
          maxLines: 2,
          error: _errors['address'],
          onChanged: (_) =>
              setState(() => _errors.remove('address')),
        ),
      ],
    );
  }

  // ── Step 1: Documents ──────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      children: [
        _InputField(
          label: 'Aadhar Number',
          controller: _aadharNumberCtrl,
          hint: 'Enter 12-digit Aadhar number',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(12),
          ],
          error: _errors['aadharNumber'],
          onChanged: (_) =>
              setState(() => _errors.remove('aadharNumber')),
        ),
        const SizedBox(height: 16),
        _FileUploadField(
          label: 'Upload Front Aadhar Card (PDF/Image)',
          value: _aadharDoc,
          error: _errors['aadharDoc'],
          onPick: (name) =>
              setState(() => _aadharDoc = name),
          onRemove: () => setState(() => _aadharDoc = null),
        ),
        const SizedBox(height: 16),
        _FileUploadField(
          label: 'Upload Back Aadhar Card (PDF/Image)',
          value: _aadharDocBack,
          error: _errors['aadharDocBack'],
          onPick: (name) =>
              setState(() => _aadharDocBack = name),
          onRemove: () =>
              setState(() => _aadharDocBack = null),
        ),
        const SizedBox(height: 16),
        _InputField(
          label: 'PAN Number',
          controller: _panNumberCtrl,
          hint: 'Enter PAN number',
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            LengthLimitingTextInputFormatter(10),
          ],
          error: _errors['panNumber'],
          onChanged: (_) =>
              setState(() => _errors.remove('panNumber')),
        ),
        const SizedBox(height: 16),
        _FileUploadField(
          label: 'Upload PAN Card (PDF/Image)',
          value: _panDoc,
          error: _errors['panDoc'],
          onPick: (name) => setState(() => _panDoc = name),
          onRemove: () => setState(() => _panDoc = null),
        ),
      ],
    );
  }

  // ── Step 2: Employment Details ─────────────────────────────────────────────

  Widget _buildStep2() {
    return Column(
      children: [
        SelectFieldPopup(
          label: 'Employment Type',
          value: _employmentType,
          error: _errors['employmentType'],
          options: const [
            SelectOption(value: 'salaried', label: 'Salaried'),
            SelectOption(
                value: 'self-employed', label: 'Self Employed'),
            SelectOption(
                value: 'business', label: 'Business Owner'),
          ],
          onChange: (val) => setState(() {
            _employmentType = val;
            _errors.remove('employmentType');
          }),
        ),
        const SizedBox(height: 16),
        _InputField(
          label: 'Company Name',
          controller: _companyNameCtrl,
          hint: 'Enter company name',
          error: _errors['companyName'],
          onChanged: (_) =>
              setState(() => _errors.remove('companyName')),
        ),
        const SizedBox(height: 16),
        _InputField(
          label: 'Monthly Income',
          controller: _monthlyIncomeCtrl,
          hint: 'Enter monthly income',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          error: _errors['monthlyIncome'],
          onChanged: (_) =>
              setState(() => _errors.remove('monthlyIncome')),
        ),
        const SizedBox(height: 16),
        SelectFieldPopup(
          label: 'Work Experience',
          value: _workExperience,
          error: _errors['workExperience'],
          options: const [
            SelectOption(value: '0-1', label: '0-1 years'),
            SelectOption(value: '1-3', label: '1-3 years'),
            SelectOption(value: '3-5', label: '3-5 years'),
            SelectOption(value: '5+', label: '5+ years'),
          ],
          onChange: (val) => setState(() {
            _workExperience = val;
            _errors.remove('workExperience');
          }),
        ),
      ],
    );
  }

  // ── Step 3: Product Details ────────────────────────────────────────────────

  Widget _buildStep3() {
    final shopOptions = _shops
        .map((shop) => SelectOption(
              value: shop['id']?.toString() ?? '',
              label:
                  '${shop['shop_name'] ?? ''}, ${shop['address'] ?? ''}, ${shop['city'] ?? ''}',
            ))
        .toList();

    return Column(
      children: [
        _InputField(
          label: 'Brand',
          controller: _brandCtrl,
          hint: 'Enter brand name',
          error: _errors['brand'],
          onChanged: (_) =>
              setState(() => _errors.remove('brand')),
        ),
        const SizedBox(height: 16),
        _InputField(
          label: 'Model',
          controller: _modelCtrl,
          hint: 'Enter model name',
          error: _errors['model'],
          onChanged: (_) =>
              setState(() => _errors.remove('model')),
        ),
        const SizedBox(height: 16),
        _InputField(
          label: 'Product Price',
          controller: _productPriceCtrl,
          hint: 'Enter product price',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          error: _errors['productPrice'],
          onChanged: (_) =>
              setState(() => _errors.remove('productPrice')),
        ),
        const SizedBox(height: 16),
        _InputField(
          label: 'Down Payment',
          controller: _downPaymentCtrl,
          hint: 'Enter down payment amount',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          error: _errors['downPayment'],
          onChanged: (_) =>
              setState(() => _errors.remove('downPayment')),
        ),
        const SizedBox(height: 16),
        SelectFieldPopup(
          label: 'Shop Name',
          value: _shopName,
          error: _errors['shopName'],
          options: shopOptions.isEmpty
              ? const [
                  SelectOption(
                      value: 'default', label: 'Default Shop'),
                ]
              : shopOptions,
          onChange: (val) => setState(() {
            _shopName = val;
            _errors.remove('shopName');
          }),
        ),
      ],
    );
  }

  // ── Success screen ─────────────────────────────────────────────────────────

  Widget _buildSuccessScreen() {
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
          Positioned.fill(
              child: CustomPaint(painter: _GridPainter())),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bouncing green checkmark
                  AnimatedBuilder(
                    animation: _bounceCtrl,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(
                          0, -8 * _bounceCtrl.value),
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
                  const SizedBox(height: 24),
                  const Text(
                    'Congratulations!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your loan application form has been submitted successfully!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF475569)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Our executives will contact you soon.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF475569)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step Indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepIndicator(
      {required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    final pct =
        ((currentStep + 1) / totalSteps * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Text('Step ${currentStep + 1}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151))),
                const SizedBox(width: 4),
                Text('of $totalSteps',
                    style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280))),
              ]),
              Text('$pct%',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFDC2626))),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / totalSteps,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation(
                  Color(0xFFDC2626)),
              minHeight: 8,
            ),
          ),
        ],
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
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final List<TextInputFormatter>? inputFormatters;
  final bool enabled;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.label,
    required this.controller,
    this.hint,
    this.error,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.enabled = true,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155))),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          enabled: enabled,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: enabled
                ? Colors.white
                : const Color(0xFFF8FAFC),
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0), width: 2),
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
                      fontSize: 12,
                      color: Color(0xFFEF4444))),
            ],
          ),
        ],
      ],
    );
  }
}

// ── File Upload Field ─────────────────────────────────────────────────────────

class _FileUploadField extends StatelessWidget {
  final String label;
  final String? value;
  final String? error;
  final ValueChanged<String> onPick;
  final VoidCallback onRemove;

  const _FileUploadField({
    required this.label,
    required this.onPick,
    required this.onRemove,
    this.value,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => onPick(
              '${label.replaceAll(' ', '_').replaceAll('/', '_')}.pdf'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            child: value != null
                ? Row(
                    children: [
                      const Icon(
                          Icons.insert_drive_file_outlined,
                          color: Color(0xFFDC2626),
                          size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(value!,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color:
                                      Color(0xFF0F172A)))),
                      GestureDetector(
                        onTap: onRemove,
                        child: const Icon(Icons.close,
                            size: 18,
                            color: Color(0xFF94A3B8)),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload_outlined,
                          color: Color(0xFF94A3B8),
                          size: 20),
                      const SizedBox(width: 8),
                      Text('Upload $label',
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF94A3B8))),
                    ],
                  ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.error_outline,
                size: 14, color: Color(0xFFEF4444)),
            const SizedBox(width: 4),
            Text(error!,
                style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFEF4444))),
          ]),
        ],
      ],
    );
  }
}

// ── Next Button (red) ─────────────────────────────────────────────────────────

class _NextButton extends StatefulWidget {
  final bool loading;
  final String text;
  final VoidCallback onTap;
  const _NextButton(
      {required this.loading,
      required this.text,
      required this.onTap});

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
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
        transform: Matrix4.identity()
          ..scale(_pressed ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
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
              blurRadius: 20,
              offset: const Offset(0, 6),
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
                        strokeWidth: 2,
                        color: Colors.white),
                  ),
                  SizedBox(width: 10),
                  Text('Processing...',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(widget.text,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(width: 8),
                  AnimatedSlide(
                    offset: _pressed
                        ? const Offset(0.2, 0)
                        : Offset.zero,
                    duration:
                        const Duration(milliseconds: 300),
                    child: const Icon(Icons.arrow_forward,
                        size: 18, color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Primary Button (for OTP view) ─────────────────────────────────────────────

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
        transform: Matrix4.identity()
          ..scale(_pressed ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0xFFB91C1C)
              : const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(12),
        ),
        child: widget.loading
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white)),
                  SizedBox(width: 10),
                  Text('Processing...',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ],
              )
            : Text(widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
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
      canvas.drawLine(
          Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      false;
}