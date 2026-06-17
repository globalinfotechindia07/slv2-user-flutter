import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:async';

class NotificationScreen extends StatefulWidget {
  final String userId;

  const NotificationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    // Re-fetch every 30 seconds — mirrors setInterval(fetchNotifications, 30000)
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _fetchNotifications(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // Mirrors fetchNotifications
  Future<void> _fetchNotifications() async {
    try {
      final data = await ApiService.getNotifications(widget.userId);
      final List list = data['notifications'] ?? [];
      setState(() {
        _notifications = list.map((n) => {
          ...Map<String, dynamic>.from(n),
          'is_read': n['is_read'] == '1' || n['is_read'] == true,
        }).toList();
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() => _loading = false);
    }
  }

  // Mirrors markAsRead
  Future<void> _markAsRead(String notificationId) async {
    try {
      await ApiService.markAsRead(notificationId, widget.userId);
      setState(() {
        _notifications = _notifications.map((n) {
          if (n['id'].toString() == notificationId) {
            return {...n, 'is_read': true};
          }
          return n;
        }).toList();
      });
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  // Mirrors markAllAsRead
  Future<void> _markAllAsRead() async {
    final unread =
        _notifications.where((n) => n['is_read'] == false).toList();
    await Future.wait(
      unread.map((n) => _markAsRead(n['id'].toString())),
    );
    setState(() {
      _notifications =
          _notifications.map((n) => {...n, 'is_read': true}).toList();
    });
  }

  bool get _hasUnread => _notifications.any((n) => n['is_read'] == false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

          // Blob decorations
          Positioned(
            right: -80, top: 80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -80, bottom: 80,
            child: Container(
              width: 300, height: 300,
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
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

                      // Centered title
                      const Expanded(
                        child: Text(
                          'Notifications',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),

                      // Mark all as read
                      if (_hasUnread)
                        GestureDetector(
                          onTap: _markAllAsRead,
                          child: const Text(
                            'Mark all as read',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        )
                      else
                        const SizedBox(width: 80), // balance layout
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: _loading
                      ? const Center(
                          child: Text(
                            'Loading...',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        )
                      : _notifications.isEmpty
                          ? const _EmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _notifications.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final n = _notifications[index];
                                return _NotificationCard(
                                  notification: n,
                                  onMarkRead: () =>
                                      _markAsRead(n['id'].toString()),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onMarkRead;

  const _NotificationCard({
    Key? key,
    required this.notification,
    required this.onMarkRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isRead = notification['is_read'] == true;
    final String message = notification['message'] ?? '';
    final String createdAt = notification['created_at'] ?? '';

    String formattedDate = '';
    try {
      final dt = DateTime.parse(createdAt);
      formattedDate =
          '${dt.day}/${dt.month}/${dt.year}  ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      formattedDate = createdAt;
    }

    return Container(
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF0F7FF),
        borderRadius: BorderRadius.circular(10),
        border: Border(
          left: BorderSide(
            color: isRead ? Colors.transparent : const Color(0xFF3B82F6),
            width: isRead ? 0 : 4,
          ),
          top: BorderSide(color: const Color(0xFFE2E8F0)),
          right: BorderSide(color: const Color(0xFFE2E8F0)),
          bottom: BorderSide(color: const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        isRead ? FontWeight.normal : FontWeight.w600,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Action buttons
          Row(
            children: [
              if (!isRead)
                _IconBtn(
                  icon: Icons.check,
                  color: const Color(0xFF2563EB),
                  hoverColor: const Color(0xFFEFF6FF),
                  onTap: onMarkRead,
                ),
              _IconBtn(
                icon: Icons.delete_outline,
                color: const Color(0xFFDC2626),
                hoverColor: const Color(0xFFFFF1F2),
                onTap: () {}, // wire up delete if needed
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Icon Button ──────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color hoverColor;
  final VoidCallback onTap;

  const _IconBtn({
    Key? key,
    required this.icon,
    required this.color,
    required this.hoverColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 48, color: Color(0xFFCBD5E1)),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}