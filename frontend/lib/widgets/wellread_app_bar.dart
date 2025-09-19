import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellread2frontend/flask_util/login_logout.dart';
import 'package:wellread2frontend/providers/user_state.dart';

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
      backgroundColor: Colors.brown,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('wellread'),
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
                  print('You clicked Profile');
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
        SizedBox(
          width: 200,
          child: TextFormField(
            decoration: InputDecoration(
              border: UnderlineInputBorder(),
              labelText: 'Search books',
              suffixIcon: Icon(Icons.search),
            ),
            // onEditingComplete: , TODO search books
          ),
        ),
      ],
    );
  }
}
