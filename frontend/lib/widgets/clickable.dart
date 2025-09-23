import 'package:flutter/material.dart';

class Clickable extends StatelessWidget {
  const Clickable({super.key, this.onClick, this.child});

  final void Function()? onClick;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return DefaultSelectionStyle(
      mouseCursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onClick, child: child),
    );
  }
}
