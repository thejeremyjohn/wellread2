import 'package:flutter/material.dart';
import 'package:wellread2frontend/models/book.dart';
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
                  Text(book.title),
                  Text(book.author),
                  Text('la di da'),
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
