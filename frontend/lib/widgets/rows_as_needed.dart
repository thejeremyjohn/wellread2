import 'dart:math';
import 'package:flutter/material.dart';
import 'package:wellread2frontend/constants.dart';

List<Widget> rowsAsNeeded(
  List<dynamic> items,
  Widget Function(dynamic) builder, {

  int perRow = 3,
  double spacing = kPadding,
  MainAxisSize mainAxisSize = MainAxisSize.max,
  CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
}) => [
  for (var idx = 0; idx < items.length; idx += perRow)
    Row(
      spacing: spacing,
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      children: items
          .sublist(idx, min(idx + perRow, items.length))
          .map<Widget>(builder)
          .toList(),
    ),
];
