import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/models/book.dart';
import 'package:wellread2frontend/widgets/clickable.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key, this.page, this.orderBy, this.reverse});
  final String? page;
  final String? orderBy;
  final String? reverse;

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  late int _page;
  late String _orderBy;
  late bool _reverse;
  late int _totalCount;

  final ScrollController _controller = ScrollController();
  final List<Book> _books = [];

  @override
  void initState() {
    super.initState();
    _page = (widget.page as int?) ?? 0;
    _orderBy = widget.orderBy ?? 'id';
    _reverse = bool.tryParse(widget.reverse ?? 'false')!;

    _controller.addListener(_scrollListener);
    fetchBooks();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  _scrollListener() {
    if (_controller.offset >= _controller.position.maxScrollExtent &&
        !_controller.position.outOfRange &&
        _books.length < _totalCount) {
      fetchBooks();
    }
  }

  Future<List<Book>> fetchBooks() async {
    Uri endpoint = flaskUri(
      '/books',
      queryParameters: {
        'per_page': '20',
        'page': (_page + 1).toString(),
        'order_by': _orderBy,
        'reverse': _reverse.toString(),
      },
    );
    final r = await flaskGet(endpoint);
    if (r.isOk) {
      List<Book> books = (r.data['books'] as List)
          .map((book) => Book.fromJson(book as Map<String, dynamic>))
          .toList();

      _books.addAll(books);
      _totalCount = r.data['total_count'] as int;
      _page = r.data['page'] as int;
      setState(() {});

      return books;
    } else {
      throw Exception(r.error);
    }
  }

  void fetchUntilScrollable() {
    /// attempting to load rows beyond the viewport
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_books.isNotEmpty &&
          _controller.hasClients &&
          _controller.position.hasContentDimensions &&
          _controller.position.maxScrollExtent == 0) {
        fetchBooks();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Book> books = _books;
    return Scaffold(
      body: SingleChildScrollView(
        controller: _controller,
        child: LayoutBuilder(
          builder: (context, constraints) {
            fetchUntilScrollable();

            List<String> columnLabels = ['id', 'cover', 'title', 'author'];

            return SizedBox(
              width: constraints.maxWidth,
              child: DataTable(
                sortColumnIndex: columnLabels.indexOf(_orderBy),
                sortAscending: !_reverse,
                columns: List.generate(columnLabels.length, (index) {
                  String columnLabel = columnLabels[index];

                  return DataColumn(
                    label: Text(
                      columnLabel,
                      style: TextStyle(
                        color: columnLabel != 'cover' ? kGreen : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    onSort: (_, __) {
                      // if column is already sorted, reverse sorting, else sort asc
                      _reverse = _orderBy == columnLabel ? !_reverse : false;
                      // push a new page, reload all books
                      context.push(
                        '/books?orderBy=$columnLabel&reverse=$_reverse',
                      );
                    },
                  );
                }),
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
              ),
            );
          },
        ),
      ),
    );
  }
}
