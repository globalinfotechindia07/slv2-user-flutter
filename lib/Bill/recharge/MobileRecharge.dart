import 'dart:convert';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:confetti/confetti.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../theme/app_theme.dart';

// const String _kApiBase = 'http://localhost/backend';
// const String _razorpayKey =
//     String.fromEnvironment('RAZORPAY_KEY', defaultValue: 'rzp_test_XXXXXXXXXXXX');

// ── Image asset paths ───────────────────────────────────────────────────
// In the original React file these were imported (fd1.png, fd22.png, etc.)
// but the carousel block that used them was commented out, and the
// `slides` variable it referenced was never even defined in that file —
// so the imports were unused dead code there too. Kept here as named
// constants (matching your assets/images/ folder) in case you want to
// re-enable a promo carousel on this screen later.
class SlideAssets {
  static const fd1 = 'assets/images/fd1.png';
  static const fd22 = 'assets/images/fd22.png';
  static const fd33 = 'assets/images/fd33.png';
  static const s1 = 'assets/images/s1.png';
  static const s2 = 'assets/images/s2.png';
  static const s3 = 'assets/images/s3.png';
  static const d1 = 'assets/images/d1.png';
  static const d2 = 'assets/images/d2.png';
  static const d3 = 'assets/images/d3.png';
  static const i1 = 'assets/images/i1.png';
  static const i2 = 'assets/images/i2.png';
  static const i3 = 'assets/images/i3.png';
  static const l1 = 'assets/images/l1.png';
  static const l2 = 'assets/images/l2.png';
  static const sk1 = 'assets/images/sk1.png';
  static const sk2 = 'assets/images/sk2.png';
}

// ── Models ──────────────────────────────────────────────────────────────

class OperatorModel {
  final String id;
  final String name;
  final String category;

  OperatorModel({required this.id, required this.name, required this.category});

  factory OperatorModel.fromJson(Map<String, dynamic> json) {
    return OperatorModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
    );
  }
}

class PlanModel {
  final String rs;
  final String validity;
  final String desc;
  final String lastUpdate;
  final String? dataBenefit;
  final String? voiceBenefit;
  final String? smsBenefit;

  PlanModel({
    required this.rs,
    required this.validity,
    required this.desc,
    required this.lastUpdate,
    this.dataBenefit,
    this.voiceBenefit,
    this.smsBenefit,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      rs: json['rs']?.toString() ?? '0',
      validity: json['validity']?.toString() ?? '',
      desc: json['desc']?.toString() ?? '',
      lastUpdate: json['last_update']?.toString() ?? '',
      dataBenefit: json['data_benefit']?.toString(),
      voiceBenefit: json['voice_benefit']?.toString(),
      smsBenefit: json['sms_benefit']?.toString(),
    );
  }
}

// ── Main Screen ─────────────────────────────────────────────────────────

class MobileRechargeScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  // Unused in the original React file beyond being destructured — kept
  // here only for parity / future use.
  final Map<String, dynamic>? serviceDetails;

  const MobileRechargeScreen({
    super.key,
    required this.userProfile,
    this.serviceDetails,
  });

  @override
  State<MobileRechargeScreen> createState() => _MobileRechargeScreenState();
}

class _MobileRechargeScreenState extends State<MobileRechargeScreen> {
  // Circles (matches React `circles` constant)
  static const List<String> _circles = [
    'Andhra Pradesh Telangana',
    'Assam',
    'Bihar Jharkhand',
    'Chennai',
    'Delhi NCR',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jammu Kashmir',
    'Karnataka',
    'Kerala',
    'Kolkata',
    'Madhya Pradesh Chhattisgarh',
    'Maharashtra Goa',
    'Mumbai',
    'North East',
    'Orissa',
    'Punjab',
    'Rajasthan',
    'Tamil Nadu',
    'UP East',
    'UP West',
    'West Bengal',
  ];

  final TextEditingController _mobileCtrl = TextEditingController();

  String _operatorId = '';
  String _circle = '';
  String _amount = '';

  Map<String, String> _errors = {};
  bool _loading = false;
  bool _isFaqOpen = false;
  Map<String, dynamic>? _isSubmitted;

