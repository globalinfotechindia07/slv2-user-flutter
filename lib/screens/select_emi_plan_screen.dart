import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'package:file_picker/file_picker.dart';
import '../screens/home_screen.dart'; 
import '../widgets/success_screen.dart';

class SelectEmiPlanScreen extends StatefulWidget {
  final Map<String, dynamic> loanDetails;
  final Map<String, dynamic> userProfile;

  const SelectEmiPlanScreen({
    super.key,
    required this.loanDetails,
    required this.userProfile,
  });

  @override
  State<SelectEmiPlanScreen> createState() => _SelectEmiPlanScreenState();
}

class _SelectEmiPlanScreenState extends State<SelectEmiPlanScreen> {
  int _currentStep = 0;
  bool _loading = false;
  Map<String, String> _errors = {};
  _ToastData? _toast;

  static const List<String> _stepLabels = [
    'Select EMI Plan',
    'Bank Details',
    'Reference Details',
  ];

  // ── Form data ─────────────────────────────────────────────────────────────
  Map<String, dynamic>? _selectedEmiPlan;

  // Bank Details
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  String? _passbookDoc;
  String? _agreementDoc;
  String? _nachDoc;

  // Reference 1
  final _ref1NameCtrl = TextEditingController();
  final _ref1ContactCtrl = TextEditingController();
  String? _ref1AadharDoc;
  String? _ref1AadharDocBack;
  String? _ref1PanDoc;

  // Reference 2
  final _ref2NameCtrl = TextEditingController();
  final _ref2ContactCtrl = TextEditingController();
  String? _ref2AadharDoc;
  String? _ref2AadharDocBack;
  String? _ref2PanDoc;

  // OTP verification state
  _OtpState _ref1Otp = const _OtpState();
  _OtpState _ref2Otp = const _OtpState();
  final _ref1OtpCtrl = TextEditingController();
  final _ref2OtpCtrl = TextEditingController();
  bool _isSubmitted = false;

@override
void initState() {
  super.initState();
}

  @override
void dispose() {
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _ref1NameCtrl.dispose();
    _ref1ContactCtrl.dispose();
    _ref2NameCtrl.dispose();
    _ref2ContactCtrl.dispose();
    _ref1OtpCtrl.dispose();
    _ref2OtpCtrl.dispose();
    super.dispose();
  }

  // ── EMI Calculation — matches calculateEMI exactly ────────────────────────

  Map<String, dynamic> _calculateEmi(
    dynamic loanAmount,
    int tenureMonths,
    double interestRate,
    double processingFee, {
    String interestRateType = 'per_month',
    String interestRateMethod = 'flat',
    String processingFeeType = 'charged_separately',
  }) {
double principal = double.tryParse(
    loanAmount?.toString().replaceAll(',', '').replaceAll('₹', '').trim() ?? '0') ?? 0;
    final fee = processingFee;

    if (processingFeeType == 'added_to_loan') principal += fee;

    double monthlyRate;
    if (interestRateType == 'per_annum') {
      monthlyRate = interestRate / 12 / 100;
    } else {
      monthlyRate = interestRate / 100;
    }

    double emi = 0;
    double totalInterest = 0;
    double totalPayable = 0;

    if (interestRateMethod == 'flat') {
      totalInterest = principal * monthlyRate * tenureMonths;
      totalPayable = principal + totalInterest;
      emi = totalPayable / tenureMonths;
    } else {
      if (monthlyRate == 0) {
        emi = principal / tenureMonths;
        totalInterest = 0;
        totalPayable = principal;
      } else {
        final r = monthlyRate;
        final n = tenureMonths;
        final rawEmi =
            (principal * r * pow(1 + r, n)) / (pow(1 + r, n) - 1);
        emi = rawEmi.roundToDouble();
        totalPayable = emi * n;
        totalInterest = totalPayable - principal;
      }
    }

    double finalTotalPayable;
    double adjustedTotalInterest;
    final originalLoanAmount = double.tryParse(
        loanAmount?.toString().replaceAll(',', '').replaceAll('₹', '').trim() ?? '0') ?? 0;

    if (processingFeeType == 'charged_separately') {
      finalTotalPayable = totalPayable + fee;
      adjustedTotalInterest = totalInterest;
    } else {
      finalTotalPayable = totalPayable;
      adjustedTotalInterest = totalPayable - originalLoanAmount - fee;
    }

    return {
      'monthlyEMI': emi.round(),
      'totalInterest': adjustedTotalInterest.round(),
      'totalPayable': finalTotalPayable.round(),
      'processingFee': fee,
    };
  }

  // ── Generate EMI plans ────────────────────────────────────────────────────

