import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/models/book.dart';

final bookNotifierProvider =
    AsyncNotifierProvider.family<BookNotifier, Book, String>(BookNotifier.new);

class BookNotifier extends AsyncNotifier<Book> {
  BookNotifier(this.bookId);
  final String bookId;

  Future<Book> _bookGet(String bookId) async {
    Uri endpoint = flaskUri(
      '/books',
      queryParameters: {'id': bookId},
      addProps: [
        'avg_rating',
        'my_rating',
        'my_shelves',
        'n_reviews',
        'n_ratings',
      ],
    );

    final r = await flaskGet(endpoint);
    if (!r.isOk) throw Exception(r.error);

    return (r.data['books'] as List)
        .map((book) => Book.fromJson(book as Map<String, dynamic>))
        .first;
  }

  @override
  FutureOr<Book> build() => _bookGet(bookId);

  FutureOr<void> refreshBook() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _bookGet(bookId));
  }
}
