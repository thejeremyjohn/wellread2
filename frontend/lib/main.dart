import 'package:flutter/material.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/login_logout.dart';
import 'package:wellread2frontend/pages/book_page.dart';
import 'package:wellread2frontend/pages/books_page.dart';
import 'package:wellread2frontend/pages/login_page.dart';
import 'package:go_router/go_router.dart';
import 'package:wellread2frontend/widgets/wellread_app_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      routerConfig: GoRouter(
        navigatorKey: kRootNavKey,
        initialLocation: '/books',
        redirect: (context, state) async =>
            await isLoggedIn() ? null : '/login',
        routes: [
          GoRoute(path: '/', redirect: (context, state) => '/books'),
          GoRoute(
            path: '/login',
            redirect: (context, state) async =>
                await isLoggedIn() ? '/books' : null,
            builder: (context, state) => const LoginPage(),
          ),
          ShellRoute(
            navigatorKey: kShellNavKey,
            builder: (context, state, child) =>
                Scaffold(appBar: WellreadAppBar(), body: child),
            routes: <RouteBase>[
              GoRoute(
                path: '/books',
                builder: (context, state) => const BooksPage(),
              ),
              GoRoute(
                path: '/book/:bookId',
                builder: (context, state) =>
                    BookPage(bookId: state.pathParameters['bookId']!),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