  List<Map<String, dynamic>> _generateEmiPlans() {
    final d = widget.loanDetails;
    final minTenure = int.tryParse(d['min_tenure']?.toString() ?? '3') ?? 3;
    final maxTenure = int.tryParse(d['max_tenure']?.toString() ?? '12') ?? 12;
    final interestRate =
        double.tryParse(d['interest_rate']?.toString() ?? '0') ?? 0;
    final processingFee = double.tryParse(
            d['processing_fee']?.toString().replaceAll(',', '') ?? '0') ??
        0;

    final plans = <Map<String, dynamic>>[];
    for (int m = minTenure; m <= maxTenure; m++) {
      plans.add({
        'months': m,
        'interest': interestRate,
        'interestRateType': d['interestRateType'] ?? 'per_month',
        'interestRateMethod': d['interestRateMethod'] ?? 'flat',
        'processingFeeType': d['processingFeeType'] ?? 'charged_separately',
        'processingFee': processingFee,
      });
    }
    return plans;
  }

  String _formatCurrency(dynamic amount) {
    final val = double.tryParse(amount.toString()) ?? 0;
    return '₹${val.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  // ── Validation ────────────────────────────────────────────────────────────

  bool _validateStep() {
    final e = <String, String>{};

    switch (_currentStep) {
      case 0:
        if (_selectedEmiPlan == null) {
          e['selectedEmiPlan'] = 'Please select an EMI plan';
        }
        break;
      case 1:
        // Bank details validation (optional fields based on React code)
        break;
      case 2:
        if (_ref1NameCtrl.text.trim().isEmpty) {
          e['reference1Name'] = 'Reference 1 name is required';
        }
        if (_ref1ContactCtrl.text.trim().isEmpty) {
          e['reference1Contact'] = 'Reference 1 contact is required';
        } else if (!RegExp(r'^\d{10}$').hasMatch(_ref1ContactCtrl.text)) {
          e['reference1Contact'] = 'Enter a valid 10-digit contact number';
        }
        if (_ref1AadharDoc == null) {
          e['reference1AadharDoc'] =
              'Reference 1 Aadhar Front document is required';
        }
        if (_ref1AadharDocBack == null) {
          e['reference1AadharDocBack'] =
              'Reference 1 Aadhar Back document is required';
        }
        if (!_ref1Otp.verified) {
          e['reference1Contact'] =
              'Please verify reference 1 contact via OTP';
        }
        if (_ref1Otp.verified) {
          if (_ref2NameCtrl.text.trim().isEmpty) {
            e['reference2Name'] = 'Reference 2 name is required';
          }
          if (_ref2ContactCtrl.text.trim().isEmpty) {
            e['reference2Contact'] = 'Reference 2 contact is required';
          } else if (!RegExp(r'^\d{10}$').hasMatch(_ref2ContactCtrl.text)) {
            e['reference2Contact'] =
                'Enter a valid 10-digit contact number';
          }
          if (_ref2AadharDoc == null) {
            e['reference2AadharDoc'] =
                'Reference 2 Aadhar Front document is required';
          }
          if (_ref2AadharDocBack == null) {
            e['reference2AadharDocBack'] =
                'Reference 2 Aadhar Back document is required';
          }
          if (!_ref2Otp.verified) {
            e['reference2Contact'] =
                'Please verify reference 2 contact via OTP';
          }
        }
        break;
    }

    setState(() => _errors = e);
    return e.isEmpty;
  }

  // ── OTP handlers ──────────────────────────────────────────────────────────

  Future<void> _sendOtp(bool isRef1) async {
    final contactCtrl = isRef1 ? _ref1ContactCtrl : _ref2ContactCtrl;
    final nameCtrl = isRef1 ? _ref1NameCtrl : _ref2NameCtrl;
    final contact = contactCtrl.text.trim();
    final name = nameCtrl.text.trim();
    final contactKey = isRef1 ? 'reference1Contact' : 'reference2Contact';
    final nameKey = isRef1 ? 'reference1Name' : 'reference2Name';
    final aadharKey = isRef1 ? 'reference1AadharDoc' : 'reference2AadharDoc';
    final aadharBackKey =
        isRef1 ? 'reference1AadharDocBack' : 'reference2AadharDocBack';
    final aadharDoc = isRef1 ? _ref1AadharDoc : _ref2AadharDoc;
    final aadharDocBack = isRef1 ? _ref1AadharDocBack : _ref2AadharDocBack;

    // ── Name — require first and last name, same as admin dashboard ────────
    if (name.isEmpty) {
      setState(() => _errors = {..._errors, nameKey: 'Reference name is required'});
      return;
    }
    if (name.split(' ').where((s) => s.trim().isNotEmpty).length < 2) {
      setState(() => _errors = {
            ..._errors,
            nameKey: 'Please enter full name (first and last name)',
          });
      return;
    }

    // ── Contact format + duplicate checks ───────────────────────────────────
    if (!RegExp(r'^\d{10}$').hasMatch(contact)) {
      setState(() => _errors = {
            ..._errors,
            contactKey: 'Enter a valid 10-digit contact number',
          });
      return;
    }
    final applicantPhone = (widget.loanDetails['phone_number'] ??
        widget.loanDetails['phoneNumber'])
    ?.toString() ??
    '';
    if (applicantPhone.isNotEmpty && contact == applicantPhone) {
      setState(() => _errors = {
            ..._errors,
            contactKey: 'Reference contact cannot be same as applicant contact number',
          });
      return;
    }
    if (!isRef1 && contact == _ref1ContactCtrl.text.trim()) {
      setState(() => _errors = {
            ..._errors,
            contactKey: 'Reference 2 contact cannot be same as Reference 1 contact',
          });
      return;
    }

    // ── Documents must be uploaded before an OTP can be requested ──────────
    if (aadharDoc == null || aadharDocBack == null) {
      setState(() => _errors = {
            ..._errors,
            if (aadharDoc == null) aadharKey: 'Please upload Aadhar Front document',
            if (aadharDocBack == null)
              aadharBackKey: 'Please upload Aadhar Back document',
          });
      return;
    }

    setState(() => _loading = true);
    try {
      // ── Reference-count fraud check (mirrors admin dashboard) ────────────
      final checkResult = await ApiService.checkReferenceCount(contact);
      final checkSuccess = checkResult['success'] == true;
      if (!checkSuccess) {
        _showToast(
            checkResult['message'] ?? 'Failed to verify reference',
            isError: true);
        return;
      }
      final checkData = checkResult['data'] as Map<String, dynamic>?;
      final count = (checkResult['count'] as num?)?.toInt() ??
          (checkData?['count'] as num?)?.toInt() ??
          0;
      final maxAllowed = (checkResult['max_allowed'] as num?)?.toInt() ??
          (checkData?['max_allowed'] as num?)?.toInt() ??
          3;
      if (count >= maxAllowed) {
        setState(() => _errors = {
              ..._errors,
              contactKey:
                  'This number is already a reference for $count people (max $maxAllowed allowed)',
            });
        return;
      }

      // ── Send OTP ──────────────────────────────────────────────────────────
      final result = await ApiService.sendOtpReferenceVerification(contact);
      debugPrint('DEBUG sendOtpReferenceVerification result: $result');

      final success = result['success'] == true || result['status'] == 'success';
      if (success) {
        final data = result['data'] as Map<String, dynamic>?;
        final requestId = (data?['request_id'] ?? data?['requestId'] ?? result['request_id'])
                ?.toString() ??
            '';

        final devOtp = data?['otp'] ?? result['otp'];
        if (devOtp != null) {
          debugPrint('🔑 REFERENCE OTP CODE for $contact: $devOtp');
        }

        setState(() {
          if (isRef1) {
            _ref1Otp = _ref1Otp.copyWith(
              otpSent: true,
              resendCount: _ref1Otp.resendCount + 1,
              requestId: requestId,
            );
          } else {
            _ref2Otp = _ref2Otp.copyWith(
              otpSent: true,
              resendCount: _ref2Otp.resendCount + 1,
              requestId: requestId,
            );
          }
        });
      } else {
        _showToast(
            result['message'] ?? 'Failed to send OTP', isError: true);
      }
    } catch (e) {
      debugPrint('=== _sendOtp EXCEPTION: $e ===');
      _showToast('Failed to send OTP. Please try again.', isError: true);
    } finally {
      setState(() => _loading = false);
    }
  }
  Future<void> _verifyOtp(bool isRef1) async {
    final otpVal =
        isRef1 ? _ref1OtpCtrl.text : _ref2OtpCtrl.text;
    final requestId = isRef1 ? _ref1Otp.requestId : _ref2Otp.requestId;

    setState(() => _loading = true);
    try {
      final result = await ApiService.verifyOtp(requestId, otpVal);
      final success = result['success'] == true || result['status'] == 'success';
      if (success) {
        setState(() {
          if (isRef1) {
            _ref1Otp = _ref1Otp.copyWith(verified: true);
          } else {
            _ref2Otp = _ref2Otp.copyWith(verified: true);
          }
        });
      } else {
        setState(() => _errors = {
              ..._errors,
              isRef1
                  ? 'reference1OtpError'
                  : 'reference2OtpError':
                  result['message'] ?? 'Invalid OTP',
            });
      }
    } catch (e) {
      setState(() => _errors = {
            ..._errors,
            isRef1
                ? 'reference1OtpError'
                : 'reference2OtpError':
                'Failed to verify OTP. Please try again.',
          });
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> _handleNext() async {
    if (!_validateStep()) return;

    setState(() => _loading = true);
    try {
if (_currentStep == _stepLabels.length - 1) {
  debugPrint('=== DISBURSE PAYLOAD application_id: ${widget.loanDetails['application_id']} ===');
  debugPrint('=== FULL loanDetails KEYS: ${widget.loanDetails.keys.toList()} ===');
  final result = await ApiService.disburseLoan(
    applicationId: (widget.loanDetails['application_id'] ??
        widget.loanDetails['applicationId'])
    ?.toString() ??
    '',
    bankName: _bankNameCtrl.text,
    accountNumber: _accountNumberCtrl.text,
    ifscCode: _ifscCtrl.text,
    reference1Name: _ref1NameCtrl.text,
    reference1Contact: _ref1ContactCtrl.text,
    reference2Name: _ref2NameCtrl.text,
    reference2Contact: _ref2ContactCtrl.text,
    selectedEmiPlan: _selectedEmiPlan ?? {},
    userName: widget.userProfile['name']?.toString(),
    userDepartment: 'Customer',
    passbookDocPath: _passbookDoc,
    nachDocPath: _nachDoc,
    agreementDocPath: _agreementDoc,
    reference1AadharDocPath: _ref1AadharDoc,
    reference1AadharDocBackPath: _ref1AadharDocBack,
    reference1PanDocPath: _ref1PanDoc,
    reference2AadharDocPath: _ref2AadharDoc,
    reference2AadharDocBackPath: _ref2AadharDocBack,
    reference2PanDocPath: _ref2PanDoc,
  );

  if (result['success'] == true) {
  await ApiService.sendNotification(
    'You have successfully selected an EMI plan for Mobile Loan.',
    widget.userProfile['id'],
  );
  setState(() => _isSubmitted = true);
} else {
  _showToast(result['message'] ?? 'Failed to submit EMI plan', isError: true);
}
} else {
        setState(() => _currentStep++);
      }
    } catch (e) {
      _showToast(e.toString(), isError: true);
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

  // ── Toast ─────────────────────────────────────────────────────────────────

  void _showToast(String message, {bool isError = false}) {
    setState(() => _toast = _ToastData(message: message, isError: isError));
    Future.delayed(const Duration(seconds: 3),
        () => setState(() => _toast = null));
  }

  // ── Build ─────────────────────────────────────────────────────────────────

 @override
Widget build(BuildContext context) {
  if (_isSubmitted) {
    return SuccessScreen(
      title: 'Congratulations!',
      message: 'EMI plan successfully selected for '
          '${widget.loanDetails['full_name'] ?? widget.loanDetails['fullName'] ?? ''}',
      onClose: () {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen(initialTab: 2)),
          (_) => false,
        );
      },
    );
  }
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
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // Main layout
          SafeArea(
            child: Column(
              children: [
                // ── Header ──────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.80),
                    border: const Border(
                      bottom: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            // Back button
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
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF475569))),
                                ],
                              ),
                            ),

                            // Title
                            Text(
                              widget.loanDetails['pstitle']?.toString() ?? 'Mobile Loan Service',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F172A),
                              ),
                            ),

