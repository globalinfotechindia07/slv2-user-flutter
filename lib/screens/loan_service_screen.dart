import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:app_links/app_links.dart';
import 'dart:convert';
import 'dart:async';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/secure_image.dart';
import '../../../screens/home_screen.dart';
import 'dart:math';
import 'package:confetti/confetti.dart';

const List<Map<String, String>> kSteps = [
  {'key': 'personal', 'label': 'Personal Details', 'subtitle': 'Tell us about yourself'},
  {'key': 'aadhaar', 'label': 'Aadhaar Verification', 'subtitle': 'Verify your Aadhaar details'},
  {'key': 'pan', 'label': 'PAN Verification', 'subtitle': 'Verify your PAN details'},
  {'key': 'employment', 'label': 'Employment Details', 'subtitle': 'Share your work information'},
  {'key': 'product', 'label': 'Product Details', 'subtitle': 'What would you like to purchase?'},
];

const List<Map<String, String>> kEmploymentTypes = [
  {'value': 'Salaried', 'label': 'Salaried'},
  {'value': 'Self-Employed', 'label': 'Self Employed'},
  {'value': 'Business', 'label': 'Business Owner'},
];

const List<Map<String, String>> kGenderOptions = [
  {'value': 'Male', 'label': 'Male'},
  {'value': 'Female', 'label': 'Female'},
  {'value': 'Other', 'label': 'Other'},
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
const Color kAmber       = Color(0xFFF59E0B); // amber-500
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
  // Remote filenames for previously-uploaded documents (fetched via SecureImage)
  String? aadharDocFilename, aadharDocBackFilename, panDocFilename;
  String employmentType, monthlyIncome, companyName, workExperience;
  String productType, shopName, brand, model, productPrice, downPayment, gender;
  String sessionToken;
  String customerId, panFullName, branchId;
  bool isAadharVerified, isPanVerified;

  LoanFormData({
    this.phoneNumber = '', this.otp = '', this.fullName = '', this.email = '',
    this.dob = '', this.address = '', this.aadharNumber = '', this.panNumber = '',
    this.aadharDoc, this.aadharDocBack, this.panDoc,
    this.aadharDocFilename, this.aadharDocBackFilename, this.panDocFilename,
    this.employmentType = '', this.monthlyIncome = '', this.companyName = '',
    this.workExperience = '', this.productType = '', this.shopName = '',
    this.brand = '', this.model = '', this.productPrice = '',
    this.downPayment = '', this.gender = '', this.sessionToken = '',
    this.customerId = '', this.panFullName = '', this.branchId = '',
    this.isAadharVerified = false, this.isPanVerified = false,
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
  // bool _isPhoneVerified = false;
  int _currentStep = 0;
  bool _loading = false;
  bool _isPhoneVerified = false;
  bool _isSubmitted = false;
  final Map<String, String> _errors = {};

  // API data
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _shops = [];
  List<Map<String, dynamic>> _branches = [];

  // Customer data from OTP verification
  // String? _customerId;
  // bool _isAadharVerified = false;
  // bool _isPanVerified = false;

  // DigiLocker
  StreamSubscription<Uri>? _deepLinkSub;
  bool _digiLockerLoading = false;
  // bool _showDigiLockerSuccess = false;
  // bool _showDigiLockerError = false;
  String _digiLockerRefId = '';
  String _digiLockerSessionToken = '';
  // List<CategoryModel> _categories = [];

  late LoanFormData _formData;

  int _carouselIndex = 0;
  Timer? _carouselTimer;

  final List<Map<String, String>> _slides = const [
  {'title': 'Quick Approval', 'description': 'Get instant mobile loans with minimal documentation', 'image': 'assets/images/m1.png'},
  {'title': 'Flexible EMIs', 'description': 'Pay in easy installments tailored to your budget', 'image': 'assets/images/m2.png'},
  {'title': 'Low Interest Rates', 'description': 'Affordable interest rates to suit your needs', 'image': 'assets/images/m3.png'},
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

    _startCarousel();
    _fetchInitialData();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _deepLinkSub?.cancel();
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
    await Future.wait([_fetchCategories(), _fetchShops(), _fetchBranches()]);
  }

  Future<void> _fetchCategories() async {
    try {
      final body = await ApiService.getLoanCategories();
      final dynamic raw = body['data'] ?? body['list'] ?? body;
      final List<dynamic> list = raw is List ? raw : <dynamic>[];
      final cats = list.whereType<Map<String, dynamic>>().toList();
      setState(() {
        _categories = cats;

        // Resolve prefilled category name (e.g. "Mobile") to its real id,
        // only if productType isn't already a valid id from these categories.
        final currentValue = _formData.productType;
        final isAlreadyValidId = cats.any((c) => c['id']?.toString() == currentValue);

        if (currentValue.isNotEmpty && !isAlreadyValidId) {
          final match = cats.firstWhere(
            (c) => (c['name']?.toString().toLowerCase() ?? '') ==
                currentValue.toLowerCase(),
            orElse: () => {},
          );
          if (match.isNotEmpty) {
            _formData.productType = match['id'].toString();
          } else {
            // No matching category found — clear it so the user must pick
            // manually rather than submitting an invalid value.
            _formData.productType = '';
          }
        }
      });
    } catch (e) {
      debugPrint('Categories error: $e');
    }
}

  Future<void> _fetchShops() async {
    try {
      final body = await ApiService.getActiveShops();
      final dynamic raw = body['data'] ?? body['list'] ?? body;
      final List<dynamic> list = raw is List ? raw : <dynamic>[];
      setState(() => _shops = list.whereType<Map<String, dynamic>>().toList());
    } catch (e) {
      debugPrint('Shops error: $e');
    }
  }

  Future<void> _fetchBranches() async {
    try {
      final body = await ApiService.getBranches();
      final dynamic raw = body['data'] ?? body['list'] ?? body;
      final List<dynamic> list = raw is List ? raw : <dynamic>[];
      setState(() => _branches = list.whereType<Map<String, dynamic>>().toList());
    } catch (e) {
      debugPrint('Branches error: $e');
    }
  }

  // ── DigiLocker ─────────────────────────────────────────────────────────────

  void _initDeepLinks() {
    final appLinks = AppLinks();
    _deepLinkSub = appLinks.uriLinkStream.listen((uri) {
      if (uri.host == 'digilocker-callback' && mounted) {
        final encdata = uri.queryParameters['encdata'] ?? '';
        if (encdata.isNotEmpty) {
          _handleDigiLockerCallback(encdata);
        }
      }
    });
  }

  Future<void> _handleDigiLockerCallback(String encdata) async {
    setState(() => _digiLockerLoading = true);
    try {
      final result = await ApiService.callbackDigilocker(
        encdata: encdata,
        refid: _digiLockerRefId,
        sessionToken: _digiLockerSessionToken,
      );

      final status = result['status']?.toString();
      if (status == 'mismatch') {
        setState(() => _digiLockerLoading = false);
        _showMismatchDialog();
        return;
      }

      final success = result['success'] == true || status == 'success';
      if (!success) {
        throw Exception(result['message']?.toString() ?? 'Verification failed');
      }

      debugPrint('=== DIGILOCKER CALLBACK RAW RESULT: $result ===');
      final data = result['data'] as Map<String, dynamic>?;
      setState(() {
        _formData.isAadharVerified = true;
        if (data != null) {
          if ((data['fullName'] ?? data['name']) != null) {
            _formData.fullName = (data['fullName'] ?? data['name']).toString();
          }
          if (data['dob'] != null) _formData.dob = data['dob'].toString();
          if (data['gender'] != null) _formData.gender = data['gender'].toString();
          if (data['address'] != null) _formData.address = data['address'].toString();
          if (data['aadharNumber'] != null) {
            _formData.aadharNumber = data['aadharNumber'].toString();
          }
          if (data['aadharImage'] != null) {
            _formData.aadharDocFilename = data['aadharImage'].toString();
          }
          if (data['aadharImageBack'] != null) {
            _formData.aadharDocBackFilename = data['aadharImageBack'].toString();
          }
          if (data['panImage'] != null) {
            _formData.panDocFilename = data['panImage'].toString();
          }
          if (data['panNumber'] != null) {
            _formData.panNumber = data['panNumber'].toString();
          }
          if (data['employmentType'] != null) {
            _formData.employmentType = data['employmentType'].toString();
          }
          if (data['monthlyIncome'] != null) {
            _formData.monthlyIncome = data['monthlyIncome'].toString();
          }
          if (data['companyName'] != null) {
            _formData.companyName = data['companyName'].toString();
          }
          if (data['workExperience'] != null) {
            _formData.workExperience = data['workExperience'].toString();
          }
          if (data['customerId'] != null) {
            _formData.customerId = data['customerId'].toString();
          }
        }
        _digiLockerLoading = false;
      });
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _errors['digilocker'] = e.toString().replaceFirst('Exception: ', '');
        _digiLockerLoading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 56),
            SizedBox(height: 12),
            Text('Aadhaar Verified Successfully',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Your details have been successfully verified with Aadhaar',
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
              onPressed: () {
                Navigator.pop(context);
                setState(() => _currentStep = 2);
              },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  void _showMismatchDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.cancel, color: Color(0xFFDC2626), size: 56),
            SizedBox(height: 12),
            Text('Verification Failed',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text(
              'The details you provided do not match with Aadhaar records. Please check and try again.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary),
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
  void _showPanSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 56),
            SizedBox(height: 12),
            Text('PAN Verified Successfully',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 6),
            Text('Your details have been successfully verified with PAN',
                textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
              onPressed: () {
                Navigator.pop(context);
                setState(() => _currentStep++);
              },
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _initiateDigiLocker() async {
    if (_formData.customerId.isEmpty) {
      setState(() => _errors['digilocker'] = 'Customer ID not found. Please try again.');
      return;
    }
    setState(() => _digiLockerLoading = true);
    try {
      final result = await ApiService.initiateDigilocker(
        _formData.customerId,
        platform: 'mobile',
        );
      final data = result['data'] as Map<String, dynamic>? ?? {};
      final authUrl = data['authorization_url']?.toString() ?? '';
      if (authUrl.isEmpty) throw Exception('Failed to get DigiLocker URL');
      _digiLockerRefId = data['refid']?.toString() ?? '';
      _digiLockerSessionToken = data['session_token']?.toString() ?? '';
      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch DigiLocker');
      }
    } catch (e) {
      setState(() => _errors['digilocker'] =
          e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _digiLockerLoading = false);
    }
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
      case 1: // Aadhaar — only validate if not yet verified
        if (!_formData.isAadharVerified) {
          final isMaskedAadhaar = _formData.aadharNumber.contains('•') ||
              _formData.aadharNumber.contains('X');
          if (_formData.aadharNumber.isEmpty) {
            errors['aadharNumber'] = 'Aadhar number is required';
          } else if (!isMaskedAadhaar &&
              !RegExp(r'^\d{12}$').hasMatch(_formData.aadharNumber)) {
            errors['aadharNumber'] = 'Enter valid 12-digit Aadhar number';
          }
          final hasExistingAadharDoc = _formData.aadharDoc == null &&
              (_formData.aadharDocFilename?.isNotEmpty ?? false);
          if (_formData.aadharDoc == null && !hasExistingAadharDoc) {
            errors['aadharDoc'] = 'Aadhar Front Side document is required';
          } else if (_formData.aadharDoc != null &&
              _formData.aadharDoc!.lengthSync() > 5 * 1024 * 1024) {
            errors['aadharDoc'] = 'Aadhar Front Side document must be less than 5MB';
          }
          final hasExistingAadharDocBack = _formData.aadharDocBack == null &&
              (_formData.aadharDocBackFilename?.isNotEmpty ?? false);
          if (_formData.aadharDocBack == null && !hasExistingAadharDocBack) {
            errors['aadharDocBack'] = 'Aadhar Back Side document is required';
          } else if (_formData.aadharDocBack != null &&
              _formData.aadharDocBack!.lengthSync() > 5 * 1024 * 1024) {
            errors['aadharDocBack'] = 'Aadhar Back Side document must be less than 5MB';
          }
        }
        break;
      case 2: // PAN — optional, but validated fully once entered
        if (!_formData.isPanVerified) {
          if (_formData.panNumber.isNotEmpty) {
            final isMaskedPan = _formData.panNumber.contains('X');
            if (!isMaskedPan &&
                !RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(_formData.panNumber)) {
              errors['panNumber'] = 'Enter valid PAN number (e.g., ABCDE1234F)';
            }
            if (_formData.panFullName.trim().isEmpty) {
              errors['panFullName'] = 'Full name as per PAN is required';
            }
            final hasExistingPanDoc = _formData.panDoc == null &&
                (_formData.panDocFilename?.isNotEmpty ?? false);
            if (_formData.panDoc == null && !hasExistingPanDoc) {
              errors['panDoc'] = 'PAN document is required when PAN number is provided';
            } else if (_formData.panDoc != null &&
                _formData.panDoc!.lengthSync() > 5 * 1024 * 1024) {
              errors['panDoc'] = 'PAN document must be less than 5MB';
            }
          }
        }
        break;
      case 3: // Employment
        if (_formData.employmentType.isEmpty) errors['employmentType'] = 'Employment type is required';
        if (_formData.companyName.trim().isEmpty) errors['companyName'] = 'Company name is required';
        if (_formData.monthlyIncome.isEmpty) {
          errors['monthlyIncome'] = 'Monthly income is required';
        } else if ((double.tryParse(_formData.monthlyIncome) ?? 0) < 10000) {
          errors['monthlyIncome'] = 'Monthly income must be at least ₹10,000';
        }
        if (_formData.workExperience.isEmpty) errors['workExperience'] = 'Work experience is required';
        break;
      case 4: // Product
        if (_formData.productType.isEmpty)   errors['productType'] = 'Product type is required';
        if (_formData.brand.trim().isEmpty)  errors['brand']  = 'Brand is required';
        if (_formData.model.trim().isEmpty)  errors['model']  = 'Model is required';
        if (_formData.shopName.isEmpty)      errors['shopName'] = 'Shop name is required';
        if (_formData.branchId.isEmpty)      errors['branchId'] = 'Branch is required';
        if (_formData.productPrice.isEmpty) {
          errors['productPrice'] = 'Product price is required';
        } else if ((double.tryParse(_formData.productPrice) ?? 0) < 1000) {
          errors['productPrice'] = 'Product price must be at least ₹1,000';
        }
        final dp = double.tryParse(_formData.downPayment) ?? 0;
        final pp = double.tryParse(_formData.productPrice) ?? 0;
        if (dp < 0) {
          errors['downPayment'] = 'DownPayment amount cannot be negative';
        } else if (_formData.downPayment.isNotEmpty && dp > pp) {
          errors['downPayment'] = 'DownPayment amount cannot be more than product price';
        }
        break;
    }
    setState(() => _errors..clear()..addAll(errors));
    return errors.isEmpty;
  }

  /// Returns a local File to upload for a given doc slot.
  /// If the user picked a new file, use it. Otherwise, if a remote
  /// filename exists from a previous attempt, fetch it via the same
  /// presigned-URL flow SecureImage uses, then download the actual
  /// bytes so we always send a real file in the multipart request —
  /// the backend requires the file to be present every time, even on
  /// a retry where nothing was re-picked.
  Future<File?> _resolveUploadFile(File? localFile, String? remoteFilename) async {
    if (localFile != null) return localFile;
    if (remoteFilename == null || remoteFilename.isEmpty) return null;

    try {
      final token = await AuthService.getAccessToken();
      final basename = remoteFilename.split('/').last.split('\\').last;

      final presignUri = Uri.parse(
        '${ApiConstants.newAuthBaseUrl}/api/v2/mobile/files/presign'
        '?folder=customers&filename=$basename',
      );
      final presignRes = await http.get(presignUri, headers: {
        'Authorization': 'Bearer $token',
      });

      debugPrint('=== _resolveUploadFile PRESIGN STATUS: ${presignRes.statusCode}');
      debugPrint('=== _resolveUploadFile PRESIGN BODY: ${presignRes.body}');

      if (presignRes.statusCode != 200) return null;
      final presignData = jsonDecode(presignRes.body);
      if (presignData['success'] != true) return null;

      final path = presignData['data']['url'] as String;
      final finalUrl = '${ApiConstants.newAuthBaseUrl}/api/v2/mobile$path';
      debugPrint('=== _resolveUploadFile FINAL image URL: $finalUrl');

      final imageRes = await http.get(Uri.parse(finalUrl));
      if (imageRes.statusCode != 200) return null;

      final tempDir = await Directory.systemTemp.createTemp('loan_docs');
      final ext = basename.contains('.') ? basename.split('.').last : 'jpg';
      final tempFile = File(
        '${tempDir.path}/reupload_${DateTime.now().millisecondsSinceEpoch}.$ext',
      );
      await tempFile.writeAsBytes(imageRes.bodyBytes);
      return tempFile;
    } catch (e) {
      debugPrint('=== _resolveUploadFile ERROR: $e ===');
      return null;
    }
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

 Future<void> _handleNext() async {
    debugPrint('=== _handleNext called, currentStep: $_currentStep, kSteps.length: ${kSteps.length}');
    if (!_validateStep()) {
      debugPrint('=== Validation failed, errors: $_errors');
      return;
    }
    debugPrint('=== Validation passed');
    setState(() { _loading = true; _errors.remove('submit'); });

    try {
      // ── Step 1: Aadhaar ──────────────────────────────────────────────────
      if (_currentStep == 1) {
        if (_formData.isAadharVerified) {
          setState(() => _currentStep++);
          return;

        }
        debugPrint('=== REGISTER CUSTOMER REQUEST — fullName: "${_formData.fullName}", '
            'email: "${_formData.email}", dob: "${_formData.dob}", '
            'gender: "${_formData.gender}", address: "${_formData.address}", '
            'customerId: "${_formData.customerId}" ===');
        debugPrint('=== aadharDoc: ${_formData.aadharDoc?.path}, exists: ${_formData.aadharDoc?.existsSync()}');
        debugPrint('=== aadharDocBack: ${_formData.aadharDocBack?.path}, exists: ${_formData.aadharDocBack?.existsSync()}');
        debugPrint('=== aadharDocFilename (remote): ${_formData.aadharDocFilename}');
        debugPrint('=== aadharDocBackFilename (remote): ${_formData.aadharDocBackFilename}');

        final aadharFrontToSend =
            await _resolveUploadFile(_formData.aadharDoc, _formData.aadharDocFilename);
        final aadharBackToSend =
            await _resolveUploadFile(_formData.aadharDocBack, _formData.aadharDocBackFilename);

        if (aadharFrontToSend == null || aadharBackToSend == null) {
          setState(() {
            _loading = false;
            _errors['submit'] = 'Could not load your existing Aadhaar documents. '
                'Please re-upload the Aadhaar front and back images.';
          });
          return;
        }

        final result = await ApiService.registerCustomer(
          {
            'phoneNumber': _formData.phoneNumber,
            'fullName': _formData.fullName,
            'panFullName': _formData.panFullName,
            'email': _formData.email,
            'dob': _formData.dob,
            'gender': _formData.gender,
            'address': _formData.address,
            'aadharNumber': _formData.aadharNumber,
            'panNumber': _formData.panNumber,
            'tempToken': _formData.sessionToken,
            if (_formData.customerId.isNotEmpty) 'customerId': _formData.customerId,
          },
          aadharImagePath: aadharFrontToSend.path,
          aadharImageBackPath: aadharBackToSend.path,
          panImagePath: _formData.panDoc?.path,
        );
        debugPrint('=== REGISTER CUSTOMER RAW RESULT: $result ===');

        // Pull whatever we can from the response regardless of `success` —
        // an "already registered" response still carries the customerId
        // and the already-uploaded doc filenames, and we still need to
        // send the user through DigiLocker since Aadhaar isn't verified yet.
        final resData = result['data'] as Map<String, dynamic>?;
        final cid = resData?['customerId']?.toString()
            ?? resData?['id']?.toString()
            ?? '';

        setState(() {
          if (cid.isNotEmpty) _formData.customerId = cid;
          if (resData?['aadharImage'] != null) {
            _formData.aadharDocFilename = resData!['aadharImage'].toString();
          }
          if (resData?['aadharImageBack'] != null) {
            _formData.aadharDocBackFilename = resData!['aadharImageBack'].toString();
          }
        });

        // IMPORTANT: don't infer success just from customerId being present —
        // the backend keeps returning the existing customerId even when it
        // rejects the update (e.g. missing Aadhaar image), which was causing
        // us to launch DigiLocker without actually saving the edited
        // personal details.
        if (result['success'] != true) {
          setState(() => _errors['submit'] =
              result['message']?.toString() ?? 'Failed to save');
          return;
        }

        if (_formData.customerId.isEmpty) {
          setState(() => _errors['submit'] =
              result['message']?.toString() ?? 'Failed to save');
          return;
        }

        // Must release loading before browser launch
        setState(() => _loading = false);
        await _initiateDigiLocker();
        return;
      }

      // ── Step 2: PAN (optional) ────────────────────────────────────────────
      if (_currentStep == 2) {
        if (_formData.isPanVerified || _formData.panNumber.isEmpty) {
          setState(() => _currentStep++);
          return;
        }
        // if (_formData.panDoc == null) {
        //   setState(() => _errors['panDoc'] = 'PAN document is required');
        //   return;
        // }
        debugPrint('=== PAN VERIFY REQUEST — customerId: "${_formData.customerId}", '
            'panNumber: "${_formData.panNumber}", panFullName: "${_formData.panFullName}" ===');
        final result = await ApiService.verifyPan(
          customerId: _formData.customerId,
          panNumber: _formData.panNumber,
          panFullName: _formData.panFullName,
          panImagePath: _formData.panDoc?.path,
        );
        debugPrint('=== VERIFY PAN RAW RESULT: $result ===');
        if (result['success'] == true || result['status'] == 'success') {
          final resData = result['data'] as Map<String, dynamic>?;
          setState(() {
            _formData.isPanVerified = true;
            if (resData?['panImage'] != null) {
              _formData.panDocFilename = resData!['panImage'].toString();
            }
          });
          _showPanSuccessDialog();
        } else {
          setState(() => _errors['panNumber'] =
              result['message']?.toString() ?? 'PAN verification failed');
        }
        return;
      }

      // ── Step 3: Employment ────────────────────────────────────────────────
      if (_currentStep == 3) {
        debugPrint('=== Step 3 — customerId: "${_formData.customerId}"');
        if (_formData.customerId.isNotEmpty) {
          debugPrint('=== Calling updateEmployment');
          final result = await ApiService.updateEmployment(
            _formData.customerId,
            {
              'employmentType': _formData.employmentType,
              'monthlyIncome': _formData.monthlyIncome,
              'companyName': _formData.companyName,
              'workExperience': _formData.workExperience,
            },
          );
          debugPrint('=== updateEmployment result: $result');
          if (result['success'] == true) {
            setState(() => _currentStep++);
          } else {
            setState(() => _errors['submit'] =
                result['message']?.toString() ?? 'Failed to save employment');
          }
        } else {
          debugPrint('=== No customerId, advancing directly');
          setState(() => _currentStep++);
        }
        return;
      }

      // ── Step 4: Final submission ──────────────────────────────────────────
      if (_currentStep == kSteps.length - 1) {
        await _submitForm();
        return;
      }

      // ── Default: advance step ─────────────────────────────────────────────
      setState(() => _currentStep++);

    } catch (e) {
      debugPrint('=== _handleNext EXCEPTION: $e');
      setState(() => _errors['submit'] =
          e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

Future<void> _submitForm() async {
  final userProfile = await AuthService.getUserProfile();
  debugPrint('=== userProfile keys: ${userProfile?.keys}');
  debugPrint('=== userProfile full: $userProfile');
  debugPrint('=== SUBMIT — raw downPayment value: "${_formData.downPayment}" ===');
  debugPrint('=== SUBMIT — downPayment isEmpty: ${_formData.downPayment.isEmpty} ===');
  final result = await ApiService.submitLoanApplication({    'customerId': _formData.customerId,
    'phoneNumber': _formData.phoneNumber,
    'otp': _formData.otp,
    'fullName': _formData.fullName,
    'panFullName': _formData.panFullName,
    'email': _formData.email,
    'dob': _formData.dob,
    'gender': _formData.gender,
    'address': _formData.address,
    'aadharNumber': _formData.aadharNumber,
    'panNumber': _formData.panNumber,
    'sessionToken': _formData.sessionToken,
    'isAadharVerified': _formData.isAadharVerified,
    'isPanVerified': _formData.isPanVerified,
    'employmentType': _formData.employmentType,
    'monthlyIncome': _formData.monthlyIncome,
    'companyName': _formData.companyName,
    'workExperience': _formData.workExperience,
    'productType': _formData.productType,
    'brand': _formData.brand,
    'model': _formData.model,
    'productPrice': _formData.productPrice,
    'downPayment': _formData.downPayment,
    'shopName': _formData.shopName,
    'branchId': _formData.branchId,
    'userName': userProfile?['username']?.toString() ?? '',
    'userDepartment': userProfile?['role']?.toString() ?? '',
  });
  if (result['success'] == true) {
    setState(() => _isSubmitted = true);
  } else {
    throw Exception(result['message']?.toString() ?? 'Submission failed');
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
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen(initialTab: 2)),
              (route) => false,
            );
          },
        );
      }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
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
          CustomPaint(painter: _GridPainter(), child: const SizedBox.expand()),
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

  // ─── Header ───────────────────────────────────────────────────────────────

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
          Text(
            widget.serviceDetails?.psTitle ?? 'Loan Service',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: kSlate900),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.help_outline, color: Colors.grey.shade600, size: 24),
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

  Widget _buildOtpBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildCarousel(),
          _OtpVerificationWidget(
            initialPhone: _formData.phoneNumber,
            onVerified: (result) {
              _carouselTimer?.cancel();
              setState(() {
                _isPhoneVerified = true;
                _formData.phoneNumber = result.phoneNumber;
                _formData.aadharNumber = result.aadhaarNumber;
                _formData.panNumber = result.panNumber;
                _formData.sessionToken = result.sessionToken;
                if (result.customerId != null && result.customerId!.isNotEmpty) {
                  _formData.customerId = result.customerId!;
                }
                if (result.isAadharVerified == true) {
                  _formData.isAadharVerified = true;
                }
                if (result.isPanVerified == true) {
                  _formData.isPanVerified = true;
                  _formData.panFullName = result.panFullName ?? '';
                }
                if (result.fullName != null && result.fullName!.isNotEmpty) {
                  _formData.fullName = result.fullName!;
                }
                if (result.email != null && result.email!.isNotEmpty) {
                  _formData.email = result.email!;
                }
                if (result.address != null && result.address!.isNotEmpty) {
                  _formData.address = result.address!;
                }
                if (result.dob != null && result.dob!.isNotEmpty) {
                  _formData.dob = result.dob!;
                }
                if (result.gender != null && result.gender!.isNotEmpty) {
                  _formData.gender = result.gender!;
                }
                if (result.employmentType != null && result.employmentType!.isNotEmpty) {
                  _formData.employmentType = result.employmentType!;
                }
                if (result.monthlyIncome != null && result.monthlyIncome!.isNotEmpty) {
                  _formData.monthlyIncome = result.monthlyIncome!;
                }
                if (result.companyName != null && result.companyName!.isNotEmpty) {
                  _formData.companyName = result.companyName!;
                }
                if (result.workExperience != null && result.workExperience!.isNotEmpty) {
                  _formData.workExperience = result.workExperience!;
                }
                if (result.aadharImage != null && result.aadharImage!.isNotEmpty) {
                  _formData.aadharDocFilename = result.aadharImage;
                }
                if (result.aadharImageBack != null && result.aadharImageBack!.isNotEmpty) {
                  _formData.aadharDocBackFilename = result.aadharImageBack;
                }
                if (result.panImage != null && result.panImage!.isNotEmpty) {
                  _formData.panDocFilename = result.panImage;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    final slide = _slides[_carouselIndex];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: Column(
          key: ValueKey(_carouselIndex),
          children: [
            Text(
              slide['title']!,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: kSlate900),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              slide['description']!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.asset(slide['image']!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
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

 Widget _buildFormBody() {
    return SingleChildScrollView(
      key: ValueKey(_currentStep),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: _buildStepContent(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildPersonalStep();
      case 1: return _buildAadhaarStep();
      case 2: return _buildPanStep();
      case 3: return _buildEmploymentStep();
      case 4: return _buildProductStep();
      default: return const SizedBox.shrink();
    }
  }

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

  Widget _buildAadhaarStep() {
    return _FormSection(
      title: 'Aadhaar Verification',
      subtitle: 'Verify your Aadhaar details',
      children: [
        // Info banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please upload clear images of your Aadhaar card.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1D4ED8)),
                ),
              ),
            ],
          ),
        ),
        if (_formData.isAadharVerified)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 8),
                  Text('Aadhaar Verified Successfully',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF15803D))),
                ],
              ),
            ),
          ),
        _LoanInputField(
          label: 'Aadhar Number',
          initialValue: _formData.aadharNumber,
          placeholder: 'Enter 12-digit Aadhar number',
          error: _errors['aadharNumber'],
          keyboardType: TextInputType.number,
          maxLength: 12,
          enabled: !_formData.isAadharVerified,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _ClearOnBackspaceFormatter(),
          ],
          onChanged: (v) => setState(() {
            _formData.aadharNumber = v;
            _errors.remove('aadharNumber');
          }),
        ),
        _DocumentField(
          label: 'Upload Front Aadhar Card Image',
          localFile: _formData.aadharDoc,
          remoteFilename: _formData.aadharDocFilename,
          error: _errors['aadharDoc'],
          enabled: !_formData.isAadharVerified,
          onChanged: (f) => setState(() {
            _formData.aadharDoc = f;
            _errors.remove('aadharDoc');
          }),
          onRemove: () => setState(() {
            _formData.aadharDoc = null;
            _errors.remove('aadharDoc');
          }),
        ),
        _DocumentField(
          label: 'Upload Back Aadhar Card Image',
          localFile: _formData.aadharDocBack,
          remoteFilename: _formData.aadharDocBackFilename,
          error: _errors['aadharDocBack'],
          enabled: !_formData.isAadharVerified,
          onChanged: (f) => setState(() {
            _formData.aadharDocBack = f;
            _errors.remove('aadharDocBack');
          }),
          onRemove: () => setState(() {
            _formData.aadharDocBack = null;
            _errors.remove('aadharDocBack');
          }),
        ),
        if (!_formData.isAadharVerified && _errors['submit'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Icon(Icons.error_outline, size: 14, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(_errors['submit']!,
                    style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
              ),
            ]),
          ),
        if (!_formData.isAadharVerified && _errors['digilocker'] != null)
          Row(children: [
            const Icon(Icons.error_outline, size: 14, color: Color(0xFFEF4444)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(_errors['digilocker']!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444))),
            ),
          ]),
        if (!_formData.isAadharVerified && _digiLockerLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: CircularProgressIndicator(strokeWidth: 2, color: kPrimary),
            ),
          ),
      ],
    );
  }

  Widget _buildPanStep() {
    return _FormSection(
      title: 'PAN Verification',
      subtitle: 'Verify your PAN details (optional)',
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PAN verification is optional. You may skip this step.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1D4ED8)),
                ),
              ),
            ],
          ),
        ),
        if (_formData.isPanVerified)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 8),
                  Text('PAN Verified Successfully',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF15803D))),
                ],
              ),
            ),
          ),
        _LoanInputField(
          label: 'PAN Number',
          initialValue: _formData.panNumber,
          placeholder: 'Enter PAN number',
          error: _errors['panNumber'],
          enabled: !_formData.isPanVerified,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [_ClearOnBackspaceFormatter()],
          onChanged: (v) => setState(() {
            _formData.panNumber = v;
            _errors.remove('panNumber');
          }),
        ),
        _LoanInputField(
          label: 'Full Name (as per PAN)',
          initialValue: _formData.panFullName,
          placeholder: 'Enter name exactly as on PAN card',
          error: _errors['panFullName'],
          enabled: !_formData.isPanVerified,
          onChanged: (v) => setState(() {
            _formData.panFullName = v;
            _errors.remove('panFullName');
          }),
        ),
        _DocumentField(
          label: 'Upload PAN Card Image',
          localFile: _formData.panDoc,
          remoteFilename: _formData.panDocFilename,
          error: _errors['panDoc'],
          enabled: !_formData.isPanVerified,
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

  Widget _buildProductStep() {
    final shopOptions = _shops
        .map((s) => {
              'value': s['id']?.toString() ?? '',
              'label':
                  '${s['shopName'] ?? s['shop_name'] ?? ''}, ${s['address'] ?? ''}, ${s['city'] ?? ''}',
            })
        .toList();

    final branchOptions = _branches
        .map((b) => {
              'value': b['id']?.toString() ?? '',
              'label':
                  '${b['branch_name'] ?? b['branchName'] ?? ''} (${b['branch_code'] ?? ''})',
            })
        .toList();

    final categoryOptions = _categories
        .map((c) => {
              'value': c['id']?.toString() ?? '',
              'label': c['name']?.toString() ?? '',
            })
        .toList();

    return _FormSection(
      title: 'Product Details',
      subtitle: 'What would you like to purchase?',
      children: [
        _SelectPopupField(
          label: 'Select Branch',
          value: _formData.branchId,
          options: branchOptions,
          error: _errors['branchId'],
          onChanged: (v) => setState(() {
            _formData.branchId = v;
            _errors.remove('branchId');
          }),
        ),
        _SelectPopupField(
          label: 'Product Type',
          value: _formData.productType,
          options: categoryOptions,
          error: _errors['productType'],
          onChanged: (v) => setState(() {
            _formData.productType = v;
            _errors.remove('productType');
          }),
        ),
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
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
          ),
      ),
    );
  }
}

