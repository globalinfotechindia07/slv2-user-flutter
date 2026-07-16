# ShubhLabh Patsanstha — Flutter App

A complete Flutter recreation of the ShubhLabh Patsanstha finance app.

---

## 📱 Screens

| Screen | Description |
|---|---|
| Splash | Animated dark-blue intro with logo & loading dots |
| Onboarding | 4-slide swipeable intro with progress bar |
| Login | Mobile number entry with +91 prefix |
| OTP Verification | 6-digit OTP with countdown timer |
| OTP Success | Animated checkmark confirmation |
| MPIN Entry | 4-digit secure PIN entry |
| Home Dashboard | Full dashboard with all sections |

## 🏠 Home Dashboard Sections
- **Featured** — Fixed Deposit, Mobile Loan, Savings Account, Insurance Service
- **Banner Carousel** — Auto-rotating 5 banners (3s interval)
- **Bill Payments** — Mobile Recharge, DTH, Electricity, Loan Repayment
- **Loans** — 10 loan types across Personal / Business tabs
- **Banking** — Daily Account, Savings Account, Current Account
- **Investment & More** — RD Scheme, FD Scheme, Sukanya Yojana
- **Insurance** — Insurance Services
- **My Loans** — Empty state with no loans found

## 🎨 Design System

| Element | Value |
|---|---|
| Primary (Red) | `#E53935` |
| Secondary (Dark Blue) | `#1A237E` |
| Accent (Blue) | `#3F51B5` |
| Background | `#FFF5F5` |
| Font | Roboto |

---

## 🚀 Setup Instructions

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android Studio / VS Code with Flutter plugin

### Steps

```bash
# 1. Navigate to project folder
cd shubhlabh

# 2. Install dependencies
flutter pub get

# 3. Run on connected device or emulator
flutter run

# 4. Build APK
flutter build apk --release
```

### Dependencies Used

```yaml
smooth_page_indicator: ^1.1.0   # Onboarding dots
pin_code_fields: ^8.0.1         # OTP input
carousel_slider: ^4.2.1         # Banner carousel
```

---

## 📂 Project Structure

```
lib/
├── main.dart
├── theme/
│   └── app_theme.dart          # Colors, ThemeData
├── screens/
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── login_screen.dart
│   ├── otp_success_screen.dart
│   ├── mpin_screen.dart
│   └── home_screen.dart
└── widgets/
    ├── app_logo.dart
    └── banner_carousel.dart
```

---

