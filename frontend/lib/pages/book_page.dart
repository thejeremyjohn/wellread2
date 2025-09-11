import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/models/book.dart';
import 'package:wellread2frontend/models/bookshelf.dart';
import 'package:wellread2frontend/models/review.dart';
import 'package:wellread2frontend/providers/user_state.dart';
import 'package:wellread2frontend/widgets/async_widget.dart';
import 'package:wellread2frontend/widgets/clickable.dart';
import 'package:wellread2frontend/widgets/column_dialog.dart';
import 'package:wellread2frontend/widgets/rows_as_needed.dart';
import 'package:wellread2frontend/widgets/underline.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key, required this.bookId});
  final String bookId;

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  late int _myUserId;
  late Future<Book> _futureBook;
  late Future<List<Review>> _futureReviews;
  late Future<List<Bookshelf>> _futureBookshelves;
  late String? _shelvedAt;
  double _myRating = 0;
  final _addTagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _myUserId = context.read<UserState>().user.id;
    _futureBook = fetchBook();
    _futureReviews = fetchReviews();
    _futureBookshelves = fetchBookshelves();
  }

  @override
  void dispose() {
    _addTagsController.dispose();
    super.dispose();
  }

  Future<Book> fetchBook() async {
    Uri endpoint = flaskUri(
      '/books',
      queryParameters: {'id': widget.bookId},
      addProps: [
        'avg_rating',
        'my_rating',
        'my_shelves',
        'n_reviews',
        'n_ratings',
      ],
    );

    final r = await flaskGet(endpoint);
    if (r.isOk) {
      Book book = (r.data['books'] as List)
          .map((book) => Book.fromJson(book as Map<String, dynamic>))
          .first;
      setState(() {
        _shelvedAt = book.myShelves!.isNotEmpty
            ? book.myShelves!.first.name
            : null;
        _myRating = book.myRating!;
      });
      return book;
    } else {
      throw Exception(r.error);
    }
  }

  Future<List<Review>> fetchReviews() async {
    Uri endpoint = flaskUri(
      '/reviews',
      queryParameters: {'book_id': widget.bookId},
      addProps: ['shelves', 'user_'],
    );
    final r = await flaskGet(endpoint);
    if (r.isOk) {
      return (r.data['reviews'] as List)
          .map((review) => Review.fromJson(review as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(r.error);
    }
  }

  Future<List<Bookshelf>> fetchBookshelves({int page = 1}) async {
    Uri endpoint = flaskUri(
      '/bookshelves',
      queryParameters: {
        'user_id': _myUserId.toString(),
        'order_by': 'can_delete',
        'page': page.toString(),
      },
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

  Future<Review> reviewCreateOrUpdate({
    required int rating,
    String? content,
  }) async {
    Uri endpoint = flaskUri('/review');
    Map<String, dynamic> body = {
      'book_id': widget.bookId.toString(),
      'rating': rating.toString(),
    };
    if (content != null) body['content'] = content;
    var flaskMethod = _myRating == 0 ? flaskPost : flaskPut;
    final r = await flaskMethod(endpoint, body: body);
    if (r.isOk) {
      Review review = Review.fromJson(r.data['review'] as Map<String, dynamic>);
      setState(() => _myRating = review.rating.toDouble());

      if (_shelvedAt == null) {
        _futureBookshelves.then((bookshelves) {
          addToShelf(bookshelves.firstWhere((s) => s.name == 'read').id);
        });
      }

      return review;
    } else {
      throw Exception(r.error);
    }
  }

  Future<Bookshelf> bookshelfAddOrRemoveBook(
    int bookshelfId,
    String method, {
    bool deleteTags = false,
  }) async {
    var flaskMethod = method == 'POST' ? flaskPost : flaskDelete;
    Uri endpoint = flaskUri(
      '/bookshelf/$bookshelfId/book/${widget.bookId}',
      queryParameters: {'delete_tags': deleteTags.toString()},
    );
    final r = await flaskMethod(endpoint);
    if (r.isOk) {
      return Bookshelf.fromJson(r.data['bookshelf'] as Map<String, dynamic>);
    } else {
      throw Exception(r.error);
    }
  }

  Future<String?> addToShelf(int bookshelfId) async {
    var shelf = await bookshelfAddOrRemoveBook(bookshelfId, 'POST');
    setState(() => _shelvedAt = shelf.name);
    return _shelvedAt;
  }

  Future<String?> removeFromShelf(
    int bookshelfId, {
    bool hide = false,
    bool deleteTags = false,
  }) async {
    await bookshelfAddOrRemoveBook(
      bookshelfId,
      'DELETE',
      deleteTags: deleteTags,
    );
    if (!hide) setState(() => _shelvedAt = null);
    return _shelvedAt;
  }

  Future<Bookshelf> tagCreate(BuildContext context, String name) async {
    Uri endpoint = flaskUri('/bookshelf');
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

  @override
  Widget build(BuildContext context) {
    Widget shelfButtonDialogs(Book book) => AsyncWidget(
      future: _futureBookshelves,
      builder: (context, awaitedData) {
        Iterable<Bookshelf> shelves = awaitedData.take(3);
        List<Bookshelf> tags = awaitedData.skip(3).toList();

        Future<void> sweepingRemoveFromShelf({
          bool hide = false,
          bool deleteTags = false,
        }) async {
          for (var shelf in shelves) {
            if (_shelvedAt == shelf.name) {
              await removeFromShelf(
                shelf.id,
                hide: hide,
                deleteTags: deleteTags,
              );
            }
          }
        }

        void changeEssentialShelf(
          Bookshelf shelf,
          StateSetter stateSetter, {
          bool deleteTags = false,
        }) {
          if (_shelvedAt != shelf.name) {
            sweepingRemoveFromShelf(
              hide: true,
              deleteTags: deleteTags,
            ).then((_) => addToShelf(shelf.id)).then((_) => stateSetter(() {}));
          }
        }

        void removeFromEssentialShelf(Book book) {
          sweepingRemoveFromShelf(hide: false, deleteTags: true).then((_) {
            book.myShelves!.clear();
            setState(() => _myRating = 0);
            if (context.mounted) context.pop();
          });
        }

        void addTag(StateSetter stateSetter) async {
          tags.add(await tagCreate(context, _addTagsController.text));
          stateSetter(() {});
        }

        void toggleTag(Bookshelf tag, bool isTagged, StateSetter stateSetter) {
          bookshelfAddOrRemoveBook(tag.id, isTagged ? 'DELETE' : 'POST').then((
            shelf,
          ) {
            isTagged
                ? book.myShelves!.remove(shelf)
                : book.myShelves!.add(shelf);
            stateSetter(() {});
          });
        }

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(kGreen),
            ),
            onPressed: () => showDialog<String>(
              context: context,
              builder: (BuildContext context) {
                return StatefulBuilder(
                  builder: (context, dSetState) => ColumnDialog(
                    children: <Widget>[
                      Text('Choose a shelf for this book'),
                      ...shelves.map((shelf) {
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () =>
                                changeEssentialShelf(shelf, dSetState),
                            label: Text(shelf.name),
                            icon: _shelvedAt == shelf.name
                                ? Icon(Icons.check)
                                : null,
                          ),
                        );
                      }),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _shelvedAt == null
                              ? null
                              : () => showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return ColumnDialog(
                                      children: <Widget>[
                                        Text(
                                          'Are you sure you want to remove this book from your shelves?',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge!
                                              .copyWith(
                                                fontFamily: 'LibreBaskerville',
                                              ),
                                        ),
                                        const Text(
                                          'Removing this book will clear associated ratings, reviews, and tags.',
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: <Widget>[
                                            ElevatedButton(
                                              onPressed: () => context.pop(),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                removeFromEssentialShelf(book);
                                                context.pop();
                                              },
                                              child: const Text('Remove'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
                                ),
                          style: ElevatedButton.styleFrom(
                            iconColor: Colors.red,
                          ),
                          label: const Text('Remove from my shelf'),
                          icon: Icon(Icons.remove_circle_outline),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _shelvedAt == null
                              ? null
                              : () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => StatefulBuilder(
                                      builder: (context, dSetState) => ColumnDialog(
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            spacing: kPadding,
                                            children: <Widget>[
                                              SizedBox(
                                                width: 200,
                                                height: kTextTabBarHeight,
                                                child: TextField(
                                                  controller:
                                                      _addTagsController,
                                                  decoration: InputDecoration(
                                                    labelText: 'Add tags',
                                                    border: OutlineInputBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            kTextTabBarHeight *
                                                                0.5,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                height: kTextTabBarHeight,
                                                child: ElevatedButton(
                                                  onPressed: () =>
                                                      addTag(dSetState),
                                                  child: const Text(
                                                    'Add',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          ConstrainedBox(
                                            constraints: BoxConstraints(
                                              minHeight: 300,
                                              maxHeight: 600,
                                            ),
                                            child: ListView(
                                              shrinkWrap: true,
                                              children: rowsAsNeeded(tags, (
                                                tag,
                                              ) {
                                                bool isTagged = book.myShelves!
                                                    .contains(tag);
                                                // toggleTag button for each tag
                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        top: kPadding,
                                                      ),
                                                  child: ConstrainedBox(
                                                    constraints: BoxConstraints(
                                                      maxWidth: 100,
                                                    ),
                                                    child: ElevatedButton(
                                                      onPressed: () =>
                                                          toggleTag(
                                                            tag,
                                                            isTagged,
                                                            dSetState,
                                                          ),
                                                      style: isTagged
                                                          ? ElevatedButton.styleFrom(
                                                              backgroundColor:
                                                                  kGreen,
                                                            )
                                                          : null,
                                                      child: Tooltip(
                                                        message:
                                                            'toggle ${tag.name}',
                                                        child: Text(
                                                          tag.name,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          maxLines: 1,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                          child: Text('Continue to tags'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            child: Text(_shelvedAt ?? 'unshelved'),
          ),
        );
      },
    );

    Widget coverAndShelf = AsyncWidget(
      future: _futureBook,
      builder: (context, awaitedData) {
        Book book = awaitedData;

        return Column(
          children: [
            book.cover,
            SizedBox(height: kPadding),
            shelfButtonDialogs(book),
            SizedBox(height: kPadding),
            RatingBar.builder(
              initialRating: _myRating,
              minRating: 1,
              itemSize: Theme.of(context).textTheme.headlineLarge!.fontSize!,
              itemBuilder: (context, idx) =>
                  Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                if (rating != _myRating) {
                  reviewCreateOrUpdate(rating: rating.toInt());
                }
              },
            ),
            Text('Rate this book'),
          ],
        );
      },
    );

    Widget bookDetails = AsyncWidget(
      future: _futureBook,
      builder: (context, awaitedData) {
        Book book = awaitedData;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              book.title,
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                fontFamily: 'LibreBaskerville',
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              book.author,
              style: TextStyle(
                fontFamily: 'LibreBaskerville',
                fontWeight: FontWeight.w400, // normal
              ),
            ),
            SizedBox(height: kPadding),
            Row(
              children: [
                RatingBar.builder(
                  initialRating: book.avgRating!,
                  itemSize: Theme.of(
                    context,
                  ).textTheme.headlineLarge!.fontSize!,
                  itemBuilder: (context, idx) =>
                      Icon(Icons.star, color: Colors.amber),
                  onRatingUpdate: (rating) {},
                  ignoreGestures: true,
                ),
                SizedBox(width: kPadding),
                Text(
                  book.avgRatingString!,
                  style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                    fontFamily: 'LibreBaskerville',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: kPadding),
                Text(
                  '${book.nReviews!} reviews · ${book.nRatings!} ratings',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall!.copyWith(color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: kPadding),
            Text(book.description ?? ''),
            SizedBox(height: kPadding),
          ],
        );
      },
    );

    Widget communityReviews = AsyncWidget(
      future: _futureReviews,
      builder: (context, awaitedData) {
        List<Review> reviews = awaitedData;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: kPadding,
          children: [
            Text(
              'Community Reviews:',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontFamily: 'LibreBaskerville',
                fontWeight: FontWeight.w600,
              ),
            ),
            for (Review review in reviews) ReviewWidget(review: review),
          ],
        );
      },
    );

    return Scaffold(
      body: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expanded(flex: 1, child: Container()), // page side spacer
            Expanded(
              flex: 1,
              child: Container(
                margin: EdgeInsets.all(kPadding),
                child: coverAndShelf,
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                margin: EdgeInsets.all(kPadding),
                child: ListView(children: [bookDetails, communityReviews]),
              ),
            ),
            // Expanded(flex: 1, child: Container()), // page side spacer
          ],
        ),
      ),
    );
  }
}

class ReviewWidget extends StatelessWidget {
  const ReviewWidget({super.key, required this.review});

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(child: Icon(Icons.person)),
              Text(review.user!.fullName),
              Text(
                '${review.user!.nReviews!} reviews',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall!.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
        SizedBox(width: kPadding),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RatingBar.builder(
                initialRating: review.rating.toDouble(),
                itemSize: Theme.of(context).textTheme.bodyLarge!.fontSize!,
                itemBuilder: (context, idx) =>
                    Icon(Icons.star, color: Colors.amber),
                onRatingUpdate: (rating) {},
                ignoreGestures: true,
              ),
              Text(review.content ?? '', softWrap: true, maxLines: 5),
              Row(
                spacing: kPadding * 0.75,
                children: [
                  for (Bookshelf shelf in review.tags!)
                    Clickable(
                      onClick: () {
                        // TODO goto ShelfPage
                      },
                      child: Underline(
                        underlineColor: kGreen,
                        text: Text(
                          shelf.name,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
