import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:photohouse/models/album_model.dart';
import 'package:photohouse/models/event_model.dart';
import 'package:photohouse/services/events_api_service.dart';
import 'package:photohouse/services/secure_storage_service.dart';

void main() {
  group('EventItem & AlbumItem Model JSON Parsing', () {
    test('AlbumItem.fromJson parses full album payload correctly', () {
      final jsonMap = {
        "id": 41,
        "uuid": "5a3e0000-0000-4000-8000-000000000001",
        "name": "Ceremony",
        "description": "Main ceremony album",
        "sort_order": 1,
        "photos_count": 620,
      };

      final album = AlbumItem.fromJson(jsonMap);
      expect(album.id, '41');
      expect(album.uuid, '5a3e0000-0000-4000-8000-000000000001');
      expect(album.title, 'Ceremony');
      expect(album.description, 'Main ceremony album');
      expect(album.sortOrder, 1);
      expect(album.photoCount, 620);
    });

    test('AlbumItem.toJson produces valid json map', () {
      const album = AlbumItem(
        id: '41',
        uuid: '5a3e0000-0000-4000-8000-000000000001',
        title: 'Ceremony',
        description: 'Main ceremony album',
        sortOrder: 1,
        photoCount: 620,
      );

      final jsonMap = album.toJson();
      expect(jsonMap['id'], '41');
      expect(jsonMap['uuid'], '5a3e0000-0000-4000-8000-000000000001');
      expect(jsonMap['name'], 'Ceremony');
      expect(jsonMap['description'], 'Main ceremony album');
      expect(jsonMap['sort_order'], 1);
      expect(jsonMap['photos_count'], 620);
    });

    test('EventItem.fromJson parses full event API response', () {
      final jsonMap = {
        "uuid": "9f1c0f0e-1a2b-4c3d-8e9f-000000000001",
        "name": "Sharma Wedding",
        "type": "wedding",
        "event_date": "2026-02-14",
        "location": "Udaipur",
        "description": "Two-day wedding",
        "gallery_enabled": true,
        "client_selection_enabled": false,
        "photos_count": 1832,
        "albums_count": 4,
        "created_at": "2026-01-02T09:15:00+00:00",
        "updated_at": "2026-02-15T18:40:11+00:00",
        "albums": [
          {
            "id": 41,
            "uuid": "5a3e0000-0000-4000-8000-000000000001",
            "name": "Ceremony",
            "photos_count": 620,
          },
        ],
      };

      final event = EventItem.fromJson(jsonMap);
      expect(event.id, '9f1c0f0e-1a2b-4c3d-8e9f-000000000001');
      expect(event.title, 'Sharma Wedding');
      expect(event.tag, 'wedding');
      expect(event.date, '2026-02-14');
      expect(event.location, 'Udaipur');
      expect(event.description, 'Two-day wedding');
      expect(event.isReadyToShare, true);
      expect(event.clientSelectionEnabled, false);
      expect(event.photoCount, 1832);
      expect(event.albumCount, 4);
      expect(event.albums.length, 1);
      expect(event.albums.first.title, 'Ceremony');
    });
  });

  group('EventsApiService Integration Tests', () {
    test('getEvents returns EventListResponse on 200 OK', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/events'));
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          '''
          {
            "data": [
              {
                "uuid": "9f1c0f0e-1a2b-4c3d-8e9f-000000000001",
                "name": "Sharma Wedding",
                "type": "wedding",
                "event_date": "2026-02-14",
                "location": "Udaipur",
                "gallery_enabled": true,
                "photos_count": 1832,
                "albums_count": 4
              }
            ],
            "links": { "next": "https://photohouse.appsaga.io/api/v1/events?cursor=eyJ..." },
            "meta": { "per_page": 50, "next_cursor": "eyJ..." }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = EventsApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: 'test-token'),
      );

      final response = await service.getEvents();
      expect(response.events.length, 1);
      expect(response.events.first.title, 'Sharma Wedding');
      expect(response.nextCursor, 'eyJ...');
      expect(response.perPage, 50);
    });

    test('getEvents passes type filter parameter correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.queryParameters['type'], 'wedding');
        return http.Response(
          '{"data": [], "meta": {"per_page": 50}}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = EventsApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: 'test-token'),
      );

      final response = await service.getEvents(type: 'Wedding');
      expect(response.events, isEmpty);
    });

    test('getEvents throws Exception on 401 Unauthenticated', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"message": "Unauthenticated."}',
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = EventsApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: null),
      );

      expect(() => service.getEvents(), throwsException);
    });

    test('getEventDetails returns single EventItem on 200 OK', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.path,
          endsWith('/events/9f1c0f0e-1a2b-4c3d-8e9f-000000000001'),
        );
        return http.Response(
          '''
          {
            "data": {
              "uuid": "9f1c0f0e-1a2b-4c3d-8e9f-000000000001",
              "name": "Sharma Wedding",
              "type": "wedding",
              "event_date": "2026-02-14",
              "photos_count": 1832,
              "albums_count": 4
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = EventsApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: 'test-token'),
      );

      final event = await service.getEventDetails(
        '9f1c0f0e-1a2b-4c3d-8e9f-000000000001',
      );
      expect(event.id, '9f1c0f0e-1a2b-4c3d-8e9f-000000000001');
      expect(event.title, 'Sharma Wedding');
    });

    test('getEventAlbums returns List<AlbumItem> on 200 OK', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.path,
          endsWith('/events/9f1c0f0e-1a2b-4c3d-8e9f-000000000001/albums'),
        );
        return http.Response(
          '''
          {
            "data": [
              {
                "id": 41,
                "uuid": "5a3e0000-0000-4000-8000-000000000001",
                "name": "Ceremony",
                "sort_order": 1,
                "photos_count": 620
              }
            ]
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = EventsApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: 'test-token'),
      );

      final albums = await service.getEventAlbums(
        '9f1c0f0e-1a2b-4c3d-8e9f-000000000001',
      );
      expect(albums.length, 1);
      expect(albums.first.id, '41');
      expect(albums.first.title, 'Ceremony');
      expect(albums.first.photoCount, 620);
    });

    test('getEventAlbums throws Exception on 404 Not Found', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"message": "Resource not found."}',
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = EventsApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: 'test-token'),
      );

      expect(
        () => service.getEventAlbums('non-existent-uuid'),
        throwsException,
      );
    });
  });
}

class FakeSecureStorageService implements SecureStorageService {
  final String? token;
  final String? user;

  FakeSecureStorageService({this.token, this.user});

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

  Future<void> deleteUser() async {}

  Future<void> clearAll() async {}
}
