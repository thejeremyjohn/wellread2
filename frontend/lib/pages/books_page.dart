import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/models/book.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key, this.page, this.orderBy, this.reverse});
  final String? page; // TODO? remove page as it is not passed to goRoute path
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

  bool _isScrollable = false;
  final ScrollController _controller = ScrollController();
  final List<Book> _books = [];

  @override
  void initState() {
    super.initState();
    _page = (widget.page as int?) ?? 0;
    _orderBy = widget.orderBy ?? 'title';
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

  List<String> columnLabels = [
    'cover',
    'title',
    'author',
    'avgRating',
    'myRating',
  ];
  // ignore: non_constant_identifier_names
  List<String?> order_byLookup = [
    null, // 'cover',
    'title',
    'author',
    'avg_rating',
    'my_rating',
  ];
  List<double?> widthModifiers = [
    0.1, // 'cover',
    null, // 'title',
    0.15, // 'author',
    0.15, // 'avgRating',
    0.15, // 'myRating',
  ];
  double myShelvesWidthModifier = 0.15;
  double dataRowHeight = 128;

  Future<List<Book>> fetchBooks() async {
    Uri endpoint = flaskUri(
      '/books',
      queryParameters: {
        'per_page': '20',
        'page': (_page + 1).toString(),
        'order_by': order_byLookup[columnLabels.indexOf(_orderBy)],
        'reverse': _reverse.toString(),
      },
      addProps: ['avg_rating', 'my_rating', 'my_shelves'],
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

  @override
  void didUpdateWidget(covariant BooksPage oldWidget) {
    fetchUntilScrollable();
    super.didUpdateWidget(oldWidget);
  }

  void fetchUntilScrollable() {
    /// attempting to load rows beyond the viewport
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isScrollable &&
          // _books.isNotEmpty &&
          _controller.hasClients &&
          _controller.position.hasContentDimensions &&
          _controller.position.maxScrollExtent == 0) {
        fetchBooks(); // calls setState
      } else {
        setState(() => _isScrollable = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            padding: EdgeInsets.all(kPadding),
            controller: _controller,
            children: [
              Container(
                margin: EdgeInsets.all(kPadding),
                child: Text(
                  'My Books',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                    fontFamily: 'LibreBaskerville',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.all(kPadding),
                    width: constraints.maxWidth * myShelvesWidthModifier,
                    child: Text('[My Shelves]', textAlign: TextAlign.center),
                  ),
                  Expanded(
                    child: DataTable(
                      horizontalMargin: 0,
                      columnSpacing: kPadding,
                      dataRowMinHeight: dataRowHeight,
                      dataRowMaxHeight: dataRowHeight,
                      sortColumnIndex: columnLabels.indexOf(_orderBy),
                      sortAscending: !_reverse,
                      showCheckboxColumn: false,
                      columns: List.generate(columnLabels.length, (index) {
                        String columnLabel = columnLabels[index];
                        bool canSort = order_byLookup[index] != null;

                        return DataColumn(
                          columnWidth: widthModifiers[index] == null
                              ? null
                              : FixedColumnWidth(
                                  constraints.maxWidth * widthModifiers[index]!,
                                ),
                          label: Text(
                            columnLabel,
                            style: TextStyle(
                              color: canSort ? kGreen : null,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          onSort: canSort
                              ? (_, __) {
                                  // if column is already sorted, reverse sorting, else sort asc
                                  _reverse = columnLabel == _orderBy
                                      ? !_reverse
                                      : false;
                                  // refresh page with new arguments and without nav history
                                  Router.neglect(
                                    context,
                                    () => context.go(
                                      '/books?orderBy=$columnLabel&reverse=$_reverse',
                                    ),
                                  );
                                }
                              : null,
                        );
                      }),
                      rows: _books.map((Book book) {
                        return DataRow(
                          onSelectChanged: (value) =>
                              context.go('/book/${book.id}'),
                          cells: [
                            DataCell(
                              Container(
                                margin: EdgeInsets.symmetric(
                                  vertical: kPadding,
                                ),
                                child: book.cover,
                              ),
                            ),
                            DataCell(Text(book.title)),
                            DataCell(
                              Text(book.author),
                              onTap: () => print('`${book.author}` clicked'),
                            ),
                            DataCell(Text(book.avgRatingString!)),
                            DataCell(
                              RatingBar.builder(
                                initialRating: book.myRating!,
                                minRating: 1,
                                itemSize: Theme.of(
                                  context,
                                ).textTheme.bodyMedium!.fontSize!,
                                itemBuilder: (context, idx) =>
                                    Icon(Icons.star, color: Colors.amber),
                                onRatingUpdate: (rating) {
                                  // TODO review_update
                                },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
