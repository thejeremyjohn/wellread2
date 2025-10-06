import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellread2frontend/flask_util/login_logout.dart';
import 'package:wellread2frontend/providers/theme_state.dart';
import 'package:wellread2frontend/providers/user_state.dart';
import 'package:wellread2frontend/widgets/search_books_bar.dart';

class WellreadAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WellreadAppBar({super.key});

  // width doesnt matter
  @override
  Size get preferredSize {
    return const Size(double.nan, kToolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'well', style: TextStyle()),
                TextSpan(
                  text: 'read',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.max,
            children: [
              IconButton(
                icon: const Icon(Icons.book),
                tooltip: 'My Books',
                onPressed: () {
                  final userId = context.read<UserState>().user.id;
                  context.go('/books?userId=$userId');
                },
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'Browse',
                onPressed: () => context.go('/books'),
              ),
              IconButton(
                icon: const Icon(Icons.person),
                tooltip: 'Profile',
                onPressed: () {
                  final userId = context.read<UserState>().user.id;
                  context.go('/profile/$userId');
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Logout',
                onPressed: () => logout(),
              ),
            ],
          ),
          Container(),
        ],
      ),
      actions: [
        SizedBox(width: 150, child: SearchBooksBar()),
        Consumer<ThemeState>(
          builder: (context, theme, child) {
            return IconButton(
              icon: Icon(theme.isDarkMode ? Icons.dark_mode : Icons.light_mode),
              tooltip: 'Toggle Dark Mode',
              onPressed: () => theme.toggleDarkMode(),
            );
          },
        ),
      ],
    );
  }
}
