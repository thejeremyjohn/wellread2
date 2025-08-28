import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/models/book.dart';
import 'package:wellread2frontend/widgets/async_widget.dart';
import 'package:wellread2frontend/widgets/clickable.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  int _currentSortColumn = 0;
  bool _isAscending = true;
  String _orderBy = 'id';
  int _page = 0;
  late int _totalCount;
  late Future<List<Book>> _futureBooks;
  final List<Book> _allBooks = [];
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    scrollController.addListener(_scrollListener);
    _futureBooks = fetchBooks();
  }

  // @override
  // void dispose() {
  //   scrollController.removeListener(_scrollListener);
  //   scrollController.dispose();
  //   super.dispose();
  // }

  _scrollListener() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent &&
        !scrollController.position.outOfRange &&
        _allBooks.length < _totalCount) {
      fetchBooks();
    }
  }

  Future<List<Book>> fetchBooks() async {
    Uri endpoint = flaskUri(
      '/books',
      queryParameters: {
        'per_page': '10',
        'page': (_page + 1).toString(),
        'order_by': _orderBy,
      },
    );
    final r = await flaskGet(endpoint);
    if (r.isOk) {
      List<Book> books = (r.data['books'] as List)
          .map((book) => Book.fromJson(book as Map<String, dynamic>))
          .toList();

      _allBooks.addAll(books);
      _totalCount = r.data['total_count'] as int;
      _page = r.data['page'] as int;
      setState(() {});

      return books;
    } else {
      throw Exception(r.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Book> books = _allBooks;
    return Scaffold(
      body: SingleChildScrollView(
        controller: scrollController,
        child: AsyncWidget(
          future: _futureBooks,
          builder: (context, __) {
            if (scrollController.position.maxScrollExtent == 0) fetchBooks();

            return DataTable(
              sortColumnIndex: _currentSortColumn,
              sortAscending: _isAscending,
              columns: [
                DataColumn(
                  label: Text(
                    'id',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                  onSort: (columnIndex, sortAscending) {
                    // TODO reload this route (with &orderBy=title in the path). pre-req: modified goRoute
                    // TODO FIXME spams requests when clicked 3 times
                    _isAscending = !_isAscending;
                    // _isAscending = sortAscending;
                    _currentSortColumn = columnIndex;
                    _orderBy = 'title';
                    _allBooks.clear();
                    // setState(() {});
                    _futureBooks = fetchBooks();
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
                    DataCell(
                      Clickable(
                        onClick: () => context.go('/book/${book.id}'),
                        child: book.cover128p,
                      ),
                    ),
                    DataCell(
                      Clickable(
                        onClick: () => context.go('/book/${book.id}'),
                        child: Text(book.title),
                      ),
                    ),
                    DataCell(Text(book.author)),
                  ],
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}
