import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
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

// ─── Color Palette ─────────────────────────────────────────────────────────────
// Matches React: red-600 (#DC2626), blue-600 (#2563EB), slate-* tokens
const Color kPrimary     = Color(0xFFDC2626); // red-600
const Color kPrimaryDark = Color(0xFFB91C1C); // red-700
const Color kBlue        = Color(0xFF2563EB); // blue-600
const Color kSurface     = Color(0xFFFFFFFF);
const Color kSlate900    = Color(0xFF0F172A);
const Color kSlate700    = Color(0xFF374151);
const Color kSlate600    = Color(0xFF475569);
const Color kSlate400    = Color(0xFF94A3B8);
const Color kSlate200    = Color(0xFFE2E8F0);
const Color kSlate100    = Color(0xFFF1F5F9);

// ─── Data Models ──────────────────────────────────────────────────────────────

class UserProfile {
  final String? id;
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? dob;
  final String? address;
  final String? gender;

  const UserProfile({
    this.id, this.name, this.email, this.phoneNumber,
    this.dob, this.address, this.gender,
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
  final List<String> categories;

  const ShopModel({
    required this.id, required this.shopName,
    required this.address, required this.city,
    this.categories = const [],
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    final rawCats = json['categories'];
    final List<String> cats = rawCats is List
        ? rawCats
            .map((c) => (c is Map ? c['name']?.toString() : c?.toString()) ?? '')
            .where((s) => s.isNotEmpty)
            .toList()
        : [];
    return ShopModel(
      id: json['id']?.toString() ?? '',
      shopName: json['shop_name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      categories: cats,
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
  String phoneNumber, otp, fullName, email, dob, address;
  String aadharNumber, panNumber;
  File? aadharDoc, aadharDocBack, panDoc;
  String employmentType, monthlyIncome, companyName, workExperience;
  String productType, shopName, brand, model, productPrice, downPayment, gender;

  LoanFormData({
    this.phoneNumber = '', this.otp = '', this.fullName = '', this.email = '',
    this.dob = '', this.address = '', this.aadharNumber = '', this.panNumber = '',
    this.aadharDoc, this.aadharDocBack, this.panDoc,
    this.employmentType = '', this.monthlyIncome = '', this.companyName = '',
    this.workExperience = '', this.productType = '', this.shopName = '',
    this.brand = '', this.model = '', this.productPrice = '',
    this.downPayment = '', this.gender = '',
  });
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class MobileLoanFormScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final ServiceDetails? serviceDetails;

  const MobileLoanFormScreen({Key? key, this.userProfile, this.serviceDetails}) : super(key: key);

  @override
  State<MobileLoanFormScreen> createState() => _MobileLoanFormScreenState();
}

class _MobileLoanFormScreenState extends State<MobileLoanFormScreen>
    with SingleTickerProviderStateMixin {
  bool _isPhoneVerified = false;
  int _currentStep = 0;
  bool _loading = false;
  bool _isSubmitted = false;

  final Map<String, String> _errors = {};
  List<ShopModel> _shops = [];
  List<CategoryModel> _categories = [];

  late LoanFormData _formData;

  int _carouselIndex = 0;
  Timer? _carouselTimer;

  // late AnimationController _blobController;

  final List<Map<String, String>> _slides = const [
    {'title': 'Quick Approval', 'image': 'assets/images/m1.png'},
    {'title': 'Flexible EMIs',  'image': 'assets/images/m2.png'},
    {'title': 'Low Interest Rates', 'image': 'assets/images/m3.png'},
  ];

  @override
  void initState() {
    super.initState();
    _formData = LoanFormData(
      phoneNumber: widget.userProfile?.phoneNumber ?? '',
      fullName:    widget.userProfile?.name ?? '',
      email:       widget.userProfile?.email ?? '',
      dob:         widget.userProfile?.dob ?? '',
      address:     widget.userProfile?.address ?? '',
      gender:      widget.userProfile?.gender ?? '',
      productType: widget.serviceDetails?.psLcategory ?? '',
    );

    // _blobController = AnimationController(
    //   vsync: this, duration: const Duration(seconds: 20),
    // )..repeat();

    _startCarousel();
    _fetchInitialData();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    // _blobController.dispose();
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
      final body = jsonDecode(res.body) as List<dynamic>;
      setState(() => _categories = body
          .map((e) => CategoryModel.fromJson(e as Map<String, dynamic>))
          .toList());
    } catch (e) { debugPrint('Categories error: $e'); }
  }

  Future<void> _fetchShops() async {
    try {
      final res = await http.get(Uri.parse('${ApiConstants.adminBaseUrl}/shops.php'));
      final body = jsonDecode(res.body);
      final allShops = (body['list'] as List<dynamic>)
          .map((e) => ShopModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final category = widget.serviceDetails?.psLcategory;
      setState(() {
        _shops = category != null
            ? allShops.where((s) => s.categories.any((c) => c == category)).toList()
            : allShops;
      });
    } catch (e) { debugPrint('Shops error: $e'); }
  }

  // ─── Validation ───────────────────────────────────────────────────────────

  bool _validateStep() {
    final errors = <String, String>{};
    switch (_currentStep) {
      case 0:
        if (_formData.fullName.trim().isEmpty) errors['fullName'] = 'Full name is required';
        if (_formData.email.trim().isEmpty) {
          errors['email'] = 'Email is required';
        } else if (!RegExp(r'\S+@\S+\.\S+').hasMatch(_formData.email)) {
          errors['email'] = 'Enter valid email';
        }
        if (_formData.dob.isEmpty)     errors['dob']     = 'Date of birth is required';
        if (_formData.gender.isEmpty)  errors['gender']  = 'Gender is required';
        if (_formData.address.trim().isEmpty) errors['address'] = 'Address is required';
        break;
      case 1:
        if (_formData.aadharNumber.isEmpty) {
          errors['aadharNumber'] = 'Aadhar number is required';
        } else if (!RegExp(r'^\d{12}$').hasMatch(_formData.aadharNumber)) {
          errors['aadharNumber'] = 'Enter valid 12-digit Aadhar number';
        }
        if (_formData.aadharDoc == null) {
          errors['aadharDoc'] = 'Aadhar Front Side document is required';
        } else if (_formData.aadharDoc!.lengthSync() > 5 * 1024 * 1024) {
          errors['aadharDoc'] = 'Aadhar Front Side document must be less than 5MB';
        }
        if (_formData.aadharDocBack == null) {
          errors['aadharDocBack'] = 'Aadhar Back Side document is required';
        } else if (_formData.aadharDocBack!.lengthSync() > 5 * 1024 * 1024) {
          errors['aadharDocBack'] = 'Aadhar Back Side document must be less than 5MB';
        }
        break;
      case 2:
        if (_formData.employmentType.isEmpty) errors['employmentType'] = 'Employment type is required';
        if (_formData.companyName.trim().isEmpty) errors['companyName'] = 'Company name is required';
        if (_formData.monthlyIncome.isEmpty) {
          errors['monthlyIncome'] = 'Monthly income is required';
        } else if ((double.tryParse(_formData.monthlyIncome) ?? 0) < 10000) {
          errors['monthlyIncome'] = 'Monthly income must be at least ₹10,000';
        }
        if (_formData.workExperience.isEmpty) errors['workExperience'] = 'Work experience is required';
        break;
      case 3:
        if (_formData.brand.trim().isEmpty)  errors['brand']  = 'Brand is required';
        if (_formData.model.trim().isEmpty)  errors['model']  = 'Model is required';
        if (_formData.shopName.isEmpty)      errors['shopName'] = 'Shop name is required';
        if (_formData.productPrice.isEmpty) {
          errors['productPrice'] = 'Product price is required';
        } else if ((double.tryParse(_formData.productPrice) ?? 0) < 1000) {
          errors['productPrice'] = 'Product price must be at least ₹1,000';
        }
        final dp = double.tryParse(_formData.downPayment) ?? 0;
        final pp = double.tryParse(_formData.productPrice) ?? 0;
        if (dp < 0) {
          errors['downPayment'] = 'DownPayment amount cannot be negative';
        } else if (_formData.downPayment.isEmpty || dp > 0) {
          if (dp > pp) errors['downPayment'] = 'DownPayment amount cannot be more than product price';
        }
        break;
    }
    setState(() => _errors..clear()..addAll(errors));
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
        setState(() => _currentStep++);
      }
    } catch (e) {
      setState(() => _errors['submit'] = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitForm() async {
    final request = http.MultipartRequest(
      'POST', Uri.parse('${ApiConstants.adminBaseUrl}/submit_loan.php'),
    );
    request.fields.addAll({
      'phoneNumber': _formData.phoneNumber, 'fullName': _formData.fullName,
      'email': _formData.email, 'dob': _formData.dob,
      'address': _formData.address, 'aadharNumber': _formData.aadharNumber,
      'panNumber': _formData.panNumber, 'employmentType': _formData.employmentType,
      'monthlyIncome': _formData.monthlyIncome, 'companyName': _formData.companyName,
      'workExperience': _formData.workExperience, 'productType': _formData.productType,
      'shopName': _formData.shopName, 'brand': _formData.brand,
      'model': _formData.model, 'productPrice': _formData.productPrice,
      'downPayment': _formData.downPayment, 'gender': _formData.gender,
    });
    if (_formData.aadharDoc != null)
      request.files.add(await http.MultipartFile.fromPath('aadharDoc', _formData.aadharDoc!.path));
    if (_formData.aadharDocBack != null)
      request.files.add(await http.MultipartFile.fromPath('aadharDocBack', _formData.aadharDocBack!.path));
    if (_formData.panDoc != null)
      request.files.add(await http.MultipartFile.fromPath('panDoc', _formData.panDoc!.path));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body);

    if (body['success'] == true) {
      await http.post(
        Uri.parse('${ApiConstants.adminBaseUrl}/notifications.php'),
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
      setState(() => _currentStep--);
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
          // React: bg-gradient-to-b from-red-50 via-white to-blue-50
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
          // React: bg-[linear-gradient(rgba(0,0,0,0.02)_1px,...)] bg-[size:32px_32px]
          CustomPaint(painter: _GridPainter(), child: const SizedBox.expand()),
          // // React: -right-40 top-20 w-96 h-96 bg-red-100 ... animate-blob
          // AnimatedBuilder(
          //   animation: _blobController,
          //   builder: (_, __) {
          //     final t = _blobController.value * 2 * 3.14159;
          //     final dx = 20 * (0.5 - 0.5 * (t * 0.7).clamp(-1.0, 1.0));
          //     final dy = -50 * (0.5 - 0.5 * (t * 0.5).clamp(-1.0, 1.0));
          //     final scale = 1.0 + 0.1 * (0.5 - 0.5 * (t * 0.3).clamp(-1.0, 1.0));
          //     return Positioned(
          //       right: -160 + dx, top: 80 + dy,
          //       child: Transform.scale(scale: scale,
          //         child: Container(width: 384, height: 384,
          //           decoration: BoxDecoration(
          //             color: const Color(0xFFFEE2E2).withOpacity(0.3), // red-100
          //             shape: BoxShape.circle,
          //           ),
          //         ),
          //       ),
          //     );
          //   },
          // ),
          // // React: -left-40 bottom-20 w-96 h-96 bg-blue-100 ... animation-delay-2000
          // AnimatedBuilder(
          //   animation: _blobController,
          //   builder: (_, __) {
          //     final t = _blobController.value * 2 * 3.14159 + 2.0;
          //     final dx = -20 * (0.5 - 0.5 * (t * 0.7).clamp(-1.0, 1.0));
          //     final dy = 50 * (0.5 - 0.5 * (t * 0.5).clamp(-1.0, 1.0));
          //     final scale = 0.9 + 0.1 * (0.5 - 0.5 * (t * 0.3).clamp(-1.0, 1.0));
          //     return Positioned(
          //       left: -160 + dx, bottom: 80 + dy,
          //       child: Transform.scale(scale: scale,
          //         child: Container(width: 384, height: 384,
          //           decoration: BoxDecoration(
          //             color: const Color(0xFFDBEAFE).withOpacity(0.3), // blue-100
          //             shape: BoxShape.circle,
          //           ),
          //         ),
          //       ),
          //     );
          //   },
          // ),
          // Main content column
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                // React: StepIndicator only shown when isPhoneVerified
                if (_isPhoneVerified) _buildStepIndicator(),
                Expanded(
                  child: _isPhoneVerified
                      ? _buildFormBody()
                      : _buildOtpBody(),
                ),
                // React: NextButton only shown when isPhoneVerified
                if (_isPhoneVerified) _buildNextButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────
  // React: sticky top-0 bg-white/80 backdrop-blur border-b border-slate-200
  // Row: Back button | service title | HelpCircle icon

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: kSlate200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // React: ArrowLeft + "Back" text, onClick = handleBack
          GestureDetector(
            onTap: _isPhoneVerified ? _handleBack : () => Navigator.of(context).pop(),
            child: Row(
              children: [
                const Icon(Icons.arrow_back_ios_new, size: 16, color: kSlate600),
                const SizedBox(width: 4),
                Text('Back',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: kSlate600)),
              ],
            ),
          ),
          // React: serviceDetails?.pstitle || 'Loan Service'
          Text(
            widget.serviceDetails?.psTitle ?? 'Loan Service',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: kSlate900),
          ),
          // React: HelpCircle icon button
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.help_outline, color: Colors.grey.shade600, size: 24),
          ),
        ],
      ),
    );
  }

  // ─── Step Indicator ───────────────────────────────────────────────────────
  // React: StepIndicator component — "Step X of Y" | "Z%" | progress bar
  // Progress bar: bg-gradient-to-r from-red-600 to-red-600

  Widget _buildStepIndicator() {
    final progress = (_currentStep + 1) / kSteps.length;
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: Colors.white.withOpacity(0.8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Step ${_currentStep + 1}',
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500, color: kSlate700),
                  ),
                  Text(
                    ' of ${kSteps.length}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500, color: kBlue),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // React: h-2 bg-gray-200 rounded-full overflow-hidden + inner div bg-gradient red-600
          ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(kPrimary),
            ),
          ),
        ],
      ),
    );
  }

  // ─── OTP Body ─────────────────────────────────────────────────────────────
  // React: Swiper carousel (top) + OTPVerification component (bottom)

  Widget _buildOtpBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCarousel(),
          _OtpVerificationWidget(
            initialPhone: _formData.phoneNumber,
            onVerified: (phone) {
              _carouselTimer?.cancel();
              setState(() {
                _isPhoneVerified = true;
                _formData.phoneNumber = phone;
              });
            },
          ),
        ],
      ),
    );
  }

  // React: Swiper with title above image, no description, dot pagination
  Widget _buildCarousel() {
    final slide = _slides[_carouselIndex];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Column(
          key: ValueKey(_carouselIndex),
          children: [
            // React: text-xl font-bold text-slate-900
            Text(
              slide['title']!,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: kSlate900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // React: aspect-[16/9] w-full h-full object-contain
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(slide['image']!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            // React: Swiper pagination dots
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
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── Form Body ────────────────────────────────────────────────────────────
  // React: <main className="flex-1 overflow-y-auto"> + w-full max-w-sm mx-auto px-4 py-8

  Widget _buildFormBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: _buildStepContent(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildPersonalStep();
      case 1: return _buildDocumentsStep();
      case 2: return _buildEmploymentStep();
      case 3: return _buildProductStep();
      default: return const SizedBox.shrink();
    }
  }

  // ─── Step 0: Personal ────────────────────────────────────────────────────

  Widget _buildPersonalStep() {
    return _FormSection(
      title: 'Personal Details of Applicant',
      subtitle: 'Kindly enter your personal information below',
      children: [
        _LoanInputField(
          label: 'Full Name',
          initialValue: _formData.fullName,
          placeholder: 'Enter your full name',
          error: _errors['fullName'],
          onChanged: (v) => setState(() { _formData.fullName = v; _errors.remove('fullName'); }),
        ),
        _LoanInputField(
          label: 'Email',
          initialValue: _formData.email,
          placeholder: 'Enter your email',
          error: _errors['email'],
          keyboardType: TextInputType.emailAddress,
          onChanged: (v) => setState(() { _formData.email = v; _errors.remove('email'); }),
        ),
        _DatePickerField(
          label: 'Date of Birth',
          value: _formData.dob,
          error: _errors['dob'],
          onChanged: (v) => setState(() { _formData.dob = v; _errors.remove('dob'); }),
        ),
        _SelectPopupField(
          label: 'Gender',
          value: _formData.gender,
          options: kGenderOptions,
          error: _errors['gender'],
          onChanged: (v) => setState(() { _formData.gender = v; _errors.remove('gender'); }),
        ),
        _LoanInputField(
          label: 'Address',
          initialValue: _formData.address,
          placeholder: 'Enter your address',
          error: _errors['address'],
          maxLines: 2,
          onChanged: (v) => setState(() { _formData.address = v; _errors.remove('address'); }),
        ),
      ],
    );
  }

  // ─── Step 1: Documents ────────────────────────────────────────────────────

  Widget _buildDocumentsStep() {
    return _FormSection(
      title: 'Documents',
      subtitle: 'Upload your identity documents',
      children: [
        _LoanInputField(
          label: 'Aadhar Number',
          initialValue: _formData.aadharNumber,
          placeholder: 'Enter 12-digit Aadhar number',
          error: _errors['aadharNumber'],
          keyboardType: TextInputType.number,
          maxLength: 12,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => setState(() { _formData.aadharNumber = v; _errors.remove('aadharNumber'); }),
        ),
        _FileUploadField(
          label: 'Upload Front Aadhar Card (PDF/Image)',
          value: _formData.aadharDoc,
          error: _errors['aadharDoc'],
          onChanged: (f) => setState(() { _formData.aadharDoc = f; _errors.remove('aadharDoc'); }),
          onRemove: () => setState(() { _formData.aadharDoc = null; _errors.remove('aadharDoc'); }),
        ),
        _FileUploadField(
          label: 'Upload Back Aadhar Card (PDF/Image)',
          value: _formData.aadharDocBack,
          error: _errors['aadharDocBack'],
          onChanged: (f) => setState(() { _formData.aadharDocBack = f; _errors.remove('aadharDocBack'); }),
          onRemove: () => setState(() { _formData.aadharDocBack = null; _errors.remove('aadharDocBack'); }),
        ),
        _LoanInputField(
          label: 'PAN Number',
          initialValue: _formData.panNumber,
          placeholder: 'Enter PAN number',
          error: _errors['panNumber'],
          textCapitalization: TextCapitalization.characters,
          onChanged: (v) => setState(() { _formData.panNumber = v; _errors.remove('panNumber'); }),
        ),
        _FileUploadField(
          label: 'Upload PAN Card (PDF/Image)',
          value: _formData.panDoc,
          error: _errors['panDoc'],
          onChanged: (f) => setState(() { _formData.panDoc = f; _errors.remove('panDoc'); }),
          onRemove: () => setState(() { _formData.panDoc = null; _errors.remove('panDoc'); }),
        ),
      ],
    );
  }

  // ─── Step 2: Employment ───────────────────────────────────────────────────

  Widget _buildEmploymentStep() {
    return _FormSection(
      title: 'Employment Details',
      subtitle: 'Share your work information',
      children: [
        _SelectPopupField(
          label: 'Employment Type',
          value: _formData.employmentType,
          options: kEmploymentTypes,
          error: _errors['employmentType'],
          onChanged: (v) => setState(() { _formData.employmentType = v; _errors.remove('employmentType'); }),
        ),
        _LoanInputField(
          label: 'Company Name',
          initialValue: _formData.companyName,
          placeholder: 'Enter company name',
          error: _errors['companyName'],
          onChanged: (v) => setState(() { _formData.companyName = v; _errors.remove('companyName'); }),
        ),
        _LoanInputField(
          label: 'Monthly Income',
          initialValue: _formData.monthlyIncome,
          placeholder: 'Enter monthly income',
          error: _errors['monthlyIncome'],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => setState(() { _formData.monthlyIncome = v; _errors.remove('monthlyIncome'); }),
        ),
        _SelectPopupField(
          label: 'Work Experience',
          value: _formData.workExperience,
          options: kWorkExperienceOptions,
          error: _errors['workExperience'],
          onChanged: (v) => setState(() { _formData.workExperience = v; _errors.remove('workExperience'); }),
        ),
      ],
    );
  }

  // ─── Step 3: Product ──────────────────────────────────────────────────────

  Widget _buildProductStep() {
    final shopOptions = _shops
        .map((s) => {'value': s.id, 'label': '${s.shopName}, ${s.address}, ${s.city}'})
        .toList();
    return _FormSection(
      title: 'Product Details',
      subtitle: 'What would you like to purchase?',
      children: [
        _LoanInputField(
          label: 'Brand',
          initialValue: _formData.brand,
          placeholder: 'Enter brand name',
          error: _errors['brand'],
          onChanged: (v) => setState(() { _formData.brand = v; _errors.remove('brand'); }),
        ),
        _LoanInputField(
          label: 'Model',
          initialValue: _formData.model,
          placeholder: 'Enter model name',
          error: _errors['model'],
          onChanged: (v) => setState(() { _formData.model = v; _errors.remove('model'); }),
        ),
        _LoanInputField(
          label: 'Product Price',
          initialValue: _formData.productPrice,
          placeholder: 'Enter product price',
          error: _errors['productPrice'],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => setState(() { _formData.productPrice = v; _errors.remove('productPrice'); }),
        ),
        _LoanInputField(
          label: 'Down Payment',
          initialValue: _formData.downPayment,
          placeholder: 'Enter down payment amount',
          error: _errors['downPayment'],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: (v) => setState(() { _formData.downPayment = v; _errors.remove('downPayment'); }),
        ),
        _SelectPopupField(
          label: 'Shop Name',
          value: _formData.shopName,
          options: shopOptions,
          error: _errors['shopName'],
          onChanged: (v) => setState(() { _formData.shopName = v; _errors.remove('shopName'); }),
        ),
      ],
    );
  }

  // ─── Next / Submit Button ─────────────────────────────────────────────────
  // React: NextButton — relative w-full group + absolute gradient blur layer
  //        + inner bg-red-600 py-4 rounded-xl flex items-center justify-center
  //        Shows Loader2 + "Processing..." when loading
  //        Shows text + ArrowLeft rotate-180 when idle

  Widget _buildNextButton() {
    final isLast = _currentStep == kSteps.length - 1;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(top: BorderSide(color: kSlate200)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: SizedBox(
        width: double.infinity,
        child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _loading ? null : _handleNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        ),
                        SizedBox(width: 8),
                        Text('Processing...',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                      ],
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
                        // React: ArrowLeft rotate-180 = ArrowRight / forward
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
          ),
      ),
    );
  }
}

// ─── OTP Verification Widget ──────────────────────────────────────────────────
// Mirrors React OTPVerification component UI exactly

class _OtpVerificationWidget extends StatefulWidget {
  final String initialPhone;
  final void Function(String phone) onVerified;

  const _OtpVerificationWidget({
    Key? key, required this.initialPhone, required this.onVerified,
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
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() { _resendTimer = 30; _canResend = false; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_resendTimer > 0) { _resendTimer--; }
        else { _canResend = true; t.cancel(); }
      });
    });
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      setState(() => _phoneError = 'Enter valid 10-digit phone number');
      return;
    }
    setState(() { _loading = true; _phoneError = null; });
    try {
      final res = await ApiService.sendOtp(phone);
      debugPrint('═══════════════════════════════');
      debugPrint('OTP SEND RESPONSE: $res');
      if (res['otp'] != null) debugPrint('OTP: ${res["otp"]}');
      debugPrint('═══════════════════════════════');
      if (res['success'] == true || res['status'] == 'success') {
        debugPrint('OTP sent successfully to: $phone');
        setState(() => _phoneSent = true);
        _startResendTimer();
      } else {
        setState(() => _phoneError = res['message']?.toString() ?? 'Failed to send OTP');
      }
    } catch (e) {
      debugPrint('sendOtp error: $e');
      setState(() => _phoneError = 'Failed to send OTP');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) _otpFocusNodes[index + 1].requestFocus();
    if (value.isEmpty && index > 0)    _otpFocusNodes[index - 1].requestFocus();
    final current = _otpControllers.map((c) => c.text).join();
    debugPrint('OTP box[$index] = "$value" | current: "$current"');
    setState(() => _otpError = null);
  }

  Future<void> _verifyOtp() async {
    final otp = _otpControllers.map((c) => c.text).join();
    debugPrint('═══════════════════════════════');
    debugPrint('DEBUG OTP ENTERED: "$otp"');
    debugPrint('OTP LENGTH: ${otp.length}');
    debugPrint('═══════════════════════════════');
    if (otp.length != 6) {
      setState(() => _otpError = 'Enter valid 6-digit OTP');
      return;
    }
    setState(() => _loading = true);
    try {
      final phone = _phoneController.text.trim();
      final res = await ApiService.verifyOtp(phone, otp);
      if (res['success'] == true || res['status'] == 'success') {
        widget.onVerified(phone);
      } else {
        setState(() => _otpError = res['message']?.toString() ?? 'Invalid OTP. Please try again.');
      }
    } catch (e) {
      setState(() => _otpError = 'Invalid OTP. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // React OTPVerification: space-y-6, "Phone Verification" title, subtitle
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Phone Verification',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kSlate900)),
          const SizedBox(height: 4),
          Text('Verify your phone number to continue',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 24),

          // Phone input — reuses _LoanInputField style (border-2 rounded-xl focus:border-red-500)
          _ControlledInputField(
            label: 'Phone Number',
            controller: _phoneController,
            placeholder: 'Enter your 10-digit phone number',
            error: _phoneError,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: !_phoneSent,
            onChanged: (_) => setState(() => _phoneError = null),
          ),

          if (!_phoneSent) ...[
            const SizedBox(height: 16),
            // React: red-600 bg button, full width
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
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Send OTP',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],

          if (_phoneSent) ...[
            const SizedBox(height: 20),
            const Text('Enter OTP',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kSlate700)),
            const SizedBox(height: 12),
            // React: 6 inputs, flex gap-2, w-12 h-12, border-2 rounded-xl
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 44, height: 52,
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
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: _otpError != null ? kPrimary : kSlate200,
                          width: 2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: kPrimary, width: 2),
                      ),
                    ),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    onChanged: (v) => _onOtpDigitChanged(i, v),
                  ),
                );
              }),
            ),
            // React: AlertCircle error message
            if (_otpError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: kPrimary),
                    const SizedBox(width: 4),
                    Text(_otpError!,
                        style: const TextStyle(fontSize: 13, color: kPrimary)),
                  ],
                ),
              ),
            // React: "Resend OTP in Xs" / "Resend OTP" link
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: _canResend
                  ? GestureDetector(
                      onTap: _sendOtp,
                      child: const Text('Resend OTP',
                          style: TextStyle(fontSize: 13, color: kBlue,
                              fontWeight: FontWeight.w500)),
                    )
                  : Text('Resend OTP in ${_resendTimer}s',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
            ),
            // React: red-600 "Verify OTP" button
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
                    ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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

