import 'package:flutter/material.dart';

class TextUnderlineOnHover extends StatefulWidget {
  const TextUnderlineOnHover(
    this.string, {
    this.style = const TextStyle(),
    super.key,
  });
  final String string;
  final TextStyle style;

  @override
  State<TextUnderlineOnHover> createState() => _TextUnderlineOnHoverState();
}

class _TextUnderlineOnHoverState extends State<TextUnderlineOnHover> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
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
          ),
        ],
      ),
    );
  }
}
