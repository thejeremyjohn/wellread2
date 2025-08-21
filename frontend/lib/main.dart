import 'package:flutter/material.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_constants.dart';
import 'package:wellread2frontend/pages/book_page.dart';
import 'package:wellread2frontend/pages/books_page.dart';
import 'package:wellread2frontend/pages/login_page.dart';
import 'package:go_router/go_router.dart';

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
        navigatorKey: kNavigatorKey,
        redirect: (BuildContext context, GoRouterState state) async {
          final notLoggedIn = await storage.read(key: 'accessToken') == null;
          return notLoggedIn ? '/login' : null;
        },
        routes: [
          GoRoute(path: '/', redirect: (context, state) => '/books'),
          GoRoute(
            path: '/login', // TODO redirect if already logged in
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: '/books',
            builder: (context, state) => const BooksPage(),
          ),
          GoRoute(
            path: '/book/:bookId',
            builder: (context, state) {
              return BookPage(bookId: state.pathParameters['bookId']!);
            },
          ),
          // ShellRoute(
          //   builder: (BuildContext context, GoRouterState state, Widget child) {
          //     return Scaffold(
          //       body: child,
          //       /* ... */
          //       appBar: WellreadAppBar(),
          //     );
          //   },
          //   routes: <RouteBase>[
          //     GoRoute(path: '/books', builder: (context, state) => const BooksPage()),
          //     GoRoute(
          //       path: '/book/:bookId',
          //       builder: (context, state) {
          //         return BookPage(bookId: state.pathParameters['bookId']!);
          //       },
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
