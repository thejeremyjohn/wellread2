import 'package:flutter/material.dart';
import 'package:wellread2frontend/flask_util/login_logout.dart';

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
                  print('You clicked My Books');
                },
              ),
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                tooltip: 'Browse',
                onPressed: () async {
                  print('You clicked Browse');
                },
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
                onPressed: () {
                  print('You clicked logout');
                  logout();
                },
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
          ),
        ),
      ],
    );
  }
}
