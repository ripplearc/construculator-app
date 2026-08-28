import 'package:construculator/l10n/generated/app_localizations.dart';
import 'package:construculator/libraries/global_search/presentation/widgets/recent_search_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

void main() {
  const term = 'MD bungalow';

  Widget makeTestableWidget({
    VoidCallback? onTap,
    VoidCallback? onTrailingTap,
    Future<bool> Function()? onDismissRequested,
  }) {
    return MaterialApp(
      theme: CoreTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: RecentSearchItem(
          term: term,
          onTap: onTap ?? () {},
          onTrailingTap: onTrailingTap ?? () {},
          // Resolves false so the static harness never completes a
          // dismissal — the row data here can never change.
          onDismissRequested: onDismissRequested ?? () async => false,
        ),
      ),
    );
  }

  group('RecentSearchItem', () {
    testWidgets(
      'invoking the labeled delete custom semantics action requests '
      'dismissal',
      (tester) async {
        var dismissRequests = 0;
        // Disposed inline: the tester verifies no live SemanticsHandle at
        // the END OF THE TEST BODY, which runs before addTearDown callbacks.
        final handle = tester.ensureSemantics();
        await tester.pumpWidget(
          makeTestableWidget(
            onDismissRequested: () async {
              dismissRequests++;
              return false;
            },
          ),
        );
        await tester.pump();

        final node = tester.getSemantics(
          find.byKey(const ValueKey('recent_search_dismissible_$term')),
        );
        final actionIds = node.getSemanticsData().customSemanticsActionIds;
        expect(actionIds, isNotNull);
        int? deleteActionId;
        if (actionIds != null) {
          for (final id in actionIds) {
            final action = CustomSemanticsAction.getAction(id);
            if (action != null &&
                action.label == 'Delete $term from recent searches') {
              deleteActionId = id;
            }
          }
        }
        expect(
          deleteActionId,
          isNotNull,
          reason:
              'the row must expose the delete affordance as a labeled '
              'custom action',
        );
        final owner = node.owner;
        expect(owner, isNotNull);
        if (owner != null && deleteActionId != null) {
          owner.performAction(
            node.id,
            SemanticsAction.customAction,
            deleteActionId,
          );
        }
        await tester.pump();
        handle.dispose();

        expect(
          dismissRequests,
          1,
          reason:
              'the custom action must run the same confirm-dismiss flow as '
              'the swipe gesture',
        );
      },
    );
  });
}
