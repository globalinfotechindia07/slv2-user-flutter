import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class DthInfo {
  final String status;
  final String balance;
  final String monthlyRecharge;
  final String nextRechargeDate;
  final String customerName;
  final String mobile;

  DthInfo({
    required this.status,
    required this.balance,
    required this.monthlyRecharge,
    required this.nextRechargeDate,
    required this.customerName,
    required this.mobile,
  });

  factory DthInfo.fromJson(Map<String, dynamic> json) {
    return DthInfo(
      status: json['status']?.toString() ?? '',
      balance: json['Balance']?.toString() ?? '0',
      monthlyRecharge: json['MonthlyRecharge']?.toString() ?? '0',
      nextRechargeDate: json['NextRechargeDate']?.toString() ?? '',
      customerName: json['CustomerName']?.toString() ?? '',
      mobile: json['Mobile']?.toString() ?? '',
    );
  }
}

// ── Main Screen ──────────────────────────────────────────────────────────────

class DthPayScreen extends StatefulWidget {
  final String subscriberId;
  final String operatorName;
  final String operatorId;

  const DthPayScreen({
    super.key,
    required this.subscriberId,
    required this.operatorName,
    required this.operatorId,
  });

  @override
  State<DthPayScreen> createState() => _DthPayScreenState();
}

class _DthPayScreenState extends State<DthPayScreen> {
  DthInfo? _info;
  bool _loading = true;
  String _amount = '';
  bool _processing = false;
  Map<String, dynamic>? _processStatus; 
  Map<String, dynamic>? _success;       

  final TextEditingController _amountCtrl = TextEditingController();
  late final Razorpay _razorpay;

