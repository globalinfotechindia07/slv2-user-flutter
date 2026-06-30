import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/api_service.dart';

// ─── Data Models ──────────────────────────────────────────────────────────────

class LoanDetailsModel {
  final String? loanId;
  final String? applicationId;
  final String? status;
  final String? productType;
  final String? brand;
  final String? model;
  final String? productPrice;
  final String? approvedLimit;
  final String? downpaymentAmount;
  final String? fullName;
  final String? phoneNumber;
  final String? email;
  final String? dob;
  final String? gender;
  final String? address;
  final String? employmentType;
  final String? companyName;
  final String? monthlyIncome;
  final String? workExperience;
  final String? aadharNumber;
  final String? panNumber;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final bool aadharVerified;
  final bool panVerified;
  final bool passbookVerified;
  final bool nachVerified;
  final bool agreementVerified;
  final String? reference1Name;
  final String? reference1Contact;
  final String? reference1AadharVerified;
  final String? reference1PanVerified;
  final String? reference2Name;
  final String? reference2Contact;
  final String? reference2AadharVerified;
  final String? reference2PanVerified;
  final ShopDetails? shopDetails;
  final String? appliedDate;
  final String? approvalDate;
  final String? disbursedDate;
  final String? closedDate;
  final String? remarks;
  final String? nocGenerated;
  final List<StatusHistoryEntry> statusHistory;

  const LoanDetailsModel({
    this.loanId,
    this.applicationId,
    this.status,
    this.productType,
    this.brand,
    this.model,
    this.productPrice,
    this.approvedLimit,
    this.downpaymentAmount,
    this.fullName,
    this.phoneNumber,
    this.email,
    this.dob,
    this.gender,
    this.address,
    this.employmentType,
    this.companyName,
    this.monthlyIncome,
    this.workExperience,
    this.aadharNumber,
    this.panNumber,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.aadharVerified = false,
    this.panVerified = false,
    this.passbookVerified = false,
    this.nachVerified = false,
    this.agreementVerified = false,
    this.reference1Name,
    this.reference1Contact,
    this.reference1AadharVerified,
    this.reference1PanVerified,
    this.reference2Name,
    this.reference2Contact,
    this.reference2AadharVerified,
    this.reference2PanVerified,
    this.shopDetails,
    this.appliedDate,
    this.approvalDate,
    this.disbursedDate,
    this.closedDate,
    this.remarks,
    this.nocGenerated,
    this.statusHistory = const [],
});

factory LoanDetailsModel.fromJson(Map<String, dynamic> json) {
  return LoanDetailsModel(
    loanId: json['loanId']?.toString(),
    applicationId: json['applicationId']?.toString(),
    status: json['status']?.toString(),

    productType: json['product_type']?.toString(),
    brand: json['brand']?.toString(),
    model: json['model']?.toString(),
    productPrice: json['productPrice']?.toString(),
    approvedLimit: json['approvedLimit']?.toString(),
    downpaymentAmount: json['downpaymentAmount']?.toString(),

    fullName: json['fullName']?.toString(),
    phoneNumber: json['phoneNumber']?.toString(),
    email: json['email']?.toString(),
    dob: json['dob']?.toString(),
    gender: json['gender']?.toString(),
    address: json['address']?.toString(),
    employmentType: json['employmentType']?.toString(),
    companyName: json['companyName']?.toString(),
    monthlyIncome: json['monthlyIncome']?.toString(),
    workExperience: json['workExperience']?.toString(),

    aadharNumber: json['aadharMasked']?.toString(),
    panNumber: json['panMasked']?.toString(),

    bankName: json['bank_name']?.toString(),
    accountNumber: json['account_number']?.toString(),
    ifscCode: json['ifsc_code']?.toString(),

    aadharVerified: json['isAadharVerified'] == true,
    panVerified: json['isPanVerified'] == true,
    passbookVerified: json['passbook_verified'] == true || json['passbook_verified'] == 1,
    nachVerified: json['nach_verified'] == true || json['nach_verified'] == 1,
    agreementVerified: json['agreement_verified'] == true || json['agreement_verified'] == 1,

    reference1Name: json['reference1_name']?.toString(),
    reference1Contact: json['reference1_contact']?.toString(),
    reference1AadharVerified: json['reference1_aadhar_verified']?.toString(),
    reference1PanVerified: json['reference1_pan_verified']?.toString(),
    reference2Name: json['reference2_name']?.toString(),
    reference2Contact: json['reference2_contact']?.toString(),
    reference2AadharVerified: json['reference2_aadhar_verified']?.toString(),
    reference2PanVerified: json['reference2_pan_verified']?.toString(),

    shopDetails: json['shop_details'] != null
        ? ShopDetails.fromJson(json['shop_details'] as Map<String, dynamic>)
        : null,

    appliedDate: json['appliedDate']?.toString(),
    approvalDate: json['approvalDate']?.toString(),
    disbursedDate: json['disbursedDate']?.toString(),
    closedDate: json['closedDate']?.toString(),

    remarks: json['remarks']?.toString(),
    nocGenerated: json['noc_generated']?.toString(),
    statusHistory: (json['status_history'] as List<dynamic>? ?? [])
        .map((e) => StatusHistoryEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
    );
    }
}

class ShopDetails {
  final String? name;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? phone;

