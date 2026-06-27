import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/about_screen.dart';
import '../Dashboard/ReferFriend.dart';
import '../Dashboard/Profile/profile_screen.dart';
import '../Dashboard/ManageMpin.dart';
import '../screens/support_screen.dart';
// ─── Menu Item Model ──────── ──────────────────────────────────────────────────

class _MenuItem {
  final IconData icon;
  final String label;
  final String desc;
  final String? path;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.desc,
    this.path,
  });
}

// ─── Main Sidebar Widget ──────────────────────────────────────────────────────

class AppSidebar extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback onLogout;
  final String userId;
  final String phoneNumber;

  const AppSidebar({
    Key? key,
    required this.isOpen,
    required this.onClose,
    required this.onLogout,
    required this.userId,
    required this.phoneNumber
  }) : super(key: key);

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar>
    with SingleTickerProviderStateMixin {

  // Mirrors React: useState('/api/placeholder/150/150'), useState(false)
  String? _profileImageUrl;
  bool _imageError = false;
  bool _logoutLoading = false;

  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;

  // Mirrors React's menuItems array
  final List<_MenuItem> _menuItems = const [
    _MenuItem(
      icon: Icons.person_outline,
      label: 'My Profile',
      desc: 'Add or modify personal details',
      path: '/app/profile',
    ),
    _MenuItem(
      icon: Icons.lock_outline,
      label: 'Manage mPIN',
      desc: 'Renew/Reset mPIN',
      path: '/app/mpin',
    ),
    _MenuItem(
      icon: Icons.help_outline,
      label: 'Help & Support',
      desc: 'Raise/Track a query, FAQs and more',
      path: '/app/support',
    ),
    _MenuItem(
      icon: Icons.group_outlined,
      label: 'Refer a Friend',
      desc: 'Invite your friends to Shubhlabh',
      path: '/app/refer',
    ),
    _MenuItem(
      icon: Icons.info_outline,
      label: 'About Us',
      desc: 'Privacy Policy, T&Cs, About Shubhlabh',
      path: '/app/about',
    ),
    _MenuItem(
      icon: Icons.logout,
      label: 'Logout',
      desc: 'Thank you. We will be happy to see you soon',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Slide animation — mirrors CSS translate-x-0 / -translate-x-full transition
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1, 0),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut));

    if (widget.isOpen) _animController.forward();
    _fetchUserData();
  }

  @override
  void didUpdateWidget(covariant AppSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mirrors React's isOpen conditional rendering with transition
    if (widget.isOpen && !oldWidget.isOpen) {
      _animController.forward();
    } else if (!widget.isOpen && oldWidget.isOpen) {
      _animController.reverse();
    }
    // Mirrors useEffect([userId]) — refetch if userId changes
    if (widget.userId != oldWidget.userId) {
      _fetchUserData();
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Mirrors React's fetchUserData
Future<void> _fetchUserData() async {
  try {
    final response = await ApiService.getProfile();
    if (response['success'] == true) {
      final data = response['data'] as Map<String, dynamic>? ?? {};
      final image = data['profileImage']?.toString() ?? '';
      if (image.isNotEmpty) {
        setState(() {
          _profileImageUrl =
              '${ApiConstants.newAuthBaseUrl}/$image';
          _imageError = false;
        });
      }
    }
  } catch (_) {
    setState(() => _imageError = true);
  }
}

  // Mirrors React's handleItemClick
  Future<void> _handleItemClick(_MenuItem item) async {
    if (item.label == 'Logout') {
      await _handleLogout();
      return;
    }

    widget.onClose();

    // Small delay to let sidebar close before pushing
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    switch (item.path) {
      case '/app/profile':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ProfileScreen(),
        ));
        break;

      case '/app/mpin':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ManageMPINScreen(
            userProfile: {'id': widget.userId, 'phoneNumber': ''},
          ),
        ));
        break;

      case '/app/refer':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ReferFriendScreen(
            referImg: 'assets/images/refer.png',
          ),
        ));
        break;

      case '/app/about':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const AboutScreen(),
        ));
        break;

      case '/app/support':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SupportScreen(),
        ));
  break;
    }
  }

  // Mirrors React's logout axios.post logic
  Future<void> _handleLogout() async {
  setState(() => _logoutLoading = true);
  try {
    final data = await ApiService.logout();
    if (data['success'] == true) {
      widget.onLogout();
      widget.onClose();
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/app', (route) => false);
    } else {
      debugPrint('Logout failed: ${data['message']}');
    }
  } catch (e) {
    debugPrint('Error during logout: $e');
  } finally {
    if (mounted) setState(() => _logoutLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop — mirrors <div className="fixed inset-0 bg-black/20 z-40">
        if (widget.isOpen)
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              color: Colors.black.withOpacity(0.2),
              width: double.infinity,
              height: double.infinity,
            ),
          ),

        // Sidebar panel — mirrors the sliding div w-[19rem]
        SlideTransition(
          position: _slideAnimation,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 304, // ~19rem
              height: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    // Close button + profile header
                    _buildHeader(),
                    // Menu items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ..._menuItems.map((item) => _MenuTile(
                                item: item,
                                logoutLoading: _logoutLoading &&
                                    item.label == 'Logout',
                                onTap: () => _handleItemClick(item),
                              )),
                          const SizedBox(height: 16),
                          // // Security banner
                          // const _SecurityBanner(),
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

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          // Profile image — mirrors img with onError fallback
          _profileImageUrl != null && !_imageError
              ? ClipOval(
                  child: Image.network(
                    _profileImageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholderAvatar(),
                  ),
                )
              : _placeholderAvatar(),
          const SizedBox(width: 12),
          // Greeting
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hi there',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                'Welcome back',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const Spacer(),
          // Close button — mirrors the X button top-right
          GestureDetector(
            onTap: widget.onClose,
            child: Icon(Icons.close, size: 24, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _placeholderAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        color: Color(0xFFDC2626),
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Text(
          'U',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ─── Menu Tile ────────────────────────────────────────────────────────────────
/// Mirrors React's <button> inside <li> for each menu item

class _MenuTile extends StatelessWidget {
  final _MenuItem item;
  final VoidCallback onTap;
  final bool logoutLoading;

  const _MenuTile({
    Key? key,
    required this.item,
    required this.onTap,
    this.logoutLoading = false,
  }) : super(key: key);

  bool get _isLogout => item.label == 'Logout';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: logoutLoading ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Icon
                logoutLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFDC2626)),
                        ),
                      )
                    : Icon(
                        item.icon,
                        size: 20,
                        color: _isLogout
                            ? const Color(0xFFDC2626)
                            : Colors.grey.shade500,
                      ),
                const SizedBox(width: 14),
                // Label + description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _isLogout
                              ? const Color(0xFFDC2626)
                              : const Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        item.desc,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF6B7280),
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
    );
  }
}

