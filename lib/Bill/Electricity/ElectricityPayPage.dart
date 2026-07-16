import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';

class ElectricityBillInfo {
  final String name;
  final String amount;
  final String? dueDate;
  final String? billDate;
  final String? cellNumber;

  ElectricityBillInfo({
    required this.name,
    required this.amount,
    this.dueDate,
    this.billDate,
    this.cellNumber,
  });

  factory ElectricityBillInfo.fromJson(Map<String, dynamic> json) {
    return ElectricityBillInfo(
      name: json['name']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      dueDate: json['duedate']?.toString(),
      billDate: json['billdate']?.toString(),
      cellNumber: json['cellNumber']?.toString(),
    );
  }
}

// ── Main Screen ───────────────────────────────────────────────────────────────

class ElectricityPayScreen extends StatefulWidget {
  final String operatorName;
  final String operatorId;
  final Map<String, dynamic> operatorData;
  final Map<String, String> formData; // main, ad1?, ad2?, ad3?

  const ElectricityPayScreen({
    super.key,
    required this.operatorName,
    required this.operatorId,
    required this.operatorData,
    required this.formData,
  });

  @override
  State<ElectricityPayScreen> createState() => _ElectricityPayScreenState();
}

class _ElectricityPayScreenState extends State<ElectricityPayScreen> {
  ElectricityBillInfo? _billInfo;
  bool _loading = true;
  String _amount = '';
  bool _processing = false;
  Map<String, dynamic>? _processStatus; // {step, message}
  Map<String, dynamic>? _success;       // {message, operator, subscriberId, amount, referenceId}
  bool _showDetails = true;

