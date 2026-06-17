import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart'; // provides ApiService.listOffersCard()

// ─── Offer Data Model ──────────────────────────────────────────────────────────
// Replaces hardcoded BannerData — mirrors React's offer object fields

class OfferData {
  final String id;
  final String imageUrl;
  final String offersTitle;
  final String offersDesc;
  final String offersNote;
  final String category;

  const OfferData({
    required this.id,
    required this.imageUrl,
    required this.offersTitle,
    required this.offersDesc,
    required this.offersNote,
    required this.category,
  });

  factory OfferData.fromJson(Map<String, dynamic> json) {
    return OfferData(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      offersTitle: json['offersTitle']?.toString() ?? '',
      offersDesc: json['offersDesc']?.toString() ?? '',
      offersNote: json['offersNote']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
    );
  }
}

// ─── BannerCarousel ────────────────────────────────────────────────────────────

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;

  // [CHANGED] Dynamic API-loaded offers replacing hardcoded banners list
  List<OfferData> _offers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  // ── Data Fetching ──────────────────────────────────────────────────────────
  // Mirrors React's fetchOffers() inside useEffect

  Future<void> _fetchOffers() async {
    try {
      final response = await ApiService.listOffersCard();
      // React checks response.data.list
      final list = response['list'] as List<dynamic>? ?? [];
      setState(() {
        _offers = list.map((e) => OfferData.fromJson(e)).toList();
        _loading = false;
      });
      // Start autoplay only after data is loaded — same as Swiper's behaviour
      _startTimer();
    } catch (e) {
      setState(() {
        _error = 'Failed to load offers';
        _loading = false;
      });
    }
  }

  void _startTimer() {
  _timer?.cancel();
  _timer = Timer.periodic(const Duration(seconds: 3), (_) {
    if (!mounted || _offers.isEmpty) return;
    final next = (_currentIndex + 1) % _offers.length;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  });
}

void _pauseAndResume() {
  _timer?.cancel();
  Future.delayed(const Duration(seconds: 5), () {
    if (mounted) _startTimer();
  });
}

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // ── Loading Skeleton ───────────────────────────────────────────────────────
  // Mirrors React's animate-pulse skeleton with 3 shimmer bars

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6), // gray-100
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Short bar — "h-4 w-1/4"
            _ShimmerBar(width: double.infinity * 0.25, height: 14),
            const SizedBox(height: 10),
            // Full bar — "h-8"
            _ShimmerBar(width: double.infinity, height: 28),
            const SizedBox(height: 10),
            // 3/4 bar — "h-4 w-3/4"
            _ShimmerBar(width: double.infinity * 0.75, height: 14),
          ],
        ),
      ),
    );
  }

  // ── Error State ────────────────────────────────────────────────────────────
  // Mirrors React's bg-red-50 error container

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        height: 180,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2), // red-50
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            _error!,
            style: const TextStyle(
              color: Color(0xFFEF4444), // red-500
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // [ADDED] Loading state — shown while API call is in progress
    if (_loading) return _buildSkeleton();

    // [ADDED] Error state — shown if API call fails
    if (_error != null) return _buildError();

    // Empty guard — nothing to show
    if (_offers.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: SizedBox(
        height: 180,
        child: PageView.builder(
          controller: _pageController,
          physics: const BouncingScrollPhysics(),
          itemCount: _offers.length,
          onPageChanged: (i) {
            setState(() => _currentIndex = i);
            _pauseAndResume();
          },
          itemBuilder: (_, i) => _OfferCard(
            offer: _offers[i],
            currentIndex: _currentIndex,
            totalCount: _offers.length,
          ),
        ),
      ),
    );
  }
}

// ─── OfferCard ─────────────────────────────────────────────────────────────────
// [CHANGED] Replaces text+icon _BannerCard with image-based card
// Mirrors React's OfferCard with 16:9 image + hover overlay
// Flutter uses tap/long-press to toggle overlay (no hover on mobile)

class _OfferCard extends StatefulWidget {
  final OfferData offer;
  final int currentIndex;
  final int totalCount;

