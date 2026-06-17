import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; 
import '../../../services/api_service.dart';


const List<Map<String, String>> kSteps = [
  {'key': 'personal', 'label': 'Personal Details', 'subtitle': 'Tell us about yourself'},
  {'key': 'documents', 'label': 'Documents', 'subtitle': 'Upload your identity documents'},
  {'key': 'employment', 'label': 'Employment Details', 'subtitle': 'Share your work information'},
  {'key': 'product', 'label': 'Product Details', 'subtitle': 'What would you like to purchase?'},
];

const List<Map<String, String>> kEmploymentTypes = [
  {'value': 'salaried', 'label': 'Salaried'},
  {'value': 'self-employed', 'label': 'Self Employed'},
  {'value': 'business', 'label': 'Business Owner'},
];

const List<Map<String, String>> kGenderOptions = [
  {'value': 'male', 'label': 'Male'},
  {'value': 'female', 'label': 'Female'},
  {'value': 'other', 'label': 'Other'},
];

const List<Map<String, String>> kWorkExperienceOptions = [
  {'value': '0-1', 'label': '0-1 years'},
  {'value': '1-3', 'label': '1-3 years'},
  {'value': '3-5', 'label': '3-5 years'},
  {'value': '5+', 'label': '5+ years'},
];

// ─── Color Palette ────────────────────────────────────────────────────────────

const Color kPrimary = Color(0xFFDC2626);       // red-600
const Color kPrimaryLight = Color(0xFFFEF2F2);  // red-50
const Color kPrimaryDark = Color(0xFFB91C1C);   // red-700
const Color kBlue = Color(0xFF2563EB);
const Color kBlueBg = Color(0xFFDBEAFE);
const Color kSurface = Color(0xFFFFFFFF);
const Color kSlate900 = Color(0xFF0F172A);
const Color kSlate700 = Color(0xFF374151);
const Color kSlate600 = Color(0xFF475569);
const Color kSlate400 = Color(0xFF94A3B8);
const Color kSlate200 = Color(0xFFE2E8F0);
const Color kSlate100 = Color(0xFFF1F5F9);

// ─── Data Models ─────────────────────────────────────────────────────────────

class UserProfile {
  final String? id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? dob;
  final String? address;
  final String? gender;

  const UserProfile({
    this.id,
    this.name,
    this.email,
    this.phoneNumber,
    this.dob,
    this.address,
    this.gender,
  });
}

class ServiceDetails {
  final String? psTitle;
  final String? psLcategory;

  const ServiceDetails({this.psTitle, this.psLcategory});
}

class ShopModel {
  final String id;
  final String shopName;
  final String address;
  final String city;

  const ShopModel({
    required this.id,
    required this.shopName,
    required this.address,
    required this.city,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id']?.toString() ?? '',
      shopName: json['shop_name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
    );
  }
}

class CategoryModel {
  final String name;
  const CategoryModel({required this.name});

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      CategoryModel(name: json['name']?.toString() ?? '');
}

// ─── Form Data ────────────────────────────────────────────────────────────────

class LoanFormData {
  String phoneNumber;
  String otp;
  String fullName;
  String email;
  String dob;
  String address;
  String aadharNumber;
  String panNumber;
  File? aadharDoc;
  File? aadharDocBack;
  File? panDoc;
  String employmentType;
  String monthlyIncome;
  String companyName;
  String workExperience;
  String productType;
  String shopName;
  String brand;
  String model;
  String productPrice;
  String downPayment;
  String gender;

  LoanFormData({
    this.phoneNumber = '',
    this.otp = '',
    this.fullName = '',
    this.email = '',
    this.dob = '',
    this.address = '',
    this.aadharNumber = '',
    this.panNumber = '',
    this.aadharDoc,
    this.aadharDocBack,
    this.panDoc,
    this.employmentType = '',
    this.monthlyIncome = '',
    this.companyName = '',
    this.workExperience = '',
    this.productType = '',
    this.shopName = '',
    this.brand = '',
    this.model = '',
    this.productPrice = '',
    this.downPayment = '',
    this.gender = '',
  });
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class MobileLoanFormScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final ServiceDetails? serviceDetails;

