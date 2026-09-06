import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'https://api.finbassshamar.online';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<Map<String, dynamic>> _handle(http.Response res) async {
    final body = jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    } else {
      final errorMsg = body['error'] ?? 'Request failed (${res.statusCode})';
      if (errorMsg.toString().startsWith('ACCOUNT_BANNED:')) {
        throw Exception('BANNED:${errorMsg.toString().replaceFirst('ACCOUNT_BANNED:', '')}');
      }
      throw Exception(errorMsg);
    }
  }

  // ---------- AUTH ----------
  static Future<void> register(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    await _handle(res);
  }

  static Future<Map<String, dynamic>> verifyRegistration(String email, String code, {String? referralCode}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-registration'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'code': code, 'referralCode': referralCode}),
    );
    final data = await _handle(res);
    await saveToken(data['token']);
    return data['user'];
  }

  static Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    await _handle(res);
  }

  static Future<Map<String, dynamic>> verifyLogin(String email, String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-login'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'code': code}),
    );
    final data = await _handle(res);
    await saveToken(data['token']);
    return data['user'];
  }

  static Future<void> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email}),
    );
    await _handle(res);
  }

  static Future<void> resetPassword(String email, String code, String newPassword) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/reset-password'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'email': email, 'code': code, 'newPassword': newPassword}),
    );
    await _handle(res);
  }

  static Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: await _headers(withAuth: false),
      body: jsonEncode({'idToken': idToken}),
    );
    final data = await _handle(res);
    await saveToken(data['token']);
    return data['user'];
  }

  // ---------- UPLOAD ----------
  static Future<String> uploadImage(File file) async {
    final token = await getToken();
    final uri = Uri.parse('$baseUrl/upload');
    final request = http.MultipartRequest('POST', uri);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedRes = await request.send();
    final resBody = await streamedRes.stream.bytesToString();

    if (streamedRes.statusCode != 200) {
      try {
        final err = jsonDecode(resBody);
        final errorMsg = err['error'] ?? 'Upload failed (${streamedRes.statusCode})';
        if (errorMsg.toString().startsWith('ACCOUNT_BANNED:')) {
          throw Exception('BANNED:${errorMsg.toString().replaceFirst('ACCOUNT_BANNED:', '')}');
        }
        throw Exception(errorMsg);
      } catch (e) {
        if (e is Exception) rethrow;
        throw Exception('Upload failed (${streamedRes.statusCode})');
      }
    }
    final data = jsonDecode(resBody);
    return data['url'];
  }

  // ---------- USER ----------
  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(Uri.parse('$baseUrl/user/me'), headers: await _headers());
    return await _handle(res);
  }

  static Future<void> updateProfile(String displayName, String phone, {String? profilePhotoUrl}) async {
    final res = await http.put(
      Uri.parse('$baseUrl/user/me'),
      headers: await _headers(),
      body: jsonEncode({'displayName': displayName, 'phone': phone, 'profilePhotoUrl': profilePhotoUrl}),
    );
    await _handle(res);
  }

  static Future<void> updateProfilePhoto(String profilePhotoUrl) async {
    final res = await http.put(
      Uri.parse('$baseUrl/user/me/photo'),
      headers: await _headers(),
      body: jsonEncode({'profilePhotoUrl': profilePhotoUrl}),
    );
    await _handle(res);
  }

  static Future<void> submitSupportRequest(String subject, String message) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/support-request'),
      headers: await _headers(),
      body: jsonEncode({'subject': subject, 'message': message}),
    );
    await _handle(res);
  }

  static Future<void> requestBankDetailsChange(String bankName, String accountName, String accountNumber, String branch) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/bank-details/request-change'),
      headers: await _headers(),
      body: jsonEncode({
        'bankName': bankName,
        'accountName': accountName,
        'accountNumber': accountNumber,
        'branch': branch,
      }),
    );
    await _handle(res);
  }

  static Future<void> confirmBankDetailsChange(String code) async {
    final res = await http.post(
      Uri.parse('$baseUrl/user/bank-details/confirm-change'),
      headers: await _headers(),
      body: jsonEncode({'code': code}),
    );
    await _handle(res);
  }

  static Future<void> changePassword(String currentPassword, String newPassword) async {
    final res = await http.put(
      Uri.parse('$baseUrl/user/change-password'),
      headers: await _headers(),
      body: jsonEncode({'currentPassword': currentPassword, 'newPassword': newPassword}),
    );
    await _handle(res);
  }

  // ---------- LISTINGS ----------
  static Future<List<dynamic>> getListings({String? game}) async {
    final uri = Uri.parse('$baseUrl/listings').replace(
      queryParameters: game != null ? {'game': game} : null,
    );
    final res = await http.get(uri, headers: await _headers(withAuth: false));
    final data = await _handle(res);
    return data['listings'];
  }

  static Future<Map<String, dynamic>> getListingDetail(int id) async {
    final res = await http.get(Uri.parse('$baseUrl/listings/$id'), headers: await _headers(withAuth: false));
    return await _handle(res);
  }

  static Future<List<dynamic>> getMyListings() async {
    final res = await http.get(Uri.parse('$baseUrl/listings/mine/all'), headers: await _headers());
    final data = await _handle(res);
    return data['listings'];
  }

  static Future<int> createListing({
    required String game,
    required String title,
    required String description,
    required String inGameUID,
    required double price,
    required List<String> screenshots,
    required String vaultEmail,
    required String vaultPassword,
    String vaultRecoveryCodes = '',
    bool allowBidding = false,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/listings'),
      headers: await _headers(),
      body: jsonEncode({
        'game': game,
        'title': title,
        'description': description,
        'inGameUID': inGameUID,
        'price': price,
        'screenshots': screenshots,
        'vaultEmail': vaultEmail,
        'vaultPassword': vaultPassword,
        'vaultRecoveryCodes': vaultRecoveryCodes,
        'allowBidding': allowBidding,
      }),
    );
    final data = await _handle(res);
    return data['id'];
  }

  static Future<void> placeBid(int listingId, double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/listings/$listingId/bid'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount}),
    );
    await _handle(res);
  }

  static Future<void> removeListing(int listingId) async {
    final res = await http.delete(Uri.parse('$baseUrl/listings/$listingId'), headers: await _headers());
    await _handle(res);
  }

  // ---------- ORDERS ----------
  static Future<Map<String, dynamic>> createOrder(int listingId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: await _headers(),
      body: jsonEncode({'listingId': listingId}),
    );
    return await _handle(res);
  }

  static Future<List<dynamic>> getMyPurchases() async {
    final res = await http.get(Uri.parse('$baseUrl/orders/my-purchases'), headers: await _headers());
    final data = await _handle(res);
    return data['orders'];
  }

  static Future<List<dynamic>> getMySales() async {
    final res = await http.get(Uri.parse('$baseUrl/orders/my-sales'), headers: await _headers());
    final data = await _handle(res);
    return data['orders'];
  }

  static Future<Map<String, dynamic>> getOrderVault(int orderId) async {
    final res = await http.get(Uri.parse('$baseUrl/orders/$orderId/vault'), headers: await _headers());
    return await _handle(res);
  }

  static Future<void> raiseDispute(int orderId, String reason) async {
    final res = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/dispute'),
      headers: await _headers(),
      body: jsonEncode({'reason': reason}),
    );
    await _handle(res);
  }

  static Future<void> notifyAdminOverdue(int orderId) async {
    final res = await http.post(Uri.parse('$baseUrl/orders/$orderId/notify-admin'), headers: await _headers());
    await _handle(res);
  }

  // ---------- ADMIN CHAT (buyer/seller <-> admin) ----------
  static Future<int> getMyAdminConversation(int orderId) async {
    final res = await http.get(Uri.parse('$baseUrl/admin-chat/my-conversation/$orderId'), headers: await _headers());
    final data = await _handle(res);
    return data['conversationId'];
  }

  static Future<List<dynamic>> getMyAdminMessages(int conversationId) async {
    final res = await http.get(Uri.parse('$baseUrl/admin-chat/my-messages/$conversationId'), headers: await _headers());
    final data = await _handle(res);
    return data['messages'];
  }

  static Future<void> sendMyAdminMessage(int conversationId, String content) async {
    final res = await http.post(
      Uri.parse('$baseUrl/admin-chat/my-messages/$conversationId'),
      headers: await _headers(),
      body: jsonEncode({'content': content}),
    );
    await _handle(res);
  }

  // ---------- CHATS ----------
  static Future<List<dynamic>> getConversations() async {
    final res = await http.get(Uri.parse('$baseUrl/chats'), headers: await _headers());
    final data = await _handle(res);
    return data['conversations'];
  }

  static Future<List<dynamic>> getMessages(int conversationId) async {
    final res = await http.get(Uri.parse('$baseUrl/chats/$conversationId/messages'), headers: await _headers());
    final data = await _handle(res);
    return data['messages'];
  }

  static Future<void> sendMessage(int conversationId, String content) async {
    final res = await http.post(
      Uri.parse('$baseUrl/chats/$conversationId/messages'),
      headers: await _headers(),
      body: jsonEncode({'content': content}),
    );
    await _handle(res);
  }

  // ---------- OFFERS ----------
  static Future<void> sendOffer(int listingId, double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/offers'),
      headers: await _headers(),
      body: jsonEncode({'listingId': listingId, 'amount': amount}),
    );
    await _handle(res);
  }

  static Future<List<dynamic>> getOffersSent() async {
    final res = await http.get(Uri.parse('$baseUrl/offers/sent'), headers: await _headers());
    final data = await _handle(res);
    return data['offers'];
  }

  static Future<List<dynamic>> getOffersReceived() async {
    final res = await http.get(Uri.parse('$baseUrl/offers/received'), headers: await _headers());
    final data = await _handle(res);
    return data['offers'];
  }

  static Future<int> acceptOffer(int offerId) async {
    final res = await http.post(Uri.parse('$baseUrl/offers/$offerId/accept'), headers: await _headers());
    final data = await _handle(res);
    return data['orderId'];
  }

  static Future<void> rejectOffer(int offerId) async {
    final res = await http.post(Uri.parse('$baseUrl/offers/$offerId/reject'), headers: await _headers());
    await _handle(res);
  }

  // ---------- NOTIFICATIONS / FCM ----------
  static Future<void> saveFcmToken(String fcmToken) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/notifications/fcm-token'),
        headers: await _headers(),
        body: jsonEncode({'token': fcmToken}),
      );
      await _handle(res);
    } catch (_) {}
  }

  static Future<List<dynamic>> getNotifications() async {
    final res = await http.get(Uri.parse('$baseUrl/notifications'), headers: await _headers());
    final data = await _handle(res);
    return data['notifications'];
  }

  static Future<int> getUnreadNotificationCount() async {
    final res = await http.get(Uri.parse('$baseUrl/notifications/unread-count'), headers: await _headers());
    final data = await _handle(res);
    return data['count'];
  }

  static Future<void> markAllNotificationsRead() async {
    final res = await http.post(Uri.parse('$baseUrl/notifications/mark-all-read'), headers: await _headers());
    await _handle(res);
  }

  // ---------- WALLET ----------
  static Future<double> getWalletBalance() async {
    final res = await http.get(Uri.parse('$baseUrl/wallet/balance'), headers: await _headers());
    final data = await _handle(res);
    return (data['walletBalance'] as num).toDouble();
  }

  static Future<Map<String, dynamic>> getAdminBankDetails() async {
    final res = await http.get(Uri.parse('$baseUrl/wallet/admin-bank-details'), headers: await _headers());
    return await _handle(res);
  }

  static Future<List<dynamic>> getTransactions() async {
    final res = await http.get(Uri.parse('$baseUrl/wallet/transactions'), headers: await _headers());
    final data = await _handle(res);
    return data['transactions'];
  }

  static Future<void> requestTopUp(double amount, String slipUrl) async {
    final res = await http.post(
      Uri.parse('$baseUrl/wallet/topup'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount, 'slipUrl': slipUrl}),
    );
    await _handle(res);
  }

  static Future<void> requestWithdrawal(double amount) async {
    final res = await http.post(
      Uri.parse('$baseUrl/wallet/withdraw'),
      headers: await _headers(),
      body: jsonEncode({'amount': amount}),
    );
    await _handle(res);
  }

  // ---------- VERIFICATION ----------
  static Future<void> submitVerification({
    required String fullName,
    required String nicNumber,
    required String address,
    required String province,
    required String district,
    required String documentType,
    required String frontImageUrl,
    String? backImageUrl,
    required String selfieImageUrl,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/verification'),
      headers: await _headers(),
      body: jsonEncode({
        'fullName': fullName,
        'nicNumber': nicNumber,
        'address': address,
        'province': province,
        'district': district,
        'documentType': documentType,
        'frontImageUrl': frontImageUrl,
        'backImageUrl': backImageUrl,
        'selfieImageUrl': selfieImageUrl,
      }),
    );
    await _handle(res);
  }

  static Future<Map<String, dynamic>> getVerificationStatusFull() async {
    final res = await http.get(Uri.parse('$baseUrl/verification/status'), headers: await _headers());
    return await _handle(res);
  }
}
