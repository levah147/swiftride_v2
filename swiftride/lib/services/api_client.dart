// ==================== api_client.dart ====================
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static const String baseUrl = 'http://192.168.102.65:8000/api';
  static ApiClient? _instance;
  
  ApiClient._internal();
  
  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

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

  Map<String, String> _getHeaders({bool requiresAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    return headers;
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

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders(requiresAuth: false);
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders(requiresAuth: false);
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      final result = _handleResponse<T>(response, fromJson);
      
      // Save tokens if present in response (for login/verify-otp endpoints)
      if (result.isSuccess && result.data is Map) {
        final responseData = result.data as Map<String, dynamic>;
        if (responseData.containsKey('tokens')) {
          final tokens = responseData['tokens'] as Map<String, dynamic>;
          if (tokens.containsKey('access') && tokens.containsKey('refresh')) {
            await _saveTokens(tokens['access'], tokens['refresh']);
          }
        }
      }
      
      return result;
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint,
    Map<String, dynamic> data, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders(requiresAuth: false);
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
        body: jsonEncode(data),
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    bool requiresAuth = true,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final headers = requiresAuth ? await _getAuthHeaders() : _getHeaders(requiresAuth: false);
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Upload file with form data (for multipart requests like image uploads)
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

      // Add regular fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add files (key: field name, value: file path)
      for (final entry in files.entries) {
        final file = await http.MultipartFile.fromPath(
          entry.key,
          entry.value,
        );
        request.files.add(file);
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final httpResponse = http.Response(responseBody, response.statusCode);

      return _handleResponse<T>(httpResponse, fromJson);
    } catch (e) {
      return ApiResponse.error('Upload error: $e');
    }
  }

  /// PATCH request with multipart for updating with file upload
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

      // Add regular fields
      fields.forEach((key, value) {
        request.fields[key] = value;
      });

      // Add files
      for (final entry in files.entries) {
        final file = await http.MultipartFile.fromPath(
          entry.key,
          entry.value,
        );
        request.files.add(file);
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final httpResponse = http.Response(responseBody, response.statusCode);

      return _handleResponse<T>(httpResponse, fromJson);
    } catch (e) {
      return ApiResponse.error('Upload error: $e');
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? fromJson,
  ) {
    try {
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (fromJson != null) {
          return ApiResponse.success(fromJson(data));
        } else {
          return ApiResponse.success(data as T);
        }
      } else {
        final errorMessage = data['error'] ?? data['message'] ?? 'Unknown error';
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response: $e');
    }
  }
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  ApiResponse.success(this.data)
      : error = null,
        isSuccess = true;

  ApiResponse.error(this.error)
      : data = null,
        isSuccess = false;
}