  static const List<int> _quickAmounts = [199, 299, 499, 799];

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _fetchDthInfo();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchDthInfo() async {
    try {
      final token = await AuthService.getToken();
      final response = await http.post(
        Uri.parse('${ApiConstants.servicesBaseUrl}/dthinfo.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'canumber': widget.subscriberId,
          'op': widget.operatorName,
        }),
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true) {
        final infoList = data['response']?['info'];
        if (infoList is List && infoList.isNotEmpty) {
          setState(() => _info = DthInfo.fromJson(infoList[0] as Map<String, dynamic>));
        }
      }
    } catch (e) {
      debugPrint('DTH info error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Payment flow — mirrors onClick Pay button ────────────────────────────

  Future<void> _handlePay() async {
    final amt = double.tryParse(_amount);
    if (amt == null || amt <= 0) return;

    setState(() {
      _processing = true;
      _processStatus = {'step': 1, 'message': 'Creating payment order...'};
    });

    try {
      // Step 1 — create order
      final token = await AuthService.getToken();
      final orderRes = await http.post(
        Uri.parse('${ApiConstants.servicesBaseUrl}/create-dth-order.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'type': 'dth',
          'amount': _amount,
          'op': widget.operatorName,
          'subscriberId': widget.subscriberId,
          'operatorId': widget.operatorId,
          'info': _info != null
              ? {
                  'status': _info!.status,
                  'Balance': _info!.balance,
                  'MonthlyRecharge': _info!.monthlyRecharge,
                  'NextRechargeDate': _info!.nextRechargeDate,
                  'CustomerName': _info!.customerName,
                  'Mobile': _info!.mobile,
                }
              : {},
        }),
      );

      final orderData = jsonDecode(orderRes.body) as Map<String, dynamic>;

      if (orderData['error'] != null) {
        setState(() => _processStatus = {
              'step': 'error',
              'message': orderData['error'].toString(),
            });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _processing = false);
        return;
      }

      setState(() => _processStatus = {
            'step': 2,
            'message': 'Loading payment gateway...',
          });

      // Step 2 — open Razorpay
      final orderId = orderData['id'].toString();
      final orderAmount = orderData['amount'];
      final currency = orderData['currency'] ?? 'INR';

      final options = {
        'key': ApiConstants.razorpayKey,
        'amount': orderAmount.toString(),
        'currency': currency,
        'name': widget.operatorName,
        'description': 'DTH Recharge',
        'order_id': orderId,
        'prefill': {
          'name': _info?.customerName ?? '',
          'email': '',
          'contact': _info?.mobile.isNotEmpty == true
              ? _info!.mobile
              : widget.subscriberId,
        },
        'theme': {'color': '#E53935'},      
        };

      _razorpay.open(options);
    } catch (e) {
      setState(() => _processStatus = {
            'step': 'error',
            'message': 'An error occurred. Please try again.',
          });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _processing = false);
    }
  }

  // ── Razorpay callbacks ───────────────────────────────────────────────────

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _processStatus = {'step': 3, 'message': 'Verifying payment...'});

    try {
      final token = await AuthService.getToken();
      final verifyRes = await http.post(
        Uri.parse('${ApiConstants.servicesBaseUrl}/verify-payment-dth.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'razorpay_payment_id': response.paymentId ?? '',
          'razorpay_order_id': response.orderId ?? '',
          'razorpay_signature': response.signature ?? '',
        }),
      );

      final data = jsonDecode(verifyRes.body) as Map<String, dynamic>;

      if (data['success'] == true && data['payment_verified'] == true) {
        setState(() => _processStatus = {'step': 4, 'message': 'Recharge successful!'});
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        setState(() {
          _processing = false;
          _success = {
            'message': data['recharge_message'],
            'operator': widget.operatorName,
            'subscriberId': widget.subscriberId,
            'amount': _amount,
            'referenceId': data['reference_id'],
          };
        });
      } else {
        setState(() => _processStatus = {
              'step': 'error',
              'message': 'Payment verification failed!',
            });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) setState(() => _processing = false);
      }
    } catch (e) {
      setState(() => _processStatus = {
            'step': 'error',
            'message': 'An error occurred during verification.',
          });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _processing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) setState(() => _processing = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) setState(() => _processing = false);
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_loading) return _buildLoadingSkeleton();

    // Connection not found
    if (_info == null) return _buildNotFound();

    // Processing state
    if (_processing) return _buildProcessing();

    // Success state
    if (_success != null) return _buildSuccess();

    // Main screen
    return _buildMain();
  }

  // ── Loading skeleton ─────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.iconBgRed, Colors.white, AppColors.iconBgBlue],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header skeleton
              Container(
                color: Colors.white.withOpacity(0.80),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Shimmer(width: 80, height: 20, radius: 20),
                    _Shimmer(width: 120, height: 20, radius: 20),
                    _Shimmer(width: 24, height: 24, radius: 12),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Connection info skeleton
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _Shimmer(width: 40, height: 40, radius: 8),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _Shimmer(width: 96, height: 14, radius: 4),
                                      const SizedBox(height: 6),
                                      _Shimmer(width: 64, height: 12, radius: 4),
                                    ],
                                  ),
                                ),
                                _Shimmer(width: 40, height: 14, radius: 4),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(child: _Shimmer(width: double.infinity, height: 40, radius: 8)),
                                const SizedBox(width: 8),
                                Expanded(child: _Shimmer(width: double.infinity, height: 40, radius: 8)),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: _Shimmer(width: double.infinity, height: 40, radius: 8),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Amount input skeleton
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Shimmer(width: 128, height: 14, radius: 4),
                            const SizedBox(height: 12),
                            _Shimmer(width: double.infinity, height: 48, radius: 8),
                            const SizedBox(height: 12),
                            Row(
                              children: List.generate(
                                4,
                                (_) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: _Shimmer(width: double.infinity, height: 32, radius: 8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Notice skeleton
                      _Shimmer(width: double.infinity, height: 44, radius: 8),
                    ],
                  ),
                ),
              ),
              // Pay button skeleton
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white.withOpacity(0.80),
                child: _Shimmer(width: double.infinity, height: 52, radius: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Not found ────────────────────────────────────────────────────────────

  Widget _buildNotFound() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.iconBgRed, Colors.white, AppColors.iconBgBlue],
          ),
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.tv, size: 48, color: Color(0xFFF87171)),
                SizedBox(height: 12),
                Text(
                  'Connection Not Found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB91C1C),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Please check your details',
                  style: TextStyle(fontSize: 14, color: Color(0xFFDC2626)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Processing ───────────────────────────────────────────────────────────

  Widget _buildProcessing() {
    final isError = _processStatus?['step'] == 'error';
    final message = _processStatus?['message']?.toString() ?? 'Processing...';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.iconBgRed, Colors.white, AppColors.iconBgBlue],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Ping ring
                    if (!isError)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withOpacity(0.20),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: isError
                          ? const Icon(Icons.warning_amber_rounded,
                              size: 40, color: Color(0xFFEF4444))
                          : const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Please wait while we process your recharge',
                  style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Success ──────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    final s = _success!;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.iconBgRed, Colors.white, AppColors.iconBgBlue],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Green checkmark circle
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF22C55E), Color(0xFF10B981)],
                    ),
                  ),
                  child: const Icon(Icons.check, size: 52, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Recharge Successful!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s['message']?.toString() ??
                      'Your DTH recharge was completed successfully.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15, color: AppColors.textGrey, height: 1.5),
                ),
                const SizedBox(height: 24),
                // Summary card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _SuccessRow(label: 'Operator', value: s['operator']?.toString() ?? '-'),
                      const Divider(height: 20),
                      _SuccessRow(label: 'Subscriber ID', value: s['subscriberId']?.toString() ?? '-'),
                      const Divider(height: 20),
                      _SuccessRow(
                        label: 'Amount Paid',
                        value: '₹${s['amount'] ?? '-'}',
                        valueColor: const Color(0xFF16A34A),
                        valueBg: const Color(0xFFF0FDF4),
                      ),
                      const Divider(height: 20),
                      _SuccessRow(
                        label: 'Reference ID',
                        value: s['referenceId']?.toString() ?? '-',
                        mono: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Back to Home button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context)
                        .popUntil((route) => route.isFirst),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text(
                      'Back to Home',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
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

  // ── Main screen ──────────────────────────────────────────────────────────

  Widget _buildMain() {
    final amtValue = double.tryParse(_amount) ?? 0;
    final canPay = amtValue > 0;

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
                // ── Header ──────────────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.80),
                    border: const Border(
                        bottom: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Row(
                          children: [
                            Icon(Icons.arrow_back,
                                size: 16, color: AppColors.textGrey),
                            SizedBox(width: 6),
                            Text('Back',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textGrey)),
                          ],
                        ),
                      ),
                      const Text(
                        'DTH Recharge',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark),
                      ),
                      const SizedBox(width: 36),
                    ],
                  ),
                ),

                // ── Scrollable content ───────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Connection Info card ──────────────────────────────
                        _buildConnectionInfo(),
                        const SizedBox(height: 16),
                        // ── Amount Input card ─────────────────────────────────
                        _buildAmountInput(),
                        const SizedBox(height: 16),
                        // ── Important Notice ──────────────────────────────────
                        _buildNotice(),
                        const SizedBox(height: 16),
                        // ── Security footer ───────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.shield_outlined,
                                size: 16, color: Color(0xFF9CA3AF)),
                            SizedBox(width: 6),
                            Text('100% Secure Payment',
                                style: TextStyle(
                                    fontSize: 12, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Fixed bottom pay button ─────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.80),
                border: const Border(top: BorderSide(color: Color(0xFFE5E7EB))),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 12,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: canPay ? _handlePay : null,
                  icon: const Icon(Icons.credit_card, size: 20),
                  label: Text(
                    canPay ? 'Pay ₹$_amount' : 'Enter Amount',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: const Color(0xFFD1D5DB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Connection Info card ─────────────────────────────────────────────────

  Widget _buildConnectionInfo() {
    final info = _info!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Operator icon — w-10 h-10 bg-red-500 rounded-lg
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tv, size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.operatorName,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827)),
                    ),
                    Text(
                      widget.subscriberId,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
              ),
              // Status badge — CheckCircle + status text
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 16, color: Color(0xFF22C55E)),
                  const SizedBox(width: 4),
                  Text(
                    info.status,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF16A34A)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Grid: Balance | Plan | Expires (4-col layout)
          Row(
            children: [
              Expanded(
                child: _InfoTile(
                    label: 'Balance', value: '₹${info.balance}', valueColor: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoTile(
                    label: 'Plan', value: '₹${info.monthlyRecharge}'),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _InfoTile(
                    label: 'Expires', value: info.nextRechargeDate, small: true),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Amount input card ────────────────────────────────────────────────────

  Widget _buildAmountInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recharge Amount',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 12),
          // Amount text field with ₹ prefix
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            onChanged: (v) => setState(() => _amount = v),
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937)),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF), fontWeight: FontWeight.normal),
              prefixText: '₹ ',
              prefixStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: Color(0xFFE5E7EB), width: 2)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2)),
            ),  // closes InputDecoration
          ),
          const SizedBox(height: 12),
          // Quick amount chips — grid-cols-4
          Row(
            children: _quickAmounts.map((qa) {
              final isSelected = _amount == qa.toString();
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                      right: qa != _quickAmounts.last ? 8 : 0),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _amount = qa.toString());
                      _amountCtrl.text = qa.toString();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.iconBgRed : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Text(
                        '₹$qa',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppColors.primary : const Color(0xFF4B5563),                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Important Notice ─────────────────────────────────────────────────────

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        border: const Border(
          left: BorderSide(color: Color(0xFFFB923C), width: 4),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: Color(0xFFD97706)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Keep your set-top box ON during recharge',
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF92400E)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info tile (Balance / Plan / Expires) ─────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool small;

  const _InfoTile({
    required this.label,
    required this.value,
    this.valueColor,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: small ? 11 : 13,
              fontWeight: FontWeight.bold,
              color: valueColor ?? const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Success row ──────────────────────────────────────────────────────────────

class _SuccessRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Color? valueBg;
  final bool mono;

  const _SuccessRow({
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
            style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500)),
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

// ── Shimmer placeholder ──────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _Shimmer(
      {required this.width, required this.height, required this.radius});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _anim =
      Tween<double>(begin: 0.4, end: 1.0).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}