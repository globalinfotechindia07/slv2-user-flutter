import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'Header.dart';
import 'MyAccount.dart';
import 'transactions_screen.dart';
import 'featured_actions_card.dart';
import 'offers_card.dart';
import 'bill_payments_card.dart';
import 'loans_card.dart';
import 'banking_card.dart';
import 'investment_more_card.dart';
import 'insurance_card.dart';
import 'loan_swiper.dart';

// ─── Main App Screen ──────────────────────────────────────────────────────────

class ShubhLabhMobileApp extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final VoidCallback onLogout;

  const ShubhLabhMobileApp({
    Key? key,
    required this.userProfile,
    required this.onLogout,
  }) : super(key: key);

  @override
  State<ShubhLabhMobileApp> createState() => _ShubhLabhMobileAppState();
}

class _ShubhLabhMobileAppState extends State<ShubhLabhMobileApp> {
  String _currentView = 'Home';
  List<dynamic> _bankingServices = [];
  List<dynamic> _insuranceServices = [];
  List<dynamic> _investmentServices = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
  try {
    final data = await ApiService.listPopularServices();
    final List list = data['list'] ?? [];

    setState(() {
      _bankingServices =
          list.where((s) => s['pstype'] == 'banking').toList();
      _insuranceServices =
          list.where((s) => s['pstype'] == 'insurance').toList();
      _investmentServices =
          list.where((s) => s['pstype'] == 'investment').toList();
      _loading = false;
    });
  } catch (e) {
    setState(() {
      _error = e.toString();
      _loading = false;
    });
  }
}

  void _handleShare() {
    // Use share_plus package
    // Share.share('Check out this App! ${Uri.base}');
  }

  List<Map<String, dynamic>> get _menuItems => [
        {
          'icon': Icons.home_outlined,
          'activeIcon': Icons.home,
          'label': 'Home',
          'action': () => setState(() => _currentView = 'Home'),
        },
        {
          'icon': Icons.share_outlined,
          'activeIcon': Icons.share,
          'label': 'Share',
          'action': _handleShare,
        },
        {
          'icon': Icons.person_outline,
          'activeIcon': Icons.person,
          'label': 'My Account',
          'action': () => setState(() => _currentView = 'My Account'),
        },
        {
          'icon': Icons.credit_card_outlined,
          'activeIcon': Icons.credit_card,
          'label': 'Transaction',
          'action': () => setState(() => _currentView = 'Transaction'),
        },
      ];

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        body: Center(child: Text('Error: $_error')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF1F2), Colors.white, Color(0xFFEFF6FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ────────────────────────────────────────────────────
              AppHeader(
                userId: widget.userProfile['id'].toString(),
                onLogout: widget.onLogout,
              ),

              // ── Body ──────────────────────────────────────────────────────
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildCurrentView(),
              ),
            ],
          ),
        ),
      ),

      // ── Bottom Navigation ─────────────────────────────────────────────────
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'My Account':
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          child: MyAccountScreen(
            userId: widget.userProfile['id'].toString(),
          ),
        );
      case 'Transaction':
        return TransactionsScreen(
          userId: widget.userProfile['id'].toString(),
        );
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        const FeaturedActionsCard(),
        const SizedBox(height: 16),
        const OffersCard(),
        const SizedBox(height: 16),
        const BillPaymentsCard(),
        const SizedBox(height: 16),
        const LoansCard(),
        const SizedBox(height: 16),
        BankingCard(services: _bankingServices),
        const SizedBox(height: 16),
        InvestmentMoreCard(services: _investmentServices),
        const SizedBox(height: 16),
        InsuranceCard(services: _insuranceServices),
        const SizedBox(height: 16),
        LoanSwiper(userId: widget.userProfile['id'].toString()),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _menuItems.map((item) {
              final bool isActive = _currentView == item['label'];
              return GestureDetector(
                onTap: () {
                  final action = item['action'] as VoidCallback;
                  action();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFDBEAFE)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isActive
                              ? item['activeIcon'] as IconData
                              : item['icon'] as IconData,
                          size: 24,
                          color: isActive
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isActive
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}