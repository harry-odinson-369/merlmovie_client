import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:merlmovie_client/src/extensions/context.dart';
import 'package:url_launcher/url_launcher.dart';

class ExpandCollapseText extends StatefulWidget {
  final String text;
  final Color? textColor;
  final TextStyle? style;
  final TextStyle? linkStyle;
  final TextAlign textAlign;
  final int collapsedMaxLines;
  const ExpandCollapseText({
    super.key,
    required this.text,
    this.textColor,
    this.style,
    this.linkStyle,
    this.collapsedMaxLines = 3,
    this.textAlign = TextAlign.center,
  });

  @override
  State<ExpandCollapseText> createState() => _ExpandCollapseTextState();
}

class _ExpandCollapseTextState extends State<ExpandCollapseText> {
  bool expand = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => expand = !expand),
      child: HyperLink(
        text: widget.text,
        textAlign: widget.textAlign,
        maxLines: expand ? 99999 : widget.collapsedMaxLines,
        overflow: TextOverflow.ellipsis,
        textStyle:
            widget.style ??
            context.theme.textTheme.bodyLarge?.copyWith(
              color: widget.textColor,
            ),
        linkStyle:
            widget.linkStyle ??
            context.theme.textTheme.bodyLarge?.copyWith(color: Colors.blue),
        linkCallBack: (msg) async {
          if (await canLaunchUrl(Uri.parse(msg))) {
            launchUrl(Uri.parse(msg));
          }
        },
      ),
    );
  }
}

typedef LinkCallBack = void Function(String msg);

/// A widget for displaying text with clickable hyperlinks.
///
/// Hyperlinks should be in the format "(link_title)[link_address]". For example:
/// "Click here to visit (Google)[https://www.google.com]".
///
/// This widget uses regular expressions to identify hyperlinks in the text and
/// applies the [linkStyle] to them. The [textStyle] is applied to the rest of
/// the text.
///
/// When a hyperlink is tapped, it attempts to launch the provided URL using
/// the [url_launcher](https://pub.dev/packages/url_launcher) package. If the URL
/// is successfully launched, it opens the link in the default browser.
class HyperLink extends StatelessWidget {
  /// The text show before [text] as prefix.
  final String? prefix;

  /// The [TextStyle] of prefix text.
  final TextStyle? prefixStyle;

  /// The text to display, including hyperlinks.
  final String text;

  /// The style of the non-link text.
  final TextStyle? textStyle;

  /// The style of the hyperlink text.
  final TextStyle? linkStyle;

  /// The name of the web-only window.
  final String? webOnlyWindowName;

  /// Called when a pointer enters the link.
  final PointerEnterEventListener? linkOnEnter;

  /// Called when a pointer exits the link.
  final PointerExitEventListener? linkOnExit;

  /// The text alignment.
  final TextAlign textAlign;

  /// The text direction.
  final TextDirection? textDirection;

  /// Whether the text should break at soft line breaks.
  final bool softWrap;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// The maximum number of lines for the text to span, wrapping if necessary.
  final int? maxLines;

  /// The locale for this text.
  final Locale? locale;

  /// The strut style to use.
  final StrutStyle? strutStyle;

  /// The width basis for the text layout.
  final TextWidthBasis textWidthBasis;

  /// The height behavior to use.
  final TextHeightBehavior? textHeightBehavior;

  /// The registrar for text selection.
  final SelectionRegistrar? selectionRegistrar;

  /// The color to use when highlighting the text for selection.
  final Color? selectionColor;

  /// This callback returns the link instead of opening the URL if initialized.
  final LinkCallBack? linkCallBack;

  const HyperLink({
    super.key,
    required this.text,
    this.prefix,
    this.prefixStyle,
    this.linkStyle,
    this.textStyle,
    this.webOnlyWindowName,
    this.linkOnEnter,
    this.linkOnExit,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.maxLines,
    this.locale,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.textHeightBehavior,
    this.selectionRegistrar,
    this.selectionColor,
    this.linkCallBack,
  });

  @override
  Widget build(BuildContext context) {
    // Regular expression to find "(link_title)[link_address]"
    RegExp linkRegex = RegExp(r'\[(.*?)\]\((.*?)\)');
    List<InlineSpan> children = [];

    int currentIndex = 0;
    linkRegex.allMatches(text).forEach((match) {
      // Add non-link text
      children.add(
        TextSpan(
          text: text.substring(currentIndex, match.start),
          style: textStyle,
        ),
      );
      // Add link text
      children.add(
        TextSpan(
          text: match.group(1),
          // link_title
          style: linkStyle,
          onEnter: linkOnEnter,
          onExit: linkOnExit,
          recognizer:
              TapGestureRecognizer()
                ..onTap = () async {
                  final link = match.group(2) ?? "";
                  linkCallBack?.call(link);
                },
        ),
      );
      currentIndex = match.end;
    });

    // Add remaining non-link text
    if (currentIndex < text.length) {
      children.add(
        TextSpan(text: text.substring(currentIndex), style: textStyle),
      );
    }

    return RichText(
      text: TextSpan(text: prefix, style: prefixStyle, children: children),
      locale: locale,
      maxLines: maxLines,
      textAlign: textAlign,
      textDirection: textDirection,
      textHeightBehavior: textHeightBehavior,
      textWidthBasis: textWidthBasis,
      selectionColor: selectionColor,
      selectionRegistrar: selectionRegistrar,
      softWrap: softWrap,
      strutStyle: strutStyle,
      overflow: overflow,
    );
  }
}
