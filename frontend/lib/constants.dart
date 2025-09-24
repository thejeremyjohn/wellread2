import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final GlobalKey<NavigatorState> kRootNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> kShellNavKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

const storage = FlutterSecureStorage();

final String initialLocation = '/books';

// final String fontFamily = 'Montserrat';
// final String fontFamilyAlt = 'LibreBaskerville';
final String fontFamily = 'LatoLatin';
final String fontFamilyAlt = 'merriweather';

const kPadding = 16.0;

const kPerPage = 20;

Color kGreen = Colors.green.shade800;
