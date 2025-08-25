import 'package:flutter/material.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_constants.dart';
import 'package:wellread2frontend/flask_util/flask_response.dart';
import 'package:wellread2frontend/models/book.dart';
import 'package:wellread2frontend/models/review.dart';

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
    final r =
        await client.get(
              Uri.parse(
                '$flaskServer/books?id=${widget.bookId}&add_props=avg_rating,my_rating,my_shelves',
              ),
            )
            as FlaskResponse;
    if (r.isOk) {
      return (r.data['books'] as List)
          .map((book) => Book.fromJson(book as Map<String, dynamic>))
          .first;
    } else {
      throw Exception('Failed to load books');
    }
  }

  Future<List<Review>> fetchReviews() async {
    final url = Uri.parse(
      '$flaskServer/reviews?book_id=${widget.bookId}&expand=user',
    );
    final r = await client.get(url) as FlaskResponse;
    if (r.isOk) {
      return (r.data['reviews'] as List)
          .map((review) => Review.fromJson(review as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget coverAndShelf = FutureBuilder(
      future: _futureBook,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Book book = snapshot.data!;
          return Column(
            children: [
              book.cover,
              SizedBox(height: kPadding),
              // TODO myShelves should hold ONLY one of want to read, currently reading, read
              Text(book.myShelves!.first.name),
              SizedBox(height: kPadding),
              // TODO myRating as stars
              Text(
                book.myRating!.toString(),
                style: TextStyle(
                  fontFamily: 'LibreBaskerville',
                  fontWeight: FontWeight.w700, // normal
                ),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return const CircularProgressIndicator();
      },
    );

    Widget bookDetails = FutureBuilder(
      future: _futureBook,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          Book book = snapshot.data!;
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
              // TODO avgRating as stars
              Text(
                book.avgRating!.toString(),
                style: TextStyle(
                  fontFamily: 'LibreBaskerville',
                  fontWeight: FontWeight.w700, // normal
                ),
              ),
              SizedBox(height: kPadding),
              Text(book.description ?? ''),
              SizedBox(height: kPadding),
            ],
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return const CircularProgressIndicator();
      },
    );

    Widget communityReviews = FutureBuilder(
      future: _futureReviews,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<Review> reviews = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Community Reviews:',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontFamily: 'LibreBaskerville',
                  fontWeight: FontWeight.w600,
                ),
              ),
              for (Review review in reviews) ReviewWidget(review: review),
              for (Review review in reviews) ReviewWidget(review: review),
              for (Review review in reviews) ReviewWidget(review: review),
              for (Review review in reviews) ReviewWidget(review: review),
              for (Review review in reviews) ReviewWidget(review: review),
              for (Review review in reviews) ReviewWidget(review: review),
              for (Review review in reviews) ReviewWidget(review: review),
              for (Review review in reviews) ReviewWidget(review: review),
              for (Review review in reviews) ReviewWidget(review: review),
              for (Review review in reviews) ReviewWidget(review: review),
              for (Review review in reviews) ReviewWidget(review: review),
            ],
          );
        } else if (snapshot.hasError) {
          return Text('${snapshot.error}');
        }
        return const CircularProgressIndicator();
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
            children: [Text(review.user!.firstName), Text(review.user!.email)],
          ),
        ),
        SizedBox(width: kPadding),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(review.rating.toString()),
              Text(review.review, softWrap: true, maxLines: 5),
            ],
          ),
        ),
      ],
    );
  }
}