// ─── Form Section ─────────────────────────────────────────────────────────────
// React: FormSection — space-y-6, title (text-lg font-semibold text-slate-900),
//        subtitle (text-sm text-slate-600), then children in space-y-4

class _FormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _FormSection({
    Key? key, required this.title, required this.subtitle, required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // React: space-y-3 with space-y-1 inner
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: kSlate900)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 24),
        // React: space-y-4 wrapping children
        ...children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: child,
            )),
      ],
    );
  }
}

// ─── React Input Field ────────────────────────────────────────────────────────
// React InputField:
//   label: text-sm font-medium text-slate-700
//   input: w-full px-4 py-3 bg-white border-2 rounded-xl
//          focus:border-red-500 focus:ring-4 focus:ring-red-100
//          error → border-red-500 ring-4 ring-red-100
//          normal → border-slate-200
//   error row: AlertCircle w-4 h-4 + text-sm text-red-500

class _LoanInputField extends StatelessWidget {
  final String label;
  final String initialValue;
  final String placeholder;
  final String? error;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final int maxLines;
  final bool enabled;
  final void Function(String) onChanged;

  const _LoanInputField({
    Key? key, required this.label, required this.initialValue,
    this.placeholder = '', this.error, this.keyboardType, this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.maxLength, this.maxLines = 1, this.enabled = true,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // React: text-sm font-medium text-slate-700
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: kSlate700)),
        const SizedBox(height: 8),
        // React: relative div with gradient blur layer behind input
        Stack(
          children: [
            // React: absolute inset-0 bg-gradient-to-r from-red-500 to-blue-500 rounded-xl blur opacity-10
            if (!hasError)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFF3B82F6)],
                    ),
                  ),
                  margin: const EdgeInsets.all(0),
                  // blur approximation via opacity
                ),
              ),
            TextFormField(
              initialValue: initialValue,
              enabled: enabled,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              textCapitalization: textCapitalization,
              maxLength: maxLength,
              maxLines: maxLines,
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                counterText: '',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                filled: true,
                fillColor: enabled ? Colors.white : kSlate100,
                // React: border-2 rounded-xl, error → border-red-500, normal → border-slate-200
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: hasError ? kPrimary : kSlate200, width: 2,
                  ),
                ),
                // React: focus:border-red-500 focus:ring-4 focus:ring-red-100
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kPrimary, width: 2),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kSlate200, width: 2),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: kSlate200, width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 14, color: kSlate900),
              onChanged: onChanged,
            ),
          ],
        ),
        // React: AlertCircle + text-sm text-red-500
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: kPrimary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(error!,
                      style: const TextStyle(fontSize: 13, color: kPrimary)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── React Controlled Input Field ─────────────────────────────────────────────
// Same styling as _LoanInputField but accepts a TextEditingController

class _ControlledInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final String? error;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool enabled;
  final void Function(String) onChanged;

  const _ControlledInputField({
    Key? key, required this.label, required this.controller,
    this.placeholder = '', this.error, this.keyboardType, this.inputFormatters,
    this.maxLength, this.enabled = true, required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: kSlate700)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            counterText: '',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: enabled ? Colors.white : kSlate100,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? kPrimary : kSlate200, width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kPrimary, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kSlate200, width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kSlate200, width: 2),
            ),
          ),
          style: const TextStyle(fontSize: 14, color: kSlate900),
          onChanged: onChanged,
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: kPrimary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(error!,
                      style: const TextStyle(fontSize: 13, color: kPrimary)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── React Date Field ─────────────────────────────────────────────────────────
// React: InputField type="date" — same styling as InputField, tapping opens date picker

class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final String? error;
  final void Function(String) onChanged;

  const _DatePickerField({
    Key? key, required this.label, required this.value,
    this.error, required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: kSlate700)),
        const SizedBox(height: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: hasError ? kPrimary : kSlate200, width: 2,
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
                    color: value.isEmpty ? Colors.grey.shade400 : kSlate900,
                  ),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 18, color: Colors.grey.shade500),
              ],
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: kPrimary),
                const SizedBox(width: 4),
                Text(error!,
                    style: const TextStyle(fontSize: 13, color: kPrimary)),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── React Select Field ───────────────────────────────────────────────────────
