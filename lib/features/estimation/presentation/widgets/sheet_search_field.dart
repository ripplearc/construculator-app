import 'package:construculator/features/estimation/presentation/widgets/sheet_surface.dart';
import 'package:construculator/libraries/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:ripplearc_coreui/ripplearc_coreui.dart';

// TODO: [CA-1341](https://ripplearc.youtrack.cloud/issue/CA-1341) Replace with CoreUI's Search Bar Sheet variants (magnifier, focus outline, plain clear button) once they exist.
/// Figma node 66342:169083 ("Search Bar", `Property 1=Sheet filled`):
/// white fill, 1px `#d0d5dd` (`colorTheme.lineMid`) stroke, 12px corner
/// radius. [CoreSearchBox] gets the icon behavior right but is borderless
/// everywhere else it is used, so this wraps it in the bordered box.
class SheetSearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const SheetSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorTheme = context.colorTheme;
    final theme = Theme.of(context);
    return Container(
      key: const Key('your_rates_search_field'),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: colorTheme.lineMid),
        borderRadius: BorderRadius.circular(CoreSpacing.space3),
      ),
      // TODO: [CA-1251](https://ripplearc.youtrack.cloud/issue/CA-1251) Drop this theme override once CoreUI has a white sheet surface.
      child: Theme(
        data: theme.copyWith(
          extensions: [
            for (final extension in theme.extensions.values)
              if (extension is AppColorsExtension)
                extension.copyWith(pageBackground: sheetSurface(context))
              else
                extension,
          ],
        ),
        child: CoreSearchBox(
          hintText: context.l10n.yourRatesSearchHint,
          controller: controller,
          onChanged: onChanged,
          clearSemanticLabel: context.l10n.yourRatesClearSearchSemanticLabel,
        ),
      ),
    );
  }
}
