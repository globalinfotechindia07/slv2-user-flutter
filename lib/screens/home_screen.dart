import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/banner_carousel.dart';
import '../widgets/sidebar.dart';
import '../screens/transactions_screen.dart';
import '../screens/support_screen.dart';
import '../screens/about_screen.dart';
import '../screens/bill_coming_soon_screen.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Dashboard/Profile/profile_screen.dart';
import '../Dashboard/ManageMpin.dart';
import '../screens/splash_screen.dart';
import '../Dashboard/MyAccount.dart';
import '../services/auth_service.dart';
import 'dart:async';
import '../screens/loan_details_screen.dart';
import '../screens/other_loan_service_details.dart';
import '../Dashboard/FAQSidebar.dart';
import '../screens/loan_service_screen.dart';

IconData getIconFromString(String iconName) {
  const Map<String, IconData> iconMap = {
    'smartphone': Icons.phone_android,
    'truck': Icons.local_shipping_outlined,
    'car': Icons.directions_car_outlined,
    'tractor': Icons.agriculture_outlined,
    'briefcase': Icons.business_outlined,
    'coins': Icons.monetization_on,
    'shield': Icons.verified_user_outlined,
    'gift': Icons.card_giftcard,
    'piggybank': Icons.savings,
    'landmark': Icons.account_balance_outlined,
    'zap': Icons.flash_on,
    'creditcard': Icons.credit_card,
    'wallet': Icons.account_balance_wallet_outlined,
    'barchart3': Icons.bar_chart,
    'umbrella': Icons.beach_access,
    'home': Icons.home_outlined,
    'user': Icons.person_outline,
    'bell': Icons.notifications_outlined,
    'linechart': Icons.show_chart,
    'shieldcheck': Icons.verified_user,
    'landmarkicon': Icons.account_balance,
  };
  return iconMap[iconName.toLowerCase()] ?? Icons.help_outline;
}

