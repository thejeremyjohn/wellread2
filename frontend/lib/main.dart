// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  int _currentSortColumn = 0;
  bool _isAscending = true;
  late Future<List<Book>> futureBooks;

  @override
  void initState() {
    super.initState();
    futureBooks = fetchBooks();
  }

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
        child: FutureBuilder<List<Book>>(
          future: futureBooks,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Book> books = snapshot.data!;
              return SingleChildScrollView(
                child: DataTable(
                  sortColumnIndex: _currentSortColumn,
                  sortAscending: _isAscending,
                  columns: [
                    DataColumn(
                      label: Text(
                        'id',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onSort: (columnIndex, _) {
                        setState(() {
                          _currentSortColumn = columnIndex;
                          if (_isAscending == true) {
                            _isAscending = false;
                            books.sort(
                              (bookA, bookB) => bookA.id.compareTo(bookB.id),
                            );
                          } else {
                            _isAscending = true;
                            books.sort(
                              (bookA, bookB) => bookB.id.compareTo(bookA.id),
                            );
                          }
                        });
                      },
                    ),
                    DataColumn(
                      label: Text(
                        'cover',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'title',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onSort: (columnIndex, _) {
                        setState(() {
                          _currentSortColumn = columnIndex;
                          if (_isAscending == true) {
                            _isAscending = false;
                            books.sort(
                              (bookA, bookB) =>
                                  bookA.title.compareTo(bookB.title),
                            );
                          } else {
                            _isAscending = true;
                            books.sort(
                              (bookA, bookB) =>
                                  bookB.title.compareTo(bookA.title),
                            );
                          }
                        });
                      },
                    ),
                    DataColumn(
                      label: Text(
                        'author',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onSort: (columnIndex, _) {
                        setState(() {
                          _currentSortColumn = columnIndex;
                          if (_isAscending == true) {
                            _isAscending = false;
                            books.sort(
                              (bookA, bookB) =>
                                  bookA.author.compareTo(bookB.author),
                            );
                          } else {
                            _isAscending = true;
                            books.sort(
                              (bookA, bookB) =>
                                  bookB.author.compareTo(bookA.author),
                            );
                          }
                        });
                      },
                    ),
                  ],
                  rows: books.map((Book book) {
                    return DataRow(
                      cells: [
                        DataCell(Text(book.id.toString())),
                        DataCell(book.cover),
                        DataCell(Text(book.title)),
                        DataCell(Text(book.author)),
                      ],
                    );
                  }).toList(),
                ),
              );
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }
            // By default, show a loading spinner.
            return const CircularProgressIndicator();
          },
        ),
      ),
    );
  }
}

class Book {
  final int id;
  final String author;
  final String title;
  final List<dynamic> images;

  Book({
    required this.id,
    required this.author,
    required this.title,
    required this.images,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': int id,
        'author': String author,
        'title': String title,
        'images': List<dynamic> images,
      } =>
        Book(id: id, author: author, title: title, images: images),
      _ => throw const FormatException('Failed to load book.'),
    };
  }

  Image get cover => images.isEmpty
      ? Image.asset(width: 128, 'images/no-cover.png')
      : Image.network(width: 128, images.first['url']);
}

Future<List<Book>> fetchBooks() async {
  final response = await http.get(Uri.http('127.0.0.1:5000', '/books'));

  if (response.statusCode == 200) {
    Map<String, dynamic> resJson = jsonDecode(response.body);
    List<dynamic> booksJson = resJson['books'];
    return booksJson
        .map((bookJson) => Book.fromJson(bookJson as Map<String, dynamic>))
        .toList();
  } else {
    throw Exception('Failed to load books');
  }
}