  OperatorModel? _selectedOperator;
  Map<String, List<PlanModel>>? _plans;
  int _step = 1; // 1 = enter details, 2 = select plan, 3 = payment
  String _searchQuery = '';
  bool _autoAdvance = true;
  bool _hasInteracted = false;
  bool _loadingPlans = false;
  String _activeTab = 'TOPUP';
  PlanModel? _selectedPlan;
  int? _planId;
  bool _isPlanDetailsOpen = false;

  bool _processingRecharge = false;
  Map<String, dynamic>? _rechargeStatus;

  List<OperatorModel> _operators = [];
  // NOTE: in the original React file, `operatorsLoaded` is initialized to
  // false and `setOperatorsLoaded` is never called anywhere — so it always
  // stays false. That made `operatorsLoaded ? <Loader/> : ...` always fall
  // through to the operator list branch. Kept identically here for parity;
  // this field currently has no effect on the UI.
  // ignore: unused_field
  bool _operatorsLoaded = false;

  late final Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchOperators();
  }

  @override
  void dispose() {
    _mobileCtrl.dispose();
    _razorpay.clear();
    super.dispose();
  }

  // ── API calls ────────────────────────────────────────────────────────

  Future<void> _fetchOperators() async {
    try {
      final data = await ApiService.getOperators();
      if (data['data'] is List) {
        setState(() {
          _operators = (data['data'] as List)
              .map((e) => OperatorModel.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching operators: $e');
    }
  }

  Future<bool> _checkHLR(String mobileNumber) async {
    try {
      if (_operators.isEmpty) {
        debugPrint('Waiting for operators data...');
        return false;
      }

      final data = await ApiService.checkHlr(mobileNumber);

      if (data['status'] == true && data['info'] != null) {
        final info = data['info'] as Map<String, dynamic>;
        final operatorName = (info['operator'] ?? '').toString();
        final circle = (info['circle'] ?? '').toString();

        OperatorModel? matched;
        for (final op in _operators) {
          if (op.name.toLowerCase() == operatorName.toLowerCase()) {
            matched = op;
            break;
          }
        }

        if (matched != null) {
          setState(() {
            _selectedOperator = matched;
            _operatorId = matched!.id;
            _circle = circle;
            _autoAdvance = true;
          });
          return true;
        } else {
          debugPrint('Operator not found in available operators: $operatorName');
        }
      }
      return false;
    } catch (e) {
      debugPrint('HLR Check failed: $e');
      return false;
    }
  }

  Future<void> _fetchPlans() async {
    if (_operatorId.isEmpty || _circle.isEmpty) return;
    setState(() => _loadingPlans = true);
    try {
      final data = await ApiService.browsePlans(
        circle: _circle,
        operatorName: _selectedOperator?.name,
      );

      if (data['status'] == true && data['info'] != null) {
        final Map<String, dynamic> infoRaw = data['info'];
        final Map<String, List<PlanModel>> parsed = {};
        infoRaw.forEach((key, value) {
          if (value is List) {
            parsed[key] = value
                .map((p) => PlanModel.fromJson(p as Map<String, dynamic>))
                .toList();
          }
        });

        String firstCategory = '';
        for (final entry in parsed.entries) {
          if (entry.value.isNotEmpty) {
            firstCategory = entry.key;
            break;
          }
        }

        setState(() {
          _plans = parsed;
          if (firstCategory.isNotEmpty) _activeTab = firstCategory;
        });
      }
    } catch (e) {
      debugPrint('Error fetching plans: $e');
    } finally {
      setState(() => _loadingPlans = false);
    }
  }

  // ── Input handlers / validation ─────────────────────────────────────

  Future<void> _handleMobileChanged(String value) async {
    if (!_autoAdvance) setState(() => _autoAdvance = true);
    if (!_hasInteracted) setState(() => _hasInteracted = true);
    setState(() => _errors.remove('mobile'));

    if (value.length == 10) {
      setState(() => _loading = true);
      final success = await _checkHLR(value);
      setState(() => _loading = false);
      if (!success) {
        setState(() => _autoAdvance = false);
      }
    }

    _maybeAutoAdvance();
  }

  void _handleOperatorSelect(OperatorModel operator) {
    setState(() {
      _selectedOperator = operator;
      _operatorId = operator.id;
      _errors.remove('operator');
    });
    _maybeAutoAdvance();
  }

  // Mirrors the React useEffect that watches mobile/operator/circle and
  // auto-advances from step 1 to step 2 once all three are valid.
  void _maybeAutoAdvance() {
    if (_step != 1 || !_autoAdvance || !_hasInteracted) return;
    final mobileValid = RegExp(r'^\d{10}$').hasMatch(_mobileCtrl.text);
    if (mobileValid && _operatorId.isNotEmpty && _circle.isNotEmpty) {
      setState(() => _step = 2);
      _fetchPlans();
    }
  }

  bool _validateDetails() {
    if (!_hasInteracted) return true;
    final e = <String, String>{};
    if (!RegExp(r'^\d{10}$').hasMatch(_mobileCtrl.text)) {
      e['mobile'] = 'Enter valid 10-digit mobile number';
    }
    if (_operatorId.isEmpty) e['operator'] = 'Operator is required';
    if (_circle.isEmpty) e['circle'] = 'Circle is required';
    setState(() => _errors = e);
    return e.isEmpty;
  }

  bool _validateForm() {
    final e = <String, String>{};
    if (!RegExp(r'^\d{10}$').hasMatch(_mobileCtrl.text)) {
      e['mobile'] = 'Enter valid 10-digit mobile number';
    }
    if (_operatorId.isEmpty) e['operator'] = 'Operator is required';
    if (_circle.isEmpty) e['circle'] = 'Circle is required';
    setState(() => _errors = e);
    return e.isEmpty;
  }

  // Present in the React source as a standalone handler, though no button
  // there directly calls it (the UI relies on auto-advance instead). Kept
  // for parity — wire a "Continue" button to this if you need a manual
  // fallback.
  void _handleContinue() {
    if (!_validateDetails()) return;
    setState(() => _step = 2);
    _fetchPlans();
  }

  // ── Razorpay payment flow ───────────────────────────────────────────

  Future<void> _handleRazorpayPayment() async {
    if (!_validateForm()) return;
    setState(() => _loading = true);
    try {
      final orderData = await ApiService.createRechargeOrder(
        activeTab: _activeTab,
        planId: _planId,
        amount: _amount,
        circle: _circle,
        operatorName: _selectedOperator?.name,
        mobileNumber: _mobileCtrl.text,
      );

      if (orderData['error'] != null) {
        setState(() => _loading = false);
        _showAlert(orderData['error'].toString());
        return;
      }

      final orderId = orderData['id'].toString();
      final amountPaise = orderData['amount'];
      final currency = orderData['currency'] ?? 'INR';

      final options = {
        'key': ApiConstants.razorpayKey,
        'amount': amountPaise.toString(),
        'currency': currency,
        'name': 'Shubhlabh App',
        'description': 'Mobile Recharge Payment',
        'order_id': orderId,
        'prefill': {
          'contact': _mobileCtrl.text,
          'email': widget.userProfile['email'] ?? '',
          'name': widget.userProfile['name'] ?? '',
        },
        'theme': {'color': '#E53935'},
      };

      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay order error: $e');
      _showAlert('Could not start payment. Please try again.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _processingRecharge = true;
      _rechargeStatus = {'step': 1, 'message': 'Verifying your payment...'};
    });

    try {
      final data = await ApiService.verifyRechargePayment(
        razorpayPaymentId: response.paymentId ?? '',
        razorpayOrderId: response.orderId ?? '',
        razorpaySignature: response.signature ?? '',
      );

      if (data['success'] == true && data['payment_verified'] == true) {
        setState(() => _rechargeStatus = {
              'step': 2,
              'message': 'Payment verified, initiating recharge...',
            });
        await Future.delayed(const Duration(milliseconds: 1500));

        if (data['recharge_status'] == 'completed') {
          setState(() => _rechargeStatus = {'step': 3, 'message': 'Recharge confirmed!'});
          await Future.delayed(const Duration(seconds: 1));

          if (!mounted) return;
          setState(() {
            _processingRecharge = false;
            _isSubmitted = {
              'message': data['recharge_message'],
              'operator': data['operator'],
              'mobile': data['mobile_number'],
              'amount': data['amount'],
              'referenceId': data['reference_id'],
            };
          });
        } else {
          setState(() => _rechargeStatus = {
                'step': 'error',
                'message': 'Recharge failed. Please contact support.',
              });
          await Future.delayed(const Duration(seconds: 2));
          if (!mounted) return;
          setState(() => _processingRecharge = false);
          _showAlert('Recharge failed. Please contact support.');
        }
      } else {
        setState(() => _rechargeStatus = {
              'step': 'error',
              'message': 'Payment verification failed!',
            });
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        setState(() => _processingRecharge = false);
        _showAlert('Payment verification failed!');
      }
    } catch (e) {
      setState(() => _rechargeStatus = {
            'step': 'error',
            'message': 'An error occurred during verification',
          });
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      setState(() => _processingRecharge = false);
      _showAlert('An error occurred during verification!');
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _loading = false);
    _showAlert('Payment failed: ${response.message ?? "Unknown error"}');
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() => _loading = false);
  }

  void _showAlert(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  // ── Small render helper (matches React renderOperatorIcon) ─────────

  Widget _renderOperatorIcon(String? name, String? category) {
    final n = (name ?? '').toLowerCase();
    if (category == 'DTH') {
      return const Icon(Icons.tv, size: 24, color: AppColors.primary);
    }
    if (n.contains('bsnl') || n.contains('mtnl')) {
      return const Icon(Icons.radio, size: 24, color: AppColors.primary);
    }
    return const Icon(Icons.smartphone, size: 24, color: AppColors.primary);
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_processingRecharge) {
      return _ProcessingScreen(status: _rechargeStatus);
    }

    if (_isSubmitted != null) {
      return _SuccessScreen(
        onClose: () {
          setState(() => _isSubmitted = null);
          Navigator.pop(context);
        },
        message: _isSubmitted!['message']?.toString(),
        operatorName: _isSubmitted!['operator']?.toString(),
        mobile: _isSubmitted!['mobile']?.toString(),
        amount: _isSubmitted!['amount'],
        referenceId: _isSubmitted!['referenceId']?.toString(),
      );
    }

    if (_step == 2) return _buildStep2();
    if (_step == 3) return _buildStep3();
    return _buildStep1();
  }

  Widget _buildHeader({
    required String title,
    String backLabel = 'Back',
    VoidCallback? onBack,
    VoidCallback? onHelp,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.80),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: onBack ?? () => Navigator.pop(context),
            child: Row(
              children: [
                const Icon(Icons.arrow_back, size: 16, color: AppColors.textGrey),
                const SizedBox(width: 6),
                Text(
                  backLabel,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textGrey),
                ),
              ],
            ),
          ),
          Text(
            title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
          ),
          onHelp != null
              ? GestureDetector(
                  onTap: onHelp,
                  child: const Icon(Icons.help_outline, size: 24, color: AppColors.textGrey),
                )
              : const SizedBox(width: 24),
        ],
      ),
    );
  }

  // ── Step 1: enter mobile / operator / circle ───────────────────────

  Widget _buildStep1() {
    final mobileLen = _mobileCtrl.text.length;
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.iconBgRed, Colors.white, AppColors.iconBgBlue],
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(
                  title: 'Mobile Recharge',
                  onHelp: () => setState(() => _isFaqOpen = true),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mobile Recharge',
                          style: TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Enter your details to recharge your mobile instantly.',
                          style: TextStyle(fontSize: 13, color: AppColors.textGrey),
                        ),
                        const SizedBox(height: 20),
                        Stack(
                          children: [
                            _InputField(
                              label: 'Mobile Number',
                              controller: _mobileCtrl,
                              hint: 'Enter 10-digit mobile number',
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              enabled: !_loading,
                              error: _errors['mobile'],
                              onChanged: _handleMobileChanged,
                            ),
                            if (_loading)
                              Positioned(
                                right: 12,
                                top: 38,
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: AppColors.primary),
                                ),
                              ),
                          ],
                        ),
                        if (!_autoAdvance && mobileLen == 10) ...[
                          const SizedBox(height: 18),
                          const Text(
                            'Select Operator',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF334155)),
                          ),
                          const SizedBox(height: 8),
                          if (_operators.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text('No operators available',
                                    style: TextStyle(color: Color(0xFF64748B))),
                              ),
                            )
                          else
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 280),
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: _operators.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (_, i) {
                                  final op = _operators[i];
                                  return _OperatorCard(
                                    operator: op,
                                    isSelected: _selectedOperator?.id == op.id,
                                    onSelect: _handleOperatorSelect,
                                  );
                                },
                              ),
                            ),
                          if (_errors['operator'] != null) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.error_outline, size: 14, color: AppColors.primary),
                                const SizedBox(width: 4),
                                Text(_errors['operator']!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.primary)),
                              ],
                            ),
                          ],
                          const SizedBox(height: 16),
                          _SelectFieldPopup(
                            label: 'Circle',
                            value: _circle,
                            options: _circles,
                            error: _errors['circle'],
                            onChanged: (val) {
                              setState(() {
                                _circle = val;
                                _errors.remove('circle');
                              });
                              _maybeAutoAdvance();
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (!_autoAdvance)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: SafeArea(
                      top: false,
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isFaqOpen)
            _FaqSidebar(
              title: 'Mobile Recharge',
              onClose: () => setState(() => _isFaqOpen = false),
            ),
        ],
      ),
    );
  }

  // ── Step 2: select plan ─────────────────────────────────────────────

  Widget _buildStep2() {
    final categories = (_plans ?? {}).entries.where((e) => e.value.isNotEmpty).map((e) => e.key).toList();

    List<PlanModel> visiblePlans;
    if (_searchQuery.isNotEmpty) {
      visiblePlans = (_plans ?? {})
          .values
          .expand((l) => l)
          .where((p) => p.rs.contains(_searchQuery))
          .toList();
    } else {
      visiblePlans = (_plans ?? {})[_activeTab] ?? [];
    }

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.iconBgRed, Colors.white, AppColors.iconBgBlue],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(
                  title: 'Select a recharge plan',
                  onBack: () => Navigator.pop(context),
                  onHelp: () => setState(() => _isFaqOpen = true),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _renderOperatorIcon(_selectedOperator?.name, _selectedOperator?.category),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_mobileCtrl.text,
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                              Text('${_selectedOperator?.name ?? ''} • $_circle',
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () => setState(() {
                          _step = 1;
                          _autoAdvance = false;
                        }),
                        child: const Text('Edit',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search by amount',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 2)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_searchQuery.isEmpty && categories.isNotEmpty)
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: categories
                                  .map((c) => _TabButton(
                                        active: _activeTab == c,
                                        label: c,
                                        onTap: () => setState(() => _activeTab = c),
                                      ))
                                  .toList(),
                            ),
                          ),
                        const SizedBox(height: 12),
                        if (_loadingPlans)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 32),
                            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                          )
                        else if (_plans == null)
                          const SizedBox.shrink()
                        else if (visiblePlans.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                                child:
                                    Text('Plan not found', style: TextStyle(color: Color(0xFF64748B)))),
                          )
                        else
                          Column(
                            children: visiblePlans.asMap().entries.map((entry) {
                              final index = entry.key;
                              final plan = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _amount = plan.rs;
                                      _selectedPlan = plan;
                                      _planId = index;
                                      _step = 3;
                                    });
                                  },
                                  child: _PlanCard(
                                    plan: plan,
                                    onViewDetails: () => setState(() {
                                      _selectedPlan = plan;
                                      _isPlanDetailsOpen = true;
                                    }),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isPlanDetailsOpen)
            _PlanDetailsOverlay(
              plan: _selectedPlan,
              onClose: () => setState(() => _isPlanDetailsOpen = false),
              // NOTE: in the React source, this button's onClick referenced
              // an out-of-scope `setFormData` (PlanDetailsPopup is a
              // top-level component, not nested inside MobileRecharge), so
              // clicking it would have thrown a ReferenceError at runtime.
              // Wired correctly here via a callback instead.
              onProceed: (p) => setState(() {
                _amount = p.rs;
                _isPlanDetailsOpen = false;
              }),
            ),
          if (_isFaqOpen)
            _FaqSidebar(
              title: 'Mobile Recharge',
              onClose: () => setState(() => _isFaqOpen = false),
            ),
        ],
      ),
    );
  }

  // ── Step 3: payment ──────────────────────────────────────────────────

  Widget _buildStep3() {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.iconBgRed, Colors.white, AppColors.iconBgBlue],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(
                  title: 'Payment',
                  backLabel: 'Change Plan',
                  onBack: () => setState(() => _step = 2),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: Row(
                    children: [
                      _renderOperatorIcon(_selectedOperator?.name, _selectedOperator?.category),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_mobileCtrl.text,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                          Text('${_selectedOperator?.name ?? ''} • $_circle',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _selectedPlan == null
                        ? const SizedBox.shrink()
                        : Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text('₹${_selectedPlan!.rs}',
                                            style: const TextStyle(
                                                fontSize: 22, fontWeight: FontWeight.bold)),
                                        const SizedBox(width: 8),
                                        Text('Valid for ${_selectedPlan!.validity}',
                                            style:
                                                const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                                      ],
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(() => _isPlanDetailsOpen = true),
                                      child: const Text('View Details',
                                          style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.primary)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _selectedPlan!.desc,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleRazorpayPayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text('Proceed to Pay ₹$_amount',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isPlanDetailsOpen)
            _PlanDetailsOverlay(
              plan: _selectedPlan,
              onClose: () => setState(() => _isPlanDetailsOpen = false),
              onProceed: (p) => setState(() {
                _amount = p.rs;
                _isPlanDetailsOpen = false;
              }),
            ),
        ],
      ),
    );
  }
}

