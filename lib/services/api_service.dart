import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

// ── API Constants — ─────────────────────────────────────
class ApiConstants {
  // static const String userBaseUrl =
  //     'https://shubhlabhpatsanstha.org/backend/userss';
  // static const String adminBaseUrl =
  //     'https://shubhlabhpatsanstha.org/backend/admin';
  // static const String otpBaseUrl =
  //     'https://shubhlabhpatsanstha.org/backend/otp';
  // static const String razorpayKey = 'rzp_test_R7xzyaqsmw9C9O';
    static const String userBaseUrl =
      'http://192.168.1.5/backend/userss';
    static const String adminBaseUrl =
        'http://192.168.1.5/backend/admin';
    static const String otpBaseUrl =
        'http://192.168.1.5/backend/otp';
    static const String servicesBaseUrl =
        'http://192.168.1.5/backend/services';
    static const String razorpayKey = 'rzp_test_R7xzyaqsmw9C9O';
    static const String newAuthBaseUrl = 'http://192.168.1.5:3000';

}

class ApiService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
  };

  
// Replace existing sendOtp:
static Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
  final response = await http.post(
    Uri.parse('${ApiConstants.newAuthBaseUrl}/api/v2/mobile/auth/otp/send'),
    headers: _headers,
    body: jsonEncode({'phone': phoneNumber, 'purpose': 'LOGIN'}),
  );
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  data['statusCode'] = response.statusCode;
  return data;
}

// Replace existing verifyOtp:
static Future<Map<String, dynamic>> verifyOtp(
    String requestId, String otp) async {
  final response = await http.post(
    Uri.parse('${ApiConstants.newAuthBaseUrl}/api/v2/mobile/auth/otp/verify'),
    headers: _headers,
    body: jsonEncode({'request_id': requestId, 'otp': otp}),
  );
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  data['statusCode'] = response.statusCode;
  return data;
}

// Add new resendOtp:
static Future<Map<String, dynamic>> resendOtp(String requestId) async {
  final response = await http.post(
    Uri.parse('${ApiConstants.newAuthBaseUrl}/api/v2/mobile/auth/otp/send'),
    headers: _headers,
    body: jsonEncode({'request_id': requestId}),
  );
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  data['statusCode'] = response.statusCode;
  return data;
}

static Future<Map<String, dynamic>> loginWithMpin({
  required String phoneNumber,
  required String mpin,
}) async {
  final response = await http.post(
    Uri.parse('${ApiConstants.newAuthBaseUrl}/api/v2/mobile/auth/mpin-login'),
    headers: _headers,
    body: jsonEncode({
      'phoneNumber': phoneNumber,
      'mpin': mpin,
    }),
  );
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  data['statusCode'] = response.statusCode;
  return data;
}
 
  static Future<Map<String, dynamic>> resetMpin(
      String phoneNumber, String newMpin) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.userBaseUrl}/reset-mpin.php'),
      headers: _headers,
      body: jsonEncode({
        'phoneNumber': phoneNumber,
        'mpin': newMpin,
      }),
    );
    return jsonDecode(response.body);
  }
  static Future<Map<String, dynamic>> resetMpinWithToken({
  required String mpin,
  required String confirmMpin,
  required String tempToken,
}) async {
  final response = await http.post(
    Uri.parse('${ApiConstants.newAuthBaseUrl}/api/v2/mobile/auth/mpin-reset'),
    headers: {
      ..._headers,
      'Authorization': 'Bearer $tempToken',
    },
    body: jsonEncode({
      'mpin': mpin,
      'confirmMpin': confirmMpin,
    }),
  );
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  data['statusCode'] = response.statusCode;
  return data;
}

static Future<Map<String, dynamic>> setupMpin({
  required String mpin,
  required String confirmMpin,
  required String tempToken,
}) async {
  final response = await http.post(
    Uri.parse('${ApiConstants.newAuthBaseUrl}/api/v2/mobile/auth/mpin-setup'),
    headers: {
      ..._headers,
      'Authorization': 'Bearer $tempToken',
    },
    body: jsonEncode({
      'mpin': mpin,
      'confirmMpin': confirmMpin,
    }),
  );
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  data['statusCode'] = response.statusCode;
  return data;
}