                            // Help icon
                            GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(999),
                                ),
                                child: const Icon(Icons.help_outline,
                                    size: 24,
                                    color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Step indicator
                      _StepIndicator(
                        currentStep: _currentStep,
                        totalSteps: _stepLabels.length,
                      ),
                    ],
                  ),
                ),

                // ── Scrollable content ───────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: _buildCurrentStep(),
                  ),
                ),

                // ── Footer button ────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.80),
                    border: const Border(
                      top: BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: _NextButton(
                    loading: _loading,
                    text: _currentStep == _stepLabels.length - 1
                        ? 'Submit Application'
                        : 'Next',
                    onTap: _handleNext,
                  ),
                ),
              ],
            ),
          ),
// // Left cannon
// Positioned(
//   left: 0,
//   top: MediaQuery.of(context).size.height * 0.4,
//   child: ConfettiWidget(
//     confettiController: _confettiControllerLeft,
//     blastDirection: 0,
//     blastDirectionality: BlastDirectionality.directional,
//     numberOfParticles: 22,
//     gravity: 0.15,
//     emissionFrequency: 0.02,
//     minimumSize: const Size(3, 3),
//     maximumSize: const Size(6, 6),
//     colors: const [
//       Color(0xFF93C5FD), // light blue
//       Color(0xFF86EFAC), // light green
//       Color(0xFFFCD34D), // light yellow
//       Color(0xFFFCA5A5), // light pink
//       Color(0xFFC4B5FD), // light purple
//       Color(0xFFFDBA74), // light orange
//       Color(0xFFA5F3FC), // light cyan
//     ],
//     createParticlePath: (size) {
//       final path = Path();
//       path.addOval(Rect.fromCircle(
//         center: Offset(size.width / 2, size.height / 2),
//         radius: size.width / 2,
//       ));
//       return path;
//     },
//   ),
// ),