// ── Input field ─────────────────────────────────────────────────────────

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? error;
  final bool optional;
  final bool enabled;
  final TextInputType? keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  const _InputField({
    required this.label,
    required this.controller,
    this.hint,
    this.error,
    this.optional = false,
    this.enabled = true,
    this.keyboardType,
    this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
            if (optional)
              const Text(' (Optional)', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLength: maxLength,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(error!, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Select field popup (Flutter equivalent of React SelectFieldPopup) ──

class _SelectFieldPopup extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? error;
  final List<String> options;

  const _SelectFieldPopup({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.options,
    this.error,
  });

  Future<void> _openPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.6,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(label,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (_, i) => ListTile(
                      title: Text(options[i]),
                      trailing: options[i] == value
                          ? const Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () => Navigator.pop(ctx, options[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF334155))),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _openPicker(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasError ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value.isEmpty ? 'Select $label' : value,
                  style: TextStyle(
                      color: value.isEmpty ? const Color(0xFF94A3B8) : const Color(0xFF0F172A)),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Color(0xFF94A3B8)),
              ],
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.error_outline, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(error!, style: const TextStyle(fontSize: 12, color: AppColors.primary)),
            ],
          ),
        ],
      ],
    );
  }
}

// ── Operator card ───────────────────────────────────────────────────────

