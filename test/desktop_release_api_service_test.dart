import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:photohouse/models/desktop_release_model.dart';
import 'package:photohouse/services/desktop_release_api_service.dart';
import 'package:photohouse/services/secure_storage_service.dart';

class FakeSecureStorageService implements SecureStorageService {
  final String? token;
  FakeSecureStorageService({this.token});

  @override
  Future<String?> getToken() async => token;

  @override
  Future<void> saveToken(String token) async {}

  @override
  Future<void> deleteToken() async {}

  @override
  Future<String?> getUser() async => null;

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

void main() {
  group('DesktopReleaseModel Unit Tests', () {
    test('DesktopCheckUpdateModel.fromJson parses check update payload', () {
      final jsonMap = {
        "has_update": true,
        "latest_version": "1.2.0",
        "current_version": "1.0.0",
        "release_notes": "Added new batch photo processing and bug fixes.",
        "pub_date": "2026-02-14T19:02:44Z",
        "download_url":
            "https://r2.photohouse.io/releases/mac/Photohouse_1.2.0.dmg",
        "signature": "dW5pY29kZSBzaWduYXR1cmU=",
        "platform": "macos_aarch64",
      };

      final model = DesktopCheckUpdateModel.fromJson(jsonMap);
      expect(model.hasUpdate, true);
      expect(model.latestVersion, "1.2.0");
      expect(model.currentVersion, "1.0.0");
      expect(
        model.releaseNotes,
        "Added new batch photo processing and bug fixes.",
      );
      expect(model.pubDate, "2026-02-14T19:02:44Z");
      expect(
        model.downloadUrl,
        "https://r2.photohouse.io/releases/mac/Photohouse_1.2.0.dmg",
      );
      expect(model.signature, "dW5pY29kZSBzaWduYXR1cmU=");
      expect(model.platform, "macos_aarch64");
    });

    test('DesktopCheckUpdateModel.toJson outputs correct map structure', () {
      const model = DesktopCheckUpdateModel(
        hasUpdate: true,
        latestVersion: "2.0.0",
        currentVersion: "1.9.0",
        releaseNotes: "Major v2 release",
        downloadUrl:
            "https://r2.photohouse.io/releases/win/Photohouse_Setup.exe",
        platform: "windows_x64",
      );

      final jsonMap = model.toJson();
      expect(jsonMap['has_update'], true);
      expect(jsonMap['latest_version'], "2.0.0");
      expect(jsonMap['current_version'], "1.9.0");
      expect(jsonMap['release_notes'], "Major v2 release");
      expect(
        jsonMap['download_url'],
        "https://r2.photohouse.io/releases/win/Photohouse_Setup.exe",
      );
      expect(jsonMap['platform'], "windows_x64");
    });

    test('DesktopLatestBuildModel.fromJson parses build metadata', () {
      final jsonMap = {
        "version": "1.5.0",
        "platform": "macos_x86_64",
        "notes": "Intel mac optimizations",
        "pub_date": "2026-03-01T10:00:00Z",
        "download_url":
            "https://r2.photohouse.io/releases/Photohouse-1.5.0.dmg",
        "installer_url":
            "https://r2.photohouse.io/releases/Photohouse-1.5.0-installer.dmg",
        "updater_url":
            "https://r2.photohouse.io/releases/Photohouse-1.5.0.tar.gz",
        "signature": "sig123456",
        "file_size": 45000000,
        "min_os_version": "11.0",
      };

      final model = DesktopLatestBuildModel.fromJson(jsonMap);
      expect(model.version, "1.5.0");
      expect(model.platform, "macos_x86_64");
      expect(model.notes, "Intel mac optimizations");
      expect(
        model.downloadUrl,
        "https://r2.photohouse.io/releases/Photohouse-1.5.0.dmg",
      );
      expect(model.fileSizeBytes, 45000000);
      expect(model.minOsVersion, "11.0");
    });

    test(
      'TauriUpdaterManifestModel.fromJson parses standard Tauri updater JSON',
      () {
        final jsonMap = {
          "version": "v1.1.0",
          "notes": "Performance improvements for desktop agent",
          "pub_date": "2026-02-14T19:02:44Z",
          "platforms": {
            "darwin-aarch64": {
              "signature": "sig_apple_silicon",
              "url": "https://r2.photohouse.io/releases/darwin-aarch64.tar.gz",
            },
            "windows-x86_64": {
              "signature": "sig_win64",
              "url": "https://r2.photohouse.io/releases/windows-x64.nsis.zip",
            },
          },
        };

        final manifest = TauriUpdaterManifestModel.fromJson(jsonMap);
        expect(manifest.version, "v1.1.0");
        expect(manifest.notes, "Performance improvements for desktop agent");
        expect(manifest.platforms.length, 2);
        expect(
          manifest.platforms['darwin-aarch64']?.signature,
          "sig_apple_silicon",
        );
        expect(
          manifest.platforms['windows-x86_64']?.url,
          "https://r2.photohouse.io/releases/windows-x64.nsis.zip",
        );
      },
    );
  });

  group('DesktopReleaseApiService Integration Tests', () {
    test(
      'checkUpdate sends GET request with Authorization header and parses response',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, endsWith('/desktop/check-update'));
          expect(request.url.queryParameters['platform'], 'macos_aarch64');
          expect(request.url.queryParameters['current_version'], '1.0.0');
          expect(request.headers['Authorization'], 'Bearer test-token');

          return http.Response(
            jsonEncode({
              "has_update": true,
              "latest_version": "1.2.0",
              "download_url": "https://r2.photohouse.io/updates/mac_arm64.dmg",
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = DesktopReleaseApiService(
          client: mockClient,
          storage: FakeSecureStorageService(token: 'test-token'),
        );
        final result = await service.checkUpdate(
          platform: 'macos_aarch64',
          currentVersion: '1.0.0',
        );

        expect(result.hasUpdate, true);
        expect(result.latestVersion, '1.2.0');
        expect(
          result.downloadUrl,
          'https://r2.photohouse.io/updates/mac_arm64.dmg',
        );
      },
    );

    test('getLatestBuild returns DesktopLatestBuildModel on 200 OK', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/desktop/latest-build'));
        expect(request.url.queryParameters['platform'], 'windows_x64');

        return http.Response(
          jsonEncode({
            "version": "2.1.0",
            "platform": "windows_x64",
            "download_url": "https://r2.photohouse.io/builds/win64_setup.exe",
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = DesktopReleaseApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: 'test-token'),
      );
      final result = await service.getLatestBuild(platform: 'windows_x64');

      expect(result.version, '2.1.0');
      expect(result.platform, 'windows_x64');
      expect(
        result.downloadUrl,
        'https://r2.photohouse.io/builds/win64_setup.exe',
      );
    });

    test('getDownloadUpdateUrl handles 302 redirect response', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, endsWith('/desktop/download-update'));
        expect(request.url.queryParameters['platform'], 'macos_aarch64');
        expect(request.url.queryParameters['type'], 'installer');

        return http.Response(
          '',
          302,
          headers: {
            'location':
                'https://r2.photohouse.io/signed-downloads/installer.dmg?token=xyz',
          },
        );
      });

      final service = DesktopReleaseApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: 'test-token'),
      );
      final result = await service.getDownloadUpdateUrl(
        platform: 'macos_aarch64',
        type: 'installer',
      );

