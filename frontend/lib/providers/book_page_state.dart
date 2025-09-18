import 'package:flutter/material.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/flask_util/flask_response.dart';
import 'package:wellread2frontend/models/book.dart';
import 'package:wellread2frontend/models/review.dart';

import '../models/bookshelf.dart';

class BookPageState extends ChangeNotifier {
  late Book book;
  Future<Book> bookGet(String bookId) async {
    Uri endpoint = flaskUri(
      '/books',
      queryParameters: {'id': bookId.toString()},
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

    book = (r.data['books'] as List)
        .map((book) => Book.fromJson(book as Map<String, dynamic>))
        .first;

    notifyListeners();
    return book;
  }

  List<Bookshelf> bookshelves = [];
  Iterable<Bookshelf> get shelves => bookshelves.take(3);
  Iterable<Bookshelf> get tags => bookshelves.skip(3).toSet();
  Future<List<Bookshelf>> bookshelvesGet(String userId, {int page = 1}) async {
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
      extendBookshelves(fetched);

      page = (r.data['page'] as int) + 1;
      bookshelvesGet(userId, page: page);
    }
    return bookshelves;
  }

  void extendBookshelves(List<Bookshelf> fetched) {
    bookshelves.addAll(fetched);
    notifyListeners();
  }

  void appendBookshelf(Bookshelf tag) {
    bookshelves.add(tag);
    notifyListeners();
  }

  List<Review> reviews = [];
  Future<List<Review>> reviewsGet(String bookId) async {
    Uri endpoint = flaskUri(
      '/reviews',
      queryParameters: {'book_id': bookId.toString()},
      addProps: ['shelves', 'user_'],
    );

    final r = await flaskGet(endpoint);
    if (!r.isOk) throw Exception(r.error);

    List<Review> fetched = (r.data['reviews'] as List)
        .map((review) => Review.fromJson(review as Map<String, dynamic>))
        .toList();
    reviews.addAll(fetched);

    // TODO paginated reviews (not the same as bookshelves I guess)

    notifyListeners();
    return reviews;
  }

  Future<Review> reviewCreateOrUpdate(
    String bookId, {
    String method = 'POST',
    required int rating,
    String? content,
  }) async {
    Uri endpoint = flaskUri('/review');
    Map<String, dynamic> body = {
      'book_id': bookId.toString(),
      'rating': rating.toString(),
    };
    if (content != null) body['content'] = content;

    var flaskMethod = book.myRating == 0 ? flaskPost : flaskPut;
    final r = await flaskMethod(endpoint, body: body);
    if (!r.isOk) throw Exception(r.error);

    Review review = Review.fromJson(r.data['review'] as Map<String, dynamic>);
    if (book.myRating == 0 && book.myShelf == null) {
      shelfChangeMembership(
        bookId,
        shelves.firstWhere((s) => s.name == 'read'),
      );
    }

    notifyListeners();
    bookGet(bookId); // for updated book.avgRating
    return review;
  }

  Future<FlaskResponse> tagCreate(String name) async {
    Uri endpoint = flaskUri('/bookshelf');

    final r = await flaskPost(endpoint, body: {'name': name});
    if (!r.isOk) return r;

    Bookshelf tag = Bookshelf.fromJson(
      r.data['bookshelf'] as Map<String, dynamic>,
    );
    appendBookshelf(tag);

    return r;
  }

  Future<Bookshelf> shelfChangeMembership(
    String bookId,
    Bookshelf shelf,
  ) async {
    if (book.myShelf == shelf) return shelf;
    if (book.myShelf != null) {
      await book.myShelf!.removeBook(book, deleteTags: false);
    }
    Bookshelf newShelf = await shelf.addBook(book);

    bookGet(bookId); // for updated book.myShelf
    return newShelf;
  }

  Future unshelf() async {
    await book.myShelf!.removeBook(book, deleteTags: true);

    bookGet(book.id.toString()); // for updated book.myShelf
    return;
  }

  Future toggleTag(Bookshelf tag, bool isTagged) async {
    (isTagged ? tag.removeBook(book) : tag.addBook(book)).then((t) {
      isTagged ? book.myShelves!.remove(t) : book.myShelves!.add(t);
      notifyListeners();
      return;
    });
  }
}
