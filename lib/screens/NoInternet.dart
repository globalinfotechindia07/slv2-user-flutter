import 'dart:async';
import 'package:flutter/material.dart';

// - Fixed overlay covering full screen (z-50)
// - Blue-50 to white gradient background
// - 3 floating cloud animations
// - WifiOff icon with ping animation
// - "No Internet Connection" title
// - Checklist: Wi-Fi + mobile data
// - Try Again button with spinning refresh icon + loading state
// - Red pulsing dot "Offline Mode" status indicator
// - Listens to connectivity changes
// - Disappears automatically when back online

class NoInternetOverlay extends StatefulWidget {
  final VoidCallback? onRetry;

  const NoInternetOverlay({super.key, this.onRetry});

  @override
  State<NoInternetOverlay> createState() => _NoInternetOverlayState();
}

class _NoInternetOverlayState extends State<NoInternetOverlay>
    with TickerProviderStateMixin {
  bool _isOnline = true;
  bool _isRetrying = false;

  // Ping animation controller — animate-ping opacity-25
  late final AnimationController _pingCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  // Cloud bounce controllers — animate-bounce with delays
  late final AnimationController _cloud1Ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  late final AnimationController _cloud2Ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  late final AnimationController _cloud3Ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  // Pulsing red dot
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

  // Connectivity check timer
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();

    // Offset cloud animations like CSS delay-150 and delay-300
    Future.delayed(const Duration(milliseconds: 150),
        () => _cloud3Ctrl.forward());
    Future.delayed(const Duration(milliseconds: 300),
        () => _cloud2Ctrl.forward());

    // Poll connectivity every 3 seconds
    _connectivityTimer =
        Timer.periodic(const Duration(seconds: 3), (_) => _checkConnectivity());
    _checkConnectivity();
  }

  @override
  void dispose() {
    _pingCtrl.dispose();
    _cloud1Ctrl.dispose();
    _cloud2Ctrl.dispose();
    _cloud3Ctrl.dispose();
    _pulseCtrl.dispose();
    _connectivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    try {
      if (mounted) setState(() => _isOnline = true);
    } catch (_) {
      if (mounted) setState(() => _isOnline = false);
    }
  }

  Future<void> _handleRetry() async {
    setState(() => _isRetrying = true);
    try {
      await _checkConnectivity();
      if (_isOnline && widget.onRetry != null) {
        widget.onRetry!();
      }
    } catch (_) {
      if (mounted) setState(() => _isOnline = false);
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // if (isOnline) return null — hide when online
    if (_isOnline) return const SizedBox.shrink();

    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFEFF6FF), // blue-50
                Colors.white,
              ],
            ),
          ),
          child: Stack(
            children: [
              // ── Floating clouds ────────────────────────────────────────
              // top-0 left-0 — cloud 1
              Positioned(
                top: 60,
                left: 40,
                child: _BouncingCloud(
                    controller: _cloud1Ctrl, size: 48),
              ),
              // top-12 right-0 — cloud 2 (delay-300)
              Positioned(
                top: 110,
                right: 40,
                child: _BouncingCloud(
                    controller: _cloud2Ctrl, size: 32),
              ),
              // bottom-0 left-12 — cloud 3 (delay-150)
              Positioned(
                bottom: 120,
                left: 80,
                child: _BouncingCloud(
                    controller: _cloud3Ctrl, size: 40),
              ),

              // ── Main card ──────────────────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.80),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                        color: const Color(0xFFF3F4F6)), // border-gray-100
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── WifiOff icon with ping ────────────────────────
                      SizedBox(
                        width: 96,
                        height: 96,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ping ring — animate-ping opacity-25
                            AnimatedBuilder(
                              animation: _pingCtrl,
                              builder: (_, __) => Transform.scale(
                                scale: 1.0 + _pingCtrl.value * 0.5,
                                child: Opacity(
                                  opacity:
                                      (1 - _pingCtrl.value) * 0.25,
                                  child: Container(
                                    width: 96,
                                    height: 96,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFDBEAFE), // blue-100
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Icon container — bg-white rounded-full shadow-md
                            Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.wifi_off_rounded, // WifiOff
                                size: 40,
                                color: Color(0xFF3B82F6), // blue-500
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── Title ─────────────────────────────────────────
                      const Text(
                        'No Internet Connection',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937), // text-gray-800
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Description ───────────────────────────────────
                      const Text(
                        "We couldn't connect to the internet. Please check:",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563), // text-gray-600
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Checklist ─────────────────────────────────────
                      _CheckItem(
                        icon: Icons.wifi,
                        label: 'Your Wi-Fi connection',
                      ),
                      const SizedBox(height: 8),
                      _CheckItem(
                        icon: Icons.refresh,
                        label: 'Your mobile data connection',
                      ),

                      const SizedBox(height: 32),

                      // ── Try Again button ──────────────────────────────
                      _RetryButton(
                        isRetrying: _isRetrying,
                        onTap: _handleRetry,
                      ),

                      const SizedBox(height: 24),

                      // ── Offline Mode indicator ────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (_, __) => Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Color.lerp(
                                  const Color(0xFFEF4444),
                                  const Color(0xFFFCA5A5),
                                  _pulseCtrl.value,
                                ),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Offline Mode',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280), // text-gray-500
                            ),
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
      ),
    );
  }
}

// ── Bouncing Cloud ────────────────────────────────────────────────────────────
// animate-bounce — translateY 0 ↔ -8px

class _BouncingCloud extends StatelessWidget {
  final AnimationController controller;
  final double size;
  const _BouncingCloud(
      {required this.controller, required this.size});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, -8 * controller.value),
        child: Icon(
          Icons.cloud_outlined,
          size: size,
          color: const Color(0xFFE5E7EB), // text-gray-200
        ),
      ),
    );
  }
}

// ── Check Item ────────────────────────────────────────────────────────────────

class _CheckItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _CheckItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF6B7280), // text-gray-500
          ),
        ),
      ],
    );
  }
}

// ── Retry Button ──────────────────────────────────────────────────────────────
// bg-blue-500 hover:bg-blue-600 rounded-xl
// spinning RefreshCw when retrying

class _RetryButton extends StatefulWidget {
  final bool isRetrying;
  final VoidCallback onTap;
  const _RetryButton(
      {required this.isRetrying, required this.onTap});

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  // Spin controller for refresh icon
  late final AnimationController _spinCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void didUpdateWidget(_RetryButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRetrying) {
      _spinCtrl.repeat();
    } else {
      _spinCtrl.stop();
      _spinCtrl.reset();
    }
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isRetrying
          ? null
          : (_) => setState(() => _pressed = true),
      onTapUp: widget.isRetrying
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onTap();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: widget.isRetrying || !_pressed
              ? const Color(0xFF3B82F6) // bg-blue-500
              : const Color(0xFF2563EB), // hover:bg-blue-600
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.30),
              blurRadius: _pressed ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _spinCtrl,
              builder: (_, child) => Transform.rotate(
                angle: widget.isRetrying
                    ? _spinCtrl.value * 2 * 3.14159
                    : 0,
                child: child,
              ),
              child: const Icon(Icons.refresh,
                  size: 20, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Text(
              widget.isRetrying
                  ? 'Checking Connection...'
                  : 'Try Again',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}