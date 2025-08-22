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
        future: _futureBook,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            Book book = snapshot.data!;
            return Center(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 1, child: Container()), // page side spacer
                  Expanded(flex: 1, child: book.cover),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('title: ${book.title}'),
                        Text('author: ${book.author}'),
                        SizedBox(height: kPadding),
                        Text('description: lorem ipsum fee fii foo fum'),
                        SizedBox(height: kPadding),
                        Text('Reviews...:'),
                        FutureBuilder(
                          future: _futureReviews,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              for (Review review in snapshot.data!) {
                                return Row(
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'user.firstName: ${review.user!.firstName}',
                                        ),
                                        Text(
                                          'user.email: ${review.user!.email}',
                                        ),
                                      ],
                                    ),
                                    SizedBox(width: kPadding),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('rating ${review.rating}'),
                                        Text('review ${review.review}'),
                                      ],
                                    ),
                                  ],
                                );
                              }
                            } else if (snapshot.hasError) {
                              return Text('${snapshot.error}');
                            }
                            return const CircularProgressIndicator();
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(flex: 1, child: Container()), // page side spacer
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
