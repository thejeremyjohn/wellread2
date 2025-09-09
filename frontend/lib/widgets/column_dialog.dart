import 'package:flutter/material.dart';
import 'package:wellread2frontend/constants.dart';

class ColumnDialog extends Dialog {
  const ColumnDialog({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      constraints: BoxConstraints(minWidth: 300, maxWidth: 400),
      child: Padding(
        padding: const EdgeInsets.all(kPadding),
        child: Column(
          spacing: kPadding,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}
