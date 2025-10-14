// ==================== auth_service.dart ====================
import '../models/user.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient.instance;

  /// Send OTP to phone number
  Future<ApiResponse<Map<String, dynamic>>> sendOtp(String phoneNumber) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/auth/send-otp/',
      {'phone_number': phoneNumber},
      requiresAuth: false,
    );
  }

  /// Verify OTP and login user
  /// Returns user data and tokens
  Future<ApiResponse<Map<String, dynamic>>> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    return await _apiClient.post<Map<String, dynamic>>(
      '/auth/verify-otp/',
      {
        'phone_number': phoneNumber,
        'otp': otp,
      },
      requiresAuth: false,
    );
  }

  /// Get current logged-in user profile
  Future<ApiResponse<User>> getCurrentUser() async {
    return await _apiClient.get<User>(
      '/auth/profile/',
      fromJson: (json) => User.fromJson(json),
    );
  }

  /// Update user profile with text fields only
  Future<ApiResponse<User>> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
  }) async {
    final data = <String, dynamic>{};
    if (firstName != null) data['first_name'] = firstName;
    if (lastName != null) data['last_name'] = lastName;
    if (email != null) data['email'] = email;

    return await _apiClient.put<User>(
      '/auth/profile/update/',
      data,
      fromJson: (json) => User.fromJson(json),
    );
  }

  /// Update user profile picture
  /// [imagePath] - Local file path to the image
  /// Returns updated user profile with new profile picture URL
  Future<ApiResponse<User>> updateProfilePicture(String imagePath) async {
    return await _apiClient.patchMultipart<User>(
      '/auth/profile/update/',
      {}, // No text fields, just the file
      {
        'profile_picture': imagePath, // Field name matches Django serializer
      },
      fromJson: (json) => User.fromJson(json),
    );
  }

  /// Update profile with both text fields and profile picture
  /// [imagePath] - Optional local file path to the image
  Future<ApiResponse<User>> updateProfileWithPicture({
    String? firstName,
    String? lastName,
    String? email,
    String? imagePath,
  }) async {
    final fields = <String, String>{};
    if (firstName != null) fields['first_name'] = firstName;
    if (lastName != null) fields['last_name'] = lastName;
    if (email != null) fields['email'] = email;

    final files = <String, String>{};
    if (imagePath != null) files['profile_picture'] = imagePath;

    return await _apiClient.patchMultipart<User>(
      '/auth/profile/update/',
      fields,
      files,
      fromJson: (json) => User.fromJson(json),
    );
  }

  /// Logout user by clearing local tokens
  Future<void> logout() async {
    await _apiClient.clearTokens();
  }

  /// Delete user account permanently
  Future<ApiResponse<Map<String, dynamic>>> deleteAccount() async {
    return await _apiClient.delete<Map<String, dynamic>>(
      '/auth/delete-account/',
      fromJson: (json) => json,
    );
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final response = await getCurrentUser();
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }
}