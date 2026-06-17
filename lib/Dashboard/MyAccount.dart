import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'SecurityBanner.dart';

// ─── Loan Status Config ────────────────────────────────────────────────────────

class _StatusConfig {
  final Color bgColor;
  final Color badgeColor;
  final Color badgeTextColor;

  const _StatusConfig({
    required this.bgColor,
    required this.badgeColor,
    required this.badgeTextColor,
  });
}

const Map<String, _StatusConfig> _loanStatusConfig = {
  'pending': _StatusConfig(
    bgColor: Color(0xFFFEFCE8),
    badgeColor: Color(0xFFFEF9C3),
    badgeTextColor: Color(0xFF854D0E),
  ),
  'approved': _StatusConfig(
    bgColor: Color(0xFFF0FDF4),
    badgeColor: Color(0xFFDCFCE7),
    badgeTextColor: Color(0xFF166534),
  ),
  'active': _StatusConfig(
    bgColor: Color(0xFFEFF6FF),
    badgeColor: Color(0xFFDBEAFE),
    badgeTextColor: Color(0xFF1E40AF),
  ),
  'rejected': _StatusConfig(
    bgColor: Color(0xFFFEF2F2),
    badgeColor: Color(0xFFFEE2E2),
    badgeTextColor: Color(0xFF991B1B),
  ),
  'completed': _StatusConfig(
    bgColor: Color(0xFFFAF5FF),
    badgeColor: Color(0xFFF3E8FF),
    badgeTextColor: Color(0xFF6B21A8),
  ),
  'default': _StatusConfig(
    bgColor: Color(0xFFF9FAFB),
    badgeColor: Color(0xFFF3F4F6),
    badgeTextColor: Color(0xFF1F2937),
  ),
};

_StatusConfig _getStatusConfig(String status) {
  return _loanStatusConfig[status.toLowerCase()] ??
      _loanStatusConfig['default']!;
}

// ─── MyAccount Screen ──────────────────────────────────────────────────────────

class MyAccountScreen extends StatefulWidget {
  final String userId;

  const MyAccountScreen({super.key, required this.userId});

  @override
  State<MyAccountScreen> createState() => _MyAccountScreenState();
}

