import 'package:construculator/features/consent/presentation/bloc/consent_gate_bloc/consent_gate_bloc.dart';
import 'package:construculator/features/consent/presentation/widgets/consent_prompt.dart';
import 'package:construculator/features/consent/presentation/widgets/consent_unavailable.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/router/interfaces/app_router.dart';
import 'package:construculator/libraries/router/routes/shell_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Full-screen page that blocks the app until consent is current.
///
/// There is no back affordance and [PopScope] blocks the system back gesture,
/// because a consent screen the user can dismiss is not a consent screen. The
/// only ways off it are accepting, or the status resolving to something
/// ungated underneath.
class ConsentGatePage extends StatelessWidget {
  /// Router used to return to the shell once consent is current.
  final AppRouter router;

  /// Opens a consent document externally.
  ///
  /// Injected rather than called directly so the page stays free of platform
  /// concerns and remains testable.
  final void Function(String url) onOpenDocument;

  const ConsentGatePage({
    super.key,
    required this.router,
    required this.onOpenDocument,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;

    return PopScope<Object?>(
      canPop: false,
      child: Scaffold(
        backgroundColor: colors.pageBackground,
        body: SafeArea(
          child: BlocConsumer<ConsentGateBloc, ConsentGateState>(
            listener: (context, state) {
              // Leaving the gate is a state transition, not a button action:
              // it fires whether the user accepted or the requirement simply
              // resolved underneath them.
              if (state is ConsentGateAllowed ||
                  state is ConsentGateUnverified) {
                router.navigate(shellRoute);
              }
            },
            builder: (context, state) => switch (state) {
              // Resolving from cache completes within a frame, so rendering a
              // spinner here would only produce a flash.
              ConsentGateChecking() ||
              ConsentGateVerifying() ||
              ConsentGateAllowed() ||
              ConsentGateUnverified() => const SizedBox.shrink(),
              ConsentGateBlocked(:final requiredVersion) => ConsentPrompt(
                version: requiredVersion,
                onOpenDocument: onOpenDocument,
              ),
              ConsentGateSubmitting(:final requiredVersion) => ConsentPrompt(
                version: requiredVersion,
                onOpenDocument: onOpenDocument,
                isSubmitting: true,
              ),
              ConsentGateSubmitFailed(:final requiredVersion) => ConsentPrompt(
                version: requiredVersion,
                onOpenDocument: onOpenDocument,
                hasSubmitFailed: true,
              ),
              ConsentGateUnavailable() => ConsentUnavailable(
                onRetry: () => context.read<ConsentGateBloc>().add(
                  const ConsentGateRetryRequested(),
                ),
              ),
            },
          ),
        ),
      ),
    );
  }
}
