import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static const String baseUrl = 'http://192.168.235.65:8000/api';
  static ApiClient? _instance;
  
  ApiClient._internal();
  
  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  // Token management
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<String?> _getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  // Headers
  Map<String, String> _getHeaders({bool requiresAuth = true}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _getMultipartAuthHeaders() async {
    final token = await _getAccessToken();
    return {
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // CRUD operations
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
    Map<String, String>? queryParams,
  }) async {
    try {
      // Build URI with query parameters
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = requiresAuth 
          ? await _getAuthHeaders() 
          : _getHeaders(requiresAuth: false);
      
      debugPrint('GET Request: $uri');
      
      final response = await http.get(uri, headers: headers)
          .timeout(const Duration(seconds: 30));

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('GET Error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = requiresAuth 
          ? await _getAuthHeaders() 
          : _getHeaders(requiresAuth: false);
      
      debugPrint('POST Request: $baseUrl$endpoint');
      debugPrint('POST Data: ${jsonEncode(data)}');
      
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));

      final result = _handleResponse<T>(response, fromJson);
      
      // Save tokens if present (for login/verify-otp)
      if (result.isSuccess && result.data != null) {
        await _extractAndSaveTokens(result.data);
      }
      
      return result;
    } catch (e) {
      debugPrint('POST Error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = requiresAuth 
          ? await _getAuthHeaders() 
          : _getHeaders(requiresAuth: false);
      
      debugPrint('PUT Request: $baseUrl$endpoint');
      
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('PUT Error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> patch<T>(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = requiresAuth 
          ? await _getAuthHeaders() 
          : _getHeaders(requiresAuth: false);
      
      debugPrint('PATCH Request: $baseUrl$endpoint');
      
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30));

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('PATCH Error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = requiresAuth 
          ? await _getAuthHeaders() 
          : _getHeaders(requiresAuth: false);
      
      debugPrint('DELETE Request: $baseUrl$endpoint');
      
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('DELETE Error: $e');
      return ApiResponse.error('Network error: ${e.toString()}');
    }
  }

  // Multipart requests
  Future<ApiResponse<T>> postMultipart<T>(
    String endpoint,
    Map<String, String> fields,
    Map<String, String> files, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = await _getMultipartAuthHeaders();
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'))
        ..headers.addAll(headers);

      // Add fields
      request.fields.addAll(fields);

      // Add files
      for (final entry in files.entries) {
        final file = await http.MultipartFile.fromPath(entry.key, entry.value);
        request.files.add(file);
      }

      debugPrint('POST Multipart: $baseUrl$endpoint');

      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('Multipart Upload Error: $e');
      return ApiResponse.error('Upload error: ${e.toString()}');
    }
  }

  Future<ApiResponse<T>> patchMultipart<T>(
    String endpoint,
    Map<String, String> fields,
    Map<String, String> files, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = await _getMultipartAuthHeaders();
      final request = http.MultipartRequest('PATCH', Uri.parse('$baseUrl$endpoint'))
        ..headers.addAll(headers);

      request.fields.addAll(fields);

      for (final entry in files.entries) {
        final file = await http.MultipartFile.fromPath(entry.key, entry.value);
        request.files.add(file);
      }

      debugPrint('PATCH Multipart: $baseUrl$endpoint');

      final streamedResponse = await request.send()
          .timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      debugPrint('Multipart Update Error: $e');
      return ApiResponse.error('Update error: ${e.toString()}');
    }
  }

  // Response handling
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    try {
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      // Handle empty responses
      if (response.body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          return ApiResponse.success(null as T);
        }
        return ApiResponse.error('Empty response from server');
      }

      final data = jsonDecode(response.body);

      // Success responses (200-299)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (fromJson != null) {
          return ApiResponse.success(fromJson(data));
        }
        return ApiResponse.success(data as T);
      }

      // Error responses
      final errorMessage = _extractErrorMessage(data);
      return ApiResponse.error(errorMessage, statusCode: response.statusCode);
      
    } catch (e) {
      debugPrint('Response Parse Error: $e');
      return ApiResponse.error('Failed to parse response: ${e.toString()}');
    }
  }

  // Extract error message from various response formats
  String _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      // Try common error fields
      if (data.containsKey('error')) {
        return data['error'].toString();
      }
      if (data.containsKey('message')) {
        return data['message'].toString();
      }
      if (data.containsKey('detail')) {
        return data['detail'].toString();
      }
      // Handle field-specific errors (e.g., {"email": ["Invalid email"]})
      if (data.isNotEmpty) {
        final firstError = data.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
        return firstError.toString();
      }
    }
    return 'Unknown error occurred';
  }

  // Extract and save tokens from response
  Future<void> _extractAndSaveTokens(dynamic data) async {
    try {
      if (data is Map<String, dynamic>) {
        // Check for tokens in response
        if (data.containsKey('tokens')) {
          final tokens = data['tokens'] as Map<String, dynamic>;
          if (tokens.containsKey('access') && tokens.containsKey('refresh')) {
            await _saveTokens(
              tokens['access'].toString(),
              tokens['refresh'].toString(),
            );
          }
        }
        // Also check root level (some APIs return tokens directly)
        if (data.containsKey('access_token') && data.containsKey('refresh_token')) {
          await _saveTokens(
            data['access_token'].toString(),
            data['refresh_token'].toString(),
          );
        }
      }
    } catch (e) {
      debugPrint('Token extraction error: $e');
    }
  }

  // Token refresh (for 401 errors)
  Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/token/refresh/'),
        headers: _getHeaders(requiresAuth: false),
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data.containsKey('access')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', data['access']);
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Token refresh error: $e');
      return false;
    }
  }
}

// Enhanced API Response class
class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;
  final int? statusCode;

  ApiResponse.success(this.data, {this.statusCode})
      : error = null,
        isSuccess = true;

  ApiResponse.error(this.error, {this.statusCode})
      : data = null,
        isSuccess = false;

  // Helper to check specific HTTP status codes
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;
}