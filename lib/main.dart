import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/about_screen.dart';
import 'screens/support_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/bill_coming_soon_screen.dart';
import 'screens/loan_details_screen.dart';
// import 'screens/mobile_loan_form_screen.dart';
// import 'models/loan_form_model.dart';
import '../screens/other_loan_service_details.dart';
import 'screens/select_emi_plan_screen.dart';
import 'Bill/recharge/MobileRecharge.dart';
import 'services/auth_service.dart';
import 'Bill/Dth/dth.dart';
import 'Bill/Dth/DthRechargeDetails.dart';
import 'Bill/Dth/DthPayPage.dart';
import 'Bill/Electricity/Electricity.dart';
import 'Bill/Electricity/ElectricityDetails.dart';
import 'Bill/Electricity/ElectricityPayPage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const ShubhLabhApp());
}

class ShubhLabhApp extends StatelessWidget {
  const ShubhLabhApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShubhLabh Patsanstha',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const SplashScreen(),

      // ── Simple routes (no arguments needed) ───────────────────────────────
      routes: {
        '/app/about': (_) => const AboutScreen(
              logoAsset: 'assets/images/logo.png',
            ),
        '/app/support': (_) => const SupportScreen(),
        '/app/bills': (_) => const BillComingSoonScreen(),
      },

      // ── Routes that require arguments ─────────────────────────────────────
      onGenerateRoute: (settings) {
        switch (settings.name) {

          // Transactions screen — pass userId as String argument:
          // Navigator.pushNamed(context, '/app/transactions', arguments: userId)
          case '/app/transactions':
            final userId = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => TransactionsScreen(userId: userId),
            );

          // TODO: Uncomment once you add mobile_loan_form_screen.dart
          // case '/app/mobile-loan':
          //   final args = settings.arguments as Map<String, dynamic>?;
          //   return MaterialPageRoute(
          //     builder: (_) => MobileLoanFormScreen(
          //       userProfile: args?['userProfile'] as UserProfile?,
          //       serviceDetails: args?['serviceDetails'] as ServiceDetails?,
          //     ),
          //   );

          case '/app/billPayments/mobileRecharge':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => FutureBuilder<String>(
                future: AuthService.getUserId(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  return MobileRechargeScreen(
                    userProfile: {'id': snapshot.data},
                    serviceDetails: args,
                  );
                },
              ),
            );

          case '/app/loanDetails':
            final map = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => LoanDetailsScreen(
                loan: LoanDetailsModel.fromJson(map),
              ),
            );
          case '/app/otherLoanServiceDetails':
            final args = settings.arguments as Map<String, dynamic>? ?? {};
            return MaterialPageRoute(
              builder: (_) => OtherLoanServiceDetailScreen(
                serviceDetails: args,
                userProfile: {'id': args['_userId'] ?? ''},
              ),
            );
            case '/app/emi-plan-selector':
              final args = settings.arguments as Map<String, dynamic>? ?? {};
              return MaterialPageRoute(
                builder: (_) => SelectEmiPlanScreen(
                  loanDetails: args['loanDetails'] as Map<String, dynamic>? ?? {},
                  userProfile: args['userProfile'] as Map<String, dynamic>? ?? {},
                ),
              );
            case '/app/dth-recharge/details':
              final args = settings.arguments as Map<String, dynamic>? ?? {};
              return MaterialPageRoute(
                builder: (_) => DthRechargeDetails(
                  args: DthRechargeDetailsArgs(
                    operatorName: args['operatorName']?.toString() ?? '',
                    operatorId: args['operatorId']?.toString() ?? '',
                  ),
                ),
              );

            case '/app/dth-recharge/pay':
              final args = settings.arguments as Map<String, dynamic>? ?? {};
              return MaterialPageRoute(
                builder: (_) => DthPayScreen(
                  subscriberId: args['subscriberId']?.toString() ?? '',
                  operatorName: args['operatorName']?.toString() ?? '',
                  operatorId: args['operatorId']?.toString() ?? '',
                ),
              );
          // Placeholder for mobile loan form
          case '/app/mobile-loan':
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Mobile Loan')),
                body: const Center(child: Text('Mobile Loan Form — Coming Soon')),
              ),
            );

          // ── Placeholders for screens not yet converted ─────────────────

          case '/app/mpin':
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Manage mPIN')),
                body: const Center(child: Text('mPIN Screen — Coming Soon')),
              ),
            );

          case '/app/refer':
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Refer a Friend')),
                body: const Center(child: Text('Refer Screen — Coming Soon')),
              ),
            );

          case '/app/profile':
            return MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('My Profile')),
                body: const Center(child: Text('Profile Screen — Coming Soon')),
              ),
            );
            case '/app/billPayments/DthRecharge':
              return MaterialPageRoute(
                builder: (_) => const DthScreen(),
              );
            
            case '/app/billPayments/electricityBill':
              return MaterialPageRoute(
                builder: (_) => const ElectricityScreen(),
              );
            case '/app/electricity-recharge/details':
              final args = settings.arguments as Map<String, dynamic>? ?? {};
              return MaterialPageRoute(
                builder: (_) => ElectricityDetails(
                  args: ElectricityDetailsArgs(
                    operatorName: args['operatorName']?.toString() ?? '',
                    operatorId: args['operatorId']?.toString() ?? '',
                    operatorData: args['operatorData'] as Map<String, dynamic>? ?? {},
                  ),
                ),
              );
              case '/app/electricity-recharge/pay':
                final args = settings.arguments as Map<String, dynamic>? ?? {};
                return MaterialPageRoute(
                  builder: (_) => ElectricityPayScreen(
                    operatorName: args['operatorName']?.toString() ?? '',
                    operatorId: args['operatorId']?.toString() ?? '',
                    operatorData: args['operatorData'] as Map<String, dynamic>? ?? {},
                    formData: Map<String, String>.from(args['formData'] as Map? ?? {}),
                  ),
                );

          default:
            return null;
        }
      },

      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.noScaling,
          ),
          child: child!,
        );
      },
    );
  }
}