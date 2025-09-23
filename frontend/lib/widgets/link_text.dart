import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class LinkText extends StatefulWidget {
  const LinkText(
    this.string, {
    this.style = const TextStyle(),
    this.onClick,
    super.key,
  });
  final String string;
  final TextStyle style;
  final void Function()? onClick;

  @override
  State<LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<LinkText> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: widget.string,
        style: widget.style.copyWith(
          decoration: _hover ? TextDecoration.underline : null,
          decorationColor: widget.style.color,
        ),
        onEnter: (_) {
          if (context.mounted) setState(() => _hover = true);
        },
        onExit: (_) {
          if (context.mounted) setState(() => _hover = false);
        },
        recognizer: TapGestureRecognizer()..onTap = widget.onClick,
      ),
    );
  }
}
