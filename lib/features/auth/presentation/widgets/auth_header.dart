import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

/// A widget that displays a header with a title and a description
/// [title] - The title to display
/// [description] - The description to display
/// [contact] - The contact to display
/// [onContactPressed] - The callback to be called when the contact is pressed
class AuthHeader extends StatelessWidget {
  final String title;
  final String description;
  final String? contact;
  final VoidCallback? onContactPressed;
  const AuthHeader({
    super.key,
    required this.title,
    required this.description,
    this.contact,
    this.onContactPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          key: Key('text_title'),
          title,
          style: CoreTypography.headlineLargeSemiBold(),
        ),
        const SizedBox(height: CoreSpacing.space2),
        contact != null
            ? RichText(
                key: Key('rich_text_description'),
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.fontFamily,
                  ),
                  children: [
                    TextSpan(
                      text: description,
                      style: CoreTypography.bodyLargeRegular(),
                    ),
                    WidgetSpan(
                      child: GestureDetector(
                        key: Key('edit_link'),
                        onTap: onContactPressed,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ' $contact',
                              style: CoreTypography.bodyLargeSemiBold(
                                color: CoreTextColors.link,
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(left: 4.0),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: CoreTextColors.link,
                              ),
                            ),
                          ],
                        ),
                      ),
                      alignment: PlaceholderAlignment.middle,
                    ),
                  ],
                ),
              )
            : Text(
                key: Key('text_description'),
                description,
                style: CoreTypography.bodyLargeRegular(),
              ),
      ],
    );
  }
}
