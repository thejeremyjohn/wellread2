import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/models/book.dart';
import 'package:wellread2frontend/models/bookshelf.dart';
import 'package:wellread2frontend/models/review.dart';
import 'package:wellread2frontend/widgets/async_widget.dart';
import 'package:wellread2frontend/widgets/clickable.dart';
import 'package:wellread2frontend/widgets/underline.dart';

class BookPage extends StatefulWidget {
  const BookPage({super.key, required this.bookId});

  final String bookId;

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  late Future<Book> _futureBook;
  late Future<List<Review>> _futureReviews;
  late Future<List<Bookshelf>> _futureBookshelves;
  late String? _shelvedAt;

  @override
  void initState() {
    super.initState();
    _futureBook = fetchBook();
    _futureReviews = fetchReviews();
    _futureBookshelves = fetchBookshelves();
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

  Future<List<Bookshelf>> fetchBookshelves() async {
    Uri endpoint = flaskUri(
      '/bookshelves',
      queryParameters: {
        'user_id': '1', // TODO user's id from login
        'order_by': 'can_delete',
      },
    );

    final r = await flaskGet(endpoint);
    if (r.isOk) {
      return (r.data['bookshelves'] as List)
          .map((shelf) => Bookshelf.fromJson(shelf as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception(r.error);
    }
  }

  Future<Bookshelf> bookshelfAddOrRemoveBook(
    int bookshelfId,
    String method,
  ) async {
    var flaskMethod = method == 'POST' ? flaskPost : flaskDelete;
    Uri endpoint = flaskUri('/bookshelf/$bookshelfId/book/${widget.bookId}');
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

  Future<String?> removeFromShelf(int bookshelfId, {bool hide = false}) async {
    await bookshelfAddOrRemoveBook(bookshelfId, 'DELETE');
    if (!hide) setState(() => _shelvedAt = null);
    return _shelvedAt;
  }

  @override
  Widget build(BuildContext context) {
    Widget coverAndShelf = AsyncWidget(
      future: _futureBook,
      builder: (context, awaitedData) {
        Book book = awaitedData;

        return Column(
          children: [
            book.cover,
            SizedBox(height: kPadding),
            AsyncWidget(
              future: _futureBookshelves,
              builder: (context, awaitedData) {
                Iterable<Bookshelf> shelves = awaitedData.take(3);
                // Iterable<Bookshelf> tags = awaitedData.skip(3);

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
                          builder: (context, StateSetter dialogSetState) {
                            return Dialog(
                              constraints: BoxConstraints(
                                minWidth: 300,
                                maxWidth: 400,
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Container(
                                padding: const EdgeInsets.all(kPadding),
                                child: Column(
                                  spacing: kPadding,
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Text('Choose a shelf for this book'),
                                    ...shelves.map((shelf) {
                                      return SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            if (_shelvedAt == shelf.name) {
                                              await removeFromShelf(shelf.id);
                                            } else {
                                              for (var shelfB in shelves) {
                                                if (_shelvedAt == shelfB.name) {
                                                  await removeFromShelf(
                                                    shelfB.id,
                                                    hide: true,
                                                  );
                                                }
                                              }
                                              await addToShelf(shelf.id);
                                            }
                                            dialogSetState(() {});
                                          },
                                          label: Text(shelf.name),
                                          icon: _shelvedAt == shelf.name
                                              ? Icon(Icons.check)
                                              : null,
                                        ),
                                      );
                                    }),
                                    Text('Remove from my shelf'),
                                    ElevatedButton(
                                      onPressed: () {
                                        // TODO tags dialog
                                      },
                                      child: Text('Continue to tags'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    child: Text(_shelvedAt ?? 'unshelved'),
                  ),
                );
              },
            ),
            SizedBox(height: kPadding),
            RatingBar.builder(
              initialRating: book.myRating!,
              minRating: 1,
              itemSize: Theme.of(context).textTheme.headlineLarge!.fontSize!,
              itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, idx) =>
                  Icon(Icons.star, color: Colors.amber),
              onRatingUpdate: (rating) {
                // TODO review_update
                // book.myRating = rating;
                // setState(() {});
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
