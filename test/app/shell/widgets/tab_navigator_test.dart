import 'package:construculator/app/shell/widgets/tab_navigator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TabNavigator', () {
    testWidgets('creates Navigator with provided key', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          home: TabNavigator(
            navigatorKey: navigatorKey,
            rootBuilder: (_) => const Text('Root Widget'),
          ),
        ),
      );

      expect(navigatorKey.currentState, isNotNull);
      expect(navigatorKey.currentState, isA<NavigatorState>());
    });

    testWidgets('builds root widget from rootBuilder', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          home: TabNavigator(
            navigatorKey: navigatorKey,
            rootBuilder: (_) => const Text('Test Root Content'),
          ),
        ),
      );

      expect(find.text('Test Root Content'), findsOneWidget);
    });

    testWidgets('passes context to rootBuilder', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      BuildContext? capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: TabNavigator(
            navigatorKey: navigatorKey,
            rootBuilder: (context) {
              capturedContext = context;
              return const Text('Content');
            },
          ),
        ),
      );

      expect(capturedContext, isNotNull);
    });

    testWidgets('supports navigation within tab', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          home: TabNavigator(
            navigatorKey: navigatorKey,
            rootBuilder: (_) => Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Text('Second Page'),
                      ),
                    );
                  },
                  child: const Text('Navigate'),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Navigate'), findsOneWidget);
      expect(find.text('Second Page'), findsNothing);

      await tester.tap(find.text('Navigate'));
      await tester.pumpAndSettle();

      expect(find.text('Second Page'), findsOneWidget);
    });

    testWidgets('canPop returns false initially', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          home: TabNavigator(
            navigatorKey: navigatorKey,
            rootBuilder: (_) => const Text('Root'),
          ),
        ),
      );

      expect(navigatorKey.currentState?.canPop(), isFalse);
    });

    testWidgets('canPop returns true after push', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          home: TabNavigator(
            navigatorKey: navigatorKey,
            rootBuilder: (_) => Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const Text('Pushed'),
                      ),
                    );
                  },
                  child: const Text('Push'),
                );
              },
            ),
          ),
        ),
      );

      expect(navigatorKey.currentState?.canPop(), isFalse);

      await tester.tap(find.text('Push'));
      await tester.pumpAndSettle();

      expect(navigatorKey.currentState?.canPop(), isTrue);
    });
  });
}