class HomeScreen extends StatefulWidget {
  final int initialTab; 
  final Map<String, dynamic>? userProfile;
  const HomeScreen({super.key, this.initialTab = 0, this.userProfile});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late int _selectedTab;
  bool _sidebarOpen = false;
  bool _faqOpen = false;
  String _userId = '';
  String _phoneNumber = '';
  bool _userLoaded = false;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _userProfile = widget.userProfile;
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final userId = await AuthService.getUserId();
    final phone = await AuthService.getPhone();
    setState(() {
      _userId = userId;
      _phoneNumber = phone;
      _userLoaded = true;
    });
  }

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.home_rounded, label: 'Home'),
    _NavItem(icon: Icons.share, label: 'Share'),
    _NavItem(icon: Icons.person_outline, label: 'My Account'),
    _NavItem(icon: Icons.credit_card_outlined, label: 'Transaction'),
  ];

  Future<void> _handleLogout() async {
  await ApiService.logout();
  await AuthService.clearSession();
  if (mounted) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Background gradient ──
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
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            toolbarHeight: 70,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            shadowColor: Colors.black.withOpacity(0.08),
            scrolledUnderElevation: 4,
            leading: IconButton(
              icon: const Icon(Icons.menu, color: AppColors.textDark),
              onPressed: () => setState(() => _sidebarOpen = true),
            ),
            title: const AppLogo(),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppColors.textDark),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const _NotificationsDialog(),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, color: AppColors.textDark),
                onPressed: () => setState(() => _faqOpen = true),
              ),
            ],
          ),
          body: !_userLoaded
              ? const Center(child: CircularProgressIndicator())
              : IndexedStack(
                  index: _selectedTab,
                  children: [
                    _HomeBody(userId: _userId),
                    _ShareBody(),
                    MyAccountScreen(userId: _userId),
                    TransactionsScreen(userId: _userId),
                  ],
                ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_navItems.length, (i) {
                    final selected = i == _selectedTab;
                    return GestureDetector(
                      onTap: () {
                        if (i == 1) {
                          Share.share(
                            'Secure payments made simple 🔒\nSend money, pay bills anytime.\nshubhlabhpatsanstha.org',
                          );
                        } else {
                          setState(() => _selectedTab = i);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _navItems[i].icon,
                              color: selected
                                  ? AppColors.primary
                                  : Colors.grey.shade400,
                              size: 26,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _navItems[i].label,
                              style: TextStyle(
                                fontSize: 11,
                                color: selected
                                    ? AppColors.primary
                                    : Colors.grey.shade400,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        Material(
          type: MaterialType.transparency,
          child: FAQSidebar(
            isOpen: _faqOpen,
            onClose: () => setState(() => _faqOpen = false),
            title: null,
          ),
        ),
         Material(
          type: MaterialType.transparency,
          child: AppSidebar(
            isOpen: _sidebarOpen,
            onClose: () => setState(() => _sidebarOpen = false),
            onLogout: _handleLogout,
            userId: _userId,
            phoneNumber: _phoneNumber,
          ),
        ),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ── Home Body ──────────────────────────────────────────────────────────────

class _HomeBody extends StatelessWidget {
  final String userId;
  const _HomeBody({required this.userId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),

          // 1. Featured
          _FeaturedSection(),
          const SizedBox(height: 20),

          // 2. BannerCarousel
          const BannerCarousel(),
          const SizedBox(height: 20),

          // 3. Bill Payments
          _BillPaymentsSection(),
          const SizedBox(height: 20),

          // 4. Loans
          _LoansSection(userId: userId),
          const SizedBox(height: 20),

          // 5. Banking
          _BankingSection(),
          const SizedBox(height: 20),

          // 6. Investment & More
          _InvestmentSection(),
          const SizedBox(height: 20),

          // 7. Insurance
          _InsuranceSection(),
          const SizedBox(height: 20),

          // 8. My Loans swiper — now wrapped in a white card to match all other sections
          _MyLoansSection(userId: userId),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Share Body ─────────────────────────────────────────────────────────────

class _ShareBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.share, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Share the App',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the Share tab to share with friends!',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ── Featured ───────────────────────────────────────────────────────────────

class _FeaturedSection extends StatelessWidget {
  final List<_FeatureItem> items = const [
    _FeatureItem(
      Icons.access_time_rounded,
      'Fixed\nDeposit',
      AppColors.iconBgRed,
      AppColors.primary,
      '/app/loanServices',
      {'pstitle': 'FD Scheme'},
    ),
    _FeatureItem(
      Icons.phone_android,
      'Mobile\nLoan',
      AppColors.iconBgGreen,
      Color(0xFF43A047),
      '/app/mobile-loan',
      {'pstitle': 'Mobile Loan', 'psLcategory': 'Mobile'},
    ),
    _FeatureItem(
      Icons.account_balance,
      'Savings\nAccount',
      AppColors.iconBgBlue,
      AppColors.accent,
      '/app/loanServices',
      {'pstitle': 'Savings Account'},
    ),
    _FeatureItem(
      Icons.verified_user_outlined,
      'Insurance\nService',
      AppColors.iconBgYellow,
      Color(0xFFF57C00),
      '/app/loanServices',
      {'pstitle': 'Insurance Services'},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Featured',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) => _FeatureCell(item: item)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final String? route;
  final Map<String, dynamic>? routeArgs;
  const _FeatureItem(
      this.icon, this.label, this.bgColor, this.iconColor, this.route,
      [this.routeArgs]);
}

class _FeatureCell extends StatelessWidget {
  final _FeatureItem item;
  const _FeatureCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (item.route != null) {
          Navigator.pushNamed(context, item.route!,
              arguments: item.routeArgs);
        }
      },
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: item.bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 28),
          ),
          const SizedBox(height: 6),
          Text(item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textDark)),
        ],
      ),
    );
  }
}

// ── Bill Payments ──────────────────────────────────────────────────────────

class _BillPaymentsSection extends StatelessWidget {
  final List<_BillItem> items = const [
    _BillItem(
      Icons.phone_android,
      'Mobile\nRecharge',
      AppColors.iconBgRed,
      AppColors.primary,
      '/app/billPayments/mobileRecharge',
      {'pstitle': 'Mobile Recharge', 'psLcategory': 'Mobile Recharge'},
    ),
    _BillItem(
      Icons.tv,
      'DTH\nRecharge',
      AppColors.iconBgBlue,
      AppColors.accent,
      '/app/billPayments/DthRecharge',
      {'pstitle': 'DTH Recharge', 'psLcategory': 'DTH Recharge'},
    ),
    _BillItem(
      Icons.flash_on,
      'Electricity\nBill',
      AppColors.iconBgGreen,
      Color(0xFF43A047),
      '/app/billPayments/electricityBill',
      {'pstitle': 'Electricity Bill', 'psLcategory': 'Electricity Bill'},
    ),
    _BillItem(
      Icons.credit_card,
      'Loan\nRepayment',
      AppColors.iconBgYellow,
      Color(0xFFF57C00),
      '/app/bills',
      {'pstitle': 'Loan Repayment', 'psLcategory': 'Loan Repayment'},
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bill Payments',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/app/bills'),
                child: const Row(
                  children: [
                    Text('View All',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_outward,
                        size: 14, color: AppColors.accent),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: items.map((item) => _BillCell(item: item)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _BillItem {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final String route;
  final Map<String, dynamic> routeArgs;
  const _BillItem(
      this.icon, this.label, this.bgColor, this.iconColor, this.route,
      this.routeArgs);
}

class _BillCell extends StatelessWidget {
  final _BillItem item;
  const _BillCell({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, item.route, arguments: item.routeArgs),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: item.bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, color: item.iconColor, size: 28),
          ),
          const SizedBox(height: 6),
          Text(item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textDark)),
        ],
      ),
    );
  }
}

// ── Loans ──────────────────────────────────────────────────────────────────

class _LoansSection extends StatefulWidget {
  final String userId;
  const _LoansSection({required this.userId});

  @override
  State<_LoansSection> createState() => _LoansSectionState();
}

class _LoansSectionState extends State<_LoansSection> {
  bool _isPersonal = true;
  bool _loading = true;
  List<dynamic> _personalLoans = [];
  List<dynamic> _businessLoans = [];

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  Future<void> _fetchLoans() async {
    try {
      final response = await ApiService.listPopularServices();
      final list = response['list'] as List<dynamic>? ?? [];
      setState(() {
        _personalLoans =
            list.where((s) => s['pstype'] == 'personal-financial').toList();
        _businessLoans =
            list.where((s) => s['pstype'] == 'Business-financial').toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

void _handleServiceTap(BuildContext context, Map<String, dynamic> service) {
    final title = service['pstitle'] ?? '';
    final source = service['pssource'] ?? '';

    if (title == 'Mobile Loan') {
      Navigator.pushNamed(context, '/app/loans', arguments: service);
    } else if (source == 'leads') {
      Navigator.pushNamed(
        context,
        '/app/otherLoanServiceDetails',
        arguments: {
          ...service,
          '_userId': widget.userId,
        },
      );
    } else if (source == 'application') {
      Navigator.pushNamed(context, '/app/loanServiceScreen', arguments: service);
    } else {
      Navigator.pushNamed(context, '/app/loans', arguments: service);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loans = _isPersonal ? _personalLoans : _businessLoans;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Loans',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              children: [
                // Tab switcher
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPersonal = true),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: _isPersonal
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: _isPersonal
                                  ? [
                                      BoxShadow(
                                          color: Colors.black
                                              .withOpacity(0.05),
                                          blurRadius: 4)
                                    ]
                                  : null,
                            ),
                            child: Text('Personal\nNeeds',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: _isPersonal
                                        ? AppColors.accent
                                        : AppColors.textGrey,
                                    fontWeight: _isPersonal
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontSize: 13)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isPersonal = false),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: !_isPersonal
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: !_isPersonal
                                  ? [
                                      BoxShadow(
                                          color: Colors.black
                                              .withOpacity(0.05),
                                          blurRadius: 4)
                                    ]
                                  : null,
                            ),
                            child: Text('Business\nNeeds',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: !_isPersonal
                                        ? AppColors.accent
                                        : AppColors.textGrey,
                                    fontWeight: !_isPersonal
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    fontSize: 13)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  )
                else if (loans.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('No services found',
                        style: TextStyle(color: Colors.grey.shade500)),
                  )
                else
                  GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 0.85,
                    children: loans.map((service) {
                      return GestureDetector(
                        onTap: () => _handleServiceTap(
                            context, Map<String, dynamic>.from(service)),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              getIconFromString(service['psicon'] ?? ''),
                              color: Colors.grey.shade700,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              service['pstitle'] ?? '',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade700),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Banking ────────────────────────────────────────────────────────────────

class _BankingSection extends StatefulWidget {
  @override
  State<_BankingSection> createState() => _BankingSectionState();
}

class _BankingSectionState extends State<_BankingSection> {
  bool _loading = true;
  List<dynamic> _services = [];

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final response = await ApiService.listPopularServices();
      final list = response['list'] as List<dynamic>? ?? [];
      setState(() {
        _services = list.where((s) => s['pstype'] == 'banking').toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _handleServiceTap(BuildContext context, Map<String, dynamic> service) {
    final source = service['pssource'] ?? '';
    if (source == 'leads') {
      Navigator.pushNamed(
        context,
        '/app/otherLoanServiceDetails',
        arguments: service,
      );
    } else if (source == 'application') {
      Navigator.pushNamed(context, '/app/loanServiceScreen', arguments: service);
    } else {
      Navigator.pushNamed(context, '/app/loanServices', arguments: service);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Banking',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _services.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('No banking services found',
                            style: TextStyle(color: Colors.grey.shade500)),
                      )
                    : GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 0.9,
                        children: _services.map((service) {
                          return GestureDetector(
                            onTap: () => _handleServiceTap(
                                context, Map<String, dynamic>.from(service)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  getIconFromString(service['psicon'] ?? ''),
                                  color: Colors.grey.shade700,
                                  size: 30,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  service['pstitle'] ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Investment ─────────────────────────────────────────────────────────────

class _InvestmentSection extends StatefulWidget {
  @override
  State<_InvestmentSection> createState() => _InvestmentSectionState();
}

class _InvestmentSectionState extends State<_InvestmentSection> {
  bool _loading = true;
  List<dynamic> _services = [];

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final response = await ApiService.listPopularServices();
      final list = response['list'] as List<dynamic>? ?? [];
      setState(() {
        _services = list.where((s) => s['pstype'] == 'investment').toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _handleServiceTap(BuildContext context, Map<String, dynamic> service) {
    final source = service['pssource'] ?? '';
    if (source == 'leads') {
      Navigator.pushNamed(
        context,
        '/app/otherLoanServiceDetails',
        arguments: service,
      );
    } else if (source == 'application') {
      Navigator.pushNamed(context, '/app/loanServiceScreen', arguments: service);
    } else {
      Navigator.pushNamed(context, '/app/loanServices', arguments: service);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Investment & More',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _services.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('No investment services found',
                            style: TextStyle(color: Colors.grey.shade500)),
                      )
                    : GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 0.9,
                        children: _services.map((service) {
                          return GestureDetector(
                            onTap: () => _handleServiceTap(
                                context, Map<String, dynamic>.from(service)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  getIconFromString(service['psicon'] ?? ''),
                                  color: Colors.grey.shade700,
                                  size: 30,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  service['pstitle'] ?? '',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── Insurance ──────────────────────────────────────────────────────────────

class _InsuranceSection extends StatefulWidget {
  @override
  State<_InsuranceSection> createState() => _InsuranceSectionState();
}

class _InsuranceSectionState extends State<_InsuranceSection> {
  bool _loading = true;
  List<dynamic> _services = [];

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    try {
      final response = await ApiService.listPopularServices();
      final list = response['list'] as List<dynamic>? ?? [];
      setState(() {
        _services = list.where((s) => s['pstype'] == 'insurance').toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _handleServiceTap(BuildContext context, Map<String, dynamic> service) {
    Navigator.pushNamed(context, '/app/loanServices', arguments: service);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Insurance',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: _loading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _services.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('No insurance services found',
                            style: TextStyle(color: Colors.grey.shade500)),
                      )
                    : Column(
                        children: _services.map((service) {
                          return GestureDetector(
                            onTap: () => _handleServiceTap(
                                context, Map<String, dynamic>.from(service)),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    getIconFromString(
                                        service['psicon'] ?? ''),
                                    color: Colors.grey.shade700,
                                    size: 30,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    service['pstitle'] ?? '',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
          ),
        ],
      ),
    );
  }
}

// ── My Loans ───────────────────────────────────────────────────────────────

class _MyLoansSection extends StatefulWidget {
  final String userId;
  const _MyLoansSection({required this.userId});

  @override
  State<_MyLoansSection> createState() => _MyLoansSectionState();
}

class _MyLoansSectionState extends State<_MyLoansSection> {
  bool _loading = true;
  List<dynamic> _loans = [];
  String? _error;

  static const int _kMultiplier = 1000;
  int _currentIndex = 0;
  late PageController _pageController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchLoans() async {
    try {
    final response = await ApiService.getLoanApplications(widget.userId);
    print('MyLoans response: $response');
    print('userId used: ${widget.userId}');
    if (response['success'] == 1) {
        final loans = response['loanApplications'] ?? [];
        setState(() {
          _loans = loans;
          _loading = false;
        });
        if (_loans.length > 1) {
          _pageController = PageController(initialPage: _loans.length * _kMultiplier);
          _startAutoScroll();
        } else {
          _pageController = PageController();
        }
      } else {
        setState(() {
          _loans = [];
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load loans';
        _loading = false;
      });
    }
  }

  // FIX 1: Retry clears error + resets loading before re-fetching
  void _retryFetch() {
    setState(() {
      _error = null;
      _loading = true;
    });
    _fetchLoans();
  }

  void _startAutoScroll() {
  _autoScrollTimer?.cancel();
  _autoScrollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
    if (!mounted || _loans.isEmpty) return;
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  });
}

  void _pauseAndResume() {
    _autoScrollTimer?.cancel();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _loans.length > 1) _startAutoScroll();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'active':
        return Colors.blue;
      case 'disbursed':
        return Colors.teal;
      case 'completed':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX 2: Outer white card wrapper with shadow — matches Banking/Investment/Insurance sections
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('My Loans',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2)),
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: _loading
                ? const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _error != null
                    ? _buildErrorState()
                    : _loans.isEmpty
                        ? _buildEmptyState()
                        : _buildCarousel(),
          ),
        ],
      ),
    );
  }

  // FIX 3: Error state now has a working "Try Again" retry button
  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 12),
          const Text(
            'Something went wrong',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _retryFetch,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        children: [
          Icon(Icons.monetization_on_outlined,
              color: Colors.grey.shade400, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No Loans Found',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 6),
          Text(
            "You don't have any active or past\nloans at the moment.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCarousel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          // FIX 1: Increased height to prevent clipping on smaller screens
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            itemCount: _loans.length * _kMultiplier * 2,
            onPageChanged: (i) {
              setState(() => _currentIndex = i % _loans.length);
              _pauseAndResume();
            },
            itemBuilder: (context, index) {
              final loan = _loans[index % _loans.length];
              final status = (loan['status'] ?? 'pending').toString();
              final statusColor = _statusColor(status);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor.withOpacity(0.2)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Top section ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Phone icon
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Icon(Icons.phone_android,
                                color: Colors.grey.shade500, size: 18),
                          ),
                          const SizedBox(width: 8),

                          // Left: product type + brand/model + IDs
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // FIX 4: product type reduced to fontSize 10
                                Text(
                                  '${loan['product_type'] ?? ''} Loan',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${loan['brand'] ?? ''} ${loan['model'] ?? ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // FIX 6: loan_id on its own line, application_id below
                                // prevents overflow from combined string
                                if ((loan['loan_id'] ?? '').toString().isNotEmpty)
                                  Text(
                                    loan['loan_id'].toString(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                if (['pending', 'approved', 'disbursed']
                                        .contains(status) &&
                                    (loan['application_id'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                  Text(
                                    loan['application_id'].toString(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Righyt: amount + status badge
                          // Right: amount + status badge — mt-3 equivalent matches React
Padding(
  padding: const EdgeInsets.only(top: 12),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      // approved_limit shown independently if != 0.00
      if (loan['approved_limit'] != null &&
          loan['approved_limit'].toString() != '0.00')
        Text(
          '₹${loan['approved_limit']}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      // product_price shown independently for pending/approved/disbursed
      if (['pending', 'approved', 'disbursed'].contains(status))
        Text(
          '₹${loan['product_price'] ?? ''}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
      const SizedBox(height: 6),
      // Status badge
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.12),
          border: Border.all(
            color: statusColor.withOpacity(0.4),
            width: 0.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            color: statusColor,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    ],
  ),
),
                        ],
                      ),
                    ),

                    // FIX 2: Divider with proper height for breathing room
                    Divider(
                      height: 1,
                      thickness: 0.5,
                      color: Colors.grey.withOpacity(0.25),
                    ),

                    // ── Bottom row ───────────────────────────────────────
                    // FIX 3: More balanced padding above/below
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left: EMI info / Select EMI Plan / empty
                          if (status == 'active' || status == 'completed')
                            Row(
                              children: [
                                const Icon(Icons.check_circle,
                                    color: Colors.green, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  '${loan['paid_emi'] ?? 0}/${loan['total_emi'] ?? 0} EMIs paid',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            )
                          else if (status == 'approved')
                            GestureDetector(
onTap: () => Navigator.pushNamed(
  context,
  '/app/emi-plan-selector',
  arguments: {
    'loanDetails': {
      ...Map<String, dynamic>.from(loan),
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
),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Select EMI Plan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(),

                          // Right: View Details — always shown
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(
                              context,
                              '/app/loanDetails',
                              arguments: loan,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.remove_red_eye_outlined,
                                    size: 13,
                                    color: Colors.grey.shade400),
                                const SizedBox(width: 4),
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade400,
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
            },
          ),
        ),

        const SizedBox(height: 10),

        // Animated dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_loans.length, (i) {
            final active = i == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active ? AppColors.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ── Notifications Dialog ───────────────────────────────────────────────────

class _NotificationsDialog extends StatelessWidget {
  const _NotificationsDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Notifications',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(Icons.notifications_none,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 8),
                  Text('No notifications yet',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}