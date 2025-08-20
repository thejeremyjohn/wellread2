import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wellread2frontend/models/book.dart';
import 'package:wellread2frontend/pages/book_page.dart';
import 'package:wellread2frontend/widgets/clickable.dart';
import 'package:wellread2frontend/widgets/wellread_app_bar.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  int _currentSortColumn = 0;
  bool _isAscending = true;
  late Future<List<Book>> _futureBooks;

  @override
  void initState() {
    super.initState();
    _futureBooks = fetchBooks();
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
    return Scaffold(
      appBar: WellreadAppBar(),
      body: FutureBuilder<List<Book>>(
        future: _futureBooks,
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
                  Future gotoBookPage() {
                    return Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) => BookPage(book: book),
                      ),
                    );
                  }

                  return DataRow(
                    cells: [
                      DataCell(
                        Clickable(
                          onClick: () {
                            print('you clicked on cover of ${book.title}');
                            gotoBookPage();
                          },
                          child: book.cover128p,
                        ),
                      ),
                      DataCell(
                        Clickable(
                          onClick: () {
                            print('you clicked on ${book.title}');
                            gotoBookPage();
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
      ),
    );
  }
}