// ─── OTP Verification Result ───────────────────────────────────────────────────

class OtpVerificationResult {
  final String phoneNumber;
  final String aadhaarNumber;
  final String panNumber;
  final String sessionToken;
  final String? fullName;
  final String? email;
  final String? address;
  final String? customerId;
  final String? panFullName;
  final bool? isAadharVerified;
  final bool? isPanVerified;
  final String? employmentType;
  final String? monthlyIncome;
  final String? companyName;
  final String? workExperience;
  final String? dob;
  final String? gender;
  final String? aadharImage;
  final String? aadharImageBack;
  final String? panImage;


  const OtpVerificationResult({
    required this.phoneNumber,
    required this.aadhaarNumber,
    required this.panNumber,
    required this.sessionToken,
    this.fullName,
    this.email,
    this.address,
    this.customerId,
    this.panFullName,
    this.isAadharVerified,
    this.isPanVerified,
    this.employmentType,
    this.monthlyIncome,
    this.companyName,
    this.workExperience,
    this.dob,
    this.gender,
    this.aadharImage,
    this.aadharImageBack,
    this.panImage,
  });
}

// Step 1: Phone + Aadhaar + PAN form (client-side validation only — your
//         current backend has no identity-precheck endpoint, so this step
//         just collects the fields and moves on)
// Step 2: Confirm masked mobile number -> ApiService.sendOtp (newAuthBaseUrl)
// Step 3: 6-digit OTP entry with resend timer -> ApiService.verifyOtp /
//         ApiService.resendOtp (newAuthBaseUrl)

