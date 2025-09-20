import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final GlobalKey<NavigatorState> kRootNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> kShellNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

const storage = FlutterSecureStorage();

// TODO restore initialLocation to /books
// final String initialLocation = '/books';
final String initialLocation = '/book/1/review';

const kPadding = 16.0;

const kPerPage = 20;

Color kGreen = Colors.green.shade800;
