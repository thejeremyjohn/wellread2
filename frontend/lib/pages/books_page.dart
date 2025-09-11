import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/models/book.dart';
import 'package:wellread2frontend/models/bookshelf.dart';
import 'package:wellread2frontend/providers/user_state.dart';
import 'package:wellread2frontend/widgets/async_widget.dart';
import 'package:wellread2frontend/widgets/clickable.dart';
import 'package:wellread2frontend/widgets/text_underline_on_hover.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key, this.page, this.orderBy, this.reverse});
  final String? page; // TODO? remove page as it is not passed to goRoute path
  final String? orderBy;
  final String? reverse;

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  late int _myUserId;
  late Future<List<Bookshelf>> _futureBookshelves;
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
    _myUserId = context.read<UserState>().user.id;
    _futureBookshelves = fetchBookshelves();
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

  Future<List<Bookshelf>> fetchBookshelves({int page = 1}) async {
    Uri endpoint = flaskUri(
      '/bookshelves',
      queryParameters: {
        'user_id': _myUserId.toString(),
        'order_by': 'can_delete',
        'page': page.toString(),
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
    fetchBooksUntilScrollable();
    super.didUpdateWidget(oldWidget);
  }

  void fetchBooksUntilScrollable() {
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
                        List<Bookshelf> tags = bookshelves.skip(3).toList();
                        tags.sort((a, b) => a.name.compareTo(b.name));

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Bookshelves',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'All (${shelves.map((s) => s.nBooks!).reduce((a, b) => a + b)})',
                              style: TextStyle(color: Colors.grey),
                            ),
                            ...shelves.map((s) => ShelfRow(shelf: s)),
                            Divider(height: kPadding),
                            ...tags.map((s) => ShelfRow(shelf: s)),
                            SizedBox(height: kPadding * 0.5),
                            AddShelf(
                              onAdd: (tagName) => tagCreate(context, tagName),
                            ),
                          ],
                        );
                      },
                    ),
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

class ShelfRow extends StatelessWidget {
  const ShelfRow({super.key, required this.shelf});

  final Bookshelf shelf;

  @override
  Widget build(BuildContext context) {
    return Clickable(
      onClick: () {
        // TODO goto ShelfPage
      },
      child: TextUnderlineOnHover('${shelf.name} (${shelf.nBooks})'),
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