// ─── Security Banner ──────────────────────────────────────────────────────────
/// Mirrors React's <SecurityBanner> component

// class _SecurityBanner extends StatelessWidget {
//   const _SecurityBanner({Key? key}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(12),
//       decoration: BoxDecoration(
//         color: const Color(0xFFF0FDF4),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: const Color(0xFFBBF7D0)),
//       ),
//       child: Row(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(6),
//             decoration: BoxDecoration(
//               color: const Color(0xFFDCFCE7),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: const Icon(Icons.security,
//                 size: 16, color: Color(0xFF16A34A)),
//           ),
//           // const SizedBox(width: 10),
//           // const Expanded(
//           //   child: Column(
//           //     crossAxisAlignment: CrossAxisAlignment.start,
//           //     children: [
//           //       Text(
//           //         'Secure & Encrypted',
//           //         style: TextStyle(
//           //           fontSize: 12,
//           //           fontWeight: FontWeight.w600,
//           //           color: Color(0xFF166534),
//           //         ),
//           //       ),
//           //       Text(
//           //         'Your data is protected with 256-bit encryption',
//           //         style: TextStyle(
//           //           fontSize: 10,
//           //           color: Color(0xFF15803D),
//           //         ),
//           //       ),
//           //     ],
//           //   ),
//           // ),
//         ],
//       ),
//     );
//   }
// }