import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

class _ContactMethod {
  final String title;
  final String contact;
  final String type; // 'tel' or 'email'
  final bool isRed;

  const _ContactMethod({
    required this.title,
    required this.contact,
    required this.type,
    required this.isRed,
  });
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class SupportScreen extends StatefulWidget {
  const SupportScreen({Key? key}) : super(key: key);

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  String _copied = '';
  final List<_ContactMethod> _contactMethods = const [
    _ContactMethod(
      title: 'Email Support',
      contact: 'financeshubhlabh4@gmail.com',
      type: 'email',
      isRed: true,
    ),
    _ContactMethod(
      title: 'Phone Support 1',
      contact: '+919359752157',
      type: 'tel',
      isRed: false,
    ),
    _ContactMethod(
      title: 'Phone Support 2',
      contact: '+917385307706',
      type: 'tel',
      isRed: false,
    ),
  ];
  Future<void> _handleContact(_ContactMethod method) async {
    final contact = method.contact.replaceAll(' ', '');
    final uri = method.type == 'tel'
        ? Uri.parse('tel:$contact')
        : Uri.parse('mailto:$contact');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _handleCopy(String contact) async {
    await Clipboard.setData(ClipboardData(text: contact));
    setState(() => _copied = contact);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background gradient — mirrors from-red-50 via-white to-blue-50
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

          // Animated blob decorations — mirrors animate-pulse blobs
          // const _BackgroundBlobs(),

          SafeArea(
            child: Column(
              children: [
                // Sticky header
                _buildHeader(context),

                // Main content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Support',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...List.generate(
                          _contactMethods.length,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ContactCard(
                              method: _contactMethods[i],
                              isCopied: _copied == _contactMethods[i].contact,
                              onTap: () => _handleContact(_contactMethods[i]),
                              onCopy: () => _handleCopy(_contactMethods[i].contact),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Toast notification — mirrors the fixed bottom toast in React
          if (_copied.isNotEmpty) const _ToastNotification(),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
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
          // Title
          const Text(
            'Help & Support',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF111827),
            ),
          ),
          // Help icon
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.help_outline, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// ─── Contact Card ─────────────────────────────────────────────────────────────
class _ContactCard extends StatelessWidget {
  final _ContactMethod method;
  final bool isCopied;
  final VoidCallback onTap;
  final VoidCallback onCopy;

  const _ContactCard({
    Key? key,
    required this.method,
    required this.isCopied,
    required this.onTap,
    required this.onCopy,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final accent =
        method.isRed ? const Color(0xFFDC2626) : const Color(0xFF2563EB);
    final accentBg =
        method.isRed ? const Color(0xFFFEF2F2) : const Color(0xFFEFF6FF);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  method.type == 'email'
                      ? Icons.mail_outline
                      : Icons.phone_outlined,
                  size: 22,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              // Title + contact
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.contact,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              // Copy button — mirrors the Copy icon button with stopPropagation
              GestureDetector(
                onTap: onCopy,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCopied
                        ? const Color(0xFFF0FDF4)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Icon(
                    isCopied ? Icons.check : Icons.copy_outlined,
                    size: 16,
                    color: isCopied
                        ? const Color(0xFF16A34A)
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Toast Notification ───────────────────────────────────────────────────────
class _ToastNotification extends StatefulWidget {
  const _ToastNotification({Key? key}) : super(key: key);

  @override
  State<_ToastNotification> createState() => _ToastNotificationState();
}

class _ToastNotificationState extends State<_ToastNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline,
                  size: 16, color: Color(0xFF16A34A)),
              SizedBox(width: 6),
              Text(
                'Contact copied to clipboard!',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF111827),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
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
//     _pulse = Tween<double>(begin: 0.25, end: 0.4)
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
//           // Right red blob
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
//           // Left blue blob
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