// // Right cannon
// Positioned(
//   right: 0,
//   top: MediaQuery.of(context).size.height * 0.4,
//   child: ConfettiWidget(
//     confettiController: _confettiControllerRight,
//     blastDirection: pi,
//     blastDirectionality: BlastDirectionality.directional,
//     numberOfParticles: 22,
//     gravity: 0.15,
//     emissionFrequency: 0.02,
//     minimumSize: const Size(3, 3),
//     maximumSize: const Size(6, 6),
//     colors: const [
//       Color(0xFF93C5FD), // light blue
//       Color(0xFF86EFAC), // light green
//       Color(0xFFFCD34D), // light yellow
//       Color(0xFFFCA5A5), // light pink
//       Color(0xFFC4B5FD), // light purple
//       Color(0xFFFDBA74), // light orange
//       Color(0xFFA5F3FC), // light cyan
//     ],
//     createParticlePath: (size) {
//       final path = Path();
//       path.addOval(Rect.fromCircle(
//         center: Offset(size.width / 2, size.height / 2),
//         radius: size.width / 2,
//       ));
//       return path;
//     },
//   ),
// ),       
          // Toast
          if (_toast != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _ToastWidget(
                data: _toast!,
                onClose: () => setState(() => _toast = null),
              ),
            ),
        ],
      ),
    );
  }
  

  // ── Step builders ─────────────────────────────────────────────────────────

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep0();
      case 1:
        return _buildStep1();
      case 2:
        return _buildStep2();
      default:
        return const SizedBox();
    }
  }

  // ── Step 0: EMI Plan selection ────────────────────────────────────────────

  Widget _buildStep0() {
    final plans = _generateEmiPlans();
    return _FormSection(
      title: 'Select EMI Plan',
      subtitle: 'Choose an EMI plan that suits your financial needs',
      child: Column(
        children: [
          if (_errors['selectedEmiPlan'] != null)
            _ErrorRow(message: _errors['selectedEmiPlan']!),
          ...plans.map((plan) {
            final emiResult = _calculateEmi(
              widget.loanDetails['approved_limit'],
              plan['months'] as int,
              (plan['interest'] as num).toDouble(),
              (plan['processingFee'] as num).toDouble(),
              interestRateType: plan['interestRateType'] ?? 'per_month',
              interestRateMethod: plan['interestRateMethod'] ?? 'flat',
              processingFeeType:
                  plan['processingFeeType'] ?? 'charged_separately',
            );
            final isSelected =
                _selectedEmiPlan?['months'] == plan['months'];
            return GestureDetector(
              onTap: () => setState(() => _selectedEmiPlan = {
                    ...plan,
                    ...emiResult,
                  }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFFEFF6FF)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2563EB)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        // Radio button
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFD1D5DB),
                              width: 2,
                            ),
                            color: isSelected
                                ? const Color(0xFF2563EB)
                                : Colors.white,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  size: 12, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${plan['months']} Months',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: _formatCurrency(
                                    emiResult['monthlyEMI']),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const TextSpan(
                                text: '/m',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Total: ${_formatCurrency(emiResult['monthlyEMI'] * plan['months'])}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ── Step 1: Bank Details ──────────────────────────────────────────────────

  Widget _buildStep1() {
    return _FormSection(
      title: 'Bank Details',
      subtitle: 'Provide your bank account information',
      child: Column(
        children: [
          _InputField(
            label: 'Bank Name',
            controller: _bankNameCtrl,
            hint: 'Enter your bank name',
            error: _errors['bankName'],
            onChanged: (_) =>
                setState(() => _errors.remove('bankName')),
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'Account Number',
            controller: _accountNumberCtrl,
            hint: 'Enter your account number',
            keyboardType: TextInputType.number,
            error: _errors['accountNumber'],
            onChanged: (_) =>
                setState(() => _errors.remove('accountNumber')),
          ),
          const SizedBox(height: 16),
          _InputField(
            label: 'IFSC Code',
            controller: _ifscCtrl,
            hint: 'Enter IFSC code',
            textCapitalization: TextCapitalization.characters,
            error: _errors['ifscCode'],
            onChanged: (_) =>
                setState(() => _errors.remove('ifscCode')),
          ),
          const SizedBox(height: 16),
          _FileUploadField(
            label: 'Bank Passbook',
            value: _passbookDoc,
            error: _errors['passbookDoc'],
            onPick: (name) =>
                setState(() => _passbookDoc = name),
            onRemove: () => setState(() => _passbookDoc = null),
          ),
          const SizedBox(height: 16),
          _FileUploadField(
            label: 'Loan Agreement Document',
            value: _agreementDoc,
            error: _errors['agreementDoc'],
            onPick: (name) =>
                setState(() => _agreementDoc = name),
            onRemove: () => setState(() => _agreementDoc = null),
          ),
          const SizedBox(height: 16),
          _FileUploadField(
            label: 'NACH Document',
            value: _nachDoc,
            error: _errors['nachDoc'],
            onPick: (name) => setState(() => _nachDoc = name),
            onRemove: () => setState(() => _nachDoc = null),
          ),
        ],
      ),
    );
  }

  // ── Step 2: Reference Details ─────────────────────────────────────────────

  Widget _buildStep2() {
    return _FormSection(
      title: 'Reference Details',
      subtitle: 'Add references for verification',
      child: Column(
        children: [
          // Reference 1
          _ReferenceSection(
            title: 'Reference 1',
            nameCtrl: _ref1NameCtrl,
            contactCtrl: _ref1ContactCtrl,
            otpCtrl: _ref1OtpCtrl,
            aadharDoc: _ref1AadharDoc,
            aadharDocBack: _ref1AadharDocBack,
            panDoc: _ref1PanDoc,
            otpState: _ref1Otp,
            errors: _errors,
            nameKey: 'reference1Name',
            contactKey: 'reference1Contact',
            aadharKey: 'reference1AadharDoc',
            aadharBackKey: 'reference1AadharDocBack',
            panKey: 'reference1PanDoc',
            otpErrorKey: 'reference1OtpError',
            disabled: false,
            onAadharPick: (name) =>
                setState(() => _ref1AadharDoc = name),
            onAadharRemove: () =>
                setState(() => _ref1AadharDoc = null),
            onAadharBackPick: (name) =>
                setState(() => _ref1AadharDocBack = name),
            onAadharBackRemove: () =>
                setState(() => _ref1AadharDocBack = null),
            onPanPick: (name) =>
                setState(() => _ref1PanDoc = name),
            onPanRemove: () => setState(() => _ref1PanDoc = null),
            onSendOtp: () => _sendOtp(true),
            onVerifyOtp: () => _verifyOtp(true),
            onOtpChanged: (_) =>
                setState(() => _errors.remove('reference1OtpError')),
            onNameChanged: (_) =>
                setState(() => _errors.remove('reference1Name')),
            onContactChanged: (_) =>
                setState(() => _errors.remove('reference1Contact')),
          ),

          // Reference 2 — shown only after Reference 1 is verified
          if (_ref1Otp.verified) ...[
            const SizedBox(height: 20),
            _ReferenceSection(
              title: 'Reference 2',
              nameCtrl: _ref2NameCtrl,
              contactCtrl: _ref2ContactCtrl,
              otpCtrl: _ref2OtpCtrl,
              aadharDoc: _ref2AadharDoc,
              aadharDocBack: _ref2AadharDocBack,
              panDoc: _ref2PanDoc,
              otpState: _ref2Otp,
              errors: _errors,
              nameKey: 'reference2Name',
              contactKey: 'reference2Contact',
              aadharKey: 'reference2AadharDoc',
              aadharBackKey: 'reference2AadharDocBack',
              panKey: 'reference2PanDoc',
              otpErrorKey: 'reference2OtpError',
              disabled: false,
              onAadharPick: (name) =>
                  setState(() => _ref2AadharDoc = name),
              onAadharRemove: () =>
                  setState(() => _ref2AadharDoc = null),
              onAadharBackPick: (name) =>
                  setState(() => _ref2AadharDocBack = name),
              onAadharBackRemove: () =>
                  setState(() => _ref2AadharDocBack = null),
              onPanPick: (name) =>
                  setState(() => _ref2PanDoc = name),
              onPanRemove: () =>
                  setState(() => _ref2PanDoc = null),
              onSendOtp: () => _sendOtp(false),
              onVerifyOtp: () => _verifyOtp(false),
              onOtpChanged: (_) =>
                  setState(() => _errors.remove('reference2OtpError')),
              onNameChanged: (_) =>
                  setState(() => _errors.remove('reference2Name')),
              onContactChanged: (_) =>
                  setState(() => _errors.remove('reference2Contact')),
            ),
          ],
        ],
      ),
    );
  }
}

// ── OTP State ─────────────────────────────────────────────────────────────────

class _OtpState {
  final bool verified;
  final bool otpSent;
  final int resendCount;
  final String requestId;

  const _OtpState({
    this.verified = false,
    this.otpSent = false,
    this.resendCount = 0,
    this.requestId = '',
  });

  _OtpState copyWith({
    bool? verified,
    bool? otpSent,
    int? resendCount,
    String? requestId,
  }) {
    return _OtpState(
      verified: verified ?? this.verified,
      otpSent: otpSent ?? this.otpSent,
      resendCount: resendCount ?? this.resendCount,
      requestId: requestId ?? this.requestId,
    );
  }
}

// ── Toast Data ────────────────────────────────────────────────────────────────

class _ToastData {
  final String message;
  final bool isError;
  const _ToastData({required this.message, required this.isError});
}

// ── Step Indicator ────────────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _StepIndicator(
      {required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    final pct = ((currentStep + 1) / totalSteps * 100).round();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Step ${currentStep + 1}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151))),
                  const SizedBox(width: 4),
                  Text('of $totalSteps',
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B7280))),
                ],
              ),
              Text('$pct%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2563EB),
                  )),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / totalSteps,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2563EB)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Form Section ──────────────────────────────────────────────────────────────

