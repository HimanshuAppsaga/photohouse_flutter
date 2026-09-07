import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:photohouse/models/upload_models.dart';
import 'package:photohouse/services/secure_storage_service.dart';
import 'package:photohouse/services/upload_api_service.dart';

class FakeSecureStorageService extends SecureStorageService {
  final String? token;
  FakeSecureStorageService([this.token = 'test-token-123']);

  @override
  Future<String?> getToken() async => token;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Upload Models Serialization', () {
    test('PresignFileItem toJson works correctly', () {
      final item = PresignFileItem(
        clientId: 'local-101',
        filename: 'wedding_01.jpg',
        mimeType: 'image/jpeg',
        fileSize: 5242880,
        derivatives: ['preview', 'thumbnail'],
      );

      final json = item.toJson();
      expect(json['client_id'], 'local-101');
      expect(json['filename'], 'wedding_01.jpg');
      expect(json['mime_type'], 'image/jpeg');
      expect(json['file_size'], 5242880);
      expect(json['derivatives'], ['preview', 'thumbnail']);
    });

    test('PresignBatchResponse.fromJson parses valid payload', () {
      final payload = {
        'uploads': [
          {
            'client_id': 'local-101',
            'presigned_url':
                'https://account.r2.cloudflarestorage.com/photos/1.jpg?token=abc',
            'storage_path': 'photos/3/17/uuid.jpg',
            'upload_via': 'r2',
          }
        ]
      };

      final response = PresignBatchResponse.fromJson(payload);
      expect(response.uploads.length, 1);
      expect(response.uploads.first.clientId, 'local-101');
      expect(
        response.uploads.first.presignedUrl,
        'https://account.r2.cloudflarestorage.com/photos/1.jpg?token=abc',
      );
      expect(response.uploads.first.storagePath, 'photos/3/17/uuid.jpg');
      expect(response.uploads.first.uploadVia, 'r2');
    });

    test('RegisterBatchResponse.fromJson parses valid payload', () {
      final payload = {
        'photos': [
          {
            'client_id': 'local-101',
            'photo_id': 90211,
            'photo_uuid': '6e0f0000-0000-4000-8000-000000000077',
            'status': 'pending',
          }
        ]
      };

      final response = RegisterBatchResponse.fromJson(payload);
      expect(response.photos.length, 1);
      expect(response.photos.first.clientId, 'local-101');
      expect(response.photos.first.photoId, 90211);
      expect(
        response.photos.first.photoUuid,
        '6e0f0000-0000-4000-8000-000000000077',
      );
      expect(response.photos.first.status, 'pending');
    });

    test('BatchCompleteRequest toJson matches spec', () {
      const req = BatchCompleteRequest(
        totalFiles: 10,
        completedFiles: 9,
        failedFiles: 1,
        albumId: 41,
      );

      final json = req.toJson();
      expect(json['total_files'], 10);
      expect(json['completed_files'], 9);
      expect(json['failed_files'], 1);
      expect(json['album_id'], 41);
    });

