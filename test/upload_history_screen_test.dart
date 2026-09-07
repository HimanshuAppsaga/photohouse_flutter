import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:photohouse/screens/upload_history_screen.dart';
import 'package:photohouse/services/secure_storage_service.dart';
import 'package:photohouse/services/upload_api_service.dart';

class FakeSecureStorageService extends SecureStorageService {
  @override
  Future<String?> getToken() async => 'test-token-123';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('UploadHistoryScreen displays sessions and filters correctly',
      (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          'data': [
            {
              'uuid': 'sess-uuid-001',
              'event_uuid': 'event-uuid-abc',
              'album_id': 5,
              'source': 'desktop_agent',
              'total_files': 100,
              'completed_files': 95,
              'failed_files': 5,
              'status': 'completed',
              'created_at': '2026-09-03T10:00:00Z',
              'updated_at': '2026-09-03T10:20:00Z',
            }
          ],
          'meta': {'next_cursor': null}
        }),
        200,
      );
    });

    final service = UploadApiService(
      client: mockClient,
      storage: FakeSecureStorageService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: UploadHistoryScreen(uploadApiService: service),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Upload Sessions'), findsOneWidget);
    expect(find.text('UPLOAD HISTORY METRICS'), findsOneWidget);
    expect(find.text('sess-uuid-001'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('Desktop Agent'), findsOneWidget);
  });
}