static Future<Map<String, dynamic>> registerUser(
    Map<String, dynamic> formData, {String tempToken = ''}) async {
  final response = await http.post(
    Uri.parse('${ApiConstants.userBaseUrl}/register.php'),
    headers: {
      ..._headers,
      if (tempToken.isNotEmpty) 'Authorization': 'Bearer $tempToken',
    },
    body: jsonEncode(formData),
  );
  return jsonDecode(response.body);
}
static Future<Map<String, dynamic>> setupProfile({
  required String fullName,
  required String email,
  required String dob,
  required String gender,
  required String address,
  required String tempToken,
}) async {
  final response = await http.post(
    Uri.parse('${ApiConstants.newAuthBaseUrl}/api/v2/mobile/auth/profile-setup'),
    headers: {
      ..._headers,
      'Authorization': 'Bearer $tempToken',
    },
    body: jsonEncode({
      'fullName': fullName,
      'email': email,
      'dob': dob,
      'gender': gender,
      'address': address,
    }),
  );
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  data['statusCode'] = response.statusCode;
  return data;
}

 
  static Future<Map<String, dynamic>> getProfile() async {
  final token = await AuthService.getAccessToken();
  final response = await http.get(
    Uri.parse('${ApiConstants.newAuthBaseUrl}/api/v2/mobile-auth/profile'),
    headers: {
      ..._headers,
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    },
  );
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  data['statusCode'] = response.statusCode;
  return data;
}

