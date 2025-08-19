import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:math'; // TODO rm

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const MyHomePage(title: 'wellread'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Generate a list of fiction prodcts
  // placeholder from https://www.kindacode.com/article/flutter-datatable
  final List<Map> _products = List.generate(30, (i) {
    return {"id": i, "name": "Product $i", "price": Random().nextInt(200) + 1};
  });

  int _currentSortColumn = 0;
  bool _isAscending = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.brown,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.title),
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
      ),
      body: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          child: DataTable(
            sortColumnIndex: _currentSortColumn,
            sortAscending: _isAscending,
            headingRowColor: WidgetStateProperty.all(Colors.amber[200]),
            columns: [
              sortableDataColumn('ID', 'id'),
              sortableDataColumn('Name', 'name'),
              sortableDataColumn('Price', 'price'),
            ],
            rows: _products.map((item) {
              return DataRow(
                cells: [
                  DataCell(Text(item['id'].toString())),
                  DataCell(Text(item['name'])),
                  DataCell(Text(item['price'].toString())),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  DataColumn sortableDataColumn(String labelText, String sortKey) {
    return DataColumn(
      label: Text(
        labelText,
        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      ),
      onSort: (columnIndex, _) {
        setState(() {
          _currentSortColumn = columnIndex;
          if (_isAscending == true) {
            _isAscending = false;
            // sort the product list in Ascending, order by sortKey
            _products.sort(
              (productA, productB) =>
                  productB[sortKey].compareTo(productA[sortKey]),
            );
          } else {
            _isAscending = true;
            // sort the product list in Descending, order by sortKey
            _products.sort(
              (productA, productB) =>
                  productA[sortKey].compareTo(productB[sortKey]),
            );
          }
        });
      },
    );
  }
}
