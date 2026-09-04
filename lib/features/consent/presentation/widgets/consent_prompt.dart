import 'package:construculator/features/consent/presentation/bloc/consent_gate_bloc/consent_gate_bloc.dart';
import 'package:construculator/features/consent/presentation/widgets/consent_document_links.dart';
import 'package:construculator/libraries/consent/domain/entities/consent_version_entity.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// The consent prompt itself: title, body, document links and the accept
/// button.
///
/// Renders the three gated states rather than one widget per state, since they
/// differ only in whether the action is pending or has failed — a separate
/// widget each would duplicate the whole layout to vary a button label.
class ConsentPrompt extends StatelessWidget {
  /// The version being presented for acceptance, and the document to open.
  final ConsentVersion version;

  /// Opens a consent document externally.
  final void Function(String url) onOpenDocument;

  /// Whether an acceptance is in flight; replaces the action with a spinner.
  final bool isSubmitting;

  /// Whether the last acceptance failed; switches the action to a retry and
  /// shows the error line.
  final bool hasSubmitFailed;

  const ConsentPrompt({
    super.key,
    required this.version,
    required this.onOpenDocument,
    this.isSubmitting = false,
    this.hasSubmitFailed = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final typography = context.textTheme;
    final colors = context.colorTheme;

    // This is a full-screen dead end -- no app bar, no back affordance, and
    // the accept/retry button below is the only way off it. A centred Column
    // with no scroll fallback overflows off both ends at large text scale
    // and clips the button away with no gesture that can bring it back, so
    // the scroll wrapper is load-bearing here, not cosmetic. ConstrainedBox
    // keeps the content vertically centred when it fits, matching the
    // checked-in goldens, and lets it scroll the moment it doesn't.
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
                l10n.consentGateTitle,
                key: const Key('consentGateTitle'),
                style: typography.headlineLargeSemiBold.copyWith(
                  color: colors.textHeadline,
                ),
              ),
              const SizedBox(height: CoreSpacing.space4),
              Text(
                l10n.consentGateBody,
                style: typography.bodyMediumRegular.copyWith(
                  color: colors.textHeadline,
                ),
              ),
              const SizedBox(height: CoreSpacing.space6),
              ConsentDocumentLinks(
                termsLabel: l10n.consentGateTermsLink,
                privacyLabel: l10n.consentGatePrivacyLink,
                onTermsPressed: () => onOpenDocument(version.documentUrl),
                onPrivacyPressed: () => onOpenDocument(version.documentUrl),
              ),
              const SizedBox(height: CoreSpacing.space8),
              if (isSubmitting)
                const Center(
                  key: Key('consentGateSubmitting'),
                  child: CoreLoadingIndicator(),
                )
              else
                CoreButton(
                  key: const Key('consentGateAcceptButton'),
                  centerAlign: true,
                  label: hasSubmitFailed
                      ? l10n.consentGateRetryButton
                      : l10n.consentGateAcceptButton,
                  onPressed: () => context.read<ConsentGateBloc>().add(
                    ConsentGateAccepted(version),
                  ),
                ),
              if (hasSubmitFailed) ...[
                const SizedBox(height: CoreSpacing.space3),
                // liveRegion so a screen-reader user hears that the write
                // failed -- otherwise the only signal is a silent button
                // relabel from "Agree and continue" to "Retry", with focus
                // left where it was.
                Semantics(
                  liveRegion: true,
                  child: Row(
                    key: const Key('consentGateSubmitError'),
                    children: [
                      CoreIconWidget(
                        icon: CoreIcons.error,
                        size: CoreIconSize.size16,
                        color: colors.iconRed,
                      ),
                      const SizedBox(width: CoreSpacing.space1),
                      Expanded(
                        child: Text(
                          l10n.consentGateSubmitErrorMessage,
                          style: typography.bodySmallRegular.copyWith(
                            color: colors.textError,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
