import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// Reusable InputField widget  (mirrors React's InputField component)
// ─────────────────────────────────────────────
class InputField extends StatelessWidget {
  final String label;
  final String? error;
  final String placeholder;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const InputField({
    super.key,
    required this.label,
    required this.controller,
    this.error,
    this.placeholder = '',
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = error != null && error!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151), // text-gray-700
          ),
        ),
        const SizedBox(height: 8),

        // Text input
        TextField(
          controller: controller,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFE5E7EB),
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? const Color(0xFFEF4444)
                    : const Color(0xFFEF4444),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
          ),
        ),

        // Error message
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.error_outline,
                  size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  error!,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────
// FAQ Sidebar  (mirrors React's FAQSidebar component)
// ─────────────────────────────────────────────
class FAQSidebar extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String title;

  const FAQSidebar({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.title,
  });

  // Sample FAQ data – replace with your real data / API call
  static const List<Map<String, String>> _faqs = [
    {
      'q': 'What is a DTH Subscriber ID?',
      'a':
          'Your Subscriber ID is a unique number assigned by your DTH provider. '
              'It is printed on your set-top box or the monthly bill.',
    },
    {
      'q': 'Can I use my registered mobile number instead?',
      'a':
          'Yes. Enter the mobile number linked to your DTH account and we will '
              'fetch your subscriber details automatically.',
    },
    {
      'q': 'How long does the recharge take to activate?',
      'a':
          'Recharges are usually activated within a few minutes. In rare cases '
              'it may take up to 24 hours.',
    },
    {
      'q': 'What if my recharge fails?',
      'a':
          'If the payment is debited but recharge fails, the amount will be '
              'refunded to your source account within 5–7 business days.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: isOpen ? Offset.zero : const Offset(1, 0),
      curve: Curves.easeInOut,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isOpen ? 1 : 0,
        child: isOpen
            ? Stack(
                children: [
                  // Scrim
                  GestureDetector(
                    onTap: onClose,
                    child: Container(color: Colors.black45),
                  ),

                  // Drawer panel
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.85,
                      height: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '$title – FAQs',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Color(0xFF475569)),
                                    onPressed: onClose,
                                  ),
                                ],
                              ),
                            ),

                            const Divider(height: 1),

                            // FAQ list
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.all(20),
                                itemCount: _faqs.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final faq = _faqs[index];
                                  return _FAQItem(
                                    question: faq['q']!,
                                    answer: faq['a']!,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;
  const _FAQItem({required this.question, required this.answer});

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
            if (_expanded) ...[
              const SizedBox(height: 8),
              Text(
                widget.answer,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF475569),
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DthRechargeDetails Screen  (main component)
// ─────────────────────────────────────────────

// Route arguments model – mirrors React's location.state
class DthRechargeDetailsArgs {
  final String operatorName;
  final String operatorId;

  const DthRechargeDetailsArgs({
    required this.operatorName,
    required this.operatorId,
  });
}

class DthRechargeDetails extends StatefulWidget {
  final DthRechargeDetailsArgs args;

  const DthRechargeDetails({super.key, required this.args});

  @override
  State<DthRechargeDetails> createState() => _DthRechargeDetailsState();
}

class _DthRechargeDetailsState extends State<DthRechargeDetails> {
  // ── State (mirrors React useState hooks) ──
  bool _loading = false;
  bool _isFAQOpen = false;
  final TextEditingController _subscriberIdController =
      TextEditingController();
  Map<String, String> _errors = {};

  @override
  void dispose() {
    _subscriberIdController.dispose();
    super.dispose();
  }

  // ── handleInputChange ──
  void _handleInputChange(String value) {
    if (_errors.containsKey('subscriberId')) {
      setState(() => _errors = {..._errors}..remove('subscriberId'));
    }
  }

  // ── validateForm ──
  bool _validateForm() {
    final newErrors = <String, String>{};
    if (_subscriberIdController.text.trim().isEmpty) {
      newErrors['subscriberId'] =
          'Subscriber ID/Mobile Number is required';
    }
    setState(() => _errors = newErrors);
    return newErrors.isEmpty;
  }

  // ── handleContinue ──
  void _handleContinue() {
    if (!_validateForm()) return;

    // Navigate to the DTH pay screen, passing all required state
    Navigator.pushNamed(
      context,
      '/app/dth-recharge/pay',
      arguments: {
        'subscriberId': _subscriberIdController.text.trim(),
        'operatorName': widget.args.operatorName,
        'operatorId': widget.args.operatorId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Main screen ──
        Scaffold(
          // Gradient background (from-red-50 via-white to-blue-50)
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFF1F2), // red-50
                  Colors.white,
                  Color(0xFFEFF6FF), // blue-50
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ── Sticky Header ──
                  _buildHeader(),

                  // ── Scrollable Body ──
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),

                          // Info card (blue-50 hint box)
                          _buildInfoCard(),

                          const SizedBox(height: 24),

                          // Subscriber ID input
                          InputField(
                            label:
                                'Subscriber ID/Registered Mobile Number',
                            controller: _subscriberIdController,
                            placeholder:
                                'subscriber ID/Registered Mobile Number',
                            error: _errors['subscriberId'],
                            onChanged: _handleInputChange,
                          ),

                          const SizedBox(height: 24),

                          // Continue button
                          _buildContinueButton(),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── FAQ Sidebar overlay ──
        if (_isFAQOpen)
          Positioned.fill(
            child: FAQSidebar(
              isOpen: _isFAQOpen,
              onClose: () => setState(() => _isFAQOpen = false),
              title: 'DTH Recharge',
            ),
          ),
      ],
    );
  }

  // ── Header widget ──
  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Back button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: const [
                  Icon(Icons.arrow_back,
                      size: 18, color: Color(0xFF475569)),
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

            // Title (operator name or default)
            Expanded(
              child: Center(
                child: Text(
                  widget.args.operatorName.isNotEmpty
                      ? widget.args.operatorName
                      : 'Enter Details',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),

            // Help / FAQ button
            GestureDetector(
              onTap: () => setState(() => _isFAQOpen = true),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.transparent,
                ),
                child: const Icon(Icons.help_outline,
                    size: 24, color: Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info card widget ──
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF), // blue-50
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Please enter your DTH subscriber ID or Registered Mobile Number '
        'to proceed with the recharge.',
        style: TextStyle(
          fontSize: 14,
          color: Color(0xFF1D4ED8), // blue-700
          height: 1.5,
        ),
      ),
    );
  }

  // ── Continue button widget ──
  Widget _buildContinueButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _loading ? null : _handleContinue,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626), // red-600
          disabledBackgroundColor:
              const Color(0xFFDC2626).withOpacity(0.6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text(
                'Continue',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}