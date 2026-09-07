import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:photohouse/models/watermark_settings_model.dart';
import 'package:photohouse/services/secure_storage_service.dart';
import 'package:photohouse/services/watermark_api_service.dart';

void main() {
  group('WatermarkSettingsModel Serialization & Helpers', () {
    test('WatermarkSettingsModel.fromJson parses spec sample payload', () {
      final jsonMap = {
        "data": {
          "enabled": true,
          "type": "text",
          "position": "bottom_right",
          "opacity": 50,
          "scale": 20,
          "margin": 20,
          "text_content": "© Doe Studios",
          "text_font_size": 32,
          "text_color": "#FFFFFF",
          "text_rotation": 0,
          "download_option": "watermarked",
          "logo_path": "watermarks/3/logo.png",
          "has_logo": true,
        },
      };

      final model = WatermarkSettingsModel.fromJson(jsonMap);
      expect(model.enabled, true);
      expect(model.type, 'text');
      expect(model.position, 'bottom_right');
      expect(model.opacity, 50);
      expect(model.scale, 20);
      expect(model.margin, 20);
      expect(model.textContent, "© Doe Studios");
      expect(model.textFontSize, 32);
      expect(model.textColor, "#FFFFFF");
      expect(model.textRotation, 0);
      expect(model.downloadOption, "watermarked");
      expect(model.logoPath, "watermarks/3/logo.png");
      expect(model.hasLogo, true);
      expect(model.positionDisplayLabel, 'Bottom right');
      expect(model.downloadOptionDisplayLabel, 'Watermarked photo');
      expect(model.typeDisplayLabel, 'Text');
    });

    test('WatermarkSettingsModel.toJson outputs correct payload structure', () {
      const model = WatermarkSettingsModel(
        enabled: true,
        type: 'logo',
        position: 'center',
        opacity: 80,
        scale: 25,
        margin: 10,
        textContent: 'Logo watermark',
        textFontSize: 40,
        textColor: '#000000',
        textRotation: 45,
        downloadOption: 'original',
        logoPath: 'watermarks/5/logo.png',
        hasLogo: true,
      );

      final jsonMap = model.toJson();
      expect(jsonMap['enabled'], true);
      expect(jsonMap['type'], 'logo');
      expect(jsonMap['position'], 'center');
      expect(jsonMap['opacity'], 80);
      expect(jsonMap['scale'], 25);
      expect(jsonMap['margin'], 10);
      expect(jsonMap['text_content'], 'Logo watermark');
      expect(jsonMap['text_font_size'], 40);
      expect(jsonMap['text_color'], '#000000');
      expect(jsonMap['text_rotation'], 45);
      expect(jsonMap['download_option'], 'original');
    });

    test(
      'WatermarkSettingsModel position and download option display mapping',
      () {
        expect(
          WatermarkSettingsModel.displayToPosition('Top left'),
          'top_left',
        );
        expect(
          WatermarkSettingsModel.displayToPosition('Bottom right'),
          'bottom_right',
        );
        expect(WatermarkSettingsModel.displayToPosition('Tiled'), 'tiled');
        expect(
          WatermarkSettingsModel.displayToDownloadOption('Original photo'),
          'original',
        );
        expect(
          WatermarkSettingsModel.displayToDownloadOption('Watermarked photo'),
          'watermarked',
        );
      },
    );
  });

  group('WatermarkApiService Integration & Error Handling', () {
    test(
      'getWatermarkSettings sends GET request with Auth header and parses response',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'GET');
          expect(request.url.path, endsWith('/watermark-settings'));
          expect(request.headers['Authorization'], 'Bearer test-token');
          return http.Response(
            '''
          {
            "data": {
              "enabled": true,
              "type": "text",
              "position": "top_center",
              "opacity": 75,
              "scale": 30,
              "margin": 15,
              "text_content": "PhotoHouse Studio",
              "text_font_size": 24,
              "text_color": "#FF0000",
              "text_rotation": 15,
              "download_option": "original",
              "logo_path": null,
              "has_logo": false
            }
          }
          ''',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = WatermarkApiService(
          client: mockClient,
          storage: FakeSecureStorageService(token: 'test-token'),
        );

        final settings = await service.getWatermarkSettings();
        expect(settings.enabled, true);
        expect(settings.position, 'top_center');
        expect(settings.opacity, 75);
        expect(settings.textContent, 'PhotoHouse Studio');
        expect(settings.downloadOption, 'original');
      },
    );

    test(
      'updateWatermarkSettings sends PUT request with correct JSON payload',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.method, 'PUT');
          expect(request.url.path, endsWith('/watermark-settings'));
          expect(request.headers['Authorization'], 'Bearer test-token');

          final payload = jsonDecode(request.body) as Map<String, dynamic>;
          expect(payload['enabled'], false);
          expect(payload['type'], 'text');
          expect(payload['position'], 'tiled');
          expect(payload['opacity'], 60);

          return http.Response(
            '''
          {
            "data": {
              "enabled": false,
              "type": "text",
              "position": "tiled",
              "opacity": 60,
              "scale": 20,
              "margin": 20,
              "text_content": "Updated",
              "text_font_size": 32,
              "text_color": "#FFFFFF",
              "text_rotation": 0,
              "download_option": "watermarked",
              "logo_path": null,
              "has_logo": false
            }
          }
          ''',
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final service = WatermarkApiService(
          client: mockClient,
          storage: FakeSecureStorageService(token: 'test-token'),
        );

        const requestModel = WatermarkSettingsModel(
          enabled: false,
          type: 'text',
          position: 'tiled',
          opacity: 60,
          scale: 20,
          margin: 20,
          textContent: 'Updated',
        );

        final result = await service.updateWatermarkSettings(requestModel);
        expect(result.enabled, false);
        expect(result.position, 'tiled');
        expect(result.opacity, 60);
        expect(result.textContent, 'Updated');
      },
    );

    test('updateWatermarkSettings handles 422 validation error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '''
          {
            "message": "The opacity field must be between 0 and 100.",
            "errors": {
              "opacity": ["The opacity field must be between 0 and 100."]
            }
          }
          ''',
          422,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = WatermarkApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: 'test-token'),
      );

      const invalidModel = WatermarkSettingsModel(opacity: 150);
      expect(
        () => service.updateWatermarkSettings(invalidModel),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'description',
            contains('opacity field must be between'),
          ),
        ),
      );
    });

    test('getWatermarkSettings handles 401 unauthenticated error', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          '{"message": "Unauthenticated."}',
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = WatermarkApiService(
        client: mockClient,
        storage: FakeSecureStorageService(token: null),
      );

      expect(() => service.getWatermarkSettings(), throwsException);
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
