import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

/// Circular avatar showing a network image when available, falling back to a
/// letter avatar derived from [name]. Fixed at 40×40 dp.
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colorTheme;
    final url = imageUrl;
    final hasImage = url != null && url.isNotEmpty;

    return GestureDetector(
      key: const Key('profile_avatar_button'),
      onTap: onTap,
      child: Semantics(
        label: context.l10n.profileSemanticLabel,
        child: CoreAvatar(
          radius: 20,
          backgroundColor: colors.backgroundGrayMid,
          image: hasImage ? NetworkImage(url) : null,
          child: hasImage ? null : CoreLetterAvatar(name: name),
        ),
      ),
    );
  }
}
