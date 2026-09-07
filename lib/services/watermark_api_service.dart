import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/watermark_settings_model.dart';
import 'api_config.dart';
import 'secure_storage_service.dart';

class WatermarkApiService {
  final http.Client _client;
  final SecureStorageService _storage;

  WatermarkApiService({
    http.Client? client,
    SecureStorageService? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? SecureStorageService();

  Future<Map<String, String>> _buildHeaders() async {
    final token = await _storage.getToken();
    final headers = Map<String, String>.from(ApiConfig.defaultHeaders);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Reads the current watermark configuration: GET /api/v1/watermark-settings
  Future<WatermarkSettingsModel> getWatermarkSettings({
    Duration? timeout,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.watermarkSettingsEndpoint}');

    try {
      final headers = await _buildHeaders();
      final response = await _client
          .get(url, headers: headers)
          .timeout(timeout ?? ApiConfig.requestTimeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body is Map<String, dynamic>) {
        return WatermarkSettingsModel.fromJson(body);
      }

      if (response.statusCode == 401) {
        throw Exception('Unauthenticated. Please sign in again.');
      }

      if (response.statusCode == 403) {
        final msg = (body is Map && body.containsKey('message'))
            ? body['message']
            : 'Access denied or tenant suspended.';
        throw Exception(msg);
      }

      if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded for watermark API (429 Too Many Attempts).');
      }

      final message = (body is Map && body.containsKey('message'))
          ? body['message']
          : 'Failed to fetch watermark settings (HTTP ${response.statusCode}).';
      throw Exception(message);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) {
        rethrow;
      }
      _handleNetworkError(e);
      rethrow;
    }
  }

  /// Updates the watermark configuration: PUT /api/v1/watermark-settings
  Future<WatermarkSettingsModel> updateWatermarkSettings(
    WatermarkSettingsModel settings, {
    Duration? timeout,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.watermarkSettingsEndpoint}');

    try {
      final headers = await _buildHeaders();
      final bodyJson = jsonEncode(settings.toJson());

      final response = await _client
          .put(url, headers: headers, body: bodyJson)
          .timeout(timeout ?? ApiConfig.requestTimeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body is Map<String, dynamic>) {
        return WatermarkSettingsModel.fromJson(body);
      }

      if (response.statusCode == 401) {
        throw Exception('Unauthenticated. Please sign in again.');
      }

      if (response.statusCode == 403) {
        final msg = (body is Map && body.containsKey('message'))
            ? body['message']
            : 'Access denied or tenant suspended.';
        throw Exception(msg);
      }

      if (response.statusCode == 422) {
        String msg = 'Validation error.';
        if (body is Map && body.containsKey('message')) {
          msg = body['message'].toString();
        } else if (body is Map && body.containsKey('errors')) {
          msg = 'Validation error: ${body['errors']}';
        }
        throw Exception(msg);
      }

      if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded for watermark API (429 Too Many Attempts).');
      }

      final message = (body is Map && body.containsKey('message'))
          ? body['message']
          : 'Failed to update watermark settings (HTTP ${response.statusCode}).';
      throw Exception(message);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) {
        rethrow;
      }
      _handleNetworkError(e);
      rethrow;
    }
  }

  void _handleNetworkError(dynamic e) {
    final errorStr = e.toString();
    if (errorStr.contains('SocketException') ||
        errorStr.contains('Failed host lookup') ||
        errorStr.contains('ClientException') ||
        errorStr.contains('TimeoutException') ||
        errorStr.contains('nodename nor servname provided')) {
      throw Exception(
        'Network connection failed. Please check your internet connection and try again.',
      );
    }
  }
}
