import 'dart:ui';

import 'package:construculator/libraries/app_lifecycle/app_lifecycle_wrapper_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLifecycleWrapperImpl', () {
    testWidgets('reports the background once the app is hidden or paused', (
      tester,
    ) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      final wrapper = AppLifecycleWrapperImpl();
      addTearDown(wrapper.dispose);
      final changes = <bool>[];
      wrapper.foregroundChanges.listen(changes.add);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(wrapper.isInForeground, isTrue, reason: 'inactive is visible');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(wrapper.isInForeground, isFalse);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(wrapper.isInForeground, isTrue);

      expect(changes, [false, true], reason: 'one event per real change');
    });

    testWidgets('starts in the background if created while paused', (
      tester,
    ) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      addTearDown(
        () => tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        ),
      );

      final wrapper = AppLifecycleWrapperImpl();
      addTearDown(wrapper.dispose);

      expect(wrapper.isInForeground, isFalse);
    });
  });
}
