import 'package:construculator/features/consent/presentation/bloc/consent_gate_bloc/consent_gate_bloc.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Shown when the requirement could not be established and there is nothing on
/// file to fall back on.
///
/// Deliberately not a consent prompt: without a published version the app has
/// no document to name, so there is nothing here for the user to agree to —
/// only something to retry.
class ConsentUnavailable extends StatelessWidget {
  const ConsentUnavailable({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typography = context.textTheme;
    final colors = context.colorTheme;

    // This is a full-screen dead end -- no app bar, no back affordance, and
    // the retry button below is the only way off it. A centred Column with
    // no scroll fallback overflows off both ends at large text scale and
    // clips the button away with no gesture that can bring it back, so the
    // scroll wrapper is load-bearing here, not cosmetic.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: CoreSpacing.space6),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.consentUnavailableTitle,
                key: const Key('consentUnavailableTitle'),
                style: typography.headlineLargeSemiBold.copyWith(
                  color: colors.textHeadline,
                ),
              ),
              const SizedBox(height: CoreSpacing.space4),
              Text(
                l10n.consentUnavailableBody,
                style: typography.bodyMediumRegular.copyWith(
                  color: colors.textHeadline,
                ),
              ),
              const SizedBox(height: CoreSpacing.space8),
              CoreButton(
                key: const Key('consentUnavailableRetryButton'),
                centerAlign: true,
                label: l10n.consentUnavailableRetryButton,
                onPressed: () => context.read<ConsentGateBloc>().add(
                  const ConsentGateRetryRequested(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
