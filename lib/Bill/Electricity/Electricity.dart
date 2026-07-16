import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class ElectricityOperatorModel {
  final String id;
  final String name;
  final String category;
  final Map<String, dynamic> raw; 

  ElectricityOperatorModel({
    required this.id,
    required this.name,
    required this.category,
    required this.raw,
  });

  factory ElectricityOperatorModel.fromJson(Map<String, dynamic> json) {
    return ElectricityOperatorModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      raw: json,
    );
  }
}

// ── Color palette — mirrors colorPalette array ────────────────────────────────

class _OperatorColors {
  final Color bg;
  final Color fg;
  final Color border;
  const _OperatorColors({
    required this.bg,
    required this.fg,
    required this.border,
  });
}

const List<_OperatorColors> _colorPalette = [
  _OperatorColors(bg: Color(0xFFDBEAFE), fg: Color(0xFF1D4ED8), border: Color(0xFFBFDBFE)), // blue
  _OperatorColors(bg: Color(0xFFFFEDD5), fg: Color(0xFFC2410C), border: Color(0xFFFED7AA)), // orange
  _OperatorColors(bg: Color(0xFFFEE2E2), fg: Color(0xFFB91C1C), border: Color(0xFFFECACA)), // red
  _OperatorColors(bg: Color(0xFFF3E8FF), fg: Color(0xFF7E22CE), border: Color(0xFFE9D5FF)), // purple
  _OperatorColors(bg: Color(0xFFFEF9C3), fg: Color(0xFFA16207), border: Color(0xFFFEF08A)), // yellow
  _OperatorColors(bg: Color(0xFFDCFCE7), fg: Color(0xFF15803D), border: Color(0xFFBBF7D0)), // green
  _OperatorColors(bg: Color(0xFFE0E7FF), fg: Color(0xFF3730A3), border: Color(0xFFC7D2FE)), // indigo
  _OperatorColors(bg: Color(0xFFFCE7F3), fg: Color(0xFF9D174D), border: Color(0xFFFBCFE8)), // pink
  _OperatorColors(bg: Color(0xFFF1F5F9), fg: Color(0xFF475569), border: Color(0xFFE2E8F0)), // gray
  _OperatorColors(bg: Color(0xFFCCFBF1), fg: Color(0xFF0F766E), border: Color(0xFF99F6E4)), // teal
];

_OperatorColors _getOperatorColor(String name) {
  int hash = 0;
  for (int i = 0; i < name.length; i++) {
    hash = name.codeUnitAt(i) + ((hash << 5) - hash);
  }
  final index = hash.abs() % _colorPalette.length;
  return _colorPalette[index];
}

// ── Main Screen ───────────────────────────────────────────────────────────────

class ElectricityScreen extends StatefulWidget {
  const ElectricityScreen({super.key});

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  // ── State — mirrors React useState ──────────────────────────────────────
  List<ElectricityOperatorModel> _operators = [];
  String _searchQuery = '';
  bool _loading = true;
  bool _isFAQOpen = false;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchOperators();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchOperators() async {
    try {
      final data = await ApiService.getOperators(category: 'Electricity');
      final raw = data['response']?['data'] ?? data['data'];
      if (raw is List) {
        setState(() {
          _operators = raw
              .map((e) =>
                  ElectricityOperatorModel.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching electricity operators: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ElectricityOperatorModel> get _filteredOperators {
    if (_searchQuery.isEmpty) return _operators;
    return _operators
        .where((op) =>
            op.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.iconBgRed,
                  Colors.white,
                  AppColors.iconBgBlue,
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Sticky Header ──────────────────────────────────────
                  _buildHeader(),

                  // ── Title & Search ─────────────────────────────────────
                  _buildTitleAndSearch(),

                  // ── Operator list / skeleton / empty ───────────────────
                  Expanded(
                    child: _loading
                        ? _buildSkeleton()
                        : _buildOperatorList(),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── FAQ Sidebar overlay ──────────────────────────────────────────
        if (_isFAQOpen)
          Positioned.fill(
            child: _FaqSidebar(
              onClose: () => setState(() => _isFAQOpen = false),
            ),
          ),
      ],
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.80),
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
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
                Icon(Icons.arrow_back, size: 16, color: AppColors.textGrey),
                SizedBox(width: 6),
                Text(
                  'Back',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textGrey,
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
              color: AppColors.textDark,
            ),
          ),

          // Help button
          GestureDetector(
            onTap: () => setState(() => _isFAQOpen = true),
            child: const Icon(
              Icons.help_outline,
              size: 24,
              color: AppColors.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ── Title & Search bar ────────────────────────────────────────────────────

  Widget _buildTitleAndSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "All Billers" title
          const Text(
            'All Billers',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),

          // Search input with Search icon
          TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search provider...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              suffixIcon: const Icon(Icons.search,
                  size: 20, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFFE2E8F0), width: 2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => _SkeletonCard(),
    );
  }

  // ── Operator list ─────────────────────────────────────────────────────────

  Widget _buildOperatorList() {
    final list = _filteredOperators;

    // Empty state
    if (list.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Text(
            'No operators found',
            style: TextStyle(color: Color(0xFF6B7280)),
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
        final colors = _getOperatorColor(op.name);
        return _OperatorCard(
          operator: op,
          colors: colors,
          onTap: () {
            final slug = op.name.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
            Navigator.pushNamed(
              context,
              '/app/electricity-recharge/details',  // ← fixed route
              arguments: {
                'operatorName': op.name,
                'operatorId': op.id,
                'operatorData': op.raw,
              },
            );
          },
        );
      },
    );
  }
}

// ── Operator card ─────────────────────────────────────────────────────────────

class _OperatorCard extends StatelessWidget {
  final ElectricityOperatorModel operator;
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Icon(Icons.flash_on, size: 24, color: colors.fg),
            ),
            const SizedBox(width: 16),

            // Operator name
            Expanded(
              child: Text(
                operator.name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),

            // Chevron hint
            const Icon(Icons.chevron_right,
                size: 18, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

// ── Skeleton card ─────────────────────────────────────────────────────────────

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

// ── FAQ Sidebar ───────────────────────────────────────────────────────────────

class _FaqSidebar extends StatelessWidget {
  final VoidCallback onClose;

  const _FaqSidebar({required this.onClose});

  static const List<Map<String, String>> _faqs = [
    {
      'q': 'Which electricity boards are supported?',
      'a':
          'We support all major state electricity boards across India including MSEB, BESCOM, TNEB, UPPCL, and more.',
    },
    {
      'q': 'How long does it take for the bill payment to reflect?',
      'a':
          'Electricity bill payments are usually updated within 2–4 hours. In some cases it may take up to 24 hours.',
    },
    {
      'q': 'What details do I need to pay my electricity bill?',
      'a':
          'You will need your Consumer Number or Account Number as printed on your electricity bill.',
    },
    {
      'q': 'What if my payment was deducted but bill is not paid?',
      'a':
          'If the amount is debited but the bill is not paid, a refund will be initiated within 5–7 business days.',
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
            onTap: () {}, // prevent scrim tap from closing when tapping panel
            child: Container(
              width: MediaQuery.of(context).size.width * 0.82,
              height: double.infinity,
              color: Colors.white,
              child: SafeArea(
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'FAQ – Electricity Bill',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark,
                            ),
                          ),
                          GestureDetector(
                            onTap: onClose,
                            child: const Icon(Icons.close,
                                size: 24, color: AppColors.textGrey),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),

                    // FAQ list
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
                                    color: AppColors.textDark,
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
                                        color: AppColors.textGrey,
                                        height: 1.5,
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