  const _OfferCard({
    required this.offer,
    required this.currentIndex,
    required this.totalCount,
  });

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard>
    with SingleTickerProviderStateMixin {
  // [ADDED] Overlay visibility — replaces React's CSS hover:opacity-100
  bool _overlayVisible = false;

  // [ADDED] Scale animation — mirrors React's hover:scale-105
  late AnimationController _scaleCtrl;
  late Animation<double> _scaleAnim;

  // Base URL matching React's import.meta.env.VITE_ADMIN_BASE_URL
  static final String _baseUrl = ApiConstants.adminBaseUrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _scaleCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    _scaleCtrl.forward();
    setState(() => _overlayVisible = true);
  }

  void _onTapUp(TapUpDetails _) {
    _scaleCtrl.reverse();
    // Keep overlay visible briefly then hide — mirrors hover behaviour
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _overlayVisible = false);
    });
  }

  void _onTapCancel() {
    _scaleCtrl.reverse();
    setState(() => _overlayVisible = false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          // [ADDED] ClipRRect so image and overlay respect the card's border radius
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                // ── 16:9 image ─────────────────────────────────────────
                // Mirrors React's aspect-[16/9] image container
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    '$_baseUrl/${widget.offer.imageUrl}',
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      // Placeholder while image loads
                      return Container(
                        color: const Color(0xFFE2E8F0),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE2E8F0),
                      child: const Icon(Icons.broken_image,
                          color: Color(0xFF94A3B8), size: 40),
                    ),
                  ),
                ),

                // ── Light dark gradient always present ─────────────────
                // Mirrors React's "from-black/20 to-transparent opacity-0
                // group-hover:opacity-100"
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _overlayVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Color(0x33000000), // black/20
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bottom overlay with title, desc, note, category ────
                // Mirrors React's absolute bottom overlay
                // "from-black/60 to-transparent opacity-0 group-hover:opacity-100"
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AnimatedOpacity(
                    opacity: _overlayVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Color(0x99000000), // black/60
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // offersTitle — truncated, bold white
                          Text(
                            widget.offer.offersTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          // offersDesc
                          Text(
                            widget.offer.offersDesc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // offersNote with Tag icon — mirrors React's Tag + span
                          Row(
                            children: [
                              const Icon(Icons.local_offer,
                                  size: 12, color: Colors.white70),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  widget.offer.offersNote,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // category — white/80 opacity
                          Text(
                            widget.offer.category,
                            style: const TextStyle(
                              color: Color(0xCCFFFFFF), // white/80
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── Pagination dot — single blue dot for active slide ──
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(widget.totalCount, (i) {
                      final active = i == widget.currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 8 : 6,
                        height: active ? 8 : 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? const Color(0xFF2563EB)  // blue dot for active
                              : Colors.white.withOpacity(0.50),
                        ),
                      );
                    }),
                  ),
                ),

                // ── Pagination dots inside card ─────────────────────────
                // Kept from original Flutter card, placed at bottom center
                // Positioned(
                //   left: 0,
                //   right: 0,
                //   bottom: 8,
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.center,
                //     children: List.generate(widget.totalCount, (i) {
                //       final active = i == widget.currentIndex;
                //       return AnimatedContainer(
                //         duration: const Duration(milliseconds: 300),
                //         margin: const EdgeInsets.symmetric(horizontal: 3),
                //         width: active ? 18 : 8,
                //         height: 6,
                //         decoration: BoxDecoration(
                //           color: active
                //               ? Colors.white
                //               : Colors.white.withOpacity(0.40),
                //           borderRadius: BorderRadius.circular(3),
                //         ),
                //       );
                //     }),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shimmer Bar ───────────────────────────────────────────────────────────────
// Used by loading skeleton — mimics Tailwind's animate-pulse gray bars

class _ShimmerBar extends StatefulWidget {
  final double width;
  final double height;

  const _ShimmerBar({required this.width, required this.height});

  @override
  State<_ShimmerBar> createState() => _ShimmerBarState();
}

class _ShimmerBarState extends State<_ShimmerBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB), // gray-200
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}