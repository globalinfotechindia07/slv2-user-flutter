import 'package:flutter/material.dart';
import 'package:card_swiper/card_swiper.dart';
import '../services/api_service.dart';

class OffersBanner extends StatefulWidget {
  const OffersBanner({Key? key}) : super(key: key);

  @override
  State<OffersBanner> createState() => _OffersBannerState();
}

class _OffersBannerState extends State<OffersBanner> {
  List<dynamic> _offers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    try {
      final data = await ApiService.listOffersCard();
      if (data['list'] != null) {
        setState(() {
          _offers = data['list'];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'No offers available';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Failed to load offers';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();
    if (_error != null) return _buildError();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Swiper(
            itemCount: _offers.length,
            autoplay: true,
            autoplayDelay: 3000,
            pagination: const SwiperPagination(
              builder: DotSwiperPaginationBuilder(
                activeColor: Colors.black,
                color: Colors.black26,
                size: 6,
                activeSize: 8,
              ),
            ),
            itemBuilder: (context, index) {
              return _OfferCard(
                offer: _offers[index],
                // FIX: uses ApiConstants.adminBaseUrl from api_service.dart
                // instead of the removed local _adminBaseUrl field
                adminBaseUrl: ApiConstants.adminBaseUrl,
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Container(
      height: 128,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonBox(width: 80, height: 14),
          const SizedBox(height: 8),
          const _SkeletonBox(width: double.infinity, height: 32),
          const SizedBox(height: 8),
          const _SkeletonBox(width: 200, height: 14),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      height: 128,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Failed to load offers',
        style: TextStyle(color: Color(0xFFEF4444), fontSize: 13),
      ),
    );
  }
}

// ─── Offer Card ───────────────────────────────────────────────────────────────

class _OfferCard extends StatefulWidget {
  final dynamic offer;
  final String adminBaseUrl;

  const _OfferCard({
    Key? key,
    required this.offer,
    required this.adminBaseUrl,
  }) : super(key: key);

  @override
  State<_OfferCard> createState() => _OfferCardState();
}

class _OfferCardState extends State<_OfferCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        '${widget.adminBaseUrl}/${widget.offer['imageUrl'] ?? ''}';

    return GestureDetector(
      onTapDown: (_) => setState(() => _hovered = true),
      onTapUp: (_) => setState(() => _hovered = false),
      onTapCancel: () => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE5E7EB),
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
              ),

              // Hover gradient overlay
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x33000000)],
                    ),
                  ),
                ),
              ),

              // Bottom overlay with title/desc on hover
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedOpacity(
                  opacity: _hovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0x99000000)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.offer['offersTitle'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.offer['offersDesc'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.local_offer,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              widget.offer['offersNote'] ?? '',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.offer['category'] ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
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

// ─── Skeleton Box ─────────────────────────────────────────────────────────────

class _SkeletonBox extends StatelessWidget {
  final double width;
  final double height;

  const _SkeletonBox({
    Key? key,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}