class _MyAccountScreenState extends State<MyAccountScreen> {
  List<dynamic> _loanData = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.userId.isNotEmpty) {
      _fetchLoanApplications();
    }
  }
  @override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (widget.userId.isNotEmpty) {
    _fetchLoanApplications();
  }
}
  // FIX: Added didUpdateWidget so the list refetches when userId changes,
  // matching React's useEffect([userId]) dependency behaviour.
  @override
  void didUpdateWidget(covariant MyAccountScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId && widget.userId.isNotEmpty) {
      _fetchLoanApplications();
    }
  }

  // ── Mirrors: fetchLoanApplications ─────────────────────────────────────────

  Future<void> _fetchLoanApplications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getLoanApplications(widget.userId);
      if (response['success'] == 1) {
        setState(() {
          _loanData = response['loanApplications'] ?? [];
        });
      } else {
        setState(() {
          _error = response['message']?.toString() ??
              'Failed to fetch loan applications.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch loan applications. Please try again later.';
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── Mirrors: handleSelectEMIPlan → navigate('/app/emi-plan-selector') ───────

void _handleSelectEMIPlan(Map<String, dynamic> loan) {
  Navigator.of(context).pushNamed(
    '/app/emi-plan-selector',
    arguments: {
      'loanDetails': {
        ...loan,
        'min_tenure': '3',
        'max_tenure': '12',
        'interest_rate': loan['interest_rate'] ?? '2.5',
        'processing_fee': loan['processing_fee'] ?? '0',
        'interestRateType': loan['interestRateType'] ?? 'per_month',
        'interestRateMethod': loan['interestRateMethod'] ?? 'flat',
        'processingFeeType': loan['processingFeeType'] ?? 'charged_separately',
        'pstitle': 'Mobile Loan Service',
      },
      'userProfile': {'id': widget.userId, 'name': ''},
    },
  );
}

  // ── Mirrors: onViewDetails → navigate('/app/loanDetails') ──────────────────

  void _onViewDetails(Map<String, dynamic> loan) {
    Navigator.of(context).pushNamed(
      '/app/loanDetails',
      arguments: loan,
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title — mirrors <h1>My Accounts</h1>
          const Text(
            'My Accounts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 8),

          // Section title — mirrors <h3>My Loans</h3>
          const Center(
            child: Text(
              'My Loans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // FIX: Error state is now shown separately from the empty state,
          // matching React where error and empty are distinct UI conditions.
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null)
            _buildErrorState()
          else if (_loanData.isEmpty)
            _buildEmptyState()
          else
            _buildLoanList(),

          const SizedBox(height: 24),

          // Security Banner — mirrors <SecurityBanner />
          const SecurityBanner(),
        ],
      ),
    );
  }

  // ── Error State ────────────────────────────────────────────────────────────
  // FIX: Separated from empty state. Previously errors fell into the empty
  // state widget and showed as a subtitle, with no visual distinction.
  // Now shows a dedicated error icon + message + retry button.

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            // Retry button — not in React (loading/error was commented out),
            // added here as a Flutter best practice since there's no page reload.
            TextButton.icon(
              onPressed: _fetchLoanApplications,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Try Again'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF2563EB),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────────
  // Mirrors: <FileX /> + "No Active Loans" + subtitle

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.file_copy_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Active Loans',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "You don't have any loans at the moment.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loan List ──────────────────────────────────────────────────────────────
  // Mirrors: loanData.map((loan) => <LoanCard />)

  Widget _buildLoanList() {
    return Column(
      children: _loanData.map<Widget>((loan) {
        final loanMap = Map<String, dynamic>.from(loan as Map);
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _LoanCard(
            loan: loanMap,
            onSelectEMIPlan: () => _handleSelectEMIPlan(loanMap),
            onViewDetails: () => _onViewDetails(loanMap),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Loan Card ─────────────────────────────────────────────────────────────────

class _LoanCard extends StatelessWidget {
  final Map<String, dynamic> loan;
  final VoidCallback onSelectEMIPlan;
  final VoidCallback onViewDetails;

  const _LoanCard({
    required this.loan,
    required this.onSelectEMIPlan,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final status = (loan['status'] ?? 'default').toString().toLowerCase();
    final config = _getStatusConfig(status);

    // Mirrors: loan?.loan_id ? 'Loan ID: ...' : 'Application ID: ...'
    final String idLabel = (status == 'active' || status == 'completed')
        ? 'Loan ID: ${loan['loan_id'] ?? ''}'
        : 'Application ID: ${loan['application_id'] ?? ''}';

    // Mirrors: loan?.approved_limit != 0.00 ? show loan amount : show product price
    final bool showApprovedLimit =
        status == 'active' || status == 'completed';

    final String amountLabel =
        showApprovedLimit ? 'Loan Amount' : 'Product Price';
    final String amountValue = showApprovedLimit
        ? '₹${loan['approved_limit']}'
        : '₹${loan['product_price'] ?? ''}';

    return Container(
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Top row ─────────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: icon + brand/model + id
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_android,
                          size: 22, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${loan['brand'] ?? ''}-${loan['model'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              idLabel,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Right: amount + status badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      amountValue,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: config.badgeColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: config.badgeTextColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Divider ──────────────────────────────────────────────────────
          Divider(height: 1, color: Colors.grey.shade200),

          // ── Bottom row ───────────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: EMI info (active) or Select EMI Plan button (approved)
                if (status == 'active' || status == 'completed')
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 4),
                      Text(
                        '${loan['paid_emi'] ?? 0}/${loan['total_emi'] ?? 0} EMIs paid',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  )
                else if (status == 'approved')
                  GestureDetector(
                    onTap: onSelectEMIPlan,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Select EMI Plan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1D4ED8),
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(),

                // Right: View Details button — always shown
                GestureDetector(
                  onTap: onViewDetails,
                  child: Row(
                    children: [
                      Icon(Icons.remove_red_eye_outlined,
                          size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
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