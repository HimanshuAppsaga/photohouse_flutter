import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/desktop_release_model.dart';
import 'api_config.dart';
import 'secure_storage_service.dart';

class DesktopReleaseApiService {
  final http.Client _client;
  final SecureStorageService _storage;

  DesktopReleaseApiService({
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

  /// Checks whether a desktop update is available: GET /api/v1/desktop/check-update
  Future<DesktopCheckUpdateModel> checkUpdate({
    required String platform,
    required String currentVersion,
    Duration? timeout,
  }) async {
    final endpoint = ApiConfig.desktopCheckUpdateEndpoint(
      platform: platform,
      currentVersion: currentVersion,
    );
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final headers = await _buildHeaders();
      final response = await _client
          .get(url, headers: headers)
          .timeout(timeout ?? ApiConfig.requestTimeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body is Map<String, dynamic>) {
        return DesktopCheckUpdateModel.fromJson(body);
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

      if (response.statusCode == 404) {
        throw Exception('No update or build found for platform: $platform');
      }

      if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded for desktop release API (429 Too Many Attempts).');
      }

      final message = (body is Map && body.containsKey('message'))
          ? body['message']
          : 'Failed to check update (HTTP ${response.statusCode}).';
      throw Exception(message);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) {
        rethrow;
      }
      _handleNetworkError(e);
      rethrow;
    }
  }

  /// Retrieves metadata for the latest desktop build: GET /api/v1/desktop/latest-build
  Future<DesktopLatestBuildModel> getLatestBuild({
    required String platform,
    Duration? timeout,
  }) async {
    final endpoint = ApiConfig.desktopLatestBuildEndpoint(platform: platform);
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final headers = await _buildHeaders();
      final response = await _client
          .get(url, headers: headers)
          .timeout(timeout ?? ApiConfig.requestTimeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body is Map<String, dynamic>) {
        return DesktopLatestBuildModel.fromJson(body);
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

      if (response.statusCode == 404) {
        throw Exception('No build found for platform: $platform');
      }

      if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded for desktop release API (429 Too Many Attempts).');
      }

      final message = (body is Map && body.containsKey('message'))
          ? body['message']
          : 'Failed to fetch latest build (HTTP ${response.statusCode}).';
      throw Exception(message);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) {
        rethrow;
      }
      _handleNetworkError(e);
      rethrow;
    }
  }

  /// Retrieves signed download/installer URL (or 302 redirect location): GET /api/v1/desktop/download-update
  Future<DesktopDownloadResponseModel> getDownloadUpdateUrl({
    required String platform,
    String type = 'installer',
    Duration? timeout,
  }) async {
    final endpoint = ApiConfig.desktopDownloadUpdateEndpoint(
      platform: platform,
      type: type,
    );
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');

    try {
      final headers = await _buildHeaders();

      // Use a custom request to capture 302 redirect header if returned without auto-redirect
      final request = http.Request('GET', url);
      request.headers.addAll(headers);
      request.followRedirects = false;

      final streamedResponse = await _client
          .send(request)
          .timeout(timeout ?? ApiConfig.requestTimeout);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 302 || response.statusCode == 301 || response.statusCode == 307) {
        final location = response.headers['location'] ?? '';
        return DesktopDownloadResponseModel(
          downloadUrl: location,
          platform: platform,
          type: type,
          statusCode: response.statusCode,
        );
      }

      Map<String, dynamic> body = {};
      if (response.body.isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map<String, dynamic>) {
            body = decoded;
          }
        } catch (_) {}
      }

      if (response.statusCode == 200) {
        final downloadUrl = (body['download_url'] ?? body['url'] ?? body['location'] ?? '').toString();
        return DesktopDownloadResponseModel(
          downloadUrl: downloadUrl,
          platform: platform,
          type: type,
          statusCode: 200,
        );
      }

      if (response.statusCode == 401) {
        throw Exception('Unauthenticated. Please sign in again.');
      }

      if (response.statusCode == 403) {
        final msg = body.containsKey('message')
            ? body['message']
            : 'Access denied or tenant suspended.';
        throw Exception(msg);
      }

      if (response.statusCode == 404) {
        throw Exception('Download build not found for platform: $platform ($type)');
      }

      if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded for desktop release API (429 Too Many Attempts).');
      }

      final message = body.containsKey('message')
          ? body['message']
          : 'Failed to request download URL (HTTP ${response.statusCode}).';
      throw Exception(message);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) {
        rethrow;
      }
      _handleNetworkError(e);
      rethrow;
    }
  }

  /// Retrieves the Tauri updater manifest: GET /api/v1/desktop/updater-manifest
  Future<TauriUpdaterManifestModel> getUpdaterManifest({
    Duration? timeout,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.desktopUpdaterManifestEndpoint}');

    try {
      final headers = await _buildHeaders();
      final response = await _client
          .get(url, headers: headers)
          .timeout(timeout ?? ApiConfig.requestTimeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body is Map<String, dynamic>) {
        return TauriUpdaterManifestModel.fromJson(body);
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
        throw Exception('Rate limit exceeded for desktop release API (429 Too Many Attempts).');
      }

      final message = (body is Map && body.containsKey('message'))
          ? body['message']
          : 'Failed to fetch updater manifest (HTTP ${response.statusCode}).';
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