  const MobileLoanFormScreen({
    Key? key,
    this.userProfile,
    this.serviceDetails,
  }) : super(key: key);

  @override
  State<MobileLoanFormScreen> createState() => _MobileLoanFormScreenState();
}

class _MobileLoanFormScreenState extends State<MobileLoanFormScreen>
    with TickerProviderStateMixin {
  // Mirrors React: isPhoneVerified, currentStep, loading, isSubmitted
  bool _isPhoneVerified = false;
  int _currentStep = 0;
  bool _loading = false;
  bool _isSubmitted = false;

  final Map<String, String> _errors = {};
  List<ShopModel> _shops = [];
  List<CategoryModel> _categories = [];

  late LoanFormData _formData;

  // For carousel auto-play
  int _carouselIndex = 0;
  Timer? _carouselTimer;

  // Animation
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, String>> _slides = const [
    {
      'title': 'Quick Approval',
      'description': 'Get instant mobile loans with minimal documentation',
      'emoji': '⚡',
    },
    {
      'title': 'Flexible EMIs',
      'description': 'Pay in easy installments tailored to your budget',
      'emoji': '📅',
    },
    {
      'title': 'Low Interest Rates',
      'description': 'Affordable interest rates to suit your needs',
      'emoji': '💰',
    },
  ];

  @override
  void initState() {
    super.initState();
    _formData = LoanFormData(
      phoneNumber: widget.userProfile?.phoneNumber ?? '',
      fullName: widget.userProfile?.name ?? '',
      email: widget.userProfile?.email ?? '',
      dob: widget.userProfile?.dob ?? '',
      address: widget.userProfile?.address ?? '',
      gender: widget.userProfile?.gender ?? '',
      productType: widget.serviceDetails?.psLcategory ?? '',
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();

    _startCarousel();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _startCarousel() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && !_isPhoneVerified) {
        setState(() => _carouselIndex = (_carouselIndex + 1) % _slides.length);
      }
    });
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([_fetchCategories(), _fetchShops()]);
  }

  Future<void> _fetchCategories() async {
    try {
      final res = await http.get(Uri.parse('${ApiConstants.adminBaseUrl}/categories.php'));
      final body = jsonDecode(res.body) as List;
      setState(() => _categories = body.map(CategoryModel.fromJson).toList());
    } catch (e) {
      debugPrint('Categories error: $e');
    }
  }

  Future<void> _fetchShops() async {
    try {
      final res = await http.get(Uri.parse('${ApiConstants.adminBaseUrl}/shops.php'));
      final body = jsonDecode(res.body);
      final allShops = (body['list'] as List).map(ShopModel.fromJson).toList();
      // Mirror: filter shops by serviceDetails category
      setState(() {
        _shops = widget.serviceDetails?.psLcategory != null
            ? allShops
                .where((s) => s.shopName
                    .toLowerCase()
                    .contains(widget.serviceDetails!.psLcategory!.toLowerCase()))
                .toList()
            : allShops;
      });
    } catch (e) {
      debugPrint('Shops error: $e');
    }
  }

  // ─── Validation (mirrors validateStep) ───────────────────────────────────

  bool _validateStep() {
    final errors = <String, String>{};

    switch (_currentStep) {
      case 0: // Personal
        if (_formData.fullName.trim().isEmpty) errors['fullName'] = 'Full name is required';
        if (_formData.email.trim().isEmpty) {
          errors['email'] = 'Email is required';
        } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(_formData.email)) {
          errors['email'] = 'Enter valid email';
        }
        if (_formData.dob.isEmpty) errors['dob'] = 'Date of birth is required';
        if (_formData.gender.isEmpty) errors['gender'] = 'Gender is required';
        if (_formData.address.trim().isEmpty) errors['address'] = 'Address is required';
        break;

      case 1: // Documents
        if (_formData.aadharNumber.isEmpty) {
          errors['aadharNumber'] = 'Aadhar number is required';
        } else if (!RegExp(r'^\d{12}$').hasMatch(_formData.aadharNumber)) {
          errors['aadharNumber'] = 'Enter valid 12-digit Aadhar number';
        }
        if (_formData.aadharDoc == null) {
          errors['aadharDoc'] = 'Aadhar Front Side document is required';
        }
        if (_formData.aadharDocBack == null) {
          errors['aadharDocBack'] = 'Aadhar Back Side document is required';
        }
        break;

      case 2: // Employment
        if (_formData.employmentType.isEmpty) errors['employmentType'] = 'Employment type is required';
        if (_formData.companyName.trim().isEmpty) errors['companyName'] = 'Company name is required';
        if (_formData.monthlyIncome.isEmpty) {
          errors['monthlyIncome'] = 'Monthly income is required';
        } else if ((double.tryParse(_formData.monthlyIncome) ?? 0) < 10000) {
          errors['monthlyIncome'] = 'Monthly income must be at least ₹10,000';
        }
        if (_formData.workExperience.isEmpty) errors['workExperience'] = 'Work experience is required';
        break;

      case 3: // Product
        if (_formData.brand.trim().isEmpty) errors['brand'] = 'Brand is required';
        if (_formData.model.trim().isEmpty) errors['model'] = 'Model is required';
        if (_formData.shopName.isEmpty) errors['shopName'] = 'Shop name is required';
        if (_formData.productPrice.isEmpty) {
          errors['productPrice'] = 'Product price is required';
        } else if ((double.tryParse(_formData.productPrice) ?? 0) < 1000) {
          errors['productPrice'] = 'Product price must be at least ₹1,000';
        }
        final dp = double.tryParse(_formData.downPayment) ?? 0;
        final pp = double.tryParse(_formData.productPrice) ?? 0;
        if (dp < 0) errors['downPayment'] = 'Down payment cannot be negative';
        if (_formData.downPayment.isNotEmpty && dp > pp) {
          errors['downPayment'] = 'Down payment cannot exceed product price';
        }
        break;
    }

    setState(() => _errors
      ..clear()
      ..addAll(errors));
    return errors.isEmpty;
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> _handleNext() async {
    if (!_validateStep()) return;

    setState(() => _loading = true);
    try {
      if (_currentStep == kSteps.length - 1) {
        await _submitForm();
      } else {
        _fadeController.reset();
        setState(() => _currentStep++);
        _fadeController.forward();
      }
    } catch (e) {
      setState(() => _errors['submit'] = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitForm() async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.adminBaseUrl}/submit_loan.php'),
    );

    // Add text fields
    request.fields.addAll({
      'phoneNumber': _formData.phoneNumber,
      'fullName': _formData.fullName,
      'email': _formData.email,
      'dob': _formData.dob,
      'address': _formData.address,
      'aadharNumber': _formData.aadharNumber,
      'panNumber': _formData.panNumber,
      'employmentType': _formData.employmentType,
      'monthlyIncome': _formData.monthlyIncome,
      'companyName': _formData.companyName,
      'workExperience': _formData.workExperience,
      'productType': _formData.productType,
      'shopName': _formData.shopName,
      'brand': _formData.brand,
      'model': _formData.model,
      'productPrice': _formData.productPrice,
      'downPayment': _formData.downPayment,
      'gender': _formData.gender,
    });

    // Add files
    if (_formData.aadharDoc != null) {
      request.files.add(await http.MultipartFile.fromPath('aadharDoc', _formData.aadharDoc!.path));
    }
    if (_formData.aadharDocBack != null) {
      request.files.add(await http.MultipartFile.fromPath('aadharDocBack', _formData.aadharDocBack!.path));
    }
    if (_formData.panDoc != null) {
      request.files.add(await http.MultipartFile.fromPath('panDoc', _formData.panDoc!.path));
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body);

    if (body['success'] == true) {
      // Send notification
      await http.post(
        Uri.parse('${ApiConstants.userBaseUrl}/notifications.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': 'Your Mobile loan application has been submitted successfully',
          'user_id': widget.userProfile?.id,
        }),
      );
      setState(() => _isSubmitted = true);
    } else {
      throw Exception(body['message'] ?? 'Submission failed');
    }
  }

  void _handleBack() {
    if (_currentStep == 0) {
      Navigator.of(context).pop();
    } else {
      _fadeController.reset();
      setState(() => _currentStep--);
      _fadeController.forward();
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) {
      return _SuccessScreen(
        onClose: () {
          setState(() => _isSubmitted = false);
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Gradient background
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
          // Decorative blobs
          Positioned(
            right: -80,
            top: 80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFFFECACA).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -80,
            bottom: 100,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFFBFDBFE).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                if (_isPhoneVerified) _buildStepIndicator(),
                Expanded(
                  child: _isPhoneVerified
                      ? _buildFormBody()
                      : _buildOtpBody(),
                ),
                if (_isPhoneVerified) _buildNextButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: kSlate200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _isPhoneVerified ? _handleBack : () => Navigator.of(context).pop(),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios_new, size: 16, color: kSlate600),
                const SizedBox(width: 4),
                Text('Back',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(
            widget.serviceDetails?.psTitle ?? 'Loan Service',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kSlate900),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.help_outline, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ─── Step Indicator ───────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    final progress = (_currentStep + 1) / kSteps.length;
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: Colors.white.withOpacity(0.8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Step ${_currentStep + 1}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kSlate700),
                    ),
                    TextSpan(
                      text: ' of ${kSteps.length}',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── OTP Body (mirrors !isPhoneVerified branch) ───────────────────────────

  Widget _buildOtpBody() {
    return Column(
      children: [
        // Carousel (mirrors Swiper)
        _buildCarousel(),
        Expanded(
          child: SingleChildScrollView(
            child: _OtpVerificationWidget(
              initialPhone: _formData.phoneNumber,
              onVerified: (phone) {
                _carouselTimer?.cancel();
                setState(() {
                  _isPhoneVerified = true;
                  _formData.phoneNumber = phone;
                });
                _fadeController.forward();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarousel() {
    final slide = _slides[_carouselIndex];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(_carouselIndex),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          children: [
            Text(
              slide['title']!,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kSlate900),
            ),
            const SizedBox(height: 8),
            Text(
              slide['emoji']!,
              style: const TextStyle(fontSize: 72),
            ),
            const SizedBox(height: 8),
            Text(
              slide['description']!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            // Dot indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_slides.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _carouselIndex ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _carouselIndex ? kPrimary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(100),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Form Body ────────────────────────────────────────────────────────────

  Widget _buildFormBody() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: _buildStepContent(),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildPersonalStep();
      case 1:
        return _buildDocumentsStep();
      case 2:
        return _buildEmploymentStep();
      case 3:
        return _buildProductStep();
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Step 0: Personal Details ─────────────────────────────────────────────

  Widget _buildPersonalStep() {
    return _FormSection(
      title: 'Personal Details of Applicant',
      subtitle: 'Kindly enter your personal information below',
      icon: Icons.person_outline,
      children: [
        _LoanInputField(
          label: 'Full Name',
          value: _formData.fullName,
          placeholder: 'Enter your full name',
          error: _errors['fullName'],
          onChanged: (v) => setState(() {
            _formData.fullName = v;
            _errors.remove('fullName');
          }),
        ),
        _LoanInputField(
          label: 'Email',
          value: _formData.email,
          placeholder: 'Enter your email',
          error: _errors['email'],
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => setState(() {
            _formData.email = v;
            _errors.remove('email');
          }),
        ),
        _DatePickerField(
          label: 'Date of Birth',
          value: _formData.dob,
          error: _errors['dob'],
          onChanged: (v) => setState(() {
            _formData.dob = v;
            _errors.remove('dob');
          }),
        ),
        _SelectPopupField(
          label: 'Gender',
          value: _formData.gender,
          options: kGenderOptions,
          error: _errors['gender'],
          onChanged: (v) => setState(() {
            _formData.gender = v;
            _errors.remove('gender');
          }),
        ),
        _LoanInputField(
          label: 'Address',
          value: _formData.address,
          placeholder: 'Enter your address',
          error: _errors['address'],
          maxLines: 2,
          onChanged: (v) => setState(() {
            _formData.address = v;
            _errors.remove('address');
          }),
        ),
      ],
    );
  }

  // ─── Step 1: Documents ────────────────────────────────────────────────────

  Widget _buildDocumentsStep() {
    return _FormSection(
      title: 'Documents',
      subtitle: 'Upload your identity documents',
      icon: Icons.file_copy_outlined,
      children: [
        _LoanInputField(
          label: 'Aadhar Number',
          value: _formData.aadharNumber,
          placeholder: 'Enter 12-digit Aadhar number',
          error: _errors['aadharNumber'],
          keyboardType: TextInputType.number,
          maxLength: 12,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => setState(() {
            _formData.aadharNumber = v;
            _errors.remove('aadharNumber');
          }),
        ),
        _FileUploadField(
          label: 'Upload Front Aadhar Card (PDF/Image)',
          value: _formData.aadharDoc,
          error: _errors['aadharDoc'],
          onChanged: (f) => setState(() {
            _formData.aadharDoc = f;
            _errors.remove('aadharDoc');
          }),
          onRemove: () => setState(() {
            _formData.aadharDoc = null;
            _errors.remove('aadharDoc');
          }),
        ),
        _FileUploadField(
          label: 'Upload Back Aadhar Card (PDF/Image)',
          value: _formData.aadharDocBack,
          error: _errors['aadharDocBack'],
          onChanged: (f) => setState(() {
            _formData.aadharDocBack = f;
            _errors.remove('aadharDocBack');
          }),
          onRemove: () => setState(() {
            _formData.aadharDocBack = null;
            _errors.remove('aadharDocBack');
          }),
        ),
        _LoanInputField(
          label: 'PAN Number',
          value: _formData.panNumber,
          placeholder: 'Enter PAN number',
          error: _errors['panNumber'],
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) => setState(() {
            _formData.panNumber = v;
            _errors.remove('panNumber');
          }),
        ),
        _FileUploadField(
          label: 'Upload PAN Card (PDF/Image)',
          value: _formData.panDoc,
          error: _errors['panDoc'],
          onChanged: (f) => setState(() {
            _formData.panDoc = f;
            _errors.remove('panDoc');
          }),
          onRemove: () => setState(() {
            _formData.panDoc = null;
            _errors.remove('panDoc');
          }),
        ),
      ],
    );
  }

  // ─── Step 2: Employment ───────────────────────────────────────────────────

  Widget _buildEmploymentStep() {
    return _FormSection(
      title: 'Employment Details',
      subtitle: 'Share your work information',
      icon: Icons.work_outline,
      children: [
        _SelectPopupField(
          label: 'Employment Type',
          value: _formData.employmentType,
          options: kEmploymentTypes,
          error: _errors['employmentType'],
          onChanged: (v) => setState(() {
            _formData.employmentType = v;
            _errors.remove('employmentType');
          }),
        ),
        _LoanInputField(
          label: 'Company Name',
          value: _formData.companyName,
          placeholder: 'Enter company name',
          error: _errors['companyName'],
          onChanged: (v) => setState(() {
            _formData.companyName = v;
            _errors.remove('companyName');
          }),
        ),
        _LoanInputField(
          label: 'Monthly Income',
          value: _formData.monthlyIncome,
          placeholder: 'Enter monthly income',
          error: _errors['monthlyIncome'],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefix: '₹',
          onChanged: (v) => setState(() {
            _formData.monthlyIncome = v;
            _errors.remove('monthlyIncome');
          }),
        ),
        _SelectPopupField(
          label: 'Work Experience',
          value: _formData.workExperience,
          options: kWorkExperienceOptions,
          error: _errors['workExperience'],
          onChanged: (v) => setState(() {
            _formData.workExperience = v;
            _errors.remove('workExperience');
          }),
        ),
      ],
    );
  }

  // ─── Step 3: Product ──────────────────────────────────────────────────────

  Widget _buildProductStep() {
    final shopOptions = _shops
        .map((s) => {
              'value': s.id,
              'label': '${s.shopName}, ${s.address}, ${s.city}',
            })
        .toList();

    return _FormSection(
      title: 'Product Details',
      subtitle: "What would you like to purchase?",
      icon: Icons.smartphone_outlined,
      children: [
        _LoanInputField(
          label: 'Brand',
          value: _formData.brand,
          placeholder: 'Enter brand name',
          error: _errors['brand'],
          onChanged: (v) => setState(() {
            _formData.brand = v;
            _errors.remove('brand');
          }),
        ),
        _LoanInputField(
          label: 'Model',
          value: _formData.model,
          placeholder: 'Enter model name',
          error: _errors['model'],
          onChanged: (v) => setState(() {
            _formData.model = v;
            _errors.remove('model');
          }),
        ),
        _LoanInputField(
          label: 'Product Price',
          value: _formData.productPrice,
          placeholder: 'Enter product price',
          error: _errors['productPrice'],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefix: '₹',
          onChanged: (v) => setState(() {
            _formData.productPrice = v;
            _errors.remove('productPrice');
          }),
        ),
        _LoanInputField(
          label: 'Down Payment',
          value: _formData.downPayment,
          placeholder: 'Enter down payment amount',
          error: _errors['downPayment'],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          prefix: '₹',
          onChanged: (v) => setState(() {
            _formData.downPayment = v;
            _errors.remove('downPayment');
          }),
        ),
        _SelectPopupField(
          label: 'Shop Name',
          value: _formData.shopName,
          options: shopOptions,
          error: _errors['shopName'],
          onChanged: (v) => setState(() {
            _formData.shopName = v;
            _errors.remove('shopName');
          }),
        ),
      ],
    );
  }

  // ─── Next / Submit Button ─────────────────────────────────────────────────

  Widget _buildNextButton() {
    final isLast = _currentStep == kSteps.length - 1;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border(top: BorderSide(color: kSlate200)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _loading ? null : _handleNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          child: _loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLast ? 'Submit Application' : 'Continue',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── OTP Verification Widget ──────────────────────────────────────────────────
/// Mirrors OTPVerification component

class _OtpVerificationWidget extends StatefulWidget {
  final String initialPhone;
  final void Function(String phone) onVerified;

  const _OtpVerificationWidget({
    Key? key,
    required this.initialPhone,
    required this.onVerified,
  }) : super(key: key);

  @override
  State<_OtpVerificationWidget> createState() => _OtpVerificationWidgetState();
}

class _OtpVerificationWidgetState extends State<_OtpVerificationWidget> {
  final _phoneController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _phoneSent = false;
  bool _loading = false;
  int _resendTimer = 30;
  bool _canResend = false;
  Timer? _timer;
  String? _phoneError;
  String? _otpError;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.initialPhone;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_resendTimer > 0) {
          _resendTimer--;
        } else {
          _canResend = true;
          t.cancel();
        }
      });
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() => _phoneError = 'Enter valid 10-digit phone number');
      return;
    }
    setState(() {
      _loading = true;
      _phoneError = null;
    });
    try {
      // Simulate OTP send — replace with real API call
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _phoneSent = true);
      _startResendTimer();
    } catch (e) {
      setState(() => _phoneError = 'Failed to send OTP');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
    setState(() => _otpError = null);
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length != 6) {
      setState(() => _otpError = 'Enter valid 6-digit OTP');
      return;
    }
    setState(() => _loading = true);
    try {
      // Simulate OTP verify — replace with real API
      await Future.delayed(const Duration(seconds: 1));
      widget.onVerified(_phoneController.text.trim());
    } catch (e) {
      setState(() => _otpError = 'Invalid OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phone Verification',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: kSlate900)),
          const SizedBox(height: 4),
          Text('Verify your phone number to continue',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 24),

          // Phone field
          _LoanInputField(
            label: 'Phone Number',
            value: _phoneController.text,
            placeholder: 'Enter your 10-digit phone number',
            error: _phoneError,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: !_phoneSent,
            onChanged: (v) {
              _phoneController.text = v;
              setState(() => _phoneError = null);
            },
          ),

          if (!_phoneSent) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Send OTP',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],

          if (_phoneSent) ...[
            const SizedBox(height: 20),
            const Text('Enter OTP',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kSlate700)),
            const SizedBox(height: 12),

            // 6-digit OTP inputs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 44,
                  height: 52,
                  child: TextField(
                    controller: _otpControllers[i],
                    focusNode: _otpFocusNodes[i],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _otpError != null ? kPrimary : kSlate200,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: kPrimary, width: 2),
                      ),
                    ),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    onChanged: (v) => _onOtpDigitChanged(i, v),
                  ),
                );
              }),
            ),

            if (_otpError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 14, color: kPrimary),
                    const SizedBox(width: 4),
                    Text(_otpError!,
                        style: const TextStyle(
                            fontSize: 12, color: kPrimary)),
                  ],
                ),
              ),

            // Resend
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _canResend
                  ? GestureDetector(
                      onTap: _sendOtp,
                      child: const Text('Resend OTP',
                          style: TextStyle(
                              fontSize: 13,
                              color: kBlue,
                              fontWeight: FontWeight.w500)),
                    )
                  : Text(
                      'Resend OTP in ${_resendTimer}s',
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade500),
                    ),
            ),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Verify OTP',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Form Section Wrapper ─────────────────────────────────────────────────────
