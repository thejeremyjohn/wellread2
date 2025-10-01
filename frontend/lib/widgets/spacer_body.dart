import 'package:flutter/material.dart';

class SpacerBody extends StatelessWidget {
  const SpacerBody({super.key, required this.child, this.flex = 4});
  final Widget child;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 1, child: Container()), // page side spacer
          Expanded(flex: flex, child: child),
          Expanded(flex: 1, child: Container()), // page side spacer
        ],
      ),
    );
  }
}
