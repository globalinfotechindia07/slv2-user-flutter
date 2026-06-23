import 'package:flutter/material.dart';
import '../../services/api_service.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class DthOperatorModel {
  final String id;
  final String name;
  final String category;

  DthOperatorModel({
    required this.id,
    required this.name,
    required this.category,
  });

  factory DthOperatorModel.fromJson(Map<String, dynamic> json) {
    return DthOperatorModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
    );
  }
}

// ── Main Screen ──────────────────────────────────────────────────────────────

class DthScreen extends StatefulWidget {
  const DthScreen({super.key});

  @override
  State<DthScreen> createState() => _DthScreenState();
}

class _DthScreenState extends State<DthScreen> {
  List<DthOperatorModel> _operators = [];
  String _searchQuery = '';
  bool _loading = true;
  bool _isFaqOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchOperators();
  }

  // ── API ──────────────────────────────────────────────────────────────────

  Future<void> _fetchOperators() async {
    try {
      final data = await ApiService.getOperators(category: 'Dth');
      // Mirrors: response.data.response.data
      final raw = data['response']?['data'] ?? data['data'];
      if (raw is List) {
        setState(() {
          _operators = raw
              .map((e) => DthOperatorModel.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching DTH operators: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Filtered list — mirrors filteredOperators ────────────────────────────

  List<DthOperatorModel> get _filteredOperators {
    if (_searchQuery.isEmpty) return _operators;
    return _operators
        .where((op) =>
            op.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // ── Operator color — mirrors getOperatorColor ────────────────────────────

  _OperatorColors _getOperatorColors(String name) {
    final n = name.toLowerCase();
    if (n.contains('tata')) {
      return _OperatorColors(
          bg: const Color(0xFFDBEAFE),
          fg: const Color(0xFF1D4ED8),
          border: const Color(0xFFBFDBFE));
    }
    if (n.contains('dish')) {
      return _OperatorColors(
          bg: const Color(0xFFFFEDD5),
          fg: const Color(0xFFC2410C),
          border: const Color(0xFFFED7AA));
    }
    if (n.contains('airtel')) {
      return _OperatorColors(
          bg: const Color(0xFFFEE2E2),
          fg: const Color(0xFFB91C1C),
          border: const Color(0xFFFECACA));
    }
    if (n.contains('d2h')) {
      return _OperatorColors(
          bg: const Color(0xFFF3E8FF),
          fg: const Color(0xFF7E22CE),
          border: const Color(0xFFE9D5FF));
    }
    if (n.contains('sun')) {
      return _OperatorColors(
          bg: const Color(0xFFFEF9C3),
          fg: const Color(0xFFA16207),
          border: const Color(0xFFFEF08A));
    }
    return _OperatorColors(
        bg: const Color(0xFFF1F5F9),
        fg: const Color(0xFF475569),
        border: const Color(0xFFE2E8F0));
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient — from-red-50 via-white to-blue-50
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

          SafeArea(
            child: Column(
              children: [
                // ── Header — sticky top-0 bg-white/80 backdrop-blur-sm ──────
                _buildHeader(),

                // ── "All Billers" title ──────────────────────────────────────
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'All Billers',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),

                // ── Operator list ────────────────────────────────────────────
                Expanded(
                  child: _loading ? _buildSkeleton() : _buildOperatorList(),
                ),
              ],
            ),
          ),

          // ── FAQ sidebar overlay ──────────────────────────────────────────
          if (_isFaqOpen)
            _FaqSidebar(
              title: 'DTH Recharge',
              onClose: () => setState(() => _isFaqOpen = false),
            ),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.80),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Row(
              children: [
                Icon(Icons.arrow_back, size: 16, color: Color(0xFF475569)),
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

          // Title
          const Text(
            'Select Provider',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),

          // Help button
          GestureDetector(
            onTap: () => setState(() => _isFaqOpen = true),
            child: const Icon(Icons.help_outline,
                size: 24, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }

  // ── Skeleton — animate-pulse h-20 bg-gray-200 rounded-xl ────────────────

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }

  // ── Operator list ────────────────────────────────────────────────────────

  Widget _buildOperatorList() {
    final list = _filteredOperators;

    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No operators found',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final op = list[i];
        final colors = _getOperatorColors(op.name);
        return _OperatorCard(
          operator: op,
          colors: colors,
          onTap: () {
            // Mirrors: navigate(`/app/dth-recharge/${slugified}`,
            //   { state: { operatorName, operatorId } })
            Navigator.pushNamed(
              context,
              '/app/dth-recharge/details',
              arguments: {
                'operatorName': op.name,
                'operatorId': op.id,
              },
            );
          },
        );
      },
    );
  }
}

// ── Operator colors data class ───────────────────────────────────────────────

class _OperatorColors {
  final Color bg;
  final Color fg;
  final Color border;
  const _OperatorColors(
      {required this.bg, required this.fg, required this.border});
}

// ── Operator card ────────────────────────────────────────────────────────────

class _OperatorCard extends StatelessWidget {
  final DthOperatorModel operator;
  final _OperatorColors colors;
  final VoidCallback onTap;

  const _OperatorCard({
    required this.operator,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Operator icon — p-3 rounded-xl with operator color
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Icon(Icons.tv, size: 24, color: colors.fg),
            ),
            const SizedBox(width: 16),
            // Operator name
            Text(
              operator.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton card — animate-pulse ────────────────────────────────────────────

class _SkeletonCard extends StatefulWidget {
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _anim =
      Tween<double>(begin: 0.4, end: 1.0).animate(
    CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Opacity(
        opacity: _anim.value,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ── FAQ sidebar ──────────────────────────────────────────────────────────────

class _FaqSidebar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _FaqSidebar({required this.title, required this.onClose});

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'How long does a DTH recharge take?',
      'a':
          'DTH recharges are usually processed instantly, but can take up to 30 minutes during high traffic.',
    },
    {
      'q': 'What if my recharge fails after payment?',
      'a':
          'If the recharge fails after a successful payment, the amount is automatically refunded within 3-5 business days.',
    },
    {
      'q': 'Can I recharge any DTH operator?',
      'a': 'Yes, we support all major DTH operators across India.',
    },
    {
      'q': 'Is my payment secure?',
      'a':
          'All payments are processed through Razorpay with bank-grade encryption.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.40),
        child: Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: MediaQuery.of(context).size.width * 0.82,
              height: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'FAQ - $title',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          GestureDetector(
                            onTap: onClose,
                            child: const Icon(Icons.close,
                                size: 24, color: Color(0xFF475569)),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: _faqs
                            .map(
                              (faq) => ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: Text(
                                  faq['q']!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      faq['a']!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}