class _FormSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _FormSection(
      {required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF475569))),
        const SizedBox(height: 24),
        child,
      ],
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
  final bool enabled;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.label,
    required this.controller,
    this.hint,
    this.error,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
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
          enabled: enabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                const TextStyle(color: Color(0xFF94A3B8)),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF8FAFC),
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
                  color: Color(0xFF3B82F6), width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFE2E8F0), width: 2),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          _ErrorRow(message: error!),
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
  final bool disabled;

  const _FileUploadField({
    required this.label,
    required this.onPick,
    required this.onRemove,
    this.value,
    this.error,
    this.disabled = false,
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
       // REPLACE WITH:
GestureDetector(
  onTap: disabled
      ? null
      : () async {
          final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
          );
          if (result != null && result.files.single.path != null) {
            onPick(result.files.single.path!);
          }
        },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: disabled
                  ? const Color(0xFFF8FAFC)
                  : Colors.white,
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
                      const Icon(Icons.insert_drive_file_outlined,
                          color: Color(0xFF3B82F6), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(value!,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF0F172A))),
                      ),
                      if (!disabled)
                        GestureDetector(
                          onTap: onRemove,
                          child: const Icon(Icons.close,
                              size: 18, color: Color(0xFF94A3B8)),
                        ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.upload_outlined,
                          color: Color(0xFF94A3B8), size: 20),
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
          _ErrorRow(message: error!),
        ],
      ],
    );
  }
}

