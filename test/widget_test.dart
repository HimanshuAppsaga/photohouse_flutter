import 'package:flutter_test/flutter_test.dart';
import 'package:photohouse/main.dart';
import 'package:photohouse/models/user_model.dart';

void main() {
  testWidgets('App renders successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump(const Duration(seconds: 3));
    expect(find.byType(MyApp), findsOneWidget);
  });

  group('UserModel Tests', () {
    test('UserModel.fromJson parses user map correctly', () {
      final jsonMap = {
        'id': 'usr_123',
        'name': 'John Doe',
        'email': 'john@example.com',
        'plan': 'ENTERPRISE',
      };
      final user = UserModel.fromJson(jsonMap);
      expect(user.id, 'usr_123');
      expect(user.name, 'John Doe');
      expect(user.email, 'john@example.com');
      expect(user.plan, 'ENTERPRISE');
      expect(user.formattedName, 'John Doe');
      expect(user.firstLetter, 'J');
    });

    test('UserModel.fromInput constructs user from email string', () {
      final user = UserModel.fromInput(emailOrUsername: 'himanshu.appsaga.in');
      expect(user.name, 'Himanshu');
      expect(user.formattedName, 'Himanshu');
      expect(user.firstLetter, 'H');
    });
  });
}
