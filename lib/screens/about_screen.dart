import 'package:flutter/material.dart';

// ─── Content Data ─────────────────────────────────────────────────────────────

class _LegalSection {
  final String title;
  final String content;
  const _LegalSection({required this.title, required this.content});
}

const List<_LegalSection> _termsContent = [
  _LegalSection(
    title: '1. Account Usage',
    content:
        'Members must maintain accurate and up-to-date information. Any misuse or fraudulent activity will result in immediate account suspension.',
  ),
  _LegalSection(
    title: '2. Financial Services',
    content:
        'All financial services are subject to eligibility criteria and applicable regulations. Interest rates and charges are subject to change with notice.',
  ),
  _LegalSection(
    title: '3. Digital Banking',
    content:
        'Users are responsible for maintaining the security of their login credentials. The bank is not liable for unauthorized access due to user negligence.',
  ),
  _LegalSection(
    title: '4. Community Guidelines',
    content:
        'Members must adhere to our community-focused approach and ethical banking practices as outlined in our mission statement.',
  ),
];

const List<_LegalSection> _privacyContent = [
  _LegalSection(
    title: '1. Data Collection',
    content:
        'We collect personal and financial information necessary for providing our services, including KYC details, transaction history, and account information.',
  ),
  _LegalSection(
    title: '2. Data Protection',
    content:
        'We implement industry-standard security measures to protect your data. Information is encrypted and stored securely following banking regulations.',
  ),
  _LegalSection(
    title: '3. Information Sharing',
    content:
        'Your information may be shared with regulatory authorities and partner institutions only as required by law or with your explicit consent.',
  ),
  _LegalSection(
    title: '4. User Rights',
    content:
        'Members have the right to access, correct, and update their personal information. You may request data reports through our official channels.',
  ),
];

// ─── Main Screen ──────────────────────────────────────────────────────────────

class AboutScreen extends StatefulWidget {
  /// Optional logo asset path — mirrors React's {logo} prop
  final String? logoAsset;

  const AboutScreen({Key? key, this.logoAsset}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // Mirrors React: useState(false), useState('terms')
  bool _showLegal = false;
  String _activeTab = 'terms';

  // Mirrors React's handleBack
  void _handleBack() {
    if (_showLegal) {
      setState(() => _showLegal = false);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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

          // Animated blobs
          // const _BackgroundBlobs(),

          SafeArea(
            child: Column(
              children: [
                // Sticky header
                _buildHeader(),

                // Scrollable content
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _showLegal
                        ? _LegalContent(
                            key: const ValueKey('legal'),
                            activeTab: _activeTab,
                          )
                        : _AboutContent(
                            key: const ValueKey('about'),
                            logoAsset: widget.logoAsset,
                            onShowTerms: () => setState(() {
                              _showLegal = true;
                              _activeTab = 'terms';
                            }),
                            onShowPrivacy: () => setState(() {
                              _showLegal = true;
                              _activeTab = 'privacy';
                            }),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button — mirrors handleBack logic
                GestureDetector(
                  onTap: _handleBack,
                  child: Row(
                    children: [
                      const Icon(Icons.arrow_back,
                          size: 20, color: Color(0xFF4B5563)),
                      const SizedBox(width: 6),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Title — mirrors conditional title
                Text(
                  _showLegal ? 'Legal Information' : 'About Shubh Labh',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 40), // balance spacer
              ],
            ),
          ),

          // Tab bar — mirrors the showLegal tab row
          if (_showLegal)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  _TabButton(
                    label: 'Terms & Conditions',
                    isActive: _activeTab == 'terms',
                    activeColor: const Color(0xFFDC2626),
                    onTap: () => setState(() => _activeTab = 'terms'),
                  ),
                  _TabButton(
                    label: 'Privacy Policy',
                    isActive: _activeTab == 'privacy',
                    activeColor: const Color(0xFF2563EB),
                    onTap: () => setState(() => _activeTab = 'privacy'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Tab Button ───────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _TabButton({
    Key? key,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: isActive
                ? Border(bottom: BorderSide(color: activeColor, width: 2))
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isActive ? activeColor : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── About Content ────────────────────────────────────────────────────────────
/// Mirrors React's !showLegal branch

class _AboutContent extends StatelessWidget {
  final String? logoAsset;
  final VoidCallback onShowTerms;
  final VoidCallback onShowPrivacy;

  const _AboutContent({
    Key? key,
    this.logoAsset,
    required this.onShowTerms,
    required this.onShowPrivacy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Logo + name section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade200, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Shubh Labh',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),

          // About text card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Column(
              children: [
                Text(
                  'Shubh Labh Finance, established in May 2024 in Hinganghat, is a trusted financial institution founded under the leadership of President Ashish Sayankar. We specialize in providing accessible, innovative, and sustainable financial solutions to individuals, families, and businesses.',
                  style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                      height: 1.6),
                ),
                SizedBox(height: 12),
                Text(
                  'The bank began with a clear vision to address the financial needs of the Hinganghat community, embracing innovation and technology while maintaining a strong commitment to financial inclusion and community development.',
                  style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1F2937),
                      height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Terms & Conditions button
          _LegalNavButton(
            label: 'Terms & Conditions',
            iconColor: const Color(0xFFDC2626),
            iconBgColor: const Color(0xFFFEF2F2),
            onTap: onShowTerms,
          ),
          const SizedBox(height: 8),

          // Privacy Policy button
          _LegalNavButton(
            label: 'Privacy Policy',
            iconColor: const Color(0xFF2563EB),
            iconBgColor: const Color(0xFFEFF6FF),
            onTap: onShowPrivacy,
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              '© All rights reserved, 2024',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Legal Nav Button ─────────────────────────────────────────────────────────

class _LegalNavButton extends StatelessWidget {
  final String label;
  final Color iconColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _LegalNavButton({
    Key? key,
    required this.label,
    required this.iconColor,
    required this.iconBgColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.info_outline, size: 20, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// ─── Legal Content ────────────────────────────────────────────────────────────
/// Mirrors React's showLegal branch with terms/privacy sections

class _LegalContent extends StatelessWidget {
  final String activeTab;

  const _LegalContent({Key? key, required this.activeTab}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isTerms = activeTab == 'terms';
    final sections = isTerms ? _termsContent : _privacyContent;
    final titleColor =
        isTerms ? const Color(0xFFDC2626) : const Color(0xFF2563EB);
    final title = isTerms ? 'Terms & Conditions' : 'Privacy Policy';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 20),
            ...sections.map((section) => Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        section.content,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ─── Background Blobs ─────────────────────────────────────────────────────────

// class _BackgroundBlobs extends StatefulWidget {
//   const _BackgroundBlobs({Key? key}) : super(key: key);

//   @override
//   State<_BackgroundBlobs> createState() => _BackgroundBlobsState();
// }

// class _BackgroundBlobsState extends State<_BackgroundBlobs>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _pulse;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat(reverse: true);
//     _pulse = Tween<double>(begin: 0.2, end: 0.35)
//         .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AnimatedBuilder(
//       animation: _pulse,
//       builder: (_, __) => Stack(
//         children: [
//           Positioned(
//             top: 80,
//             right: -160,
//             child: Container(
//               width: 384,
//               height: 384,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: const Color(0xFFFECACA).withOpacity(_pulse.value),
//               ),
//             ),
//           ),
//           Positioned(
//             bottom: 80,
//             left: -160,
//             child: Container(
//               width: 384,
//               height: 384,
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 color: const Color(0xFFBFDBFE).withOpacity(_pulse.value),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }