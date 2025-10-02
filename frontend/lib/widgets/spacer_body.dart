import 'package:flutter/material.dart';
import 'package:wellread2frontend/constants.dart';

class SpacerBody extends StatelessWidget {
  const SpacerBody({super.key, required this.child, this.flex = 4});
  final Widget child;
  final int flex;

  @override
  Widget build(BuildContext context) {
    bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    int lrFlex = isLandscape ? 1 : 0;
    double horizontalPadding = !isLandscape ? kPadding : 0;

    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: lrFlex, child: Container()), // page side spacer
          Expanded(
            flex: flex,
            child: Padding(
              padding: EdgeInsets.symmetric(
                vertical: kPadding,
                horizontal: horizontalPadding,
              ),
              child: child,
            ),
          ),
          Expanded(flex: lrFlex, child: Container()), // page side spacer
        ],
      ),
    );
  }
}