      expect(result.statusCode, 302);
      expect(
        result.downloadUrl,
        'https://r2.photohouse.io/signed-downloads/installer.dmg?token=xyz',
      );
    });

    test(
      'getUpdaterManifest returns TauriUpdaterManifestModel on 200 OK',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, endsWith('/desktop/updater-manifest'));

          return http.Response(
            jsonEncode({
              "version": "1.0.5",
              "notes": "Bug fixes",
              "platforms": {
                "macos-aarch64": {
                  "url": "https://r2.photohouse.io/manifest/mac.tar.gz",
                },
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = DesktopReleaseApiService(
          client: mockClient,
          storage: FakeSecureStorageService(token: 'test-token'),
        );
        final result = await service.getUpdaterManifest();

        expect(result.version, '1.0.5');
        expect(result.notes, 'Bug fixes');
        expect(result.platforms.containsKey('macos-aarch64'), true);
      },
    );

    test('checkUpdate throws Exception on 401 Unauthenticated', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Unauthenticated.'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = DesktopReleaseApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: 'test-token'),
      );
      expect(
        () => service.checkUpdate(
          platform: 'windows_x64',
          currentVersion: '1.0.0',
        ),
        throwsA(predicate((e) => e.toString().contains('Unauthenticated'))),
      );
    });

    test('getLatestBuild throws Exception on 404 Not Found', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'No build found for platform.'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = DesktopReleaseApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: 'test-token'),
      );
      expect(
        () => service.getLatestBuild(platform: 'linux_x64'),
        throwsA(predicate((e) => e.toString().contains('No build found'))),
      );
    });

    test('getUpdaterManifest throws Exception on 429 Rate Limit', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Too Many Attempts.'}),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = DesktopReleaseApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: 'test-token'),
      );
      expect(
        () => service.getUpdaterManifest(),
        throwsA(predicate((e) => e.toString().contains('Rate limit exceeded'))),
      );
    });
  });
}
