import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/health_model.dart';
import '../models/platform_branding_model.dart';
import 'api_config.dart';

class PublicApiService {
  final http.Client _client;

  PublicApiService({http.Client? client})
      : _client = client ?? http.Client();


  Future<HealthModel> getHealthStatus({Duration? timeout}) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.healthEndpoint}');

    try {
      final response = await _client
          .get(
            url,
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(timeout ?? ApiConfig.requestTimeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body is Map<String, dynamic>) {
        return HealthModel.fromJson(body);
      }

      final message = (body is Map && body.containsKey('message'))
          ? body['message']
          : 'Failed to retrieve health status (HTTP ${response.statusCode}).';
      throw Exception(message);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) {
        rethrow;
      }
      _handleNetworkError(e);
      rethrow;
    }
  }


  Future<PlatformBrandingModel> getPlatformBranding({
    Duration? timeout,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.brandingEndpoint}');

    try {
      final response = await _client
          .get(
            url,
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(timeout ?? ApiConfig.requestTimeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body is Map<String, dynamic>) {
        return PlatformBrandingModel.fromJson(body);
      }

      if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded for branding requests (429 Too Many Attempts).');
      }

      final message = (body is Map && body.containsKey('message'))
          ? body['message']
          : 'Failed to retrieve platform branding (HTTP ${response.statusCode}).';
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
