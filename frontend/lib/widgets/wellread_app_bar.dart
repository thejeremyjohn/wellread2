import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
                  var url = Uri.http('127.0.0.1:5000', '/books');
                  http.Response response = await http.get(
                    url,
                    // headers: { HttpHeaders.authorizationHeader: token != null ? "Bearer $token" : null },
                  );

                  print(response.body);
                },
              ),
              IconButton(
                icon: const Icon(Icons.person),
                tooltip: 'Profile',
                onPressed: () {
                  print('You clicked Profile');
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