class _OtpVerificationWidget extends StatefulWidget {
  final String initialPhone;
  final void Function(OtpVerificationResult result) onVerified;

  const _OtpVerificationWidget({
    Key? key, required this.initialPhone, required this.onVerified,
  }) : super(key: key);

  @override
  State<_OtpVerificationWidget> createState() => _OtpVerificationWidgetState();
}

class _OtpVerificationWidgetState extends State<_OtpVerificationWidget> {
  // Step control: 1 = form, 2 = confirm, 3 = otp
  int _step = 1;

  final _phoneController = TextEditingController();
  final _aadharNumberCtrl = TextEditingController();
  final _panNumberCtrl = TextEditingController();
  final _panFullNameCtrl = TextEditingController();

  String _precheckPhone = '';
  String _requestId = '';
  bool _showUpdatePrompt = false;
  Map<String, dynamic>? _fetchedCustomer;

  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _loading = false;
  String? _error;

  int _resendTimer = 30;
  bool _canResend = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _phoneController.text = widget.initialPhone;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _aadharNumberCtrl.dispose();
    _panNumberCtrl.dispose();
    _panFullNameCtrl.dispose();
    for (final c in _otpControllers) c.dispose();
    for (final f in _otpFocusNodes) f.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String _maskPhone(String num) {
    if (num.isEmpty) return '';
    return '*****${num.substring(num.length - 4)}';
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() { _resendTimer = 30; _canResend = false; });
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_resendTimer > 0) { _resendTimer--; }
        else { _canResend = true; t.cancel(); }
      });
    });
  }

  // ─── Step 1 — Validate details, move to confirm step ───────────────────────

  Future<void> _handlePhoneSubmit() async {
  final phone = _phoneController.text.trim();
  final aadhaar = _aadharNumberCtrl.text.trim();
  final pan = _panNumberCtrl.text.trim();

  if (phone.length < 10) {
    setState(() => _error = 'Please enter a valid 10-digit mobile number');
    return;
  }
  if (aadhaar.length != 12) {
    setState(() => _error = 'Please enter a valid 12-digit Aadhaar number');
    return;
  }

  setState(() { _error = null; _loading = true; });
  try {
    debugPrint('=== LOAN OTP — checkCustomerIdentity ===');
    debugPrint('phone: $phone, aadhaar: $aadhaar, pan: ${pan.isEmpty ? "(not provided)" : pan}');

    final res = await ApiService.checkCustomerIdentity(
      phone: phone,
      aadhaar: aadhaar,
      pan: pan.isEmpty ? null : pan,
    );

    debugPrint('=== LOAN OTP — checkCustomerIdentity RAW RESPONSE ===');
    debugPrint(res.toString());

    if (res['success'] != true) {
      throw Exception(res['message']?.toString() ?? 'Verification failed');
    }

    final data = res['data'] as Map<String, dynamic>?;
    if (data != null && data['customer'] != null) {
      _fetchedCustomer = data['customer'] as Map<String, dynamic>;
    }

    if (data != null && data['action'] == 'UPDATE_PHONE') {
      debugPrint('=== LOAN OTP — Aadhaar already linked to a different phone (UPDATE_PHONE) ===');
      setState(() { _showUpdatePrompt = true; _loading = false; });
      return;
    }

    setState(() {
      _precheckPhone = phone;
      _step = 2;
    });
  } catch (e) {
    debugPrint('=== LOAN OTP — checkCustomerIdentity EXCEPTION: $e ===');
    setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  // ─── Step 2 — Send OTP (ApiService.sendOtp -> newAuthBaseUrl) ──────────────

  Future<void> _handleSendOtp() async {
    setState(() { _error = null; _loading = true; });
    try {
      debugPrint('=== LOAN OTP — Send OTP ===');
      debugPrint('Phone: $_precheckPhone');

      final res = await ApiService.sendOtp(_precheckPhone);

      debugPrint('=== LOAN OTP — Send OTP RAW RESPONSE ===');
      debugPrint(res.toString());
      debugPrint('statusCode: ${res['statusCode']}');
      debugPrint('success: ${res['success']}');
      debugPrint('status: ${res['status']}');
      debugPrint('message: ${res['message']}');

      if (res['success'] != true && res['status'] != 'success') {
        debugPrint('=== LOAN OTP — Send OTP FAILED ===');
        throw Exception(res['message']?.toString() ?? 'Failed to send OTP');
      }
      final data = res['data'] as Map<String, dynamic>?;
      _requestId = (data?['request_id'] ?? data?['requestId'] ?? res['request_id'])
              ?.toString() ??
          '';

      debugPrint('=== LOAN OTP — request_id: $_requestId ===');

      // 🔑 Print the OTP itself if the backend returns it (dev/test mode only)
      final devOtp = data?['otp'] ?? res['otp'];
      if (devOtp != null) {
        debugPrint('🔑🔑🔑 LOAN OTP — OTP CODE: $devOtp 🔑🔑🔑');
      }

      setState(() {
        _phoneController.text = _precheckPhone;
        _step = 3;
      });
      _startResendTimer();
    } catch (e) {
      debugPrint('=== LOAN OTP — Send OTP EXCEPTION: $e ===');
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;
    setState(() { _loading = true; _error = null; });
    _startResendTimer();
    try {
      debugPrint('=== LOAN OTP — Resend OTP — request_id: $_requestId ===');
      final res = await ApiService.resendOtp(_requestId);
      debugPrint('=== LOAN OTP — Resend OTP RAW RESPONSE ===');
      debugPrint(res.toString());
      if (res['success'] != true && res['status'] != 'success') {
        throw Exception(res['message']?.toString() ?? 'Failed to resend OTP');
      }
      final data = res['data'] as Map<String, dynamic>?;
      final newId = data?['request_id'] ?? data?['requestId'] ?? res['request_id'];
      if (newId != null) {
        _requestId = newId.toString();
      }
      final devOtp = data?['otp'] ?? res['otp'];
      if (devOtp != null) {
        debugPrint('🔑🔑🔑 LOAN OTP — RESENT OTP CODE: $devOtp 🔑🔑🔑');
      }
    } catch (e) {
      debugPrint('=== LOAN OTP — Resend OTP EXCEPTION: $e ===');
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ─── Step 3 — Verify OTP (ApiService.verifyOtp -> newAuthBaseUrl) ──────────

  void _onOtpDigitChanged(int index, String value) {
    if (_error != null) setState(() => _error = null);
    if (value.isNotEmpty && index < 5) {
      _otpFocusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }

    final otp = _otpControllers.map((c) => c.text).join();
    if (otp.length == 6 && index == 5) {
      _verifyOtp(otp);
    }
  }

  Future<void> _verifyOtp(String otp) async {
    setState(() { _loading = true; _error = null; });
    try {
      debugPrint('=== LOAN OTP — Verify OTP — request_id: $_requestId, otp: $otp ===');
      final res = await ApiService.verifyOtp(_requestId, otp);
      debugPrint('=== LOAN OTP — Verify OTP RAW RESPONSE ===');
      debugPrint(res.toString());
      if (res['success'] == true || res['status'] == 'success') {
        final data = res['data'] as Map<String, dynamic>?;
        final sessionToken = (data?['tempToken'] ??
                data?['accessToken'] ??
                data?['token'] ??
                res['tempToken'])
            ?.toString() ??
            '';
        final customer = data?['user'] as Map<String, dynamic>? ??
            data?['customer'] as Map<String, dynamic>? ??
            _fetchedCustomer;
        
         // ─── ADD THIS ───────────────────────────────────────────────
        debugPrint('=== LOAN OTP — customer object: $customer ===');
        debugPrint('=== LOAN OTP — aadharImage: ${customer?['aadharImage']} ===');
        debugPrint('=== LOAN OTP — aadharImageBack: ${customer?['aadharImageBack']} ===');
        debugPrint('=== LOAN OTP — panImage: ${customer?['panImage']} ===');
        // ────────────────────────────────────────────────────────────


        debugPrint('=== LOAN OTP — Verify OTP SUCCESS — sessionToken: $sessionToken ===');
        widget.onVerified(OtpVerificationResult(
          phoneNumber: _phoneController.text.trim(),
          aadhaarNumber: customer?['aadharMasked']?.toString()
              ?? _aadharNumberCtrl.text.trim(),
          panNumber: customer?['panMasked']?.toString()
              ?? _panNumberCtrl.text.trim(),
          sessionToken: sessionToken,
          fullName: customer?['fullName']?.toString()
              ?? customer?['name']?.toString(),
          email: customer?['email']?.toString(),
          address: customer?['address']?.toString(),
          customerId: customer?['customerId']?.toString()
              ?? customer?['id']?.toString(),
          panFullName: customer?['panFullName']?.toString(),
          isAadharVerified: customer?['isAadharVerified'] == true ||
              customer?['isAadharVerified'] == 1 ||
              customer?['isAadharVerified'] == '1',
          isPanVerified: customer?['isPanVerified'] == true ||
              customer?['isPanVerified'] == 1 ||
              customer?['isPanVerified'] == '1',
          employmentType: customer?['employmentType']?.toString(),
          monthlyIncome: customer?['monthlyIncome']?.toString(),
          companyName: customer?['companyName']?.toString(),
          workExperience: customer?['workExperience']?.toString(),
          dob: customer?['dob']?.toString(),
          gender: customer?['gender']?.toString(),
          aadharImage: customer?['aadharImage']?.toString(),
          aadharImageBack: customer?['aadharImageBack']?.toString(),
          panImage: customer?['panImage']?.toString(),
        ));
      } else {
        debugPrint('=== LOAN OTP — Verify OTP FAILED — message: ${res['message']} ===');
        setState(() => _error = res['message']?.toString() ?? 'Invalid OTP. Please try again.');
        for (final c in _otpControllers) c.clear();
        _otpFocusNodes[0].requestFocus();
      }
    } catch (e) {
      debugPrint('=== LOAN OTP — Verify OTP EXCEPTION: $e ===');
      setState(() => _error = 'Verification failed. Please try again.');
      for (final c in _otpControllers) c.clear();
      _otpFocusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 1 && _showUpdatePrompt) return _buildUpdatePrompt();
    if (_step == 2) return _buildConfirmStep();
    if (_step == 3) return _buildOtpStep();
    return _buildFormStep();
  }

  // ─── Step 1 UI — Phone / Aadhaar / PAN form ────────────────────────────────

  Widget _buildFormStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Verification Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: kSlate900)),
          const SizedBox(height: 4),
          Text('Please verify your details',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 24),

          _ControlledInputField(
            label: 'Phone Number',
            controller: _phoneController,
            placeholder: 'Enter 10-digit number',
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),
          _ControlledInputField(
            label: 'Aadhaar Number',
            controller: _aadharNumberCtrl,
            placeholder: 'Enter 12-digit Aadhaar number',
            keyboardType: TextInputType.number,
            maxLength: 12,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {},
          ),
          const SizedBox(height: 16),
          _ControlledInputField(
            label: 'PAN Number',
            controller: _panNumberCtrl,
            placeholder: 'Enter PAN number',
            maxLength: 10,
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) {},
          ),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: kPrimary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(_error!,
                        style: const TextStyle(fontSize: 13, color: kPrimary)),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _handlePhoneSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text('Get Verification Code',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatePrompt() {
  final aadhaar = _aadharNumberCtrl.text;
  final lastFour = aadhaar.length >= 4 ? aadhaar.substring(aadhaar.length - 4) : aadhaar;
  return Padding(
    padding: const EdgeInsets.all(20),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kSlate200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.error_outline, color: kAmber, size: 32),
          ),
          const SizedBox(height: 16),
          const Text('Phone Number Mismatch',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kSlate900)),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5),
              children: [
                const TextSpan(text: 'The Aadhaar number '),
                TextSpan(
                  text: 'XXXX-XXXX-$lastFour',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: kSlate900),
                ),
                const TextSpan(
                  text: ' is already registered with another mobile number.\n\n'
                      'Do you want to update your registered mobile number to ',
                ),
                TextSpan(
                  text: '+91 ${_phoneController.text}',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: kBlue),
                ),
                const TextSpan(text: '?'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          // const SizedBox(height: 20),
          // SizedBox(
          //   width: double.infinity,
          //   height: 48,
            // Disabled to match the React reference — the "update number" action
            // isn't wired to a backend mutation yet.
            // child: ElevatedButton(
            //   onPressed: null,
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: kAmber.withOpacity(0.5),
            //     foregroundColor: Colors.white,
            //     elevation: 0,
            //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            //   ),
            //   child: const Text('Yes, Update Number',
            //       style: TextStyle(fontWeight: FontWeight.w600)),
            // ),
          // ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: () => setState(() => _showUpdatePrompt = false),
              style: OutlinedButton.styleFrom(
                foregroundColor: kSlate700,
                side: BorderSide.none,
                backgroundColor: kSlate100,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('No, use a different Aadhaar',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    ),
  );
}

  // ─── Step 2 UI — Confirm masked number ─────────────────────────────────────

  Widget _buildConfirmStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kSlate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.shield_outlined, color: kPrimary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STEP 2 OF 3',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500, letterSpacing: 0.5)),
                      const SizedBox(height: 2),
                      const Text('Confirm mobile number',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: kSlate900)),
                      const SizedBox(height: 4),
                      Text('We\'ll send a secure verification code to the number below.',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kSlate100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('PRIMARY CONTACT',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500, letterSpacing: 0.5)),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, size: 18, color: kSlate600),
                      const SizedBox(width: 8),
                      Text('+91 ${_maskPhone(_precheckPhone)}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kSlate900)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Standard SMS charges may apply',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: kPrimary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(_error!, style: const TextStyle(fontSize: 13, color: kPrimary)),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _handleSendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                          SizedBox(width: 8),
                          Text('Sending code...', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.check_circle_outline, size: 18),
                          SizedBox(width: 8),
                          Text('Send OTP', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 1),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kSlate700,
                  side: const BorderSide(color: kSlate200),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Use a different number', style: TextStyle(fontWeight: FontWeight.w500)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  children: const [
                    TextSpan(text: 'Need help? Reach our support team at '),
                    TextSpan(
                      text: 'support@slfintech.in',
                      style: TextStyle(fontWeight: FontWeight.w600, color: kSlate700),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Step 3 UI — OTP entry ──────────────────────────────────────────────────

  Widget _buildOtpStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('OTP Verification',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kSlate900)),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.5),
              children: [
                const TextSpan(text: 'Enter the 6-digit verification code sent to\n'),
                TextSpan(
                  text: '+91 ${_phoneController.text}',
                  style: const TextStyle(fontWeight: FontWeight.w500, color: kSlate700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
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
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: _error != null ? kPrimary : kSlate200, width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBlue, width: 2),
                    ),
                  ),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  onChanged: (v) => _onOtpDigitChanged(i, v),
                ),
              );
            }),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 16, color: kPrimary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(_error!, style: const TextStyle(fontSize: 13, color: kPrimary)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Center(
            child: _canResend
                ? GestureDetector(
                    onTap: _loading ? null : _handleResendOtp,
                    child: _loading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2)),
                              const SizedBox(width: 8),
                              Text('Sending...', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                            ],
                          )
                        : const Text('Resend Verification Code',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: kBlue)),
                  )
                : Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      children: [
                        const TextSpan(text: 'Request new code in '),
                        TextSpan(
                          text: '${_resendTimer}s',
                          style: const TextStyle(fontWeight: FontWeight.w500, color: kBlue),
                        ),
                      ],
                    ),
                  ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
    );
  }
}