    test('UploadSessionsResponse.fromJson parses sessions list', () {
      final payload = {
        'data': [
          {
            'uuid': 'sess-123',
            'event_uuid': 'event-456',
            'album_id': 41,
            'source': 'desktop_agent',
            'total_files': 100,
            'completed_files': 98,
            'failed_files': 2,
            'status': 'completed',
            'created_at': '2026-02-14T18:41:02+00:00',
            'updated_at': '2026-02-14T19:02:44+00:00',
          }
        ],
        'meta': {'next_cursor': 'cursor-999'}
      };

      final response = UploadSessionsResponse.fromJson(payload);
      expect(response.sessions.length, 1);
      expect(response.sessions.first.uuid, 'sess-123');
      expect(response.sessions.first.totalFiles, 100);
      expect(response.nextCursor, 'cursor-999');
    });
  });

  group('UploadApiService Endpoints & Cloudflare R2 Isolation', () {
    test('uploadBytesToR2 does NOT send Authorization header to R2 host', () async {
      String? capturedAuthHeader;
      String? capturedContentType;

      final mockClient = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        capturedContentType = request.headers['Content-Type'];
        return http.Response('', 200);
      });

      final service = UploadApiService(
        client: mockClient,
        storage: FakeSecureStorageService(),
      );

      final success = await service.uploadBytesToR2(
        presignedUrl: 'https://photohouse-r2.cloudflarestorage.com/upload/test.jpg',
        bytes: [1, 2, 3, 4, 5],
        mimeType: 'image/jpeg',
      );

      expect(success, isTrue);
      // SPEC REQUIREMENT: Authorization header must NOT be sent to Cloudflare R2
      expect(capturedAuthHeader, isNull);
      expect(capturedContentType, 'image/jpeg');
    });

    test('presignBatch sends valid request to API endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/upload/presign-batch'));
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer test-token-123');

        final decoded = jsonDecode(request.body) as Map<String, dynamic>;
        expect(decoded['files'], isA<List>());

        return http.Response(
          jsonEncode({
            'uploads': [
              {
                'client_id': 'local-1',
                'presigned_url': 'https://r2.test/url1',
                'storage_path': 'photos/3/17/a.jpg',
                'upload_via': 'r2',
              }
            ]
          }),
          200,
        );
      });

      final service = UploadApiService(
        client: mockClient,
        storage: FakeSecureStorageService(),
      );

      final result = await service.presignBatch(
        eventUuid: 'event-uuid-123',
        files: [
          const PresignFileItem(
            clientId: 'local-1',
            filename: 'test.jpg',
            mimeType: 'image/jpeg',
            fileSize: 1024,
          )
        ],
      );

      expect(result.uploads.length, 1);
      expect(result.uploads.first.clientId, 'local-1');
      expect(result.uploads.first.presignedUrl, 'https://r2.test/url1');
    });

    test('registerBatch sends valid request to API endpoint', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/upload/register-batch'));
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer test-token-123');

        final decoded = jsonDecode(request.body) as Map<String, dynamic>;
        expect(decoded['album_id'], 41);
        expect(decoded['uploads'], isA<List>());

        return http.Response(
          jsonEncode({
            'photos': [
              {
                'client_id': 'local-1',
                'photo_id': 101,
                'photo_uuid': 'uuid-101',
                'status': 'pending',
              }
            ]
          }),
          201,
        );
      });

      final service = UploadApiService(
        client: mockClient,
        storage: FakeSecureStorageService(),
      );

      final result = await service.registerBatch(
        eventUuid: 'event-uuid-123',
        albumId: 41,
        uploads: [
          const RegisterUploadItem(
            clientId: 'local-1',
            storagePath: 'photos/3/17/a.jpg',
            filename: 'test.jpg',
            mimeType: 'image/jpeg',
            fileSize: 1024,
          )
        ],
      );

      expect(result.photos.length, 1);
      expect(result.photos.first.photoId, 101);
    });

    test('batchComplete sends valid session closure request', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/upload/batch-complete'));
        expect(request.method, 'POST');
        expect(request.headers['Authorization'], 'Bearer test-token-123');

        final decoded = jsonDecode(request.body) as Map<String, dynamic>;
        expect(decoded['total_files'], 10);
        expect(decoded['completed_files'], 10);
        expect(decoded['failed_files'], 0);

        return http.Response(
          jsonEncode({
            'session_uuid': 'session-uuid-999',
            'status': 'completed',
          }),
          201,
        );
      });

      final service = UploadApiService(
        client: mockClient,
        storage: FakeSecureStorageService(),
      );

      final result = await service.batchComplete(
        eventUuid: 'event-uuid-123',
        request: const BatchCompleteRequest(
          totalFiles: 10,
          completedFiles: 10,
          failedFiles: 0,
        ),
      );

      expect(result.sessionUuid, 'session-uuid-999');
      expect(result.status, 'completed');
    });

    test('getUploadSessions handles query parameters correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/upload-sessions'));
        expect(request.method, 'GET');
        expect(request.headers['Authorization'], 'Bearer test-token-123');
        expect(request.url.queryParameters['event_uuid'], 'event-999');
        expect(request.url.queryParameters['status'], 'completed');
        expect(request.url.queryParameters['source'], 'desktop_agent');
        expect(request.url.queryParameters['cursor'], 'cur-1');

        return http.Response(
          jsonEncode({
            'data': [
              {
                'uuid': 'sess-999',
                'event_uuid': 'event-999',
                'album_id': 12,
                'source': 'desktop_agent',
                'total_files': 50,
                'completed_files': 48,
                'failed_files': 2,
                'status': 'completed',
                'created_at': '2026-09-03T10:00:00Z',
                'updated_at': '2026-09-03T10:15:00Z',
              }
            ],
            'meta': {'next_cursor': 'cur-2'}
          }),
          200,
        );
      });

      final service = UploadApiService(
        client: mockClient,
        storage: FakeSecureStorageService(),
      );

      final result = await service.getUploadSessions(
        eventUuid: 'event-999',
        status: 'completed',
        source: 'desktop_agent',
        cursor: 'cur-1',
      );

      expect(result.sessions.length, 1);
      final item = result.sessions.first;
      expect(item.uuid, 'sess-999');
      expect(item.eventUuid, 'event-999');
      expect(item.albumId, 12);
      expect(item.source, 'desktop_agent');
      expect(item.formattedSource, 'Desktop Agent');
      expect(item.completionProgress, 0.96);
      expect(item.isCompleted, isTrue);
      expect(item.isFailed, isFalse);
      expect(result.nextCursor, 'cur-2');

      final json = item.toJson();
      expect(json['uuid'], 'sess-999');
      expect(json['album_id'], 12);
    });

    test('uploadBatchPipeline handles 404 error with local upload fallback', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({'message': 'Resource not found'}), 404);
      });

      final service = UploadApiService(
        client: mockClient,
        storage: FakeSecureStorageService(),
      );

      final result = await service.uploadBatchPipeline(
        eventUuid: 'sample-event-1',
        files: [
          QueueUploadFile(
            clientId: 'local-1',
            filePath: '/non/existent/test.jpg',
            filename: 'test.jpg',
            mimeType: 'image/jpeg',
            fileSize: 100,
          ),
        ],
      );

      expect(result.sessionUuid, 'local-fallback');
      expect(result.status, 'completed');
    });
  });
}
