import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/subscription_model.dart';
import 'api_config.dart';
import 'secure_storage_service.dart';

class SubscriptionApiService {
  final http.Client _client;
  final SecureStorageService _storage;

  SubscriptionApiService({
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

  /// Fetches subscription & quota details from GET /api/v1/subscription
  Future<SubscriptionModel> getSubscription({
    Duration? timeout,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.subscriptionEndpoint}');

    try {
      final headers = await _buildHeaders();
      final response = await _client
          .get(url, headers: headers)
          .timeout(timeout ?? ApiConfig.requestTimeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body is Map<String, dynamic>) {
        return SubscriptionModel.fromJson(body);
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
        throw Exception('Rate limit exceeded for subscription API (429 Too Many Attempts).');
      }

      final message = (body is Map && body.containsKey('message'))
          ? body['message']
          : 'Failed to fetch subscription details (HTTP ${response.statusCode}).';
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
