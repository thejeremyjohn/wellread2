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

  @override
  void initState() {
    super.initState();
    _futureBook = fetchBook();
    _futureReviews = fetchReviews();
  }

  // TODO reuse fetchBooks. pre-req: refactor
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
      return (r.data['books'] as List)
          .map((book) => Book.fromJson(book as Map<String, dynamic>))
          .first;
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
            // TODO myShelves should hold ONLY one of want to read, currently reading, read
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(kGreen),
                ),
                onPressed: () {
                  // TODO open dialog to change shelf OR 'want to read' if unshelved
                },
                child: Text(
                  book.myShelves!.isNotEmpty
                      ? book.myShelves!.first.name
                      : 'unshelved',
                ),
              ),
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
