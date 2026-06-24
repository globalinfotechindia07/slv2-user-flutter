import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
// ─────────────────────────────────────────────
// Route arguments model
// ─────────────────────────────────────────────

class ElectricityDetailsArgs {
  final String operatorName;
  final String operatorId;
  final Map<String, dynamic> operatorData;

  const ElectricityDetailsArgs({
    required this.operatorName,
    required this.operatorId,
    required this.operatorData,
  });
}

// ─────────────────────────────────────────────
// InputField — mirrors React's InputField component
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
            color: Color(0xFF374151),
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
              borderSide: const BorderSide(
                color: AppColors.primary,
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
                      fontSize: 13, color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
        ],

        // Blue hint text — mirrors:
        // <div className="text-xs text-blue-600 mb-2">Please enter your valid {label}.</div>
        const SizedBox(height: 4),
        Text(
          'Please enter your valid $label.',
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// ElectricityDetails Screen — main component
// ─────────────────────────────────────────────

class ElectricityDetails extends StatefulWidget {
  final ElectricityDetailsArgs args;

  const ElectricityDetails({super.key, required this.args});

  @override
  State<ElectricityDetails> createState() => _ElectricityDetailsState();
}

class _ElectricityDetailsState extends State<ElectricityDetails> {
  // ── State ────────────────────────────────────────────────────────────────
  bool _loading = false;
  bool _isFAQOpen = false;
  Map<String, String> _errors = {};

  // ── Controllers — one per dynamic field ─────────────────────────────────
  // mirrors: initialFormData built from operatorData
  late final TextEditingController _mainCtrl;
  TextEditingController? _ad1Ctrl;
  TextEditingController? _ad2Ctrl;
  TextEditingController? _ad3Ctrl;

  // Shorthand getters
  Map<String, dynamic> get _opData => widget.args.operatorData;
  String get _operatorName => widget.args.operatorName;
  String get _operatorId => widget.args.operatorId;

  @override
  void initState() {
    super.initState();
    // Build controllers dynamically — mirrors initialFormData logic
    _mainCtrl = TextEditingController();
    if (_opData['ad1_name'] != null) _ad1Ctrl = TextEditingController();
    if (_opData['ad2_name'] != null) _ad2Ctrl = TextEditingController();
    if (_opData['ad3_name'] != null) _ad3Ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _ad1Ctrl?.dispose();
    _ad2Ctrl?.dispose();
    _ad3Ctrl?.dispose();
    super.dispose();
  }

  // ── handleInputChange — clears error for the field on change ─────────────

  void _handleChange(String fieldKey, String value) {
    if (_errors.containsKey(fieldKey)) {
      setState(() => _errors = {..._errors}..remove(fieldKey));
    }
  }

  // ── validateForm — mirrors React validateForm ────────────────────────────

  bool _validateForm() {
    final newErrors = <String, String>{};

    // Main field
    final mainVal = _mainCtrl.text.trim();
    if (mainVal.isEmpty) {
      final displayName = _opData['displayname']?.toString();
      newErrors['main'] =
          displayName != null ? '$displayName is required' : 'Required field';
    } else if (_opData['regex'] != null) {
      final regex = RegExp(_opData['regex'].toString());
      if (!regex.hasMatch(mainVal)) {
        newErrors['main'] =
            'Invalid ${_opData['displayname'] ?? 'value'}';
      }
    }

    // ad1 field
    if (_opData['ad1_name'] != null && _ad1Ctrl != null) {
      final ad1Val = _ad1Ctrl!.text.trim();
      if (ad1Val.isEmpty) {
        final d = _opData['ad1_d_name']?.toString();
        newErrors['ad1'] = d != null ? '$d is required' : 'Required field';
      } else if (_opData['ad1_regex'] != null) {
        final regex = RegExp(_opData['ad1_regex'].toString());
        if (!regex.hasMatch(ad1Val)) {
          newErrors['ad1'] =
              'Invalid ${_opData['ad1_d_name'] ?? 'value'}';
        }
      }
    }

    // ad2 field
    if (_opData['ad2_name'] != null && _ad2Ctrl != null) {
      final ad2Val = _ad2Ctrl!.text.trim();
      if (ad2Val.isEmpty) {
        final d = _opData['ad2_d_name']?.toString();
        newErrors['ad2'] = d != null ? '$d is required' : 'Required field';
      } else if (_opData['ad2_regex'] != null) {
        final regex = RegExp(_opData['ad2_regex'].toString());
        if (!regex.hasMatch(ad2Val)) {
          newErrors['ad2'] =
              'Invalid ${_opData['ad2_d_name'] ?? 'value'}';
        }
      }
    }

    // ad3 field
    if (_opData['ad3_name'] != null && _ad3Ctrl != null) {
      final ad3Val = _ad3Ctrl!.text.trim();
      if (ad3Val.isEmpty) {
        final d = _opData['ad3_d_name']?.toString();
        newErrors['ad3'] = d != null ? '$d is required' : 'Required field';
      } else if (_opData['ad3_regex'] != null) {
        final regex = RegExp(_opData['ad3_regex'].toString());
        if (!regex.hasMatch(ad3Val)) {
          newErrors['ad3'] =
              'Invalid ${_opData['ad3_d_name'] ?? 'value'}';
        }
      }
    }

    setState(() => _errors = newErrors);
    return newErrors.isEmpty;
  }

  // ── handleContinue — mirrors React handleContinue ────────────────────────

  void _handleContinue() {
    if (!_validateForm()) return;

    // Build formData map — mirrors React's formData state
    final formData = <String, String>{
      'main': _mainCtrl.text.trim(),
      if (_ad1Ctrl != null) 'ad1': _ad1Ctrl!.text.trim(),
      if (_ad2Ctrl != null) 'ad2': _ad2Ctrl!.text.trim(),
      if (_ad3Ctrl != null) 'ad3': _ad3Ctrl!.text.trim(),
    };

    Navigator.pushNamed(
      context,
      '/app/electricity-recharge/pay',
      arguments: {
        'operatorName': _operatorName,
        'operatorId': _operatorId,
        'operatorData': _opData,
        'formData': formData,
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.iconBgRed,
                  Colors.white,
                  AppColors.iconBgBlue,
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // ── Sticky Header ────────────────────────────────────
                  _buildHeader(),

                  // ── Scrollable form fields ───────────────────────────
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),

                          // Main field — always shown
                          InputField(
                            label: _opData['displayname']?.toString() ??
                                'Consumer ID / Account Number',
                            controller: _mainCtrl,
                            placeholder: _opData['displayname']?.toString() ??
                                'Enter Consumer ID / Account Number',
                            error: _errors['main'],
                            onChanged: (v) => _handleChange('main', v),
                          ),

                          // ad1 — conditional
                          if (_opData['ad1_name'] != null &&
                              _ad1Ctrl != null) ...[
                            const SizedBox(height: 20),
                            InputField(
                              label: _opData['ad1_d_name']?.toString() ??
                                  _opData['ad1_name'].toString(),
                              controller: _ad1Ctrl!,
                              placeholder:
                                  _opData['ad1_d_name']?.toString() ??
                                      _opData['ad1_name'].toString(),
                              error: _errors['ad1'],
                              onChanged: (v) => _handleChange('ad1', v),
                            ),
                          ],

                          // ad2 — conditional
                          if (_opData['ad2_name'] != null &&
                              _ad2Ctrl != null) ...[
                            const SizedBox(height: 20),
                            InputField(
                              label: _opData['ad2_d_name']?.toString() ??
                                  _opData['ad2_name'].toString(),
                              controller: _ad2Ctrl!,
                              placeholder:
                                  _opData['ad2_d_name']?.toString() ??
                                      _opData['ad2_name'].toString(),
                              error: _errors['ad2'],
                              onChanged: (v) => _handleChange('ad2', v),
                            ),
                          ],

                          // ad3 — conditional
                          if (_opData['ad3_name'] != null &&
                              _ad3Ctrl != null) ...[
                            const SizedBox(height: 20),
                            InputField(
                              label: _opData['ad3_d_name']?.toString() ??
                                  _opData['ad3_name'].toString(),
                              controller: _ad3Ctrl!,
                              placeholder:
                                  _opData['ad3_d_name']?.toString() ??
                                      _opData['ad3_name'].toString(),
                              error: _errors['ad3'],
                              onChanged: (v) => _handleChange('ad3', v),
                            ),
                          ],

                          const SizedBox(height: 100), // space for sticky button
                        ],
                      ),
                    ),
                  ),

                  // ── Sticky bottom Continue button ────────────────────
                  _buildContinueButton(),
                ],
              ),
            ),
          ),
        ),

        // ── FAQ Sidebar overlay ──────────────────────────────────────
        if (_isFAQOpen)
          Positioned.fill(
            child: _FaqSidebar(
              onClose: () => setState(() => _isFAQOpen = false),
            ),
          ),
      ],
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: const Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              children: [
                Icon(Icons.arrow_back,
                    size: 18, color: AppColors.textGrey),
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

          // Title — operator name or fallback, truncated
          Expanded(
            child: Center(
              child: Text(
                _operatorName.isNotEmpty
                    ? _operatorName
                    : 'Enter Details',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ),

          // Help / FAQ button
          GestureDetector(
            onTap: () => setState(() => _isFAQOpen = true),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.help_outline,
                  size: 24, color: AppColors.textGrey),
            ),
          ),
        ],
      ),
    );
  }

  // ── Sticky Continue button ────────────────────────────────────────────────

  Widget _buildContinueButton() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _loading ? null : _handleContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
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
                      strokeWidth: 2, color: Colors.white),
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
      ),
    );
  }
}

// ─────────────────────────────────────────────
// FAQ Sidebar
// ─────────────────────────────────────────────

class _FaqSidebar extends StatelessWidget {
  final VoidCallback onClose;

  const _FaqSidebar({required this.onClose});

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'Where do I find my Consumer Number?',
      'a':
          'Your Consumer Number is printed on your electricity bill, usually at the top or in the account details section.',
    },
    {
      'q': 'Can I pay for any electricity board?',
      'a':
          'Yes, we support all major state electricity boards across India.',
    },
    {
      'q': 'How long does bill payment take to reflect?',
      'a':
          'Payments are usually updated within 2–4 hours. In some cases it may take up to 24 hours.',
    },
    {
      'q': 'What if my payment fails after deduction?',
      'a':
          'A refund will be initiated to your source account within 5–7 business days.',
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
                      padding:
                          const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'FAQ – Electricity Bill',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          GestureDetector(
                            onTap: onClose,
                            child: const Icon(Icons.close,
                                size: 24, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: _faqs
                            .map(
                              (faq) => ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: Text(
                                  faq['q']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 8),
                                    child: Text(
                                      faq['a']!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textGrey,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
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