/// Mirrors FormSection

class _FormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  const _FormSection({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: kSlate900)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const SizedBox(height: 20),
        ...children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: child,
            )),
      ],
    );
  }
}

// ─── Input Field ──────────────────────────────────────────────────────────────
/// Mirrors InputField / LoanInputField

class _LoanInputField extends StatelessWidget {
  final String label;
  final String value;
  final String placeholder;
  final String? error;
  final String? prefix;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final int maxLines;
  final bool enabled;
  final void Function(String) onChanged;

  const _LoanInputField({
    Key? key,
    required this.label,
    required this.value,
    this.placeholder = '',
    this.error,
    this.prefix,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength,
    this.maxLines = 1,
    this.enabled = true,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kSlate700)),
        const SizedBox(height: 6),
        TextFormField(
          initialValue: value,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          maxLength: maxLength,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixText: prefix,
            counterText: '',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: enabled ? Colors.white : kSlate100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: kSlate200, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: error != null ? kPrimary : kSlate200,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimary, width: 2),
            ),
          ),
          style: const TextStyle(fontSize: 14, color: kSlate900),
          onChanged: onChanged,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: kPrimary),
                const SizedBox(width: 4),
                Text(error!,
                    style: const TextStyle(fontSize: 12, color: kPrimary)),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Date Picker Field ────────────────────────────────────────────────────────

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final String? error;
  final void Function(String) onChanged;

  const _DatePickerField({
    Key? key,
    required this.label,
    required this.value,
    this.error,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kSlate700)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1940),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.light(primary: kPrimary),
                ),
                child: child!,
              ),
            );
            if (picked != null) {
              final formatted =
                  '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
              onChanged(formatted);
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: error != null ? kPrimary : kSlate200,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value.isEmpty ? 'Select date of birth' : value,
                  style: TextStyle(
                    fontSize: 14,
                    color: value.isEmpty
                        ? Colors.grey.shade400
                        : kSlate900,
                  ),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 18, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: kPrimary),
                const SizedBox(width: 4),
                Text(error!,
                    style: const TextStyle(fontSize: 12, color: kPrimary)),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Select Popup Field ───────────────────────────────────────────────────────
