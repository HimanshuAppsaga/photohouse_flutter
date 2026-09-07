import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:photohouse/models/endpoint_summary_model.dart';
import 'package:photohouse/services/endpoint_summary_api_service.dart';
import 'package:photohouse/services/secure_storage_service.dart';

class FakeSecureStorageService implements SecureStorageService {
  final String? token;
  final String? user;

  FakeSecureStorageService({this.token = 'mock_jwt_token_123', this.user});

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> deleteToken() async {}

  @override
  Future<String?> getUser() async => user;

  @override
  Future<void> saveUser(String jsonUser) async {}

  @override
  Future<String> getOrCreateDeviceId() async => 'test-device-id';

  @override
  Future<void> saveUploadQueue(String queueJson) async {}

  @override
  Future<String?> getUploadQueue() async => null;

  @override
  Future<void> deleteUploadQueue() async {}

  @override
  Future<String?> readKey(String key) async => null;

  @override
  Future<void> writeKey(String key, String value) async {}
}

void main() {
  group('EndpointSummaryCatalog & Model Tests', () {
    test(
      'getAllEndpoints returns exactly 23 endpoints covering 8 categories',
      () {
        final endpoints = EndpointSummaryCatalog.getAllEndpoints();
        expect(endpoints.length, equals(23));

        final categories = endpoints.map((e) => e.category).toSet();
        expect(categories.length, equals(8));
        expect(categories, contains(EndpointCategory.system));
        expect(categories, contains(EndpointCategory.auth));
        expect(categories, contains(EndpointCategory.events));
        expect(categories, contains(EndpointCategory.upload));
        expect(categories, contains(EndpointCategory.history));
        expect(categories, contains(EndpointCategory.subscription));
        expect(categories, contains(EndpointCategory.watermark));
        expect(categories, contains(EndpointCategory.desktop));
      },
    );

    test('getIntegrationChecklist returns 8 checklist items', () {
      final checklist = EndpointSummaryCatalog.getIntegrationChecklist();
      expect(checklist.length, equals(8));
      expect(checklist.first.step, equals(1));
      expect(checklist.first.title, contains('Branding'));
    });

    test(
      'EndpointSummaryItem copyWithTestResult updates status and metrics',
      () {
        final item = EndpointSummaryItem(
          id: 1,
          method: 'GET',
          path: '/health',
          requiresAuth: false,
          purpose: 'Health check',
          category: EndpointCategory.system,
        );

        expect(item.status, equals(EndpointHealthStatus.untested));
        expect(item.responseTimeMs, isNull);

        final updated = item.copyWithTestResult(
          status: EndpointHealthStatus.healthy,
          responseTimeMs: 45,
          lastTestMessage: 'HTTP 200 OK',
        );

        expect(updated.status, equals(EndpointHealthStatus.healthy));
        expect(updated.responseTimeMs, equals(45));
        expect(updated.lastTestMessage, equals('HTTP 200 OK'));
        expect(updated.lastTestedAt, isNotNull);
      },
    );
  });

  group('EndpointSummaryApiService cURL Snippet Generation', () {
    late EndpointSummaryApiService apiService;

    setUp(() {
      apiService = EndpointSummaryApiService(
        storageService: FakeSecureStorageService(token: 'test_bearer_token'),
      );
    });

    test('generateCurlSnippet formats GET request correctly with token', () {
      final item = EndpointSummaryItem(
        id: 4,
        method: 'GET',
        path: '/user',
        requiresAuth: true,
        purpose: 'Fetch profile',
        category: EndpointCategory.auth,
      );

      final curl = apiService.generateCurlSnippet(
        item,
        userToken: 'my_secret_token',
      );
      expect(
        curl,
        contains('curl -s -X GET "https://photohouse.appsaga.io/api/v1/user"'),
      );
      expect(curl, contains('-H "Accept: application/json"'));
      expect(curl, contains('-H "Authorization: Bearer my_secret_token"'));
      expect(curl, contains('| jq'));
    });

    test(
      'generateCurlSnippet formats POST request with JSON body and replaces {uuid}',
      () {
        final item = EndpointSummaryItem(
          id: 9,
          method: 'POST',
          path: '/events/{uuid}/upload/presign',
          requiresAuth: true,
          purpose: 'Presign upload',
          category: EndpointCategory.upload,
          sampleBody: '{"filename": "test.jpg"}',
        );

        final curl = apiService.generateCurlSnippet(
          item,
          userToken: 'my_secret_token',
        );
        expect(curl, contains('/events/<EVENT_UUID>/upload/presign'));
        expect(curl, contains('-H "Content-Type: application/json"'));
        expect(curl, contains('-d \'{"filename": "test.jpg"}\''));
      },
    );

    test(
      'generateFullCurlSmokeTestScript outputs bash script with all 23 endpoints',
      () {
        final script = apiService.generateFullCurlSmokeTestScript(
          userToken: 'test_token',
        );
        expect(script, startsWith('#!/bin/bash'));
        expect(
          script,
          contains(
            '# PhotoHouse Mobile API (v1) - Automated cURL Smoke Test Suite',
          ),
        );
        expect(
          script,
          contains('BASE_URL="https://photohouse.appsaga.io/api/v1"'),
        );
        expect(script, contains('Endpoint 1: [GET] /health'));
        expect(
          script,
          contains('Endpoint 23: [GET] /desktop/updater-manifest'),
        );
      },
    );
  });

  group('EndpointSummaryApiService Dynamic Smoke Testing', () {
    test('testEndpoint returns healthy on HTTP 200 OK', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"status": "ok"}', 200);
      });

      final service = EndpointSummaryApiService(
        client: mockClient,
        storageService: FakeSecureStorageService(token: 'valid_token'),
      );

      final item = service.getEndpointCatalog().firstWhere(
        (e) => e.path == '/health',
      );
      final result = await service.testEndpoint(item);

      expect(result.status, equals(EndpointHealthStatus.healthy));
      expect(result.lastTestMessage, contains('HTTP 200 OK'));
      expect(result.responseTimeMs, isNotNull);
    });

    test(
      'testEndpoint returns healthy on HTTP 302 redirect (R2 presigned)',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            '',
            302,
            headers: {'location': 'https://pub-r2.photohouse.com/file.zip'},
          );
        });

        final service = EndpointSummaryApiService(
          client: mockClient,
          storageService: FakeSecureStorageService(token: 'valid_token'),
        );

        final item = service.getEndpointCatalog().firstWhere(
          (e) => e.path == '/desktop/download-update',
        );
        final result = await service.testEndpoint(item);

        expect(result.status, equals(EndpointHealthStatus.healthy));
        expect(result.lastTestMessage, contains('HTTP 302 Redirect'));
      },
    );

    test('testEndpoint returns unauthorized on HTTP 401', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Unauthenticated"}', 401);
      });

      final service = EndpointSummaryApiService(
        client: mockClient,
        storageService: FakeSecureStorageService(token: null),
      );

      final item = service.getEndpointCatalog().firstWhere(
        (e) => e.path == '/user',
      );
      final result = await service.testEndpoint(item);

      expect(result.status, equals(EndpointHealthStatus.unauthorized));
      expect(result.lastTestMessage, contains('HTTP 401 Unauthorized'));
    });

    test('testEndpoint returns degraded on HTTP 404 or 422', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"message": "Event not found"}', 404);
      });

      final service = EndpointSummaryApiService(
        client: mockClient,
        storageService: FakeSecureStorageService(token: 'valid_token'),
      );

      final item = service.getEndpointCatalog().firstWhere(
        (e) => e.path == '/events/{uuid}',
      );
      final result = await service.testEndpoint(item);

      expect(result.status, equals(EndpointHealthStatus.degraded));
      expect(result.lastTestMessage, contains('HTTP 404 - Event not found'));
    });

    test(
      'testEndpoint returns error on HTTP 500 Internal Server Error',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            'Internal error',
            500,
            reasonPhrase: 'Internal Server Error',
          );
        });

        final service = EndpointSummaryApiService(
          client: mockClient,
          storageService: FakeSecureStorageService(token: 'valid_token'),
        );

        final item = service.getEndpointCatalog().firstWhere(
          (e) => e.path == '/events',
        );
        final result = await service.testEndpoint(item);

        expect(result.status, equals(EndpointHealthStatus.error));
        expect(result.lastTestMessage, contains('HTTP 500 Server Error'));
      },
    );

    test(
      'runFullSmokeTest runs smoke tests on all catalog endpoints',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response('{"status": "ok"}', 200);
        });

        final service = EndpointSummaryApiService(
          client: mockClient,
          storageService: FakeSecureStorageService(token: 'valid_token'),
        );

        final results = await service.runFullSmokeTest();
        expect(results.length, equals(23));
        expect(
          results.every((r) => r.status == EndpointHealthStatus.healthy),
          isTrue,
        );
      },
    );
  });
}