class _OperatorCard extends StatelessWidget {
  final OperatorModel operator;
  final bool isSelected;
  final ValueChanged<OperatorModel> onSelect;

  const _OperatorCard({
    required this.operator,
    required this.isSelected,
    required this.onSelect,
  });

  static const Map<String, Color> _bgColors = {
    'airtel': Color(0xFFFEE2E2),
    'jio': Color(0xFFDBEAFE),
    'vodafone': Color(0xFFFEE2E2),
    'idea': Color(0xFFFEF9C3),
    'bsnl': Color(0xFFDCFCE7),
    'mtnl': Color(0xFFF3E8FF),
    'dish': Color(0xFFFFEDD5),
    'tata': Color(0xFFDBEAFE),
    'sun': Color(0xFFFEF9C3),
    'videocon': Color(0xFFE0E7FF),
  };

  static const Map<String, Color> _fgColors = {
    'airtel': Color(0xFFB91C1C),
    'jio': Color(0xFF1D4ED8),
    'vodafone': Color(0xFFB91C1C),
    'idea': Color(0xFFA16207),
    'bsnl': Color(0xFF15803D),
    'mtnl': Color(0xFF7E22CE),
    'dish': Color(0xFFC2410C),
    'tata': Color(0xFF1D4ED8),
    'sun': Color(0xFFA16207),
    'videocon': Color(0xFF4338CA),
  };