  late final Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    if (widget.operatorId.isNotEmpty &&
        (widget.formData['main'] ?? '').isNotEmpty) {
      _fetchBillInfo();
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _fetchBillInfo() async {
    try {
      final token = await AuthService.getToken();
      final payload = <String, dynamic>{
        'operator': widget.operatorId,
        'canumber': widget.formData['main'],
        'mode': 'online',
      };
      if (widget.formData['ad1'] != null) payload['ad1'] = widget.formData['ad1'];
      if (widget.formData['ad2'] != null) payload['ad2'] = widget.formData['ad2'];
      if (widget.formData['ad3'] != null) payload['ad3'] = widget.formData['ad3'];

      final response = await http.post(
        Uri.parse('${ApiConstants.servicesBaseUrl}/electricity-bill-fetch.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (data['response']?['status'] == true &&
          data['response']?['bill_fetch'] != null) {
        final billFetch =
            data['response']['bill_fetch'] as Map<String, dynamic>;
        final info = ElectricityBillInfo.fromJson(billFetch);
        setState(() {
          _billInfo = info;
          _amount = info.amount;
        });
      }
    } catch (e) {
      debugPrint('Bill fetch error: $e');
      setState(() => _billInfo = null);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
  Future<void> _handlePay() async {
    final amt = double.tryParse(_amount);
    if (amt == null || amt <= 0) return;

    setState(() {
      _processing = true;
      _processStatus = {'step': 1, 'message': 'Creating payment order...'};
    });

    try {
      final token = await AuthService.getToken();

      // Build payload
      final payload = <String, dynamic>{
        'operator': widget.operatorId,
        'canumber': widget.formData['main'],
        'amount': _amount,
        'mode': 'online',
      };
      if (widget.formData['ad1'] != null) payload['ad1'] = widget.formData['ad1'];
      if (widget.formData['ad2'] != null) payload['ad2'] = widget.formData['ad2'];
      if (widget.formData['ad3'] != null) payload['ad3'] = widget.formData['ad3'];

      // Step 1 — create order
      final orderRes = await http.post(
        Uri.parse(
            '${ApiConstants.servicesBaseUrl}/create-electricity-order.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode(payload),
      );

      final orderData =
          jsonDecode(orderRes.body) as Map<String, dynamic>;

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
        'description': 'Electricity Bill Payment',
        'order_id': orderId,
        'prefill': {
          'name': _billInfo?.name ?? '',
          'email': '',
          'contact': _billInfo?.cellNumber?.isNotEmpty == true
              ? _billInfo!.cellNumber
              : widget.formData['main'] ?? '',
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

  // ── Razorpay callbacks ────────────────────────────────────────────────────

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() =>
        _processStatus = {'step': 3, 'message': 'Verifying payment...'});

    try {
      final token = await AuthService.getToken();
      final verifyRes = await http.post(
        Uri.parse(
            '${ApiConstants.servicesBaseUrl}/verify-payment-electricity.php'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'razorpay_payment_id': response.paymentId ?? '',
          'razorpay_order_id': response.orderId ?? '',
          'razorpay_signature': response.signature ?? '',
        }),
      );

      final data =
          jsonDecode(verifyRes.body) as Map<String, dynamic>;

      if (data['success'] == true && data['payment_verified'] == true) {
        setState(() =>
            _processStatus = {'step': 4, 'message': 'Payment successful!'});
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        setState(() {
          _processing = false;
          _success = {
            'message': data['recharge_message'],
            'operator': widget.operatorName,
            'subscriberId': widget.formData['main'],
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
  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildLoadingSkeleton();
    if (_billInfo == null) return _buildNotFound();
    if (_processing) return _buildProcessing();
    if (_success != null) return _buildSuccess();
    return _buildMain();
  }

  // ────────────────────────────────────────────────────────────────────────
  // ① Loading skeleton
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return Scaffold(
      body: _gradientBg(
        child: SafeArea(
          child: Column(
            children: [
              // Header skeleton
              Container(
                color: Colors.white.withOpacity(0.80),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _Shimmer(width: 80, height: 20, radius: 20),
                    _Shimmer(width: 140, height: 20, radius: 20),
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
                          border: Border.all(
                              color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _Shimmer(
                                    width: 40, height: 40, radius: 8),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _Shimmer(
                                          width: 96,
                                          height: 14,
                                          radius: 4),
                                      const SizedBox(height: 6),
                                      _Shimmer(
                                          width: 64,
                                          height: 12,
                                          radius: 4),
                                    ],
                                  ),
                                ),
                                _Shimmer(
                                    width: 40, height: 14, radius: 4),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: List.generate(
                                4,
                                (_) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    child: _Shimmer(
                                        width: double.infinity,
                                        height: 40,
                                        radius: 8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Amount skeleton
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: const Color(0xFFE5E7EB)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Shimmer(width: 128, height: 14, radius: 4),
                            const SizedBox(height: 12),
                            _Shimmer(
                                width: double.infinity,
                                height: 48,
                                radius: 8),
                            const SizedBox(height: 12),
                            Row(
                              children: List.generate(
                                4,
                                (_) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    child: _Shimmer(
                                        width: double.infinity,
                                        height: 32,
                                        radius: 8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _Shimmer(
                          width: double.infinity, height: 44, radius: 8),
                    ],
                  ),
                ),
              ),
              // Pay button skeleton
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white.withOpacity(0.80),
                child: _Shimmer(
                    width: double.infinity, height: 52, radius: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // ② Bill not found
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildNotFound() {
    return Scaffold(
      body: _gradientBg(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 12,
                    offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.flash_on,
                    size: 48, color: Color(0xFFF87171)),
                SizedBox(height: 12),
                Text(
                  'Bill Not Found',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB91C1C),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Please check your details',
                  style: TextStyle(
                      fontSize: 14, color: Color(0xFFDC2626)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // ③ Processing
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildProcessing() {
    final isError = _processStatus?['step'] == 'error';
    final message =
        _processStatus?['message']?.toString() ?? 'Processing...';

    return Scaffold(
      body: _gradientBg(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
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
                              offset: Offset(0, 4)),
                        ],
                      ),
                      child: isError
                          ? const Icon(Icons.warning_amber_rounded,
                              size: 40, color: AppColors.primary)
                          : const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.primary,
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
                  'Please wait while we process your payment',
                  style: TextStyle(
                      fontSize: 14, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────
  // ④ Success
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    final s = _success!;
    return Scaffold(
      body: _gradientBg(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Green gradient checkmark circle
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF22C55E),
                        Color(0xFF34D399),
                        Color(0xFF10B981),
                      ],
                    ),
                  ),
                  child: const Icon(Icons.check,
                      size: 52, color: Colors.white),
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
                      'Your electricity bill was paid successfully.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textGrey,
                      height: 1.5),
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
                          offset: Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    children: [
                      _SuccessRow(
                          label: 'Operator',
                          value: s['operator']?.toString() ?? '-'),
                      const Divider(height: 20),
                      _SuccessRow(
                          label: 'Consumer No.',
                          value:
                              s['subscriberId']?.toString() ?? '-'),
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
                      padding:
                          const EdgeInsets.symmetric(vertical: 18),
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

  // ────────────────────────────────────────────────────────────────────────
  // ⑤ Main screen
  // ────────────────────────────────────────────────────────────────────────

  Widget _buildMain() {
    final canPay =
        double.tryParse(_amount) != null && double.parse(_amount) > 0;

    return Scaffold(
      body: Stack(
        children: [
          _gradientBg(child: const SizedBox.expand()),
          SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────
                _buildHeader(),

                // ── Scrollable content ────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    child: Column(
                      children: [
                        // Bill info card
                        _buildBillCard(),
                        const SizedBox(height: 20),

                        // Security footer
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.shield_outlined,
                                size: 16, color: Color(0xFFF87171)),
                            SizedBox(width: 6),
                            Text(
                              '100% Secure Payment',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Fixed bottom pay button ──────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.80),
                border: const Border(
                    top: BorderSide(color: Color(0xFFE5E7EB))),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 12,
                      offset: Offset(0, -4)),
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                  16,
                  12,
                  16,
                  12 + MediaQuery.of(context).padding.bottom),
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
                    disabledBackgroundColor:
                        const Color(0xFFD1D5DB),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: 16),
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

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.80),
        border: const Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
            'Electricity Bill Payment',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark),
          ),
          const SizedBox(width: 36),
        ],
      ),
    );
  }
  Widget _buildBillCard() {
    final info = _billInfo!;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // Top: operator icon + name + consumer number
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.flash_on,
                      size: 20, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.operatorName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        widget.formData['main'] ?? '',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Bill Details toggle row
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bill Details:',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      setState(() => _showDetails = !_showDetails),
                  child: Text(
                    _showDetails ? 'HIDE' : 'SHOW',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_showDetails) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  _BillDetailRow(
                      label: 'Customer Name', value: info.name),
                  if (info.billDate != null && info.billDate!.isNotEmpty)
                    _BillDetailRow(
                        label: 'Bill Date', value: info.billDate!),
                ],
              ),
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFD1D5DB)),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 4,
                      offset: Offset(0, 1)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹ ${info.amount}',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const Divider(height: 20, color: Color(0xFFE5E7EB)),
                  if (info.dueDate != null && info.dueDate!.isNotEmpty)
                    Text(
                      'Due Date: ${info.dueDate}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
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

  // ── Gradient background helper ────────────────────────────────────────────

  Widget _gradientBg({required Widget child}) {
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
      child: child,
    );
  }
}

// ── Bill detail row ───────────────────────────────────────────────────────────

class _BillDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _BillDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: Color(0xFF6B7280))),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF374151))),
        ],
      ),
    );
  }
}

// ── Success row ───────────────────────────────────────────────────────────────

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
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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

// ── Shimmer placeholder ───────────────────────────────────────────────────────

class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const _Shimmer(
      {required this.width, required this.height, required this.radius});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
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