  const ShopDetails({
    this.name,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.phone,
  });

  factory ShopDetails.fromJson(Map<String, dynamic> json) {
    return ShopDetails(
      name: json['name']?.toString(),
      address: json['address']?.toString(),
      city: json['city']?.toString(),
      state: json['state']?.toString(),
      pincode: json['pincode']?.toString(),
      phone: json['phone']?.toString(),
    );
  }
}

class EmiDetails {
  final int? paidEmis;
  final int? totalEmis;
  final int? tenure;
  final String? startDate;
  final String? endDate;
  final double? totalPaid;

  const EmiDetails({
    this.paidEmis,
    this.totalEmis,
    this.tenure,
    this.startDate,
    this.endDate,
    this.totalPaid,
  });

  factory EmiDetails.fromJson(Map<String, dynamic> json) {
    return EmiDetails(
      paidEmis: json['paid_emis'] as int?,
      totalEmis: json['total_emis'] as int?,
      tenure: json['tenure'] as int?,
      startDate: json['start_date']?.toString(),
      endDate: json['end_date']?.toString(),
      totalPaid: (json['total_paid'] as num?)?.toDouble(),
    );
  }
}
class StatusHistoryEntry {
  final String? status;
  final String? remarks;
  final String? createdAt;
  final String? changedBy;

  const StatusHistoryEntry({
    this.status,
    this.remarks,
    this.createdAt,
    this.changedBy,
  });

  factory StatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return StatusHistoryEntry(
      status: json['status']?.toString(),
      remarks: json['remarks']?.toString(),
      createdAt: json['createdAt']?.toString(),
      changedBy: json['changedBy']?.toString(),
    );
  }
}

class StatementPayment {
  final String? paymentNumber;
  final String? paymentDate;
  final String? emiAmount;
  final String? paymentStatus;

  const StatementPayment({
    this.paymentNumber,
    this.paymentDate,
    this.emiAmount,
    this.paymentStatus,
  });

  factory StatementPayment.fromJson(Map<String, dynamic> json) {
    return StatementPayment(
      paymentNumber: json['payment_number']?.toString(),
      paymentDate: json['payment_date']?.toString(),
      emiAmount: json['emi_amount']?.toString(),
      paymentStatus: json['payment_status']?.toString(),
    );
  }
}

// ─── Status Config ────────────────────────────────────────────────────────────

class _StatusConfig {
  final Color bgColor;
  final Color textColor;
  final Color badgeBg;
  final Color badgeText;

  const _StatusConfig({
    required this.bgColor,
    required this.textColor,
    required this.badgeBg,
    required this.badgeText,
  });
}