  IconData _icon() {
    if (operator.category == 'DTH') return Icons.tv;
    final n = operator.name.toLowerCase();
    if (n.contains('bsnl') || n.contains('mtnl')) return Icons.radio;
    return Icons.smartphone;
  }

  Color _bg() {
    final n = operator.name.toLowerCase();
    for (final key in _bgColors.keys) {
      if (n.contains(key)) return _bgColors[key]!;
    }
    return const Color(0xFFF1F5F9);
  }

  Color _fg() {
    final n = operator.name.toLowerCase();
    for (final key in _fgColors.keys) {
      if (n.contains(key)) return _fgColors[key]!;
    }
    return const Color(0xFF334155);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelect(operator),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.iconBgRed : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _bg(), borderRadius: BorderRadius.circular(8)),
              child: Icon(_icon(), size: 22, color: _fg()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(operator.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                  Text(operator.category,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Tab button ──────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final bool active;
  final String label;
  final VoidCallback onTap;

  const _TabButton({required this.active, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}

// ── Plan card ───────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final PlanModel plan;
  final VoidCallback onViewDetails;

  const _PlanCard({required this.plan, required this.onViewDetails});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('₹${plan.rs}',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(width: 8),
                  Text('Valid for ${plan.validity}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                ],
              ),
              Text('Last updated: ${plan.lastUpdate}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plan.desc,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, color: AppColors.textGrey),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: onViewDetails,
            child: const Text('View Details',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

// ── Plan details overlay (Flutter equivalent of React PlanDetailsPopup) ─

class _PlanDetailsOverlay extends StatelessWidget {
  final PlanModel? plan;
  final VoidCallback onClose;
  final ValueChanged<PlanModel> onProceed;

  const _PlanDetailsOverlay({
    required this.plan,
    required this.onClose,
    required this.onProceed,
  });

  @override
  Widget build(BuildContext context) {
    if (plan == null) return const SizedBox.shrink();
    final p = plan!;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.40),
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Plan Details',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      GestureDetector(
                        onTap: onClose,
                        child: const Icon(Icons.close, size: 20, color: AppColors.textGrey),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text('₹${p.rs}',
                                    style:
                                        const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Text('Valid for ${p.validity}',
                                    style:
                                        const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                              ],
                            ),
                            Text('Last updated: ${p.lastUpdate}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Description',
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              const SizedBox(height: 6),
                              Text(p.desc, style: const TextStyle(fontSize: 13, color: AppColors.textGrey)),
                            ],
                          ),
                        ),
                        if (p.dataBenefit != null && p.dataBenefit!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Data Benefits',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF1E3A8A))),
                                const SizedBox(height: 6),
                                Text(p.dataBenefit!,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF1D4ED8))),
                              ],
                            ),
                          ),
                        ],
                        if (p.voiceBenefit != null && p.voiceBenefit!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Voice Benefits',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF14532D))),
                                const SizedBox(height: 6),
                                Text(p.voiceBenefit!,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF15803D))),
                              ],
                            ),
                          ),
                        ],
                        if (p.smsBenefit != null && p.smsBenefit!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFAF5FF), borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('SMS Benefits',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: Color(0xFF581C87))),
                                const SizedBox(height: 6),
                                Text(p.smsBenefit!,
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF7E22CE))),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration:
                      const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => onProceed(p),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Proceed with ₹${p.rs}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Processing screen ───────────────────────────────────────────────────