/// Mirrors SelectFieldPopup — bottom sheet picker

class _SelectPopupField extends StatelessWidget {
  final String label;
  final String value;
  final List<Map<String, String>> options;
  final String? error;
  final void Function(String) onChanged;

  const _SelectPopupField({
    Key? key,
    required this.label,
    required this.value,
    required this.options,
    this.error,
    required this.onChanged,
  }) : super(key: key);

  String get _displayLabel {
    if (value.isEmpty) return 'Select $label';
    final match = options.firstWhere(
      (o) => o['value'] == value,
      orElse: () => {'label': value},
    );
    return match['label'] ?? value;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kSlate700)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: error != null ? kPrimary : kSlate200,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _displayLabel,
                    style: TextStyle(
                      fontSize: 14,
                      color: value.isEmpty
                          ? Colors.grey.shade400
                          : kSlate900,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 20, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: kPrimary),
                const SizedBox(width: 4),
                Text(error!,
                    style: const TextStyle(fontSize: 12, color: kPrimary)),
              ],
            ),
          ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(100)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Select $label',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...options.map((opt) {
                  final isSelected = opt['value'] == value;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(opt['label'] ?? '',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected ? kPrimary : kSlate900)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: kPrimary, size: 20)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      onChanged(opt['value'] ?? '');
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── File Upload Field ────────────────────────────────────────────────────────
/// Mirrors FileUpload — tap to pick file, shows name, remove button

