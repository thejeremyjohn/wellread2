import 'package:flutter/material.dart';
import 'package:wellread2frontend/constants.dart';
import 'package:wellread2frontend/flask_util/flask_constants.dart';
import 'package:wellread2frontend/flask_util/flask_response.dart';
import 'package:wellread2frontend/models/book.dart';
import 'package:wellread2frontend/models/review.dart';
import 'package:wellread2frontend/widgets/wellread_app_bar.dart';

class BookPage extends StatefulWidget {
  const BookPage({
    super.key,
    required this.book,
    // required this.reviews, // TODO reviews
  });

  final Book book;
  // late List<Review> reviews;

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  late Future<List<Review>> _futureReviews;

  @override
  void initState() {
    super.initState();
    _futureReviews = fetchReviews();
  }

  Future<List<Review>> fetchReviews() async {
    // final url = Uri.http(flaskHost, '/reviews', {'book_id': widget.book.id});
    final url = Uri.parse(
      '$flaskServer/reviews?book_id=${widget.book.id}&expand=user',
    );
    final r = await client.get(url) as FlaskResponse;
    if (r.isOk) {
      print(r.body);
      return (r.data['reviews'] as List)
          .map((review) => Review.fromJson(review as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load reviews');
    }
  }

  @override
  Widget build(BuildContext context) {
    Book book = widget.book;
    return Scaffold(
      appBar: WellreadAppBar(),
      body: Center(
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'user.firstName: ${review.user!.firstName}',
                                  ),
                                  Text('user.email: ${review.user!.email}'),
                                ],
                              ),
                              SizedBox(width: kPadding),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
      ),
    );
  }
}
