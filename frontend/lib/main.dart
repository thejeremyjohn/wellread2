import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/login_logout.dart';
import 'package:wellread2frontend/pages/author_page.dart';
import 'package:wellread2frontend/pages/book_page.dart';
import 'package:wellread2frontend/pages/books_page.dart';
import 'package:wellread2frontend/pages/login_page.dart';
import 'package:go_router/go_router.dart';
import 'package:wellread2frontend/pages/review_page.dart';
import 'package:wellread2frontend/pages/signup_page.dart';
import 'package:wellread2frontend/pages/forgot_pw_page.dart';
import 'package:wellread2frontend/pages/verify_page.dart';
import 'package:wellread2frontend/providers/book_page_state.dart';
import 'package:wellread2frontend/providers/user_state.dart';
import 'package:wellread2frontend/widgets/wellread_app_bar.dart';

void main() {
  usePathUrlStrategy(); // remove '#' from paths
  GoRouter.optionURLReflectsImperativeAPIs =
      true; // ctx.push(...) updates path (same as ctx.go(...))
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserState()),
        ChangeNotifierProvider(create: (context) => BookPageState()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter goRouter;

  @override
  void initState() {
    goRouter = GoRouter(
      navigatorKey: kRootNavKey,
      initialLocation: initialLocation,
      routes: [
        GoRoute(path: '/', redirect: (_, __) => initialLocation),
        GoRoute(
          path: '/login',
          redirect: (_, __) async =>
              await isLoggedIn(context) ? initialLocation : null,
          builder: (context, state) => SelectionArea(child: const LoginPage()),
        ),
        GoRoute(
          path: '/forgotpw',
          builder: (context, state) => SelectionArea(
            child: ForgotPwPage(
              email: (state.extra as Map?)?['email'],
              token: state.uri.queryParameters['token'],
            ),
          ),
        ),
        GoRoute(
          path: '/signup',
          redirect: (_, __) async =>
              await isLoggedIn(context) ? initialLocation : null,
          builder: (context, state) => SelectionArea(child: const SignupPage()),
        ),
        GoRoute(
          path: '/verify',
          redirect: (_, __) async =>
              await isLoggedIn(context) ? initialLocation : null,
          builder: (context, state) => SelectionArea(
            child: VerifyPage(token: state.uri.queryParameters['token']),
          ),
        ),
        ShellRoute(
          navigatorKey: kShellNavKey,
          builder: (context, state, child) => SelectionArea(
            child: Scaffold(appBar: WellreadAppBar(), body: child),
          ),
          redirect: (_, __) async =>
              await isLoggedIn(context) ? null : '/login',
          routes: <RouteBase>[
            GoRoute(
              path: '/books',
              builder: (context, state) => BooksPage(
                key: UniqueKey(), // forces .go([same]) to trigger initState
                userId: state.uri.queryParameters['userId'],
                bookshelfId: state.uri.queryParameters['bookshelfId'],
                orderBy: state.uri.queryParameters['orderBy'],
                reverse: state.uri.queryParameters['reverse'],
              ),
            ),
            GoRoute(
              path: '/book/:bookId',
              builder: (context, state) =>
                  BookPage(bookId: state.pathParameters['bookId']!),
            ),
            GoRoute(
              path: '/book/:bookId/review',
              builder: (context, state) =>
                  ReviewPage(bookId: state.pathParameters['bookId']!),
            ),
            GoRoute(
              path: '/author',
              builder: (context, state) =>
                  AuthorPage(name: state.extra as String?),
            ),
          ],
        ),
      ],
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'Montserrat',
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final platform in TargetPlatform.values)
              platform: const NoTransitionsBuilder(),
          },
        ),
      ),
      routerConfig: goRouter,
    );
  }
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
