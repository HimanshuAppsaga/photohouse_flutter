import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/login_response.dart';
import '../models/user_model.dart';
import 'api_config.dart';
import 'secure_storage_service.dart';

class AuthService {
  final http.Client _client;
  final SecureStorageService _storage;

  AuthService({http.Client? client, SecureStorageService? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? SecureStorageService();

  Future<LoginResponse> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}');
    final effectiveDeviceName = (deviceName != null && deviceName.isNotEmpty)
        ? deviceName
        : await _storage.getOrCreateDeviceId();

    try {
      final response = await _client.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          'device_name': effectiveDeviceName,
        }),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final loginResponse = LoginResponse.fromJson(body);

        await _storage.saveToken(loginResponse.token);
        await _storage.saveUser(jsonEncode(loginResponse.user.toJson()));

        return loginResponse;
      }

      if (response.statusCode == 422) {
        final message = _extract422Error(body);

        throw Exception(message);
      }

      if (response.statusCode == 403) {
        throw Exception(
          body['message'] ??
              'Your account has been suspended. Please contact support.',
        );
      }

      throw Exception(body['message'] ?? 'Login failed. Please try again.');
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('ClientException') ||
          e.toString().contains('nodename nor servname provided')) {
        throw Exception(
          'Network connection failed. Please check your internet connection and try again.',
        );
      }
      rethrow;
    }
  }

  Future<UserModel> getCurrentUser() async {
    final token = await _storage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token found.');
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.userEndpoint}');

      final response = await _client.get(
        url,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final user = UserModel.fromJson(body['data']);
        await _storage.saveUser(jsonEncode(user.toJson()));
        return user;
      }

      if (response.statusCode == 401) {
        await _storage.deleteToken();
        throw Exception('Session expired. Please login again.');
      }
    } catch (e) {
      if (e.toString().contains('Session expired')) rethrow;
    }

    final cachedUserJson = await _storage.getUser();
    if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
      return UserModel.fromJson(jsonDecode(cachedUserJson));
    }

    return UserModel.sampleUser;
  }

  Future<void> logout() async {
    final token = await _storage.getToken();

    if (token != null && token.isNotEmpty) {
      final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.logoutEndpoint}');

      try {
        await _client.post(
          url,
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      } catch (_) {
        // Ignore network / offline error during backend logout request
      }
    }

    await _storage.deleteToken();
  }

  Future<bool> hasToken() async {
    final token = await _storage.getToken();

    return token != null && token.isNotEmpty;
  }

  String _extract422Error(Map<String, dynamic> body) {
    final errors = body['errors'];

    if (errors is Map<String, dynamic> && errors.isNotEmpty) {
      for (final key in errors.keys) {
        final fieldErrors = errors[key];
        if (fieldErrors is List && fieldErrors.isNotEmpty) {
          return fieldErrors.first.toString();
        }
      }
    }

    return body['message'] ?? 'The provided credentials are incorrect.';
  }
}
