import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../services/api_service.dart';

// ─── Data Model ───────────────────────────────────────────────────────────────

class TransactionModel {
  final String id;
  final String type;
  final String provider;
  final double amount;
  final String date;
  final String time;
  final String status;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.provider,
    required this.amount,
    required this.date,
    required this.time,
    required this.status,
  });

  /// Mirrors React's formattedTransactions map()
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final datetimeStr = json['transaction_datetime']?.toString() ?? '';
    final parts = datetimeStr.split(' ');
    final dateStr = parts.isNotEmpty ? parts[0] : '';
    final timeStr = parts.length > 1 ? _formatTime(parts[1]) : '12:00 AM';

    return TransactionModel(
      id: (json['id'] ?? json['transaction_id'] ?? '').toString(),
      type: json['type']?.toString() ?? 'Recharge',
      provider: json['provider']?.toString() ?? 'Unknown',
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
      date: dateStr,
      time: timeStr,
      status: json['status']?.toString() ?? 'Pending',
    );
  }

  /// Mirrors React's toLocaleTimeString with hour12: true
  static String _formatTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      int hour = int.parse(parts[0]);
      final minute = parts.length > 1 ? parts[1] : '00';
      final period = hour >= 12 ? 'PM' : 'AM';
      if (hour > 12) hour -= 12;
      if (hour == 0) hour = 12;
      return '$hour:$minute $period';
    } catch (_) {
      return timeStr;
    }
  }

  bool get isEmi => type.toLowerCase() == 'emi';
}

// ─── Main Screen ──────────────────────────────────────────────────────────────

class TransactionsScreen extends StatefulWidget {
  final String userId;

  const TransactionsScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  // Mirrors React: useState(null), useState(false), useState([]), useState(true), useState(null)
  String? _activeFilter;
  bool _showFilters = false;
  List<TransactionModel> _transactions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  // Mirrors React's fetchTransactions inside useEffect
  Future<void> _fetchTransactions() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });
      final response = await http.get(Uri.parse(
      '${ApiConstants.userBaseUrl}/get_transactions.php?user_id=${widget.userId}',
    ));
      final result = jsonDecode(response.body);
      if (result['status'] == 'success') {
        setState(() {
          _transactions = (result['data'] as List)
              .map((t) => TransactionModel.fromJson(t as Map<String, dynamic>))
              .toList();
        });
      } else {
        setState(() => _error = result['message'] ?? 'Failed to load transactions');
      }
    } catch (e) {
      setState(() => _error = 'Failed to load transactions. Please try again later.');
    } finally {
      setState(() => _loading = false);
    }
  }

  // Mirrors React's filteredTransactions filter()
  List<TransactionModel> get _filteredTransactions {
    if (_activeFilter == null) return _transactions;
    if (_activeFilter == 'Success' || _activeFilter == 'Failed') {
      return _transactions.where((t) => t.status == _activeFilter).toList();
    }
    return _transactions.where((t) => t.type == _activeFilter).toList();
  }

  // Mirrors React's groupedTransactions reduce()
  Map<String, List<TransactionModel>> get _groupedTransactions {
    final groups = <String, List<TransactionModel>>{};
    for (final t in _filteredTransactions) {
      final label = _formatGroupDate(t.date);
      groups.putIfAbsent(label, () => []).add(t);
    }
    return groups;
  }

  String _formatGroupDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildHeader(),
              const SizedBox(height: 16),
              // Animated filter panel — mirrors the max-h transition in React
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _showFilters
                    ? Column(
                        children: [
                          _TransactionFilter(
                            activeFilter: _activeFilter,
                            onFilterChanged: (f) =>
                                setState(() => _activeFilter = f),
                          ),
                          const SizedBox(height: 16),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transactions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            Text(
              'Track your payment history',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        // Filter toggle button — mirrors the filter icon button in React
        GestureDetector(
          onTap: () => setState(() => _showFilters = !_showFilters),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _showFilters
                  ? const Color(0xFF2563EB)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _showFilters
                      ? const Color(0xFF2563EB).withOpacity(0.3)
                      : Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.filter_list_rounded,
              size: 20,
              color: _showFilters ? Colors.white : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Body ──────────────────────────────────────────────────────────────────

  Widget _buildBody() {
    // Loading state — mirrors the animate-spin div in React
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
        ),
      );
    }

    // Error state
    if (_error != null) {
      return _ErrorState(error: _error!, onRetry: _fetchTransactions);
    }

    // Empty state
    if (_filteredTransactions.isEmpty) {
      return _EmptyState(activeFilter: _activeFilter);
    }

    // Grouped transaction list
    final groups = _groupedTransactions;
    return ListView.separated(
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (_, i) {
        final date = groups.keys.elementAt(i);
        final txns = groups[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date group header — mirrors the date label + hr line
            _DateHeader(date: date),
            const SizedBox(height: 8),
            ...txns.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _TransactionCard(transaction: t),
                )),
          ],
        );
      },
    );
  }
}

// ─── Transaction Filter ───────────────────────────────────────────────────────
/// Mirrors React's <TransactionFilter> component

class _TransactionFilter extends StatelessWidget {
  final String? activeFilter;
  final ValueChanged<String?> onFilterChanged;

