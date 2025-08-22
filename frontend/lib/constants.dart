import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> kRootNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> kShellNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

const kPadding = 16.0;

const kPerPage = 20;
