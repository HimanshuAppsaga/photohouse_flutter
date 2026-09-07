import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:photohouse/models/subscription_model.dart';
import 'package:photohouse/services/secure_storage_service.dart';
import 'package:photohouse/services/subscription_api_service.dart';

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
}

void main() {
  group('SubscriptionModel & Sub-models Unit Tests', () {
    test(
      'SubscriptionModel.fromJson parses full mobile API specification payload',
      () {
        final jsonMap = {
          'data': {
            'status': 'active',
            'is_active': true,
            'is_trialing': false,
            'is_expired': false,
            'is_expiring_soon': false,
            'current_period_start': '2026-02-01T00:00:00+00:00',
            'current_period_end': '2026-03-01T00:00:00+00:00',
            'trial_ends_at': null,
            'cancelled_at': null,
            'start_date': '2026-01-01T00:00:00+00:00',
            'end_date': '2026-03-01T00:00:00+00:00',
            'plan': {
              'id': 2,
              'name': 'Professional',
              'slug': 'professional',
              'max_events': null,
              'storage_bytes': 536870912000,
              'storage_label': '500 GB',
              'ftp_sftp_enabled': false,
              'team_members_enabled': false,
              'max_team_members': 0,
              'price_inr': 2999,
              'formatted_price': '₹2,999',
            },
            'usage': {
              'storage_used_bytes': 91234567890,
              'storage_limit_bytes': 536870912000,
              'storage_used_formatted': '84.97 GB of 500 GB',
              'storage_percent': 17.0,
              'event_count': 12,
              'can_create_event': true,
            },
          },
        };

        final sub = SubscriptionModel.fromJson(jsonMap);

        expect(sub.status, 'active');
        expect(sub.isActive, true);
        expect(sub.isTrialing, false);
        expect(sub.isExpired, false);
        expect(sub.statusLabel, 'ACTIVE');

        expect(sub.plan, isNotNull);
        expect(sub.plan!.name, 'Professional');
        expect(sub.plan!.slug, 'professional');
        expect(sub.plan!.maxEvents, isNull);
        expect(sub.plan!.isUnlimitedEvents, true);
        expect(sub.plan!.storageLabel, '500 GB');
        expect(sub.plan!.priceInr, 2999);
        expect(sub.plan!.formattedPrice, '₹2,999');

        expect(sub.usage, isNotNull);
        expect(sub.usage!.storageUsedBytes, 91234567890);
        expect(sub.usage!.storageLimitBytes, 536870912000);
        expect(sub.usage!.storageUsedFormatted, '84.97 GB of 500 GB');
        expect(sub.usage!.storagePercent, 17.0);
        expect(sub.usage!.eventCount, 12);
        expect(sub.usage!.canCreateEvent, true);

        expect(sub.isStorageWarning, false);
        expect(sub.isStorageCritical, false);
        expect(sub.isStorageExceeded, false);
        expect(sub.canCreateEvent, true);
      },
    );

    test(
      'SubscriptionModel correctly evaluates quota warning & critical flags',
      () {
        final warningJson = {
          'status': 'active',
          'is_active': true,
          'usage': {
            'storage_used_bytes': 420000000000,
            'storage_limit_bytes': 500000000000,
            'storage_used_formatted': '420 GB of 500 GB',
            'storage_percent': 84.0,
            'event_count': 5,
            'can_create_event': true,
          },
        };

        final subWarning = SubscriptionModel.fromJson(warningJson);
        expect(subWarning.isStorageWarning, true);
        expect(subWarning.isStorageCritical, false);
        expect(subWarning.isStorageExceeded, false);

        final criticalJson = {
          'status': 'active',
          'is_active': true,
          'usage': {
            'storage_used_bytes': 490000000000,
            'storage_limit_bytes': 500000000000,
            'storage_used_formatted': '490 GB of 500 GB',
            'storage_percent': 98.0,
            'event_count': 10,
            'can_create_event': false,
          },
        };

        final subCritical = SubscriptionModel.fromJson(criticalJson);
        expect(subCritical.isStorageWarning, true);
        expect(subCritical.isStorageCritical, true);
        expect(subCritical.isStorageExceeded, false);
        expect(subCritical.canCreateEvent, false);

        final exceededJson = {
          'status': 'active',
          'is_active': true,
          'usage': {
            'storage_used_bytes': 510000000000,
            'storage_limit_bytes': 500000000000,
            'storage_used_formatted': '510 GB of 500 GB',
            'storage_percent': 102.0,
            'event_count': 15,
            'can_create_event': false,
          },
        };

        final subExceeded = SubscriptionModel.fromJson(exceededJson);
        expect(subExceeded.isStorageWarning, true);
        expect(subExceeded.isStorageCritical, true);
        expect(subExceeded.isStorageExceeded, true);
        expect(subExceeded.canCreateEvent, false);
      },
    );

    test('SubscriptionModel toJson converts model back to map', () {
      const sub = SubscriptionModel(
        status: 'active',
        isActive: true,
        plan: SubscriptionPlanModel(
          id: 1,
          name: 'Starter',
          slug: 'starter',
          maxEvents: 5,
        ),
        usage: SubscriptionUsageModel(
          storagePercent: 50.0,
          eventCount: 3,
          canCreateEvent: true,
        ),
      );

      final map = sub.toJson();
      expect(map['status'], 'active');
      expect(map['is_active'], true);
      expect(map['plan']['name'], 'Starter');
      expect(map['usage']['storage_percent'], 50.0);
    });
  });

  group('SubscriptionApiService Integration Tests', () {
    test('getSubscription returns SubscriptionModel on HTTP 200', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/subscription'));
        expect(request.headers['Authorization'], 'Bearer test-token');
        return http.Response(
          '''
          {
            "data": {
              "status": "active",
              "is_active": true,
              "is_trialing": false,
              "is_expired": false,
              "is_expiring_soon": false,
              "plan": {
                "id": 2,
                "name": "Professional",
                "slug": "professional",
                "storage_label": "500 GB"
              },
              "usage": {
                "storage_used_formatted": "84.97 GB of 500 GB",
                "storage_percent": 17.0,
                "event_count": 12,
                "can_create_event": true
              }
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SubscriptionApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: 'test-token'),
      );
      final sub = await service.getSubscription();

      expect(sub.status, 'active');
      expect(sub.isActive, true);
      expect(sub.plan?.name, 'Professional');
      expect(sub.usage?.storagePercent, 17.0);
    });

    test('getSubscription throws Exception on 401 unauthenticated', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"message": "Unauthenticated."}',
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SubscriptionApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: null),
      );
      expect(
        () => service.getSubscription(),
        throwsA(predicate((e) => e.toString().contains('Unauthenticated'))),
      );
    });

    test('getSubscription throws Exception on 429 rate limit', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"message": "Too many requests."}',
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = SubscriptionApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: 'test-token'),
      );
      expect(
        () => service.getSubscription(),
        throwsA(predicate((e) => e.toString().contains('Rate limit exceeded'))),
      );
    });
  });
}
