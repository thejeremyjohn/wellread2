import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/models/book.dart';
import 'package:wellread2frontend/models/bookshelf.dart';
import 'package:wellread2frontend/providers/user_state.dart';
import 'package:wellread2frontend/widgets/async_widget.dart';
import 'package:wellread2frontend/widgets/clickable.dart';
import 'package:wellread2frontend/widgets/text_underline_on_hover.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({
    super.key,
    this.userId,
    this.bookshelfId,
    this.orderBy,
    this.reverse,
  });
  final String? userId;
  final String? bookshelfId;
  final String? orderBy;
  final String? reverse;

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  late Future<List<Bookshelf>> _futureBookshelves;
  int _page = 1;
  final int _perPage = 20;
  late String _orderBy;
  late bool _reverse;
  final List<Book> _books = [];
  bool _isGettingMore = false;
  bool _isAllGot = false;

  @override
  void initState() {
    super.initState();
    _futureBookshelves = fetchBookshelves();
    _orderBy = widget.orderBy ?? 'title';
    _reverse = bool.tryParse(widget.reverse ?? 'false')!;
    booksGet();
  }

  Future<void> booksGetMore() async {
    if (!_isAllGot && !_isGettingMore) {
      setState(() => _isGettingMore = true);
      await booksGet();
      setState(() => _isGettingMore = false);
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
    0.2, // 'title',
    0.15, // 'author',
    0.15, // 'avgRating',
    0.15, // 'myRating',
  ];
  double myShelvesWidthModifier = 0.15;
  double dataRowHeight = 128;

  Future<List<Bookshelf>> fetchBookshelves({int page = 1}) async {
    Uri endpoint = flaskUri(
      '/bookshelves',
      queryParameters: {
        'user_id': context.read<UserState>().user.id.toString(),
        'order_by': 'can_delete',
        'page': page.toString(),
        'per_page': '100',
      },
      addProps: ['n_books'],
    );
    final r = await flaskGet(endpoint);
    if (r.isOk) {
      List<Bookshelf> fetched = (r.data['bookshelves'] as List)
          .map((shelf) => Bookshelf.fromJson(shelf as Map<String, dynamic>))
          .toList();

      if (fetched.isNotEmpty) {
        _futureBookshelves.then((fetchedSoFar) {
          page = (r.data['page'] as int) + 1;
          fetchBookshelves(page: page).then((subsequentFetch) {
            fetchedSoFar.addAll(subsequentFetch);
            setState(() {});
          });
        });
      }

      return fetched;
    } else {
      throw Exception(r.error);
    }
  }

  Future<Bookshelf> tagCreate(BuildContext context, String name) async {
    Uri endpoint = flaskUri(
      '/bookshelf',
      queryParameters: {},
      addProps: ['n_books'],
    );
    final r = await flaskPost(endpoint, body: {'name': name});
    if (r.isOk) {
      Bookshelf tag = Bookshelf.fromJson(
        r.data['bookshelf'] as Map<String, dynamic>,
      );
      _futureBookshelves.then((bookshelves) => bookshelves.add(tag));
      setState(() {});
      return tag;
    } else {
      if (context.mounted) r.showSnackBar(context);
      throw Exception(r.error);
    }
  }

  Future<List<Book>> booksGet() async {
    Map<String, String> queryParameters = {
      'page': _page.toString(),
      'per_page': _perPage.toString(),
      'order_by': order_byLookup[columnLabels.indexOf(_orderBy)]!,
      'reverse': _reverse.toString(),
    };
    if (widget.userId != null) {
      queryParameters['user_id'] = widget.userId!;
    }
    if (widget.bookshelfId != null) {
      queryParameters['bookshelf_id'] = widget.bookshelfId!;
    }

    Uri endpoint = flaskUri(
      '/books',
      queryParameters: queryParameters,
      addProps: ['avg_rating', 'my_rating', 'my_shelves'],
    );
    final r = await flaskGet(endpoint);
    if (r.isOk) {
      List<Book> fetched = (r.data['books'] as List)
          .map((book) => Book.fromJson(book as Map<String, dynamic>))
          .toList();

      if (fetched.isEmpty) {
        _isAllGot = true;
      } else {
        _books.addAll(fetched);
        _page = (r.data['page'] as int) + 1;
      }
      setState(() {});

      return fetched;
    } else {
      throw Exception(r.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ListView(
            padding: EdgeInsets.all(kPadding),
            children: [
              Container(
                margin: EdgeInsets.all(kPadding),
                child: Text(
                  // TODO conditional So-and-so's Books
                  '${context.watch<UserState>().user.firstName}\'s Books',
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
                    child: AsyncWidget(
                      future: _futureBookshelves,
                      builder: (context, bookshelves) {
                        Iterable<Bookshelf> shelves = bookshelves.take(3);
                        List<Bookshelf> tags = bookshelves
                            .skip(3)
                            .toSet()
                            .toList();
                        tags.sort((a, b) => a.name.compareTo(b.name));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Bookshelves',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Clickable(
                              onClick: () {
                                Router.neglect(context, () {
                                  final userId = context
                                      .read<UserState>()
                                      .user
                                      .id;
                                  context.go('/books?userId=$userId');
                                });
                              },
                              child: TextUnderlineOnHover(
                                'All (${shelves.map((s) => s.nBooks!).reduce((a, b) => a + b)})',
                                style: widget.userId != null
                                    ? TextStyle(color: Colors.grey)
                                    : TextStyle(),
                              ),
                            ),
                            ...shelves.map(
                              (s) => ShelfRow(
                                shelf: s,
                                style: s.id.toString() == widget.bookshelfId
                                    ? TextStyle(color: Colors.grey)
                                    : TextStyle(),
                              ),
                            ),
                            Divider(height: kPadding),
                            ...tags.map(
                              (s) => ShelfRow(
                                shelf: s,
                                style: s.id.toString() == widget.bookshelfId
                                    ? TextStyle(color: Colors.grey)
                                    : TextStyle(),
                              ),
                            ),
                            SizedBox(height: kPadding * 0.5),
                            AddShelf(
                              onAdd: (tagName) => tagCreate(context, tagName),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  DataTable(
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
                                Router.neglect(context, () {
                                  Map<String, String> queryParameters = {
                                    'orderBy': columnLabel,
                                    'reverse': '$_reverse',
                                  };
                                  if (widget.userId != null) {
                                    queryParameters['userId'] = widget.userId!;
                                  }
                                  if (widget.bookshelfId != null) {
                                    queryParameters['bookshelfId'] =
                                        widget.bookshelfId!;
                                  }
                                  context.go(
                                    Uri(
                                      path: '/books',
                                      queryParameters: queryParameters,
                                    ).toString(),
                                  );
                                });
                              }
                            : null,
                      );
                    }),
                    rows: List.generate(_books.length, (index) {
                      Book book = _books[index];

                      return DataRow(
                        onSelectChanged: (value) =>
                            context.go('/book/${book.id}'),
                        cells: [
                          DataCell(
                            Container(
                              margin: EdgeInsets.symmetric(vertical: kPadding),
                              child: book.coverThumb,
                            ),
                          ),
                          DataCell(
                            index != _books.length - 5
                                ? Text(book.title)
                                : VisibilityDetector(
                                    key: Key('nearBottom'),
                                    onVisibilityChanged: (v) {
                                      if (v.visibleFraction > 0) booksGetMore();
                                    },
                                    child: Text(book.title),
                                  ),
                          ),
                          DataCell(
                            Text(book.author),
                            onTap: () {
                              print('`${book.author}` clicked');
                              // TODO goto AuthorPage
                            },
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
                    }),
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

class ShelfRow extends StatelessWidget {
  const ShelfRow({
    super.key,
    required this.shelf,
    this.style = const TextStyle(),
  });

  final Bookshelf shelf;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onClick: () {
        Router.neglect(
          context,
          () => context.go('/books?bookshelfId=${shelf.id}'),
        );
      },
      child: TextUnderlineOnHover(
        '${shelf.name} (${shelf.nBooks})',
        style: style,
      ),
    );
  }
}

class AddShelf extends StatefulWidget {
  const AddShelf({super.key, required this.onAdd});
  final Future Function(String) onAdd;

  @override
  State<AddShelf> createState() => _AddShelfState();
}

class _AddShelfState extends State<AddShelf> {
  bool _firstClicked = false;
  void submitFirstForm() {
    setState(() => _firstClicked = true);
  }

  final TextEditingController _controller = TextEditingController();
  void submitSecondForm() {
    widget.onAdd(_controller.text).then((_) {
      _controller.clear();
      _firstClicked = false;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return !_firstClicked
        ? ElevatedButton(onPressed: submitFirstForm, child: Text('Add shelf'))
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: kPadding),
              Text(
                'Add a Shelf:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 100,
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        border: OutlineInputBorder(borderSide: BorderSide()),
                      ),
                      onSubmitted: (_) => submitSecondForm(),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: submitSecondForm,
                    child: Text('add'),
                  ),
                ],
              ),
            ],
          );
  }
}
