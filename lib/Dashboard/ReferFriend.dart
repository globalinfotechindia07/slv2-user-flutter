import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ReferFriendScreen extends StatefulWidget {
  final String referImg;

  const ReferFriendScreen({Key? key, required this.referImg}) : super(key: key);

  @override
  State<ReferFriendScreen> createState() => _ReferFriendScreenState();
}

class _ReferFriendScreenState extends State<ReferFriendScreen> {
  bool _showQR = false;
  bool _copied = false;

  static const String _referralLink =
      'https://shubhlabh.app/refer/YOUR_REFERRAL_CODE';
  static const String _referralMessage =
      'Join me on Shubh Labh for better financial prosperity! Download now: $_referralLink';

  Future<void> _handleWhatsAppShare() async {
    final uri = Uri.parse(
        'whatsapp://send?text=${Uri.encodeComponent(_referralMessage)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUri = Uri.parse(
          'https://web.whatsapp.com/send?text=${Uri.encodeComponent(_referralMessage)}');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleShare() async {
    await Share.share(_referralMessage, subject: 'Join Shubh Labh');
  }

  Future<void> _handleCopy() async {
    await Clipboard.setData(const ClipboardData(text: _referralLink));
    setState(() => _copied = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF1F2), Colors.white, Color(0xFFEFF6FF)],
              ),
            ),
          ),

          // // Blob decorations
          // Positioned(
          //   right: -80,
          //   top: 80,
          //   child: Container(
          //     width: 300,
          //     height: 300,
          //     decoration: BoxDecoration(
          //       color: const Color(0xFFFEE2E2).withOpacity(0.3),
          //       shape: BoxShape.circle,
          //     ),
          //   ),
          // ),
          // Positioned(
          //   left: -80,
          //   bottom: 80,
          //   child: Container(
          //     width: 300,
          //     height: 300,
          //     decoration: BoxDecoration(
          //       color: const Color(0xFFDBEAFE).withOpacity(0.3),
          //       shape: BoxShape.circle,
          //     ),
          //   ),
          // ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    border: Border(
                        bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Row(
                          children: [
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
                      const Text(
                        'Refer a Friend',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.help_outline,
                            color: Color(0xFF475569)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: Column(
                      children: [
                        // Illustration
                        Image.asset(
                          widget.referImg,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 24),

                        // Title
                        const Text(
                          'Spread the Prosperity',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Refer Shubh Labh to your friends and family',
                          style: TextStyle(
                              fontSize: 14, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 32),

                        // Share buttons grid
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _ShareButton(
                              label: 'WhatsApp',
                              icon: Icons.share,
                              bgColor: const Color(0xFFF0FDF4),
                              iconBgColor: const Color(0xFF22C55E),
                              onTap: _handleWhatsAppShare,
                            ),
                            _ShareButton(
                              label: 'Share',
                              icon: Icons.share,
                              bgColor: const Color(0xFFF5F3FF),
                              iconBgColor: const Color(0xFFA855F7),
                              onTap: _handleShare,
                            ),
                            _ShareButton(
                              label: _copied ? 'Copied!' : 'Copy',
                              icon: Icons.copy,
                              bgColor: const Color(0xFFEFF6FF),
                              iconBgColor: const Color(0xFF3B82F6),
                              onTap: _handleCopy,
                            ),
                            _ShareButton(
                              label: 'QR Code',
                              icon: Icons.qr_code,
                              bgColor: const Color(0xFFFFF7ED),
                              iconBgColor: const Color(0xFFF97316),
                              onTap: () => setState(() => _showQR = true),
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

          // QR Code Modal
          if (_showQR)
            GestureDetector(
              onTap: () => setState(() => _showQR = false),
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // prevent closing when tapping inside
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Share via QR Code',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          QrImageView(
                            data: _referralLink,
                            version: QrVersions.auto,
                            size: 200,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () =>
                                  setState(() => _showQR = false),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEAB308),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Close'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Share Button ─────────────────────────────────────────────────────────────

class _ShareButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color bgColor;
  final Color iconBgColor;
  final VoidCallback onTap;

  const _ShareButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.bgColor,
    required this.iconBgColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF334155)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}