final Map<String, _StatusConfig> loanStatusConfig = {
  'pending': _StatusConfig(
    bgColor: const Color(0xFFFEFCE8),
    textColor: const Color(0xFFB45309),
    badgeBg: const Color(0xFFFEF9C3),
    badgeText: const Color(0xFF92400E),
  ),
  'active': _StatusConfig(
    bgColor: const Color(0xFFEFF6FF),
    textColor: const Color(0xFF1D4ED8),
    badgeBg: const Color(0xFFDBEAFE),
    badgeText: const Color(0xFF1E40AF),
  ),
  'approved': _StatusConfig(
    bgColor: const Color(0xFFF0FDF4),
    textColor: const Color(0xFF16A34A),
    badgeBg: const Color(0xFFDCFCE7),
    badgeText: const Color(0xFF166534),
  ),
  'rejected': _StatusConfig(
    bgColor: const Color(0xFFFEF2F2),
    textColor: const Color(0xFFDC2626),
    badgeBg: const Color(0xFFFEE2E2),
    badgeText: const Color(0xFF991B1B),
  ),
  'completed': _StatusConfig(
    bgColor: const Color(0xFFFAF5FF),
    textColor: const Color(0xFF7C3AED),
    badgeBg: const Color(0xFFEDE9FE),
    badgeText: const Color(0xFF5B21B6),
  ),
  'disbursed': _StatusConfig(
    bgColor: const Color(0xFFF0FDFA),
    textColor: const Color(0xFF0D9488),
    badgeBg: const Color(0xFFCCFBF1),
    badgeText: const Color(0xFF115E59),
  ),
  'default': _StatusConfig(
    bgColor: const Color(0xFFF9FAFB),
    textColor: const Color(0xFF374151),
    badgeBg: const Color(0xFFF3F4F6),
    badgeText: const Color(0xFF1F2937),
  ),
};

String _timelineLabel(String? status) {
  switch (status?.toLowerCase()) {
    case 'pending': return 'Application Submitted';
    case 'approved': return 'Application Approved';
    case 'rejected': return 'Application Rejected';
    case 'disbursed': return 'Loan Disbursed';
    case 'active': return 'Loan Activated';
    case 'completed': return 'Loan Closed';
    default: return status != null ? _capitalizeGlobal(status) : 'Status Updated';
  }
}