  const _TransactionFilter({
    Key? key,
    required this.activeFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  static const _filters = [
    {'key': 'All', 'label': 'All', 'icon': null},
    {'key': 'Success', 'label': 'Success', 'icon': Icons.check_circle_outline},
    {'key': 'Failed', 'label': 'Failed', 'icon': Icons.cancel_outlined},
    {'key': 'Recharge', 'label': 'Recharge', 'icon': Icons.phone_outlined},
    {'key': 'EMI', 'label': 'EMI', 'icon': Icons.credit_card_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final filter = _filters[i];
          final key = filter['key'] as String;
          final isActive = activeFilter == key ||
              (activeFilter == null && key == 'All');
          final iconData = filter['icon'] as IconData?;

          return GestureDetector(
            onTap: () => onFilterChanged(key == 'All' ? null : key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: isActive
                    ? const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                      )
                    : null,
                color: isActive ? null : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isActive
                      ? Colors.transparent
                      : Colors.grey.shade200,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  if (iconData != null) ...[
                    Icon(iconData,
                        size: 13,
                        color: isActive ? Colors.white : Colors.grey.shade600),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    filter['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Transaction Card ─────────────────────────────────────────────────────────
/// Mirrors React's <TransactionCard> component with expand/collapse

class _TransactionCard extends StatefulWidget {
  final TransactionModel transaction;

  const _TransactionCard({Key? key, required this.transaction}) : super(key: key);

  @override
  State<_TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<_TransactionCard> {
  // Mirrors React: const [expanded, setExpanded] = useState(false)
  bool _expanded = false;

  String _formatCardDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = ['Jan','Feb','Mar','Apr','May','Jun',
                      'Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _txnId() =>
      'TXN${widget.transaction.id.toString().padLeft(6, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = widget.transaction;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main row — mirrors the clickable top section
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Icon box
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      t.isEmi
                          ? Icons.credit_card_outlined
                          : Icons.phone_outlined,
                      size: 20,
                      color: t.isEmi
                          ? const Color(0xFF7C3AED)
                          : const Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Provider + date/time
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.provider,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 11, color: Colors.grey.shade400),
                            const SizedBox(width: 3),
                            Text(_formatCardDate(t.date),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500)),
                            Text(' • ',
                                style: TextStyle(
                                    color: Colors.grey.shade300,
                                    fontSize: 11)),
                            Icon(Icons.access_time_outlined,
                                size: 11, color: Colors.grey.shade400),
                            const SizedBox(width: 3),
                            Text(t.time,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Amount + status + chevron
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${t.amount.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _StatusBadge(status: t.status),
                          const SizedBox(width: 4),
                          Icon(
                            _expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Expanded details — mirrors the max-h animated div in React
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expanded
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border(
                          top: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _DetailCell(
                                label: 'TYPE',
                                child: _TypeBadge(type: t.type),
                              ),
                            ),
                            Expanded(
                              child: _DetailCell(
                                label: 'TRANSACTION ID',
                                child: Text(
                                  _txnId(),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _DetailCell(
                          label: 'DATE & TIME',
                          child: Text(
                            '${_formatCardDate(t.date)} at ${t.time}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _DetailCell extends StatelessWidget {
  final String label;
  final Widget child;

  const _DetailCell({Key? key, required this.label, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────
/// Mirrors React's <StatusBadge> component

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({Key? key, required this.status}) : super(key: key);

  Color get _bg {
    switch (status) {
      case 'Success': return const Color(0xFFDCFCE7);
      case 'Failed': return const Color(0xFFFEE2E2);
      case 'Pending': return const Color(0xFFFEF9C3);
      default: return const Color(0xFFF3F4F6);
    }
  }

  Color get _text {
    switch (status) {
      case 'Success': return const Color(0xFF15803D);
      case 'Failed': return const Color(0xFFB91C1C);
      case 'Pending': return const Color(0xFFB45309);
      default: return const Color(0xFF374151);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: _text.withOpacity(0.2)),
      ),
      child: Text(
        status,
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600, color: _text),
      ),
    );
  }
}

// ─── Type Badge ───────────────────────────────────────────────────────────────
/// Mirrors React's <TypeBadge> component

class _TypeBadge extends StatelessWidget {
  final String type;
  const _TypeBadge({Key? key, required this.type}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isEmi = type.toLowerCase() == 'emi';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isEmi ? const Color(0xFFEDE9FE) : const Color(0xFFDBEAFE),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: isEmi
              ? const Color(0xFF7C3AED).withOpacity(0.2)
              : const Color(0xFF2563EB).withOpacity(0.2),
        ),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isEmi ? const Color(0xFF6D28D9) : const Color(0xFF1D4ED8),
        ),
      ),
    );
  }
}

// ─── Date Header ─────────────────────────────────────────────────────────────
/// Mirrors React's date group label + gradient hr line

class _DateHeader extends StatelessWidget {
  final String date;
  const _DateHeader({Key? key, required this.date}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          date,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFD1D5DB), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
/// Mirrors React's empty state with Wallet icon

class _EmptyState extends StatelessWidget {
  final String? activeFilter;
  const _EmptyState({Key? key, this.activeFilter}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3F4F6), Color(0xFFE5E7EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Icon(Icons.account_balance_wallet_outlined,
                  size: 48, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
            const Text(
              'No transactions found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            Text(
              activeFilter != null
                  ? 'No ${activeFilter!.toLowerCase()} transactions match your filter'
                  : 'Your transaction history will appear here once you make your first payment',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error State ──────────────────────────────────────────────────────────────
/// Mirrors React's error state with retry button

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({Key? key, required this.error, required this.onRetry})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  size: 40, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error Loading Transactions',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151)),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Retry',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}