// ─── Form Section ─────────────────────────────────────────────────────────────

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
        Text(title,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w600, color: kSlate900)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(height: 24),
        ...children.map((child) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: child,
            )),
      ],
    );
  }
}
class _ClearOnBackspaceFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length < oldValue.text.length) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    return newValue;
  }
}

// ─── React Input Field ────────────────────────────────────────────────────────

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
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: kSlate700)),
        const SizedBox(height: 8),
        Stack(
          children: [
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
          ],
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

// ─── React Controlled Input Field ─────────────────────────────────────────────

class _ControlledInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String placeholder;
  final String? error;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final int? maxLength;
  final bool enabled;
  final void Function(String) onChanged;

  const _ControlledInputField({
    Key? key, required this.label, required this.controller,
    this.placeholder = '', this.error, this.keyboardType, this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
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
          textCapitalization: textCapitalization,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _displayLabel,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: value.isEmpty ? Colors.grey.shade400 : kSlate900,
                    ),
                    softWrap: true,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: Colors.grey.shade500),
                ),
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
                Center(
                  child: Container(
                    width: 48, height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(100)),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Select $label',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600, color: kSlate900)),
                const SizedBox(height: 12),
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
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFEF2F2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(opt['label'] ?? '',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected ? kPrimary : kSlate900)),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle,
                                color: kPrimary, size: 20),
                          ],
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

