import 'package:flutter/material.dart';

class Clickable extends StatelessWidget {
  const Clickable({super.key, this.onClick, this.child});

  final Function()? onClick;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onClick, child: child),
    );
  }
}