class _ProcessingScreen extends StatelessWidget {
  final Map<String, dynamic>? status;

  const _ProcessingScreen({required this.status});

  @override
  Widget build(BuildContext context) {
    final stepValue = status?['step'];
    final isError = stepValue == 'error';
    final message = status?['message']?.toString() ?? 'Processing...';

    return Scaffold(
      body: Stack(
        children: [
          Container(color: const Color(0xFFF8FAFC)),
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.20),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
                            ],
                          ),
                          child: isError
                              ? const Icon(Icons.error_outline, size: 48, color: AppColors.primary)
                              : const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF3B82F6)),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 6),
                    const Text('Please wait while we process your recharge',
                        style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
                    if (!isError) ...[
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 6)),
                          ],
                        ),
                        child: Column(
                          children: [
                            _Step(
                                number: 1,
                                title: 'Payment Verification',
                                description: 'Confirming your payment',
                                complete: (stepValue is int && stepValue >= 1)),
                            const SizedBox(height: 16),
                            _Step(
                                number: 2,
                                title: 'Recharge Initiation',
                                description: 'Processing with operator',
                                complete: (stepValue is int && stepValue >= 2)),
                            const SizedBox(height: 16),
                            _Step(
                                number: 3,
                                title: 'Confirmation',
                                description: 'Finalizing your recharge',
                                complete: (stepValue is int && stepValue >= 3)),
                          ],
                        ),
                      ),
                    ],
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