// React: SelectFieldPopup — same border-2 rounded-xl styling as InputField
// Tapping opens a bottom sheet modal (React's popup → Flutter bottom sheet)
// React bottom sheet: bg-white w-full rounded-t-3xl p-6 animate-slideUp
//   w-12 h-1 bg-gray-300 drag handle
//   "Select {label}" title
//   each option: w-full p-4 text-left rounded-xl hover:bg-gray-50

class _SelectPopupField extends StatelessWidget {
  final String label;
  final String value;
  final List<Map<String, String>> options;
  final String? error;
  final void Function(String) onChanged;

  const _SelectPopupField({
    Key? key, required this.label, required this.value,
    required this.options, this.error, required this.onChanged,
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
    final hasError = error != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: kSlate700)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showPicker(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: hasError ? kPrimary : kSlate200, width: 2,
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
                      color: value.isEmpty ? Colors.grey.shade400 : kSlate900,
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
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: kPrimary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(error!,
                      style: const TextStyle(fontSize: 13, color: kPrimary)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _showPicker(BuildContext context) {
    // React: fixed bottom-0 bg-black/50 z-50 + bg-white w-full rounded-t-3xl p-6
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // React: w-12 h-1 bg-gray-300 rounded-full mx-auto mb-6
                Center(
                  child: Container(
                    width: 48, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(100)),
                  ),
                ),
                const SizedBox(height: 16),
                // React: text-lg font-semibold
                Text('Select $label',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600, color: kSlate900)),
                const SizedBox(height: 12),
                // React: space-y-2 options
                ...options.map((opt) {
                  final isSelected = opt['value'] == value;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      onChanged(opt['value'] ?? '');
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      // React: hover:bg-gray-50 rounded-xl
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFEF2F2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(opt['label'] ?? '',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected ? kPrimary : kSlate900)),
                          if (isSelected)
                            const Icon(Icons.check_circle,
                                color: kPrimary, size: 20),
                        ],
                      ),
                    ),
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

// ─── React File Upload ────────────────────────────────────────────────────────
// React FileUpload component:
//   border-2 border-dashed when no file, border-slate-200 / border-red-500
//   icon (Upload) + "Upload a file" text + "or drag and drop" + "PNG, JPG, PDF up to 5MB"
//   When file selected: file icon + file name + remove button

class _FileUploadField extends StatelessWidget {
  final String label;
  final File? value;
  final String? error;
  final void Function(File) onChanged;
  final VoidCallback onRemove;

