import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wellread2frontend/models/book.dart';
import 'package:wellread2frontend/pages/second_route.dart';
import 'package:wellread2frontend/widgets/clickable.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  int _currentSortColumn = 0;
  bool _isAscending = true;
  late Future<List<Book>> futureBooks;

  @override
  void initState() {
    super.initState();
    futureBooks = fetchBooks();
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Book>>(
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
                          (bookA, bookB) => bookA.title.compareTo(bookB.title),
                        );
                      } else {
                        _isAscending = true;
                        books.sort(
                          (bookA, bookB) => bookB.title.compareTo(bookA.title),
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
                    DataCell(
                      Clickable(
                        onClick: () {
                          print('you clicked on ${book.title}');
                          // TODO navigate to book page
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (context) => const SecondRoute(),
                            ),
                          );
                        },
                        child: book.cover,
                      ),
                    ),
                    DataCell(
                      Clickable(
                        onClick: () {
                          print('you clicked on ${book.title}');
                          // TODO navigate to book page
                        },
                        child: Text(book.title),
                      ),
                    ),
                    DataCell(Text(book.author)),
                  ],
                );
              }).toList(),
            ),
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
