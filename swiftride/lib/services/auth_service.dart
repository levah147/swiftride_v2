import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient.instance;

  Future<ApiResponse<Map<String, dynamic>>> sendOtp(String phoneNumber) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/accounts/send-otp/',
      {'phone_number': phoneNumber},
      requiresAuth: false,
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/accounts/verify-otp/',
      {
        'phone_number': phoneNumber,
        'otp': otp,
      },
      requiresAuth: false,
    );
  }

  Future<ApiResponse<User>> getCurrentUser() async {
    return await _apiClient.get<User>(
      '/accounts/profile/',
      fromJson: (json) => User.fromJson(json),
    );
  }

  Future<ApiResponse<User>> updateProfile(Map<String, dynamic> data) async {
    return await _apiClient.put<User>(
      '/accounts/profile/',
      data,
      fromJson: (json) => User.fromJson(json),
    );
  }

  Future<void> logout() async {
    await _apiClient.clearToken();
  }

  Future<bool> isLoggedIn() async {
    try {
      final response = await getCurrentUser();
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }
}