String _capitalizeGlobal(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

Color _timelineColor(String? status) {
  final cfg = _getStatusConfig(status);
  return cfg.textColor;
}

Color _timelineBgColor(String? status) {
  final cfg = _getStatusConfig(status);
  return cfg.badgeBg;
}

_StatusConfig _getStatusConfig(String? status) =>
    loanStatusConfig[status?.toLowerCase()] ?? loanStatusConfig['default']!;

// ─── Main Screen ──────────────────────────────────────────────────────────────

class LoanDetailsScreen extends StatefulWidget {
  final LoanDetailsModel loan;

  const LoanDetailsScreen({Key? key, required this.loan}) : super(key: key);

  @override
  State<LoanDetailsScreen> createState() => _LoanDetailsScreenState();
}

class _LoanDetailsScreenState extends State<LoanDetailsScreen> {
  // Mirrors React: useState('personal'), useState(true), useState(null)
  String _activeTab = 'personal';
  bool _loading = true;
  EmiDetails? _emiDetails;
  bool _showStatement = false;
  List<StatementPayment> _statement = [];

  @override
  void initState() {
    super.initState();
    // Mirrors: useEffect(() => { fetchEmiDetails() }, [loan?.loan_id])
    if (widget.loan.loanId != null) {
      _fetchEmiDetails();
    }
  }

  // Mirrors React's fetchEmiDetails
  Future<void> _fetchEmiDetails() async {
    try {
      setState(() => _loading = true);
      final response = await http.get(Uri.parse(
    '${ApiConstants.userBaseUrl}/loan_details.php?loan_id=${widget.loan.loanId}'));
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        setState(() => _emiDetails = EmiDetails.fromJson(body['data']));
      }
    } catch (e) {
      debugPrint('Error fetching EMI details: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // Mirrors React's fetchStatement
  Future<void> _fetchStatement() async {
    try {
      final response = await http.get(Uri.parse(
    '${ApiConstants.userBaseUrl}/loan_details.php?loan_id=${widget.loan.loanId}&action=statement'));
      final body = jsonDecode(response.body);
      if (body['success'] == true) {
        setState(() {
          _statement = (body['data'] as List)
              .map((e) => StatementPayment.fromJson(e))
              .toList();
          _showStatement = true;
        });
      }
    } catch (e) {
      debugPrint('Error fetching statement: $e');
    }
  }

  // REPLACE WITH:
void _handleSelectEMIPlan() {
  final loan = widget.loan;
  Navigator.of(context).pushNamed(
    '/app/emi-plan-selector',
    arguments: {
      'loanDetails': {
        'loan_id': loan.loanId,
        'application_id': loan.applicationId,
        'full_name': loan.fullName,
        'phone_number': loan.phoneNumber,
        'approved_limit': loan.approvedLimit ?? loan.productPrice ?? '0',
        'product_price': loan.productPrice,
        'min_tenure': '3',
        'max_tenure': '12',
        'interest_rate': '2.5',
        'processing_fee': '0',
        'interestRateType': 'per_month',
        'interestRateMethod': 'flat',
        'processingFeeType': 'charged_separately',
        'pstitle': 'Mobile Loan Service',
      },
      'userProfile': {
        'id': '',
        'name': '',
      },
    },
  );
}

  String _formatDate(String? dateStr, {bool includeTime = false}) {
    if (dateStr == null || dateStr.isEmpty) return '--';
    try {
      final date = DateTime.parse(dateStr);
      final months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      if (includeTime) {
        return '${date.day}-${months[date.month - 1]}-${date.year}, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      }
      return '${date.day.toString().padLeft(2, '0')}-${months[date.month - 1]}-${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _maskAadhar(String? aadhar) {
    if (aadhar == null || aadhar.length < 4) return '--';
    return 'XXXX-XXXX-${aadhar.substring(aadhar.length - 4)}';
  }

  String _maskPan(String? pan) {
    if (pan == null || pan.length < 6) return '--';
    return '${pan.substring(0, 2)}XXX${pan.substring(pan.length - 4)}';
  }

  bool _hasStatus(List<String> statuses) =>
      statuses.contains(widget.loan.status?.toLowerCase());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF1F2), Colors.white, Color(0xFFEFF6FF)],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildLoanCard(),
                        _buildTabs(),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              _buildTabContent(),
                              _buildTimeline(),
                              _buildActionButtons(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Statement modal overlay
          if (_showStatement)
            _StatementModal(
              payments: _statement,
              onClose: () => setState(() => _showStatement = false),
            ),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Row(
              children: [
                const Icon(Icons.arrow_back, size: 18, color: Color(0xFF475569)),
                const SizedBox(width: 4),
                Text('Back',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600)),
              ],
            ),
          ),
          const Text(
            'Loan Details',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A)),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.help_outline, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // ─── Loan Card ────────────────────────────────────────────────────────────

  Widget _buildLoanCard() {
    final loan = widget.loan;
    final statusCfg = _getStatusConfig(loan.status);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: icon + info
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.smartphone, color: Colors.grey.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Loan Type: ${loan.productType ?? '--'} Loan',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569)),
                            ),
                            Text(
                              '${loan.brand ?? '--'}-${loan.model ?? '--'}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B)),
                            ),
                            if (_hasStatus(['active', 'completed']))
                              Text('Loan ID: ${loan.loanId ?? '--'}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                            if (_hasStatus(['pending', 'approved', 'disbursed']))
                              Text('Application ID: ${loan.applicationId ?? '--'}',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Right: amount + status badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (_hasStatus(['pending', 'approved', 'disbursed'])) ...[
                      Text('Product Price',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                      Text('₹${loan.productPrice ?? '--'}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B))),
                    ],
                    if (_hasStatus(['active', 'completed'])) ...[
                      Text('Loan Amount',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                      Text('₹${loan.approvedLimit ?? '--'}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B))),
                    ],
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusCfg.badgeBg,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        (loan.status ?? '--').toUpperCase(),
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusCfg.badgeText,
                            letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_hasStatus(['active', 'completed']))
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 4),
                      Text(
                        '${_emiDetails?.paidEmis ?? '--'}/${_emiDetails?.totalEmis ?? '--'} EMIs paid',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                if (_hasStatus(['active', 'completed']))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Loan Tenure',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                      Text('${_emiDetails?.tenure ?? '--'} Months',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B))),
                    ],
                  ),
                if (widget.loan.status?.toLowerCase() == 'completed')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Loan Closure Date',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600)),
                      Text(_formatDate(widget.loan.closedDate),
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B))),
                    ],
                  ),
                if (widget.loan.status?.toLowerCase() == 'approved')
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSelectEMIPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDBEAFE),
                        foregroundColor: const Color(0xFF1D4ED8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Select EMI Plan',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tabs ─────────────────────────────────────────────────────────────────

  final List<Map<String, dynamic>> _tabs = const [
    {'key': 'personal', 'label': 'Personal Info', 'icon': Icons.person_outline},
    {'key': 'loan', 'label': 'Loan Details', 'icon': Icons.description_outlined},
    {'key': 'bank', 'label': 'Bank Details', 'icon': Icons.credit_card_outlined},
    {'key': 'documents', 'label': 'Documents', 'icon': Icons.file_copy_outlined},
    {'key': 'shop', 'label': 'Shop Details', 'icon': Icons.store_outlined},
    {'key': 'references', 'label': 'References', 'icon': Icons.group_outlined},
  ];

  Widget _buildTabs() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final tab = _tabs[i];
          final isActive = _activeTab == tab['key'];
          return GestureDetector(
            onTap: () => setState(() => _activeTab = tab['key'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFFDBEAFE)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    tab['icon'] as IconData,
                    size: 15,
                    color: isActive
                        ? const Color(0xFF1D4ED8)
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    tab['label'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? const Color(0xFF1D4ED8)
                          : Colors.grey.shade600,
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

  // ─── Tab Content ──────────────────────────────────────────────────────────

  Widget _buildTabContent() {
    final loan = widget.loan;
    switch (_activeTab) {
      case 'personal':
        return _InfoCard(title: 'Personal Information', children: [
          _InfoRow(icon: Icons.person_outline, label: 'Full Name', value: loan.fullName),
          _InfoRow(icon: Icons.phone_outlined, label: 'Contact', value: loan.phoneNumber),
          _InfoRow(icon: Icons.mail_outline, label: 'Email', value: loan.email),
          _InfoRow(icon: Icons.calendar_today_outlined, label: 'Date of Birth', value: _formatDate(loan.dob)),
          _InfoRow(icon: Icons.person_outline, label: 'Gender', value: loan.gender != null ? _capitalize(loan.gender!) : null),
          _InfoRow(icon: Icons.location_on_outlined, label: 'Address', value: loan.address, multiLine: true),
          const _SectionDivider(title: 'Employment Information'),
          _InfoRow(icon: Icons.work_outline, label: 'Employment Type', value: loan.employmentType != null ? _capitalize(loan.employmentType!) : null),
          _InfoRow(icon: Icons.business_outlined, label: 'Company Name', value: loan.companyName),
          _InfoRow(icon: Icons.currency_rupee, label: 'Monthly Income', value: loan.monthlyIncome != null ? '₹${loan.monthlyIncome}' : null),
          _InfoRow(icon: Icons.access_time_outlined, label: 'Work Experience', value: loan.workExperience != null ? '${loan.workExperience} years' : null),
          const _SectionDivider(title: 'Document Information'),
          _InfoRow(icon: Icons.description_outlined, label: 'Aadhar Number', value: loan.aadharNumber),
          _InfoRow(icon: Icons.description_outlined, label: 'PAN Number', value: loan.panNumber),
        ]);

      case 'loan':
        return _InfoCard(title: 'Basic Loan Information', children: [
          _InfoRow(icon: Icons.description_outlined, label: 'Application ID', value: loan.applicationId),
          _InfoRow(icon: Icons.description_outlined, label: 'Loan ID', value: loan.loanId),
          _StatusRow(status: loan.status),
          _InfoRow(icon: Icons.calendar_today_outlined, label: 'Applied Date', value: _formatDate(loan.appliedDate)),
          _InfoRow(icon: Icons.smartphone_outlined, label: 'Product Type', value: loan.productType != null ? '${loan.productType} Loan' : null),
          _InfoRow(icon: Icons.smartphone_outlined, label: 'Product', value: (loan.brand != null && loan.model != null) ? '${loan.brand} - ${loan.model}' : null),
          _InfoRow(icon: Icons.currency_rupee, label: 'Product Price', value: loan.productPrice != null ? '₹${loan.productPrice}' : null),
          if (_hasStatus(['approved', 'disbursed', 'active', 'completed'])) ...[
            const _SectionDivider(title: 'Loan Amount & Terms'),
            _InfoRow(icon: Icons.currency_rupee, label: 'Loan Amount', value: loan.approvedLimit != null ? '₹${loan.approvedLimit}' : null),
            if ((double.tryParse(loan.downpaymentAmount ?? '0') ?? 0) > 0)
              _InfoRow(icon: Icons.currency_rupee, label: 'Down Payment', value: '₹${loan.downpaymentAmount}'),
            _InfoRow(icon: Icons.calendar_today_outlined, label: 'Tenure', value: _emiDetails?.tenure != null ? '${_emiDetails!.tenure} months' : null),
          ],
          if (_hasStatus(['active', 'completed'])) ...[
            const _SectionDivider(title: 'EMI Information'),
            _InfoRow(icon: Icons.calendar_today_outlined, label: 'EMIs Paid', value: _emiDetails?.paidEmis?.toString()),
            _InfoRow(icon: Icons.calendar_today_outlined, label: 'EMI Start Date', value: _emiDetails?.startDate),
            _InfoRow(icon: Icons.calendar_today_outlined, label: 'EMI End Date', value: _emiDetails?.endDate),
            _InfoRow(icon: Icons.credit_card_outlined, label: 'Amount Paid Till Date', value: _emiDetails?.totalPaid != null ? '₹${_emiDetails!.totalPaid!.toStringAsFixed(0)}' : null),
          ],
        ]);

      case 'bank':
        return _InfoCard(title: 'Bank Account Details', children: [
          _InfoRow(icon: Icons.business_outlined, label: 'Bank Name', value: loan.bankName),
          _InfoRow(icon: Icons.credit_card_outlined, label: 'Account Number', value: loan.accountNumber),
          _InfoRow(icon: Icons.business_outlined, label: 'IFSC Code', value: loan.ifscCode),
        ]);

      case 'documents':
        return _InfoCard(title: 'Document Verification', children: [
          _VerificationRow(label: 'Aadhar Card', verified: loan.aadharVerified),
          _VerificationRow(label: 'PAN Card', verified: loan.panVerified),
          _VerificationRow(label: 'Bank Passbook', verified: loan.passbookVerified),
          _VerificationRow(label: 'NACH Form', verified: loan.nachVerified),
          _VerificationRow(label: 'Agreement', verified: loan.agreementVerified),
        ]);

      case 'references':
        return _InfoCard(title: 'Reference Details', children: [
          const _SectionDivider(title: 'Reference 1'),
          _InfoRow(icon: Icons.person_outline, label: 'Name', value: loan.reference1Name),
          _PhoneRow(label: 'Contact', phone: loan.reference1Contact),
          _ReferenceDocRow(
            aadharVerified: loan.reference1AadharVerified == 'verified',
            panVerified: loan.reference1PanVerified == 'verified',
          ),
          const _SectionDivider(title: 'Reference 2'),
          _InfoRow(icon: Icons.person_outline, label: 'Name', value: loan.reference2Name),
          _PhoneRow(label: 'Contact', phone: loan.reference2Contact),
          _ReferenceDocRow(
            aadharVerified: loan.reference2AadharVerified == 'verified',
            panVerified: loan.reference2PanVerified == 'verified',
          ),
        ]);

      case 'shop':
        return _InfoCard(title: 'Shop Information', children: [
          _InfoRow(icon: Icons.store_outlined, label: 'Shop Name', value: loan.shopDetails?.name),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Address',
            value: [
              loan.shopDetails?.address,
              loan.shopDetails?.city,
              loan.shopDetails?.state,
              loan.shopDetails?.pincode,
            ].where((e) => e != null && e.isNotEmpty).join(', '),
            multiLine: true,
          ),
          _PhoneRow(label: 'Contact', phone: loan.shopDetails?.phone),
        ]);

      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Timeline ─────────────────────────────────────────────────────────────

  Widget _buildTimeline() {
  final loan = widget.loan;
  final history = loan.statusHistory;

  return Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2))
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Application Timeline',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B))),
        const SizedBox(height: 12),
        if (history.isEmpty)
          // Fallback: at least show applied date if history is empty
          _TimelineItem(
            label: 'Application Submitted',
            date: _formatDate(loan.appliedDate, includeTime: true),
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFDBEAFE),
            isLast: true,
          )
        else
          ...List.generate(history.length, (i) {
            final entry = history[i];
            final isLast = i == history.length - 1;
            return _TimelineItem(
              label: _timelineLabel(entry.status),
              date: _formatDate(entry.createdAt, includeTime: true),
              color: _timelineColor(entry.status),
              bgColor: _timelineBgColor(entry.status),
              isLast: isLast,
              remarks: entry.remarks,
            );
          }),
      ],
    ),
  );
}

  // ─── Action Buttons ───────────────────────────────────────────────────────

  Widget _buildActionButtons() {
    final loan = widget.loan;
    return Column(
      children: [
        if (_hasStatus(['active', 'completed']))
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _fetchStatement,
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('View Statement'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF374151),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                  backgroundColor: const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        if (loan.nocGenerated == '1')
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text('Download NOC'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDCFCE7),
                  foregroundColor: const Color(0xFF166534),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ),
        if (loan.remarks != null &&
            loan.remarks!.isNotEmpty &&
            loan.status?.toLowerCase() == 'rejected')
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              border: Border.all(color: const Color(0xFFFDE68A)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: Color(0xFFD97706)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Remarks',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E))),
                      const SizedBox(height: 2),
                      Text(loan.remarks!,
                          style: const TextStyle(
                              fontSize: 11, color: Color(0xFFB45309))),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

// ─── Reusable Info Widgets ────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _InfoCard({Key? key, required this.title, required this.children})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool multiLine;

  const _InfoRow({
    Key? key,
    required this.icon,
    required this.label,
    this.value,
    this.multiLine = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment:
            multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600)),
            ],
          ),
          Flexible(
            child: Text(
              value?.isNotEmpty == true ? value! : '--',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String? status;
  const _StatusRow({Key? key, this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cfg = _getStatusConfig(status);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text('Status',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ]),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: cfg.badgeBg, borderRadius: BorderRadius.circular(100)),
            child: Text(
              (status ?? '--').toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cfg.badgeText),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationRow extends StatelessWidget {
  final String label;
  final bool verified;
  const _VerificationRow({Key? key, required this.label, required this.verified})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(
              verified ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: verified ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ]),
          Text(
            verified ? 'Verified' : 'Pending',
            style: TextStyle(
                fontSize: 12,
                color: verified
                    ? const Color(0xFF16A34A)
                    : Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  final String label;
  final String? phone;
  const _PhoneRow({Key? key, required this.label, this.phone}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ]),
          GestureDetector(
            onTap: () async {
              if (phone != null) {
                final uri = Uri.parse('tel:$phone');
                if (await canLaunchUrl(uri)) launchUrl(uri);
              }
            },
            child: Text(
              phone ?? '--',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2563EB)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReferenceDocRow extends StatelessWidget {
  final bool aadharVerified;
  final bool panVerified;
  const _ReferenceDocRow(
      {Key? key, required this.aadharVerified, required this.panVerified})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(Icons.file_copy_outlined,
                size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text('Documents',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ]),
          Row(
            children: [
              Icon(
                aadharVerified ? Icons.check_circle : Icons.cancel,
                size: 14,
                color: aadharVerified
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 3),
              Text('Aadhar',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(width: 12),
              Icon(
                panVerified ? Icons.check_circle : Icons.cancel,
                size: 14,
                color: panVerified
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 3),
              Text('PAN',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String title;
  const _SectionDivider({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(title,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B))),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final String label;
  final String date;
  final Color color;
  final Color bgColor;
  final bool isLast;
  final String? remarks;

  const _TimelineItem({
    Key? key,
    required this.label,
    required this.date,
    required this.color,
    required this.bgColor,
    this.isLast = false,
    this.remarks,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(Icons.check_circle_outline, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B))),
                Text(date,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
                if (remarks != null && remarks!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(remarks!,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                          fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Statement Modal ──────────────────────────────────────────────────────────
/// Mirrors React's <Statement> component — shown as a full-screen overlay

class _StatementModal extends StatelessWidget {
  final List<StatementPayment> payments;
  final VoidCallback onClose;

  const _StatementModal(
      {Key? key, required this.payments, required this.onClose})
      : super(key: key);

  Color _statusBg(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid': return const Color(0xFFDCFCE7);
      case 'pending': return const Color(0xFFFEF9C3);
      default: return const Color(0xFFFEE2E2);
    }
  }

  Color _statusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'paid': return const Color(0xFF166534);
      case 'pending': return const Color(0xFF92400E);
      default: return const Color(0xFF991B1B);
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '--';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent close on inner tap
            child: Container(
              margin: const EdgeInsets.all(16),
              constraints: const BoxConstraints(maxHeight: 600),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Loan Statement',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        IconButton(
                            onPressed: onClose,
                            icon: const Icon(Icons.close)),
                      ],
                    ),
                  ),
                  Divider(height: 1, color: Colors.grey.shade200),
                  // Table
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(2),
                          2: FlexColumnWidth(2),
                          3: FlexColumnWidth(2),
                        },
                        children: [
                          // Header row
                          TableRow(
                            decoration: const BoxDecoration(
                                color: Color(0xFFF9FAFB)),
                            children: ['Payment #', 'Date', 'Amount', 'Status']
                                .map((h) => Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: Text(h,
                                          style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey.shade600)),
                                    ))
                                .toList(),
                          ),
                          // Data rows
                          ...payments.map((p) => TableRow(
                                decoration: BoxDecoration(
                                    border: Border(
                                        top: BorderSide(
                                            color: Colors.grey.shade200))),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(p.paymentNumber ?? '--',
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(_formatDate(p.paymentDate),
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text('₹${p.emiAmount ?? '--'}',
                                        style: const TextStyle(fontSize: 12)),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _statusBg(p.paymentStatus),
                                        borderRadius:
                                            BorderRadius.circular(100),
                                      ),
                                      child: Text(
                                        (p.paymentStatus ?? '--')
                                            .toUpperCase(),
                                        style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: _statusText(
                                                p.paymentStatus)),
                                      ),
                                    ),
                                  ),
                                ],
                              )),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}