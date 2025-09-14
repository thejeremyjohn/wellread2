import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/models/bookshelf.dart';

final bookshelvesNotifierProvider =
    AsyncNotifierProvider.family<BookshelvesNotifier, List<Bookshelf>, String>(
      BookshelvesNotifier.new,
    );

class BookshelvesNotifier extends AsyncNotifier<List<Bookshelf>> {
  BookshelvesNotifier(this.userId);
  final String userId;

  Future<List<Bookshelf>> _bookshelvesGet(String userId, {int page = 1}) async {
    Uri endpoint = flaskUri(
      '/bookshelves',
      queryParameters: {
        'user_id': userId,
        'order_by': 'can_delete',
        'page': page.toString(),
      },
    );

    final r = await flaskGet(endpoint);
    if (!r.isOk) throw Exception(r.error);

    List<Bookshelf> fetched = (r.data['bookshelves'] as List)
        .map((shelf) => Bookshelf.fromJson(shelf as Map<String, dynamic>))
        .toList();

    if (fetched.isNotEmpty) {
      _bookshelvesGetNextPage((r.data['page'] as int) + 1);
    }
    return fetched;
  }

  @override
  FutureOr<List<Bookshelf>> build() => _bookshelvesGet(userId);

  FutureOr<void> refreshBookshelves() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _bookshelvesGet(userId));
  }

  Future<void> _bookshelvesGetNextPage(int page) async {
    state = AsyncData([
      ...await future,
      ...await _bookshelvesGet(userId, page: page),
    ]);
  }
}
