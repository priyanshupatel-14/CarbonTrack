import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/auth/ui/login_screen.dart';
import 'package:frontend/features/auth/ui/register_screen.dart';

void main() {
  group('Auth Screen Widget Tests', () {
    testWidgets('LoginScreen renders branding and form fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('CarbonTrack'), findsOneWidget);
      expect(find.text('Campus Sustainability & Green Points'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Register as Student'), findsOneWidget);
      expect(find.text('Student Demo'), findsOneWidget);
    });

    testWidgets('RegisterScreen renders registration form fields', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      expect(find.text('Join CarbonTrack'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(5));
      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });
  });
}
