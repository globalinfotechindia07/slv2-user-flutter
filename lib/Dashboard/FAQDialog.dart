import 'package:flutter/material.dart';

// ─── FAQ Data ─────────────────────────────────────────────────────────────────

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

const List<_FaqItem> _faqs = [
  _FaqItem(
    question: "What is Shubh Labh Finance Bank?",
    answer:
        "Shubh Labh Finance Bank is your trusted financial partner for everyday needs. You can:\n\n"
        "- Invest in Recurring/Fixed Deposits, apply for Personal/Business Loans, and Buy General/Life Insurance\n"
        "- Complete bill payments, recharges and send/receive money using UPI\n"
        "- Easily raise a request, manage notifications and earn rewards on every transaction",
  ),
  _FaqItem(
    question: "How can I invest in Fixed Deposit using Shubh Labh Finance Bank?",
    answer:
        "You can invest in Fixed Deposits through our mobile app or website. We offer competitive interest rates and flexible tenure options.",
  ),
  _FaqItem(
    question: "How can I apply for a loan with Shubh Labh Finance Bank?",
    answer:
        "You can apply for personal or business loans through our app. The process is simple and paperless.",
  ),
  _FaqItem(
    question: "How can I pay my EMIs using Shubh Labh Finance Bank?",
    answer:
        "EMI payments can be made easily through the app using UPI or other payment methods.",
  ),
  _FaqItem(
    question: "How can I buy a Life Insurance policy on Shubh Labh Finance Bank?",
    answer:
        "Browse and purchase life insurance policies directly through our insurance section in the app.",
  ),
  _FaqItem(
    question: "How can I buy Motor Insurance on Shubh Labh Finance Bank?",
    answer:
        "Motor insurance policies are available in our insurance section with quick quote generation.",
  ),
  _FaqItem(
    question: "Can I pay insurance premiums on Shubh Labh Finance Bank?",
    answer:
        "Yes, you can pay insurance premiums for all policies through our app using various payment methods.",
  ),
];

// ─── FAQ Dialog ───────────────────────────────────────────────────────────────

class FAQDialog extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;

  const FAQDialog({
    Key? key,
    required this.isOpen,
    required this.onClose,
  }) : super(key: key);

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => FAQDialog(isOpen: true, onClose: () => Navigator.pop(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isOpen) return const SizedBox.shrink();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 448,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  // "?" circle
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black),
                    ),
                    child: const Center(
                      child: Text(
                        '?',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Help',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: onClose,
                    child: Icon(Icons.close,
                        size: 24, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),

            // ── FAQ List ─────────────────────────────────────────────────────
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _faqs.length,
                itemBuilder: (context, index) {
                  return _FAQItemWidget(faq: _faqs[index]);
                },
              ),
            ),

            // ── Footer ───────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF2563EB)),
                    ),
                    child: const Center(
                      child: Text(
                        '?',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Still have a query?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FAQ Item (expandable) ────────────────────────────────────────────────────

class _FAQItemWidget extends StatefulWidget {
  final _FaqItem faq;
  const _FAQItemWidget({Key? key, required this.faq}) : super(key: key);

  @override
  State<_FAQItemWidget> createState() => _FAQItemWidgetState();
}

class _FAQItemWidgetState extends State<_FAQItemWidget> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Question row
          InkWell(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.faq.question,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isOpen
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ),

          // Answer
          if (_isOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  widget.faq.answer,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}