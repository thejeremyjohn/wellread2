import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/models/book.dart';
import 'package:wellread2frontend/models/bookshelf.dart';
import 'package:wellread2frontend/models/user.dart';
import 'package:wellread2frontend/providers/user_state.dart';
import 'package:wellread2frontend/widgets/async_widget.dart';
import 'package:wellread2frontend/widgets/link_text.dart';
import 'package:wellread2frontend/widgets/spacer_body.dart';

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
  late Future<User> _futureUser;
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
    if (widget.userId != null) _futureUser = userGet();
    _futureBookshelves = fetchBookshelves();
    _orderBy = widget.orderBy ?? 'avgRating';
    _reverse = bool.tryParse(widget.reverse ?? 'true')!;
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

  Future<User> userGet() async {
    User me = context.read<UserState>().user;
    if (widget.userId == me.id.toString()) return me;

    Uri endpoint = flaskUri('/users', queryParameters: {'id': widget.userId!});
    final r = await flaskGet(endpoint);
    if (!r.isOk) throw Exception(r.error);

    return (r.data['users'] as List)
        .map((shelf) => User.fromJson(shelf as Map<String, dynamic>))
        .first;
  }

  Future<List<Bookshelf>> fetchBookshelves({int page = 1}) async {
    Uri endpoint = flaskUri(
      '/bookshelves',
      queryParameters: {
        'user_id': widget.userId != null
            ? widget.userId!
            : context.read<UserState>().user.id.toString(),
        'order_by': 'can_delete',
        'page': page.toString(),
        'per_page': '100',
      },
      addProps: ['n_books'],
    );

    final r = await flaskGet(endpoint);
    if (!r.isOk) throw Exception(r.error);

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
    if (!r.isOk) throw Exception(r.error);

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
  }

  @override
  Widget build(BuildContext context) {
    return SpacerBody(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final headerStyle = Theme.of(context).textTheme.bodyLarge!.copyWith(
            fontFamily: fontFamilyAlt,
            fontWeight: FontWeight.w600,
          );

          return ListView(
            padding: EdgeInsets.all(kPadding),
            children: [
              Container(
                margin: EdgeInsets.all(kPadding),
                child: widget.userId == null
                    ? Text('All Books', style: headerStyle)
                    : AsyncWidget<User>(
                        future: _futureUser,
                        builder: (context, user) => Row(
                          spacing: kPadding,
                          children: [
                            Text(
                              '${user.firstName}\'s Books',
                              style: headerStyle,
                            ),
                            widget.bookshelfId == null
                                ? Container()
                                : AsyncWidget<List<Bookshelf>>(
                                    future: _futureBookshelves,
                                    builder: (context, bookshelves) {
                                      int? aId = int.parse(widget.bookshelfId!);
                                      final shelf = bookshelves.firstWhere(
                                        (b) => aId == b.id,
                                      );
                                      return Text(
                                        '> ${shelf.name}',
                                        style: headerStyle.copyWith(
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                          ],
                        ),
                      ),
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.all(kPadding),
                    width: constraints.maxWidth * myShelvesWidthModifier,
                    child: AsyncWidget<List<Bookshelf>>(
                      future: _futureBookshelves,
                      builder: (context, bookshelves) {
                        Iterable<Bookshelf> shelves = bookshelves.take(3);
                        List<Bookshelf> tags = bookshelves
                            .skip(3)
                            .toSet()
                            .toList();
                        tags.sort((a, b) => a.name.compareTo(b.name));
                        String meId = context
                            .read<UserState>()
                            .user
                            .id
                            .toString();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Bookshelves',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            LinkText(
                              'From All Shelves (${shelves.map((s) => s.nBooks!).reduce((a, b) => a + b)})',
                              style:
                                  widget.userId != null &&
                                      widget.bookshelfId == null
                                  ? TextStyle(color: Colors.grey)
                                  : TextStyle(),
                              onClick: () {
                                Router.neglect(
                                  context,
                                  () => context.go(
                                    '/books?userId=${widget.userId ?? meId}',
                                  ),
                                );
                              },
                            ),
                            ...shelves.map(
                              (shelf) => ShelfRow(
                                shelf: shelf,
                                isSelected:
                                    shelf.id.toString() == widget.bookshelfId,
                                userId: widget.userId ?? meId,
                              ),
                            ),
                            Divider(height: kPadding),
                            ...tags.map(
                              (tag) => ShelfRow(
                                shelf: tag,
                                isSelected:
                                    tag.id.toString() == widget.bookshelfId,
                                userId: widget.userId ?? meId,
                              ),
                            ),
                            SizedBox(height: kPadding * 0.5),
                            widget.userId == meId
                                ? AddShelf(
                                    onAdd: (tagName) =>
                                        tagCreate(context, tagName),
                                  )
                                : Container(),
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
                                    key: Key('nearBottomBook'),
                                    onVisibilityChanged: (v) {
                                      if (v.visibleFraction > 0) booksGetMore();
                                    },
                                    child: Text(book.title),
                                  ),
                          ),
                          DataCell(
                            Text(book.author),
                            onTap: () {
                              context.go('/author', extra: book.author);
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
                              onRatingUpdate: (rating) {},
                              ignoreGestures: true,
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
    this.isSelected = false,
    this.userId,
    this.style = const TextStyle(),
  });

  final Bookshelf shelf;
  final bool isSelected;
  final String? userId;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LinkText(
      '${shelf.name} (${shelf.nBooks})',
      style: isSelected ? TextStyle(color: Colors.grey) : TextStyle(),
      onClick: () {
        Router.neglect(context, () {
          Map<String, String> queryParameters = {'bookshelfId': '${shelf.id}'};
          if (userId != null) queryParameters['userId'] = userId!;
          Uri loc = Uri(path: '/books', queryParameters: queryParameters);
          context.go(loc.toString());
        });
      },
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
