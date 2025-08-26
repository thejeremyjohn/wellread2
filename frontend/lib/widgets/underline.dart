import 'package:flutter/material.dart';

class Underline extends StatelessWidget {
  const Underline({
    super.key,
    required this.text,
    required this.underlineColor,
    this.underlineWidth = 2,
    this.space = 0,
  });

  final Text text;
  final Color underlineColor;
  final double underlineWidth;
  final double space;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: space, // the space between text and underline
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: underlineColor, width: underlineWidth),
        ),
      ),
      child: text,
    );
  }
}
