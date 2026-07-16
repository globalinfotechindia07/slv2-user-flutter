import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:async';
import 'sidebar.dart';
import 'FAQSidebar.dart';

class AppHeader extends StatefulWidget {
  final String userId;
  final VoidCallback onLogout;
  const AppHeader({
    super.key,
    required this.userId,
    required this.onLogout,
  });

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  bool _isSidebarOpen = false;
  bool _isFAQOpen = false;
  bool _hasUnread = false;

  @override
  void initState() {
    super.initState();
    if (widget.userId.isNotEmpty) {
      _checkUnreadNotifications();
    }
  }

  @override
  void didUpdateWidget(covariant AppHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId && widget.userId.isNotEmpty) {
        _checkUnreadNotifications();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }


  Future<void> _checkUnreadNotifications() async {
  try {
    final data = await ApiService.getNotifications(widget.userId);
    final List notifications = data['notifications'] ?? [];
    final bool unreadExists =
        notifications.any((n) => n['is_read'] == '0');
    if (mounted) setState(() => _hasUnread = unreadExists);
  } catch (e) {
    debugPrint('Error checking notifications: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Header bar ────────────────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: hamburger + logo
              Row(
                children: [
                  _HeaderIconBtn(
                    icon: Icons.menu,
                    onTap: () => setState(() => _isSidebarOpen = true),
                  ),
                  const SizedBox(width: 8),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Shubh',
                          style: TextStyle(
                            color: Color(0xFFDC2626),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        TextSpan(
                          text: 'labh',
                          style: TextStyle(
                            color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Right: notification + help
              Row(
                children: [
                  // Bell with unread dot
                  Stack(
                    children: [
                      _HeaderIconBtn(
                        icon: Icons.notifications_none,
                        onTap: () => Navigator.pushNamed(
                            context, '/app/notification'),
                      ),
                      if (_hasUnread)
                        const Positioned(
                          top: 6,
                          right: 6,
                          child: _PulseDot(),
                        ),
                    ],
                  ),
                  _HeaderIconBtn(
                    icon: Icons.help_outline,
                    onTap: () => setState(() => _isFAQOpen = true),
                  ),
                ],
              ),
            ],
          ),
        ),
        Sidebar(
          isOpen: _isSidebarOpen,
          onClose: () => setState(() => _isSidebarOpen = false),
          userId: widget.userId,
          onLogout: widget.onLogout,
        ),
        FAQSidebar(
          isOpen: _isFAQOpen,
          onClose: () => setState(() => _isFAQOpen = false),
        ),
      ],
    );
  }
}

// ─── Header Icon Button ───────────────────────────────────────────────────────

class _HeaderIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  // FIX: Updated to modern super.key syntax
  const _HeaderIconBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 24, color: const Color(0xFF4B5563)),
        ),
      ),
    );
  }
}

// ─── Pulsing Red Dot ──────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  const _PulseDot({super.key});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFFEF4444),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}