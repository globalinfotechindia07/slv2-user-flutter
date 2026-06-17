import 'package:flutter/material.dart';

// ─── FAQ Data ─────────────────────────────────────────────────────────────────

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});
}

const Map<String, List<_FaqItem>> faqsByTitle = {
  "Daily Account": [
    _FaqItem(
      question: "How can I open a Daily Account with Shubh Labh Finance Bank?",
      answer: "You can visit our nearest branch or use our app to open a Daily Account.",
    ),
    _FaqItem(
      question: "What is the minimum balance requirement for a Daily Account?",
      answer: "Our Daily Account has no minimum balance requirement, making it ideal for daily transactions.",
    ),
  ],
  "Savings Account": [
    _FaqItem(
      question: "What are the benefits of a Savings Account?",
      answer: "Savings Accounts offer competitive interest rates, easy withdrawals, and online banking services.",
    ),
    _FaqItem(
      question: "How can I activate internet banking for my Savings Account?",
      answer: "Internet banking can be activated via our app or by visiting your nearest branch.",
    ),
  ],
  "Current Account": [
    _FaqItem(
      question: "What is a Current Account best used for?",
      answer: "Current Accounts are ideal for businesses and frequent transactions.",
    ),
    _FaqItem(
      question: "Are there any charges for Current Accounts?",
      answer: "Current Accounts may have nominal charges based on the services availed.",
    ),
  ],
  "Personal Loan": [
    _FaqItem(
      question: "How do I apply for a Personal Loan?",
      answer: "Personal Loans can be applied for through our mobile app or by visiting a branch.",
    ),
    _FaqItem(
      question: "What is the maximum loan tenure for a Personal Loan?",
      answer: "Personal Loans can be availed for up to 5 years.",
    ),
  ],
  "Business Loan": [
    _FaqItem(
      question: "What documents are required for a Business Loan?",
      answer: "You need business registration, financial statements, and identity proofs.",
    ),
    _FaqItem(
      question: "Can I get a Business Loan for a startup?",
      answer: "Yes, we offer loans for startups based on specific eligibility criteria.",
    ),
  ],
  "Home Loan": [
    _FaqItem(
      question: "How do I calculate EMIs for Home Loans?",
      answer: "Use our Home Loan EMI calculator available on our app and website.",
    ),
    _FaqItem(
      question: "What is the interest rate for Home Loans?",
      answer: "Competitive interest rates are offered based on tenure and loan amount.",
    ),
  ],
  "Gold Loan": [
    _FaqItem(
      question: "How is the value of gold determined for Gold Loans?",
      answer: "The loan value is based on the current market price and purity of gold.",
    ),
    _FaqItem(
      question: "How soon can I get a Gold Loan disbursed?",
      answer: "Gold Loans are processed and disbursed within hours.",
    ),
  ],
  "Shop Loan": [
    _FaqItem(
      question: "What is a Shop Loan?",
      answer: "Shop Loans help retail businesses with funding for expansion or renovation.",
    ),
    _FaqItem(
      question: "Can I apply for a Shop Loan online?",
      answer: "Yes, apply via our app or website for quick approval.",
    ),
  ],
  "Commercial Vehicle Loan": [
    _FaqItem(
      question: "What is the eligibility for a Commercial Vehicle Loan?",
      answer: "Provide proof of income, vehicle details, and ID proofs to apply.",
    ),
    _FaqItem(
      question: "Do you finance used commercial vehicles?",
      answer: "Yes, we finance both new and used commercial vehicles.",
    ),
  ],
  "JCB Loan": [
    _FaqItem(
      question: "Can I get a loan for construction equipment like JCB?",
      answer: "Yes, JCB Loans are available with flexible repayment terms.",
    ),
    _FaqItem(
      question: "What is the repayment tenure for JCB Loans?",
      answer: "Repayment tenures range from 1 to 5 years.",
    ),
  ],
  "Construction Equipment Loan": [
    _FaqItem(
      question: "What types of construction equipment are eligible for loans?",
      answer: "We provide loans for various construction equipment like excavators, loaders, and cranes.",
    ),
    _FaqItem(
      question: "What is the maximum tenure for a Construction Equipment Loan?",
      answer: "The loan tenure can go up to 7 years, depending on the equipment and eligibility.",
    ),
  ],
  "Land Loan": [
    _FaqItem(
      question: "Can I get a loan to purchase agricultural land?",
      answer: "Yes, we provide loans for purchasing agricultural or commercial land.",
    ),
    _FaqItem(
      question: "What is the eligibility for a Land Loan?",
      answer: "Eligibility depends on income proof, property documents, and credit history.",
    ),
  ],
  "RD Scheme": [
    _FaqItem(
      question: "What is the minimum tenure for an RD Scheme?",
      answer: "Recurring Deposit Schemes can start from 6 months and go up to 10 years.",
    ),
    _FaqItem(
      question: "Are there penalties for missed RD installments?",
      answer: "Yes, a nominal penalty may be charged for missed installments.",
    ),
  ],
  "Fixed Deposit": [
    _FaqItem(
      question: "What are the interest rates for Fixed Deposits?",
      answer: "Interest rates vary based on tenure and deposit amount. Please check our website for the latest rates.",
    ),
    _FaqItem(
      question: "Can I withdraw my FD before maturity?",
      answer: "Yes, premature withdrawal is allowed with applicable penalties.",
    ),
  ],
  "Sukanya Yojana": [
    _FaqItem(
      question: "Who can open a Sukanya Yojana account?",
      answer: "Parents or guardians can open this account for a girl child below 10 years of age.",
    ),
    _FaqItem(
      question: "What is the maximum deposit limit for Sukanya Yojana?",
      answer: "You can deposit up to ₹1.5 lakhs per year.",
    ),
  ],
  "Mobile Loan": [
    _FaqItem(
      question: "Can I get a loan for purchasing a smartphone?",
      answer: "Yes, we provide loans for smartphones with flexible repayment options.",
    ),
    _FaqItem(
      question: "What documents are required for a Mobile Loan?",
      answer: "ID proof, address proof, and income proof are required.",
    ),
  ],
  "Bike Loan": [
    _FaqItem(
      question: "What is the maximum loan amount for a Bike Loan?",
      answer: "You can get up to 90% of the bike's on-road price as a loan.",
    ),
    _FaqItem(
      question: "What is the tenure for Bike Loans?",
      answer: "Tenure ranges from 12 to 36 months.",
    ),
  ],
  "Bachat Gat Loan": [
    _FaqItem(
      question: "What is a Bachat Gat Loan?",
      answer: "It is a loan offered to self-help groups for financial assistance.",
    ),
    _FaqItem(
      question: "How can my group apply for a Bachat Gat Loan?",
      answer: "Submit the group's registration and financial documents at your nearest branch.",
    ),
  ],
  "Udyog Aadhar": [
    _FaqItem(
      question: "What is Udyog Aadhar?",
      answer: "It is a unique identification for small businesses provided by the government.",
    ),
    _FaqItem(
      question: "How can I apply for Udyog Aadhar services?",
      answer: "You can apply through our assistance at any branch.",
    ),
  ],
  "Gumasta": [
    _FaqItem(
      question: "What is Gumasta?",
      answer: "Gumasta is a license required for businesses to operate legally in Maharashtra.",
    ),
    _FaqItem(
      question: "Do you provide assistance with obtaining a Gumasta license?",
      answer: "Yes, we assist with documentation and application for the Gumasta license.",
    ),
  ],
  "Passport": [
    _FaqItem(
      question: "Can you help with passport applications?",
      answer: "Yes, we provide guidance and assistance for passport applications.",
    ),
    _FaqItem(
      question: "What documents are needed for a passport application?",
      answer: "Documents required include proof of identity, address, and date of birth.",
    ),
  ],
  "Pan Card": [
    _FaqItem(
      question: "How can I apply for a PAN Card?",
      answer: "Visit our branch or use our app to apply for a PAN Card.",
    ),
    _FaqItem(
      question: "What is the processing time for a PAN Card?",
      answer: "PAN Cards are usually processed within 7 to 10 working days.",
    ),
  ],
  "Food License": [
    _FaqItem(
      question: "What is a Food License?",
      answer: "It is a mandatory license for businesses involved in food production or distribution.",
    ),
    _FaqItem(
      question: "How can I apply for a Food License?",
      answer: "We provide assistance for applying for food licenses through our branch network.",
    ),
  ],
  "ITR Income Tax Return": [
    _FaqItem(
      question: "Do you assist with filing Income Tax Returns?",
      answer: "Yes, we provide assistance for ITR filing with professional support.",
    ),
    _FaqItem(
      question: "What documents are required for ITR filing?",
      answer: "Income proofs, PAN Card, and bank statements are typically required.",
    ),
  ],
  "Insurance Services": [
    _FaqItem(
      question: "What types of insurance do you offer?",
      answer: "We offer health, life, motor, and general insurance policies.",
    ),
    _FaqItem(
      question: "How can I purchase insurance through your services?",
      answer: "Visit our branch or use our app to explore and purchase insurance plans.",
    ),
  ],
  "Car Loan": [
    _FaqItem(
      question: "What is the eligibility for a Car Loan?",
      answer: "Eligibility includes proof of income, credit history, and car details.",
    ),
    _FaqItem(
      question: "What is the maximum loan tenure for Car Loans?",
      answer: "Tenure can go up to 7 years for Car Loans.",
    ),
  ],
};