class _FileUploadField extends StatelessWidget {
  final String label;
  final File? value;
  final String? error;
  final bool enabled;
  final void Function(File) onChanged;
  final VoidCallback onRemove;

  const _FileUploadField({
    Key? key, required this.label, this.value, this.error,
    this.enabled = true,
    required this.onChanged, required this.onRemove,
  }) : super(key: key);

  String get _fileName => value != null ? value!.path.split('/').last : '';

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
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
          onTap: (!hasFile && enabled) ? () => _pickFile(context) : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                color: hasError
                    ? kPrimary
                    : (hasFile ? const Color(0xFF16A34A) : kSlate200),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: hasFile
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
                      if (enabled)
                        GestureDetector(
                          onTap: onRemove,
                          child: const Icon(Icons.close, size: 18, color: kPrimary),
                        ),
                    ],
                  )
                : Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
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
                      Text('PNG, JPG up to 5MB',
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

// ─── Document Field (local upload OR remote SecureImage preview) ─────────────

class _DocumentField extends StatelessWidget {
  final String label;
  final File? localFile;
  final String? remoteFilename;
  final String? error;
  final bool enabled;
  final void Function(File) onChanged;
  final VoidCallback onRemove;

  const _DocumentField({
    Key? key,
    required this.label,
    this.localFile,
    this.remoteFilename,
    this.error,
    this.enabled = true,
    required this.onChanged,
    required this.onRemove,
  }) : super(key: key);

  Future<void> _pickReplacement(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png'],
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
    final hasRemote = localFile == null &&
        remoteFilename != null &&
        remoteFilename!.isNotEmpty;

    if (hasRemote) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500, color: kSlate700)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF16A34A), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SecureImage(
                      folder: 'customers',
                      filename: remoteFilename!,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (enabled)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => _pickReplacement(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (error != null)
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

    // Fallback — normal local upload field (shown once a new file is picked,
    // either from scratch or as a replacement for the remote one above)
    return _FileUploadField(
      label: label,
      value: localFile,
      error: error,
      enabled: enabled,
      onChanged: onChanged,
      onRemove: onRemove,
    );
  }
}

// ─── Success Screen ───────────────────────────────────────────────────────────

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
  late ConfettiController _confettiControllerLeft;
  late ConfettiController _confettiControllerRight;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
    _confettiControllerLeft = ConfettiController(duration: const Duration(seconds: 2));
    _confettiControllerRight = ConfettiController(duration: const Duration(seconds: 2));
    _confettiControllerLeft.play();
    _confettiControllerRight.play();
    _autoCloseTimer = Timer(const Duration(seconds: 5), widget.onClose);
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _confettiControllerLeft.dispose();
    _confettiControllerRight.dispose();
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                    const Text('Congratulations!',
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold,
                            color: kSlate900)),
                    const SizedBox(height: 12),
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
        Positioned(
            left: 0,
            top: MediaQuery.of(context).size.height * 0.4,
            child: ConfettiWidget(
              confettiController: _confettiControllerLeft,
              blastDirection: 0,
              blastDirectionality: BlastDirectionality.directional,
              numberOfParticles: 22,
              gravity: 0.15,
              emissionFrequency: 0.02,
              minimumSize: const Size(3, 3),
              maximumSize: const Size(6, 6),
              colors: const [
                Color(0xFF93C5FD),
                Color(0xFF86EFAC),
                Color(0xFFFCD34D),
                Color(0xFFFCA5A5),
                Color(0xFFC4B5FD),
                Color(0xFFFDBA74),
                Color(0xFFA5F3FC),
              ],
              createParticlePath: (size) {
                final path = Path();
                path.addOval(Rect.fromCircle(
                  center: Offset(size.width / 2, size.height / 2),
                  radius: size.width / 2,
                ));
                return path;
              },
            ),
          ),
          // Right cannon
          Positioned(
            right: 0,
            top: MediaQuery.of(context).size.height * 0.4,
            child: ConfettiWidget(
              confettiController: _confettiControllerRight,
              blastDirection: pi,
              blastDirectionality: BlastDirectionality.directional,
              numberOfParticles: 22,
              gravity: 0.15,
              emissionFrequency: 0.02,
              minimumSize: const Size(3, 3),
              maximumSize: const Size(6, 6),
              colors: const [
                Color(0xFF93C5FD),
                Color(0xFF86EFAC),
                Color(0xFFFCD34D),
                Color(0xFFFCA5A5),
                Color(0xFFC4B5FD),
                Color(0xFFFDBA74),
                Color(0xFFA5F3FC),
              ],
              createParticlePath: (size) {
                final path = Path();
                path.addOval(Rect.fromCircle(
                  center: Offset(size.width / 2, size.height / 2),
                  radius: size.width / 2,
                ));
                return path;
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grid Painter ─────────────────────────────────────────────────────────────

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