class _Step extends StatelessWidget {
  final int number;
  final String title;
  final String description;
  final bool complete;

  const _Step({
    required this.number,
    required this.title,
    required this.description,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: complete ? const Color(0xFF22C55E) : const Color(0xFFE2E8F0),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: complete
              ? const Icon(Icons.check, size: 18, color: Colors.white)
              : Text('$number',
                  style: const TextStyle(color: AppColors.textGrey, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textDark)),
              const SizedBox(height: 2),
              Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Success screen ──────────────────────────────────────────────────────

class _SuccessScreen extends StatefulWidget {
  final VoidCallback onClose;
  final String? message;
  final String? operatorName;
  final String? mobile;
  final dynamic amount;
  final String? referenceId;

  const _SuccessScreen({
    required this.onClose,
    this.message,
    this.operatorName,
    this.mobile,
    this.amount,
    this.referenceId,
  });

  @override
  State<_SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<_SuccessScreen> {
  late final ConfettiController _confettiCtrl =
      ConfettiController(duration: const Duration(seconds: 2));

  @override
  void initState() {
    super.initState();
    _confettiCtrl.play();
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
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
                colors: [AppColors.iconBgRed, Colors.white, AppColors.iconBgBlue],
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              numberOfParticles: 40,
              colors: const [
                Color(0xFF22C55E),
                Color(0xFF3B82F6),
                Color(0xFF0EA5E9),
                Color(0xFF14B8A6),
                Color(0xFF84CC16),
              ],
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF10B981)]),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 48, color: Colors.white),
                  ),
                  const SizedBox(height: 24),
                  const Text('Recharge Successful!',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 10),
                  Text(
                    widget.message ?? 'Your mobile recharge was completed successfully.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: AppColors.textGrey, height: 1.4),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _SummaryRow(label: 'Operator', value: widget.operatorName ?? '-'),
                        const Divider(height: 24),
                        _SummaryRow(label: 'Mobile Number', value: widget.mobile ?? '-'),
                        const Divider(height: 24),
                        _SummaryRow(
                          label: 'Amount Paid',
                          value: '₹${widget.amount ?? '-'}',
                          valueColor: const Color(0xFF16A34A),
                          valueBg: const Color(0xFFF0FDF4),
                        ),
                        const Divider(height: 24),
                        _SummaryRow(
                            label: 'Reference ID', value: widget.referenceId ?? '-', mono: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: wire up native share (e.g. via share_plus,
                        // already a dependency in your pubspec.yaml) to
                        // share a receipt summary, matching the React
                        // "Share Receipt" button.
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFF1F5F9), width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Share Receipt',
                          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      child: const Text('Back to Home',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
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

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Color? valueBg;
  final bool mono;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.valueBg,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: valueBg ?? const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF0F172A),
              fontFamily: mono ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ── FAQ sidebar ──────────────────────────────────────────────────────────

class _FaqSidebar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _FaqSidebar({required this.title, required this.onClose});

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How long does a recharge take?',
      'a': 'Recharges are usually processed instantly, but can take up to 30 minutes during high traffic.'
    },
    {
      'q': 'What if my recharge fails after payment?',
      'a':
          'If the recharge fails after a successful payment, the amount is automatically refunded within 3-5 business days.'
    },
    {'q': 'Can I recharge any operator?', 'a': 'Yes, we support all major prepaid operators across India.'},
    {
      'q': 'Is my payment secure?',
      'a': 'All payments are processed through Razorpay with bank-grade encryption.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.40),
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: MediaQuery.of(context).size.width * 0.82,
              height: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('FAQ - $title',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          GestureDetector(
                            onTap: onClose,
                            child: const Icon(Icons.close, size: 24, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: _faqs
                            .map((faq) => ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: Text(faq['q']!,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Text(faq['a']!,
                                          style:
                                              const TextStyle(fontSize: 12, color: AppColors.textGrey)),
                                    ),
                                  ],
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Grid painter (decorative background, shared visual style) ──────────

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