class _FileUploadField extends StatelessWidget {
  final String label;
  final File? value;
  final String? error;
  final void Function(File) onChanged;
  final VoidCallback onRemove;

  const _FileUploadField({
    Key? key,
    required this.label,
    this.value,
    this.error,
    required this.onChanged,
    required this.onRemove,
  }) : super(key: key);

  String get _fileName => value != null ? value!.path.split('/').last : '';

  Future<void> _pickFile(BuildContext context) async {
    // NOTE: In a real app integrate file_picker package:
    // final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf','jpg','jpeg','png']);
    // if (result != null) onChanged(File(result.files.single.path!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Integrate file_picker package to enable file selection'),
        backgroundColor: kPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kSlate700)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: value == null ? () => _pickFile(context) : null,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: error != null
                    ? kPrimary
                    : (value != null ? const Color(0xFF16A34A) : kSlate200),
                width: 2,
                style: value == null ? BorderStyle.solid : BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: value != null
                ? Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined,
                          size: 18, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fileName,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onRemove,
                        child: const Icon(Icons.close,
                            size: 18, color: kPrimary),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_outlined,
                          size: 20, color: Colors.grey.shade500),
                      const SizedBox(width: 8),
                      Text('Upload a file',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500)),
                    ],
                  ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('PNG, JPG, PDF up to 5MB',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 14, color: kPrimary),
                const SizedBox(width: 4),
                Text(error!,
                    style: const TextStyle(fontSize: 12, color: kPrimary)),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Success Screen ───────────────────────────────────────────────────────────
/// Mirrors SuccessScreen with 5-second auto-close

class _SuccessScreen extends StatefulWidget {
  final VoidCallback onClose;

  const _SuccessScreen({Key? key, required this.onClose}) : super(key: key);

  @override
  State<_SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<_SuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Mirror: setTimeout 5000ms then onClose
    _autoCloseTimer = Timer(const Duration(seconds: 5), widget.onClose);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF1F2), Colors.white, Color(0xFFEFF6FF)],
              ),
            ),
          ),
          // Decorative blobs
          Positioned(
            right: -80,
            top: 80,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFFFECACA).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -80,
            bottom: 100,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                color: const Color(0xFFBFDBFE).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Bouncing checkmark circle
                    AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _bounceAnimation.value),
                        child: child,
                      ),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Congratulations!',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: kSlate900),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your loan application form has been submitted successfully!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 15, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our executives will contact you soon.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 40),
                    // Auto-close indicator
                    Text(
                      'Redirecting you shortly...',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade400),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: widget.onClose,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                        decoration: BoxDecoration(
                          color: kPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Go to Home',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15),
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