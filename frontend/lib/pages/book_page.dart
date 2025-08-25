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
        await client.get(Uri.parse('$flaskServer/books?id=${widget.bookId}'))
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
    return Scaffold(
      body: FutureBuilder(
        future: Future.wait([_futureBook, _futureReviews]),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Book book = snapshot.data![0] as Book;
            List<Review> reviews = snapshot.data![1] as List<Review>;

            Widget coverAndShelf = Column(children: [book.cover]);

            Widget detailsAndReviews = ListView(
              children: [
                // book details
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
                Text(book.description ?? ''),
                SizedBox(height: kPadding),

                // reviews
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

            return Center(
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
                      child: detailsAndReviews,
                    ),
                  ),
                  // Expanded(flex: 1, child: Container()), // page side spacer
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }
          return const CircularProgressIndicator();
        },
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
