import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:parkshare_app/features/auth/data/auth_repository.dart';
import 'package:parkshare_app/features/auth/presentation/login_screen.dart';
import 'package:parkshare_app/features/auth/presentation/auth_providers.dart';

@GenerateNiceMocks([MockSpec<AuthRepository>()])
import 'login_screen_test.mocks.dart';

void main() {
  late MockAuthRepository mockRepo;

  setUp(() {
    mockRepo = MockAuthRepository();
  });

  Widget createLoginScreen() {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
      ],
      child: const MaterialApp(
        home: LoginScreen(),
      ),
    );
  }

  group('LoginScreen Destructive Testing', () {
    testWidgets('Empty fields validation', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      // Find login button
      final loginButton = find.byType(ElevatedButton);
      expect(loginButton, findsOneWidget);

      // Tap without entering anything
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Expect validation errors
      expect(find.text('Required'), findsNWidgets(2));
    });

    testWidgets('SQL Injection & Long String Handling', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      final inputs = find.byType(TextFormField);
      expect(inputs, findsNWidgets(2));

      // Enter malicious long string payload
      final maliciousPayload = "' OR 1=1 -- ${"A" * 10000}";
      await tester.enterText(inputs.at(0), maliciousPayload);
      await tester.enterText(inputs.at(1), maliciousPayload);

      // Setup mock to throw an exception when such payload is sent
      when(mockRepo.login(any, any)).thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        throw Exception('Server crash simulation');
      });

      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.pump(); // Trigger loading state

      // Verify loading indicator appears during async operation
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Finish the async operation
      await tester.pumpAndSettle();

      // Since an error is thrown, the UI should handle it gracefully without crashing
      // Expect a SnackBar indicating login failure
      expect(find.text('Login failed. Please check your credentials.'), findsOneWidget);
    });

    testWidgets('Valid login success state', (WidgetTester tester) async {
      await tester.pumpWidget(createLoginScreen());

      final inputs = find.byType(TextFormField);
      await tester.enterText(inputs.at(0), 'valid_user');
      await tester.enterText(inputs.at(1), 'password123');

      // Return a dummy user
      when(mockRepo.login('valid_user', 'password123')).thenAnswer((_) async => null); // Null means success for this test, or we can construct a User

      final loginButton = find.byType(ElevatedButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      // Verify that navigation would occur (by checking the UI state or mocking GoRouter)
      // Since GoRouter isn't fully mocked here, we just ensure it doesn't crash and no error snackbar is shown.
      expect(find.text('Login failed. Please check your credentials.'), findsNothing);
    });
  });
}