  const _FileUploadField({
    Key? key, required this.label, this.value, this.error,
    required this.onChanged, required this.onRemove,
  }) : super(key: key);

  String get _fileName => value != null ? value!.path.split('/').last : '';

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result != null && result.files.single.path != null) {
        onChanged(File(result.files.single.path!));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick file: $e'), backgroundColor: kPrimary),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = error != null;
    final hasFile = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: kSlate700)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: !hasFile ? () => _pickFile(context) : null,
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              // React: border-2 border-dashed when no file
              border: Border.all(
                color: hasError
                    ? kPrimary
                    : (hasFile ? const Color(0xFF16A34A) : kSlate200),
                width: 2,
                // dashed style approximated — Flutter doesn't natively support dashed border
                // Use a CustomPaint wrapper for full dashed effect if needed
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: hasFile
                // React: file selected state — icon + name + remove
                ? Row(
                    children: [
                      const Icon(Icons.insert_drive_file_outlined,
                          size: 20, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fileName,
                          style: const TextStyle(
                              fontSize: 13, color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: onRemove,
                        child: const Icon(Icons.close, size: 18, color: kPrimary),
                      ),
                    ],
                  )
                // React: upload state — SVG cloud icon + "Upload a file" + "or drag and drop"
                : Column(
                    children: [
                      // React: SVG path icon (cloud upload) — approximated with Icon
                      Icon(Icons.cloud_upload_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      // React: "Upload a file" (blue link) + " or drag and drop"
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Upload a file',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: kBlue,
                                  fontWeight: FontWeight.w500),
                            ),
                            TextSpan(
                              text: ' or drag and drop',
                              style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      // React: "PNG, JPG, PDF up to 10MB" (React says 10MB, Flutter validation is 5MB)
                      Text('PNG, JPG, PDF up to 5MB',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                const Icon(Icons.error_outline, size: 16, color: kPrimary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(error!,
                      style: const TextStyle(fontSize: 13, color: kPrimary)),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Success Screen ───────────────────────────────────────────────────────────
// React SuccessScreen:
//   bg-gradient-to-b from-red-50 to-blue-50 + grid + blobs
//   green-500 w-20 h-20 rounded-full mx-auto mb-6 animate-bounce + Check icon
//   "Congratulations!" text-3xl font-bold
//   "Your loan application form has been submitted successfully!"
//   "our executives will contact you soon."
//   Auto-closes after 5 seconds

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
  // late AnimationController _blobController;
  Timer? _autoCloseTimer;

  @override
  void initState() {
    super.initState();
    // React: animate-bounce
    _bounceController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
    // _blobController = AnimationController(
    //   vsync: this, duration: const Duration(seconds: 20),
    // )..repeat();
    // React: auto-close after 5 seconds
    _autoCloseTimer = Timer(const Duration(seconds: 5), widget.onClose);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    // _blobController.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // React: bg-gradient-to-b from-red-50 to-blue-50
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF1F2), Color(0xFFEFF6FF)],
              ),
            ),
          ),
          CustomPaint(painter: _GridPainter(), child: const SizedBox.expand()),
          // Blobs
          // AnimatedBuilder(
          //   animation: _blobController,
          //   builder: (_, __) {
          //     final t = _blobController.value * 2 * 3.14159;
          //     return Positioned(
          //       right: -160 + 20 * (0.5 - 0.5 * (t * 0.7).clamp(-1.0, 1.0)),
          //       top:   80  - 50 * (0.5 - 0.5 * (t * 0.5).clamp(-1.0, 1.0)),
          //       child: Container(width: 384, height: 384,
          //         decoration: BoxDecoration(
          //           color: const Color(0xFFFEE2E2).withOpacity(0.3),
          //           shape: BoxShape.circle,
          //         ),
          //       ),
          //     );
          //   },
          // ),
          // AnimatedBuilder(
          //   animation: _blobController,
          //   builder: (_, __) {
          //     final t = _blobController.value * 2 * 3.14159 + 2.0;
          //     return Positioned(
          //       left:   -160 - 20 * (0.5 - 0.5 * (t * 0.7).clamp(-1.0, 1.0)),
          //       bottom: 80  + 50 * (0.5 - 0.5 * (t * 0.5).clamp(-1.0, 1.0)),
          //       child: Container(width: 384, height: 384,
          //         decoration: BoxDecoration(
          //           color: const Color(0xFFDBEAFE).withOpacity(0.3),
          //           shape: BoxShape.circle,
          //         ),
          //       ),
          //     );
          //   },
          // ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // React: bg-green-500 w-20 h-20 rounded-full animate-bounce + Check
                    AnimatedBuilder(
                      animation: _bounceAnimation,
                      builder: (_, child) => Transform.translate(
                        offset: Offset(0, _bounceAnimation.value),
                        child: child,
                      ),
                      child: Container(
                        width: 80, height: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E), // green-500
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 40),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // React: text-3xl font-bold
                    const Text('Congratulations!',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold,
                            color: kSlate900)),
                    const SizedBox(height: 12),
                    // React: text-gray-600 animate-fadeIn
                    Text(
                      'Your loan application form has been submitted successfully!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Our executives will contact you soon.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
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

// ─── Grid Painter ─────────────────────────────────────────────────────────────
// React: bg-[linear-gradient(rgba(0,0,0,0.02)_1px,transparent_1px),
//           linear-gradient(90deg,rgba(0,0,0,0.02)_1px,transparent_1px)]
//        bg-[size:32px_32px]

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x05000000) // rgba(0,0,0,0.02)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}