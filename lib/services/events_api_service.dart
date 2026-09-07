import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/album_model.dart';
import '../models/event_model.dart';
import 'api_config.dart';
import 'secure_storage_service.dart';

class EventListResponse {
  final List<EventItem> events;
  final String? nextCursor;
  final String? prevCursor;
  final int perPage;

  const EventListResponse({
    required this.events,
    this.nextCursor,
    this.prevCursor,
    this.perPage = 50,
  });

  factory EventListResponse.fromJson(Map<String, dynamic> json) {
    final List<EventItem> loadedEvents = [];
    if (json['data'] is List) {
      for (final item in (json['data'] as List)) {
        if (item is Map<String, dynamic>) {
          loadedEvents.add(EventItem.fromJson(item));
        }
      }
    }

    String? nextCursor;
    String? prevCursor;
    int perPage = ApiConfig.defaultPageSize;

    if (json['meta'] is Map<String, dynamic>) {
      final meta = json['meta'] as Map<String, dynamic>;
      nextCursor = meta['next_cursor'] as String?;
      prevCursor = meta['prev_cursor'] as String?;
      if (meta['per_page'] is int) {
        perPage = meta['per_page'] as int;
      }
    }

    return EventListResponse(
      events: loadedEvents,
      nextCursor: nextCursor,
      prevCursor: prevCursor,
      perPage: perPage,
    );
  }
}

class EventsApiService {
  final http.Client _client;
  final SecureStorageService _storage;

  EventsApiService({
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

  /// Fetches paginated events list from GET /api/v1/events
  Future<EventListResponse> getEvents({
    String? type,
    String? cursor,
    Duration? timeout,
  }) async {
    final queryParams = <String, String>{};
    if (type != null && type.isNotEmpty && type.toLowerCase() != 'all') {
      queryParams['type'] = type.toLowerCase();
    }
    if (cursor != null && cursor.isNotEmpty) {
      queryParams['cursor'] = cursor;
    }

    final baseUri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.eventsEndpoint}');
    final url = queryParams.isEmpty
        ? baseUri
        : baseUri.replace(queryParameters: queryParams);

    try {
      final headers = await _buildHeaders();
      final response = await _client
          .get(url, headers: headers)
          .timeout(timeout ?? ApiConfig.requestTimeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body is Map<String, dynamic>) {
        return EventListResponse.fromJson(body);
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
        throw Exception('Rate limit exceeded for events API (429 Too Many Attempts).');
      }

      final message = (body is Map && body.containsKey('message'))
          ? body['message']
          : 'Failed to fetch events (HTTP ${response.statusCode}).';
      throw Exception(message);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) {
        rethrow;
      }
      _handleNetworkError(e);
      rethrow;
    }
  }

  /// Fetches single event details from GET /api/v1/events/{event_uuid}
  Future<EventItem> getEventDetails(
    String eventUuid, {
    Duration? timeout,
  }) async {
    final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.eventDetailsEndpoint(eventUuid)}');

    try {
      final headers = await _buildHeaders();
      final response = await _client
          .get(url, headers: headers)
          .timeout(timeout ?? ApiConfig.requestTimeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          body is Map<String, dynamic> &&
          body['data'] is Map<String, dynamic>) {
        return EventItem.fromJson(body['data'] as Map<String, dynamic>);
      }

      if (response.statusCode == 401) {
        throw Exception('Unauthenticated. Please sign in again.');
      }

      if (response.statusCode == 404) {
        throw Exception('Event not found or does not belong to your account.');
      }

      final message = (body is Map && body.containsKey('message'))
          ? body['message']
          : 'Failed to fetch event details (HTTP ${response.statusCode}).';
      throw Exception(message);
    } catch (e) {
      if (e is Exception && e.toString().contains('Exception:')) {
        rethrow;
      }
      _handleNetworkError(e);
      rethrow;
    }
  }

  /// Fetches albums of an event from GET /api/v1/events/{event_uuid}/albums
  Future<List<AlbumItem>> getEventAlbums(
    String eventUuid, {
    Duration? timeout,
  }) async {
    final url = Uri.parse(
        '${ApiConfig.baseUrl}${ApiConfig.eventAlbumsEndpoint(eventUuid)}');

    try {
      final headers = await _buildHeaders();
      final response = await _client
          .get(url, headers: headers)
          .timeout(timeout ?? ApiConfig.requestTimeout);

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          body is Map<String, dynamic> &&
          body['data'] is List) {
        final list = body['data'] as List;
        return list
            .whereType<Map<String, dynamic>>()
            .map((item) => AlbumItem.fromJson(item))
            .toList();
      }

      if (response.statusCode == 401) {
        throw Exception('Unauthenticated. Please sign in again.');
      }

      if (response.statusCode == 404) {
        throw Exception('Event or albums not found.');
      }

      final message = (body is Map && body.containsKey('message'))
          ? body['message']
          : 'Failed to fetch event albums (HTTP ${response.statusCode}).';
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