static Future<Map<String, dynamic>> checkUserRegistration(
      String phoneNumber) async {
    final response = await http.post(
      Uri.parse(
          '${ApiConstants.userBaseUrl}/check-registration.php'),
      headers: _headers,
      body: jsonEncode({'phoneNumber': phoneNumber}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> getUserById(String userId) async {
    final response = await http.get(
      Uri.parse(
          '${ApiConstants.userBaseUrl}/getUser.php?userId=$userId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

 
  static Future<Map<String, dynamic>> verifyUserToken() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.userBaseUrl}/verify_token.php'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }


  static Future<Map<String, dynamic>> getTransactions(
      String userId) async {
    final response = await http.get(
      Uri.parse(
          '${ApiConstants.userBaseUrl}/get_transactions.php?user_id=$userId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  
  static Future<Map<String, dynamic>> getNotifications(
      String userId) async {
    final response = await http.get(
      Uri.parse(
          '${ApiConstants.userBaseUrl}/notifications.php?user_id=$userId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

 
  static Future<void> markAsRead(
      String notificationId, String userId) async {
    await http.put(
      Uri.parse('${ApiConstants.userBaseUrl}/notifications.php'),
      headers: _headers,
      body: jsonEncode({
        'notification_id': notificationId,
        'user_id': userId,
      }),
    );
  }

  static Future<Map<String, dynamic>> listPopularServices() async {
    final response = await http.get(
      Uri.parse(
          '${ApiConstants.adminBaseUrl}/getPopularServices.php'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  // listOffersCard — GET admin/list_OffersCard.php
  static Future<Map<String, dynamic>> listOffersCard() async {
    final response = await http.get(
      Uri.parse(
          '${ApiConstants.adminBaseUrl}/list_OffersCard.php'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  
  static Future<Map<String, dynamic>> getLoanApplications(
      String userId) async {
    final response = await http.get(
      Uri.parse(
          '${ApiConstants.userBaseUrl}/getLoanApplication.php?userId=$userId'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

 
  static Future<Map<String, dynamic>> fetchCategories() async {
    final response = await http.get(
      Uri.parse(
          '${ApiConstants.userBaseUrl}/get_loan_categories.php'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }


  static Future<Map<String, dynamic>> addForm(
      Map<String, dynamic> formData) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.userBaseUrl}/add_form.php'),
      headers: _headers,
      body: jsonEncode(formData),
    );
    return jsonDecode(response.body);
  }


  static Future<Map<String, dynamic>> listShop() async {
    final response = await http.get(
      Uri.parse('${ApiConstants.userBaseUrl}/listShop.php'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  
  static Future<Map<String, dynamic>> uploadProfileImage(
      String filePath, String userId) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConstants.userBaseUrl}/upload_profile.php'),
    );
    request.fields['user_id'] = userId;
    String ext = filePath.split('.').last.toLowerCase();
  if (!['jpg', 'jpeg', 'png', 'gif'].contains(ext)) {
    ext = 'jpg';
  }

  final mimeMap = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'gif': 'image/gif',
  };
    request.files.add(
    await http.MultipartFile.fromPath(
      'profile_image',
      filePath,
      filename: 'profile.$ext',
      contentType: MediaType.parse(mimeMap[ext]!),
    ),
  );

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);
  return jsonDecode(response.body);
}

  static Future<Map<String, dynamic>> sendEmailOtp(String email) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConstants.otpBaseUrl}/send_email_otp.php'),
      headers: _headers,
      body: jsonEncode({'email': email}),
    );
    if (response.body.trim().startsWith('<')) {
      return {'success': false, 'message': 'Email verification service not available yet'};
    }
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Email verification service not available yet'};
  }
}

static Future<Map<String, dynamic>> verifyEmailOtp(String email, String otp) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConstants.otpBaseUrl}/verify_email_otp.php'),
      headers: _headers,
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    if (response.body.trim().startsWith('<')) {
      return {'success': false, 'message': 'Email verification service not available yet'};
    }
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Email verification service not available yet'};
  }
}

static Future<Map<String, dynamic>> sendAadhaarOtp(String phone, String aadhaar) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConstants.otpBaseUrl}/send_aadhaar_otp.php'),
      headers: _headers,
      body: jsonEncode({'phone': phone, 'aadhaar': aadhaar}),
    );
    if (response.body.trim().startsWith('<')) {
      return {'success': false, 'message': 'Aadhaar verification service not available yet'};
    }
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Aadhaar verification service not available yet'};
  }
}

static Future<Map<String, dynamic>> verifyAadhaarOtp(String phone, String aadhaar, String otp) async {
  try {
    final response = await http.post(
      Uri.parse('${ApiConstants.otpBaseUrl}/verify_aadhaar_otp.php'),
      headers: _headers,
      body: jsonEncode({'phone': phone, 'aadhaar': aadhaar, 'otp': otp}),
    );
    if (response.body.trim().startsWith('<')) {
      return {'success': false, 'message': 'Aadhaar verification service not available yet'};
    }
    return jsonDecode(response.body);
  } catch (e) {
    return {'success': false, 'message': 'Aadhaar verification service not available yet'};
  }
}

static Future<Map<String, dynamic>> logout() async {
  final response = await http.post(
    Uri.parse('${ApiConstants.userBaseUrl}/logout.php'),
    headers: _headers,
  );
  return jsonDecode(response.body);
}
static Future<Map<String, dynamic>> sendReferenceOtp({
  required String phoneNumber,
  required String referenceName,
  required String applicationName,
}) async {
  final response = await http.post(
    Uri.parse('${ApiConstants.otpBaseUrl}/new_otp2.php?action=send_otp'),
    headers: _headers,
    body: jsonEncode({
      'phone_number': phoneNumber,
      'reference_name': referenceName,
      'application_name': applicationName,
    }),
  );
  return jsonDecode(response.body);
}
static Future<Map<String, dynamic>> verifyReferenceOtp(
    String phoneNumber, String otp) async {
  final response = await http.post(
    Uri.parse('${ApiConstants.otpBaseUrl}/new_otp2.php?action=verify_otp'),
    headers: _headers,
    body: jsonEncode({
      'phone_number': phoneNumber,
      'otp': otp,
    }),
  );
  return jsonDecode(response.body);
}
static Future<Map<String, dynamic>> saveLoanDocuments(
    Map<String, dynamic> data) async {
  final request = http.MultipartRequest(
    'POST',
    Uri.parse('${ApiConstants.adminBaseUrl}/save_loan_documents.php'),
  );

  // Plain string fields
  final stringFields = [
    'loan_id', 'application_id', 'userName', 'userDepartment',
    'bankName', 'accountNumber', 'ifscCode',
    'reference1Name', 'reference1Contact',
    'reference2Name', 'reference2Contact',
  ];
  for (final key in stringFields) {
    if (data[key] != null) {
      request.fields[key] = data[key].toString();
    }
  }

  final token = await AuthService.getAccessToken();
  if (token != null && token.isNotEmpty) {
    request.headers['Authorization'] = 'Bearer $token';
  }

  // EMI plan as JSON string
  if (data['selectedEmiPlan'] != null) {
    request.fields['selectedEmiPlan'] = jsonEncode(data['selectedEmiPlan']);
  }

  // File fields — value is a local file path string
  final fileFields = [
    'passbookDoc', 'agreementDoc', 'nachDoc',
    'reference1AadharDoc', 'reference1AadharDocBack', 'reference1PanDoc',
    'reference2AadharDoc', 'reference2AadharDocBack', 'reference2PanDoc',
  ];
  for (final key in fileFields) {
    if (data[key] != null) {
      request.files.add(
        await http.MultipartFile.fromPath(key, data[key] as String),
      );
    }
  }

  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);
  print('saveLoanDocuments response: ${response.body}');
  return jsonDecode(response.body);
}
static Future<void> sendNotification(String message, dynamic userId) async {
  await http.post(
    Uri.parse('${ApiConstants.userBaseUrl}/notifications.php'),
    headers: _headers,
    body: jsonEncode({
      'message': message,
      'user_id': userId,
    }),
  );
}
static Future<Map<String, dynamic>> verifyMpin(
    String phoneNumber, String mpin) async {
  final response = await http.post(
    Uri.parse('${ApiConstants.userBaseUrl}/verify_mpin.php'),
    headers: _headers,
    body: jsonEncode({
      'phoneNumber': phoneNumber,
      'mpin': mpin,
    }),
  );
  final data = jsonDecode(response.body) as Map<String, dynamic>;
  data['statusCode'] = response.statusCode;
  return data;
}
static Future<Map<String, dynamic>> getOperators({String category = 'Prepaid'}) async {
    final response = await http.get(
      Uri.parse('${ApiConstants.servicesBaseUrl}/getoperator.php?category=$category'),
      headers: _headers,
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> checkHlr(String number, {String type = 'mobile'}) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.servicesBaseUrl}/hlr-check.php'),
      headers: _headers,
      body: jsonEncode({'number': number, 'type': type}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> browsePlans({
    required String circle,
    required String? operatorName,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConstants.servicesBaseUrl}/browseplans.php'),
      headers: _headers,
      body: jsonEncode({'circle': circle, 'op': operatorName}),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> createRechargeOrder({
    required String activeTab,
    required int? planId,
    required String amount,
    required String circle,
    required String? operatorName,
    required String mobileNumber,
  }) async {
    final token = await AuthService.getAccessToken();
    debugPrint('RECHARGE TOKEN: $token');
    final response = await http.post(
      Uri.parse('${ApiConstants.servicesBaseUrl}/create-order.php'),
      headers: {
        ..._headers,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'activeTab': activeTab,
        'planId': planId,
        'amount': amount,
        'circle': circle,
        'op': operatorName,
        'mobile_number': mobileNumber,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> verifyRechargePayment({
    required String razorpayPaymentId,
    required String razorpayOrderId,
    required String razorpaySignature,
  }) async {
    final token = await AuthService.getAccessToken();
    final response = await http.post(
      Uri.parse('${ApiConstants.servicesBaseUrl}/verify-payment.php'),
      headers: {
        ..._headers,
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'razorpay_payment_id': razorpayPaymentId,
        'razorpay_order_id': razorpayOrderId,
        'razorpay_signature': razorpaySignature,
      }),
    );
    return jsonDecode(response.body);
  }
}