import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:photohouse/models/health_model.dart';
import 'package:photohouse/models/platform_branding_model.dart';
import 'package:photohouse/services/public_api_service.dart';

void main() {
  group('HealthModel Unit Tests', () {
    test('HealthModel.fromJson parses status and app correctly', () {
      final jsonMap = {
        'status': 'ok',
        'app': 'PhotoHouse',
      };
      final health = HealthModel.fromJson(jsonMap);
      expect(health.status, 'ok');
      expect(health.app, 'PhotoHouse');
      expect(health.isHealthy, true);
    });

    test('HealthModel handles non-ok status correctly', () {
      final jsonMap = {
        'status': 'degraded',
        'app': 'PhotoHouse Service',
      };
      final health = HealthModel.fromJson(jsonMap);
      expect(health.status, 'degraded');
      expect(health.app, 'PhotoHouse Service');
      expect(health.isHealthy, false);
    });
  });

  group('PlatformBrandingModel Unit Tests', () {
    test('PlatformBrandingModel.fromJson parses full branding payload', () {
      final jsonMap = {
        'app_name': 'PhotoHouse Pro',
        'logo_url': 'https://photohouse.appsaga.io/logo.png',
        'logo_dark_url': 'https://photohouse.appsaga.io/logo-dark.png',
        'logo_light_url': 'https://photohouse.appsaga.io/logo-light.png',
        'favicon_url': 'https://photohouse.appsaga.io/favicon.png',
        'loading_gif_url': 'https://photohouse.appsaga.io/loading.gif',
      };
      final branding = PlatformBrandingModel.fromJson(jsonMap);
      expect(branding.appName, 'PhotoHouse Pro');
      expect(branding.logoUrl, 'https://photohouse.appsaga.io/logo.png');
      expect(branding.logoDarkUrl, 'https://photohouse.appsaga.io/logo-dark.png');
      expect(branding.logoLightUrl, 'https://photohouse.appsaga.io/logo-light.png');
      expect(branding.faviconUrl, 'https://photohouse.appsaga.io/favicon.png');
      expect(branding.loadingGifUrl, 'https://photohouse.appsaga.io/loading.gif');
    });

    test('PlatformBrandingModel handles missing optional fields gracefully', () {
      final jsonMap = {
        'app_name': 'Custom Studio',
      };
      final branding = PlatformBrandingModel.fromJson(jsonMap);
      expect(branding.appName, 'Custom Studio');
      expect(branding.logoUrl, isNull);
      expect(branding.logoDarkUrl, isNull);
    });
  });

  group('PublicApiService Integration Tests', () {
    test('getHealthStatus returns HealthModel on 200 OK', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/health'));
        return http.Response(
          '{"status": "ok", "app": "PhotoHouse"}',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = PublicApiService(client: mockClient);
      final health = await service.getHealthStatus();

      expect(health.status, 'ok');
      expect(health.app, 'PhotoHouse');
      expect(health.isHealthy, true);
    });

    test('getHealthStatus throws Exception on 500 error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"message": "Internal Server Error"}',
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = PublicApiService(client: mockClient);
      expect(() => service.getHealthStatus(), throwsException);
    });

    test('getPlatformBranding returns PlatformBrandingModel on 200 OK', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, endsWith('/platform/branding'));
        return http.Response(
          '''
          {
            "app_name": "PhotoHouse",
            "logo_url": "https://photohouse.appsaga.io/logo.png",
            "logo_dark_url": "https://photohouse.appsaga.io/logo-dark.png",
            "logo_light_url": "https://photohouse.appsaga.io/logo-light.png",
            "favicon_url": "https://photohouse.appsaga.io/favicon.png",
            "loading_gif_url": "https://photohouse.appsaga.io/loading.gif"
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = PublicApiService(client: mockClient);
      final branding = await service.getPlatformBranding();

      expect(branding.appName, 'PhotoHouse');
      expect(branding.logoUrl, 'https://photohouse.appsaga.io/logo.png');
      expect(branding.loadingGifUrl, 'https://photohouse.appsaga.io/loading.gif');
    });

    test('getPlatformBranding throws Exception on 429 rate limit', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"message": "Too Many Attempts."}',
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = PublicApiService(client: mockClient);
      expect(
        () => service.getPlatformBranding(),
        throwsA(predicate((e) => e.toString().contains('429'))),
      );
    });
  });
}
