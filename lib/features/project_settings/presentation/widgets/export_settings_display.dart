import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:construculator/libraries/project/domain/entities/enums.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Displays the export folder configuration for a project.
///
/// Shows the section title and, when [storageProvider] is non-null, a row with
/// the provider icon, a localised label, and a chip with the [folderName].
/// Renders the title only when [storageProvider] is null.
class ExportSettingsDisplay extends StatelessWidget {
  const ExportSettingsDisplay({
    super.key,
    required this.storageProvider,
    required this.folderName,
  });

  /// The cloud storage provider configured for this project's export, or null
  /// when no export destination has been set.
  final StorageProvider? storageProvider;

  /// The display name of the export folder, or null when not configured.
  final String? folderName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          context.l10n.exportSettingsTitle,
          style: typography.bodyLargeSemiBold.copyWith(
            color: colors.textHeadline,
          ),
        ),
        if (storageProvider case final provider?) ...[
          const SizedBox(height: CoreSpacing.space4),
          _ProviderRow(
            storageProvider: provider,
            folderName: folderName,
          ),
        ],
      ],
    );
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.storageProvider,
    required this.folderName,
  });

  final StorageProvider storageProvider;
  final String? folderName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _providerIcon(colors),
        const SizedBox(width: CoreSpacing.space4),
        Text(
          _providerLabel(context),
          style: typography.bodyMediumRegular.copyWith(
            color: colors.textDark,
          ),
        ),
        if (folderName case final name?) ...[
          const SizedBox(width: CoreSpacing.space4),
          _FolderNameChip(folderName: name),
        ],
      ],
    );
  }

  Widget _providerIcon(AppColorsExtension colors) {
    final icon = switch (storageProvider) {
      StorageProvider.googleDrive => CoreIcons.google,
      StorageProvider.oneDrive => CoreIcons.microsoft,
      StorageProvider.dropbox => CoreIcons.share,
    };
    return CoreIconWidget(
      key: const Key('export_settings_provider_icon'),
      icon: icon,
      size: CoreIconSize.size24,
      color: colors.iconDark,
    );
  }

  String _providerLabel(BuildContext context) {
    return switch (storageProvider) {
      StorageProvider.googleDrive => context.l10n.exportGoogleDriveLabel,
      StorageProvider.oneDrive => context.l10n.exportOneDriveLabel,
      StorageProvider.dropbox => context.l10n.exportDropboxLabel,
    };
  }
}

class _FolderNameChip extends StatelessWidget {
  const _FolderNameChip({required this.folderName});

  final String folderName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final typography = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: CoreSpacing.space1,
        horizontal: CoreSpacing.space3,
      ),
      decoration: BoxDecoration(
        color: colors.backgroundGrayMid,
        borderRadius: BorderRadius.circular(CoreSpacing.space5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreIconWidget(
            icon: CoreIcons.editDocument,
            size: CoreIconSize.size16,
            color: colors.iconDark,
          ),
          const SizedBox(width: CoreSpacing.space2),
          Text(
            folderName,
            style: typography.bodyMediumRegular.copyWith(
              color: colors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
