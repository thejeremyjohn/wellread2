import 'package:flutter/material.dart';
import 'package:wellread2frontend/constants.dart';

class ThemeState extends ChangeNotifier {
  bool isDarkMode = false;
  ThemeData get theme => isDarkMode ? _darkTheme : _lightTheme;

  void toggleDarkMode() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    appBarTheme: AppBarTheme(backgroundColor: kBrownLt),
    fontFamily: fontFamily,
    pageTransitionsTheme: noTransition,
  );

  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    appBarTheme: AppBarTheme(backgroundColor: kBrown),
    fontFamily: fontFamily,
    pageTransitionsTheme: noTransition,
  );
}

class NoTransitionsBuilder extends PageTransitionsBuilder {
  const NoTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T>? route,
    BuildContext? context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget? child,
  ) {
    return child!;
  }
}

final noTransition = PageTransitionsTheme(
  builders: {
    for (final platform in TargetPlatform.values)
      platform: const NoTransitionsBuilder(),
  },
);