// ── Reference Section ─────────────────────────────────────────────────────────

class _ReferenceSection extends StatelessWidget {
  final String title;
  final TextEditingController nameCtrl;
  final TextEditingController contactCtrl;
  final TextEditingController otpCtrl;
  final String? aadharDoc;
  final String? aadharDocBack;
  final String? panDoc;
  final _OtpState otpState;
  final Map<String, String> errors;
  final String nameKey;
  final String contactKey;
  final String aadharKey;
  final String aadharBackKey;
  final String panKey;
  final String otpErrorKey;
  final bool disabled;
  final ValueChanged<String> onAadharPick;
  final VoidCallback onAadharRemove;
  final ValueChanged<String> onAadharBackPick;
  final VoidCallback onAadharBackRemove;
  final ValueChanged<String> onPanPick;
  final VoidCallback onPanRemove;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final ValueChanged<String>? onOtpChanged;
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<String>? onContactChanged;

  const _ReferenceSection({
    required this.title,
    required this.nameCtrl,
    required this.contactCtrl,
    required this.otpCtrl,
    required this.otpState,
    required this.errors,
    required this.nameKey,
    required this.contactKey,
    required this.aadharKey,
    required this.aadharBackKey,
    required this.panKey,
    required this.otpErrorKey,
    required this.onAadharPick,
    required this.onAadharRemove,
    required this.onAadharBackPick,
    required this.onAadharBackRemove,
    required this.onPanPick,
    required this.onPanRemove,
    required this.onSendOtp,
    required this.onVerifyOtp,
    this.aadharDoc,
    this.aadharDocBack,
    this.panDoc,
    this.disabled = false,
    this.onOtpChanged,
    this.onNameChanged,
    this.onContactChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E40AF))),
          const SizedBox(height: 14),

          _InputField(
            label: 'Name',
            controller: nameCtrl,
            hint: 'Enter $title name',
            error: errors[nameKey],
            enabled: !otpState.verified,
            onChanged: onNameChanged,
          ),
          const SizedBox(height: 12),

          _FileUploadField(
            label: 'Aadhar Front Document',
            value: aadharDoc,
            error: errors[aadharKey],
            onPick: onAadharPick,
            onRemove: onAadharRemove,
            disabled: otpState.verified,
          ),
          const SizedBox(height: 12),

          _FileUploadField(
            label: 'Aadhar Back Document',
            value: aadharDocBack,
            error: errors[aadharBackKey],
            onPick: onAadharBackPick,
            onRemove: onAadharBackRemove,
            disabled: otpState.verified,
          ),
          const SizedBox(height: 12),

          _FileUploadField(
            label: 'PAN Document',
            value: panDoc,
            error: errors[panKey],
            onPick: onPanPick,
            onRemove: onPanRemove,
            disabled: otpState.verified,
          ),
          const SizedBox(height: 12),

          _InputField(
            label: 'Contact Number',
            controller: contactCtrl,
            hint: 'Enter 10-digit contact number',
            keyboardType: TextInputType.phone,
            error: errors[contactKey],
            enabled: !otpState.verified,
            onChanged: onContactChanged,
          ),
          const SizedBox(height: 10),

          // Send OTP button
          if (!otpState.verified)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: otpState.otpSent ? null : onSendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: otpState.otpSent
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(otpState.otpSent ? 'OTP Sent' : 'Send OTP'),
              ),
            ),

          // OTP input + verify
          if (otpState.otpSent && !otpState.verified) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user,
                      size: 18, color: Color(0xFF16A34A)),
                  const SizedBox(width: 8),
                  Text(
                    'OTP sent to ${contactCtrl.text}'
                    '${otpState.resendCount > 0 ? ' (Resent ${otpState.resendCount} time${otpState.resendCount > 1 ? 's' : ''})' : ''}',
                    style: const TextStyle(
                        fontSize: 12, color: Color(0xFF166534)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _InputField(
              label: 'Enter OTP',
              controller: otpCtrl,
              hint: 'Enter 6-digit OTP',
              keyboardType: TextInputType.number,
              error: errors[otpErrorKey],
              onChanged: onOtpChanged,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onVerifyOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Verify OTP'),
                  ),
                ),
                if (otpState.resendCount < 3) ...[
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: onSendOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5E7EB),
                      foregroundColor: const Color(0xFF374151),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Icon(Icons.refresh, size: 20),
                  ),
                ],
              ],
            ),
            if (otpState.resendCount >= 3)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Maximum resend attempts reached. Please contact support.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFFEF4444)),
                ),
              ),
          ],

          // Verified badge
          if (otpState.verified)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF86EFAC)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.check_circle,
                      size: 18, color: Color(0xFF16A34A)),
                  SizedBox(width: 8),
                  Text('Contact verified successfully',
                      style: TextStyle(
                          fontSize: 13, color: Color(0xFF166534))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Next Button ───────────────────────────────────────────────────────────────

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
        transform: Matrix4.identity()..scale(_pressed ? 1.02 : 1.0),
        transformAlignment: Alignment.center,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _pressed
              ? const Color(0xFF1E3A8A)
              : const Color(0xFF1E40AF),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E40AF).withOpacity(0.30),
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
                        strokeWidth: 2, color: Colors.white),
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

// ── Toast Widget ──────────────────────────────────────────────────────────────

class _ToastWidget extends StatelessWidget {
  final _ToastData data;
  final VoidCallback onClose;
  const _ToastWidget({required this.data, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: data.isError
            ? const Color(0xFFFEF2F2)
            : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: data.isError
                ? const Color(0xFFEF4444)
                : const Color(0xFF22C55E),
            width: 4,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            data.isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 20,
            color: data.isError
                ? const Color(0xFFDC2626)
                : const Color(0xFF16A34A),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              data.message,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: data.isError
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF166534),
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Icon(
              Icons.close,
              size: 18,
              color: data.isError
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF166534),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error Row ─────────────────────────────────────────────────────────────────

class _ErrorRow extends StatelessWidget {
  final String message;
  const _ErrorRow({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 14, color: Color(0xFFEF4444)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFFEF4444)),
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