const List<_FaqItem> _defaultFaqs = [
  _FaqItem(
    question: "What is Shubh Labh Finance Bank?",
    answer:
        "Shubh Labh Finance Bank is your trusted financial partner for everyday needs. You can:\n\n- Invest in Recurring/Fixed Deposits\n- Apply for Personal/Business Loans\n- Buy General/Life Insurance",
  ),
  _FaqItem(
    question: "How can I invest in Fixed Deposit using Shubh Labh Finance Bank?",
    answer: "You can invest in Fixed Deposits through our mobile app or website.",
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
];

// ─── FAQ Sidebar ──────────────────────────────────────────────────────────────

class FAQSidebar extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final String? title;

  const FAQSidebar({
    Key? key,
    required this.isOpen,
    required this.onClose,
    this.title,
  }) : super(key: key);

  @override
  State<FAQSidebar> createState() => _FAQSidebarState();
}

class _FAQSidebarState extends State<FAQSidebar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut));

    if (widget.isOpen) _animController.forward();
  }

  @override
  void didUpdateWidget(covariant FAQSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _animController.forward();
    } else if (!widget.isOpen && oldWidget.isOpen) {
      _animController.reverse();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<_FaqItem> faqs =
        (widget.title != null ? faqsByTitle[widget.title] : null) ??
            _defaultFaqs;

    return Stack(
      children: [
        // Backdrop
        if (widget.isOpen)
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

        // Sliding panel from right
        Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              width: 304, // ~19rem
              height: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    // ── Header ──────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(color: Colors.grey.shade200)),
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
                                    fontWeight: FontWeight.bold),
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
                            onTap: widget.onClose,
                            child: Icon(Icons.close,
                                size: 24, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),

                    // ── FAQ List ─────────────────────────────────────────────
                    Expanded(
                      child: ListView.builder(
                        itemCount: faqs.length,
                        itemBuilder: (context, index) {
                          return _FAQItem(faq: faqs[index]);
                        },
                      ),
                    ),

                    // ── Footer ───────────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border(
                            top: BorderSide(color: Colors.grey.shade200)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: const Color(0xFF2563EB)),
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
            ),
          ),
        ),
      ],
    );
  }
}

// ─── FAQ Item (expandable) ────────────────────────────────────────────────────

class _FAQItem extends StatefulWidget {
  final _FaqItem faq;
  const _FAQItem({Key? key, required this.faq}) : super(key: key);

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
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
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
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

          // Answer (expanded)
          if (_isOpen)
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 14),
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