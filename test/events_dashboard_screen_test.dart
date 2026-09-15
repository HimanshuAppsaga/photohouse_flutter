import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:photohouse/screens/events_dashboard_screen.dart';
import 'package:photohouse/services/events_api_service.dart';
import 'events_api_service_test.dart';

void main() {
  testWidgets('EventsDashboardScreen displays empty state when user has no events', (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        '{"data": [], "meta": {"per_page": 50}}',
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final eventsApiService = EventsApiService(
      client: mockClient,
      storage: FakeSecureStorageService(token: 'test-token'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: EventsDashboardScreen(
          eventsApiService: eventsApiService,
        ),
      ),
    );

    // Let the async _fetchEvents finish
    await tester.pumpAndSettle();

    expect(find.text('No events found'), findsOneWidget);
    expect(find.text('Please create an event on the PhotoHouse web portal first.'), findsOneWidget);
    expect(find.text('Maulik'), findsNothing);
    expect(find.text('deep'), findsNothing);
    expect(find.text('Wedding'), findsNothing);
  });
}
