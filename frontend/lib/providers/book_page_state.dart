import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/flask_util/flask_response.dart';
import 'package:wellread2frontend/models/book.dart';
import 'package:wellread2frontend/models/bookshelf.dart';
import 'package:wellread2frontend/models/review.dart';

class BookPageState extends ChangeNotifier {
  late Book _book;
  Book get book => _book;
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

    _book = (r.data['books'] as List)
        .map((b) => Book.fromJson(b as Map<String, dynamic>))
        .first;

    notifyListeners();
    return _book;
  }

  final List<Bookshelf> _bookshelves = [];
  UnmodifiableListView<Bookshelf> get bookshelves =>
      UnmodifiableListView(_bookshelves);
  Iterable<Bookshelf> get shelves => _bookshelves.take(3);
  Iterable<Bookshelf> get tags => _bookshelves.skip(3).toSet();

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
    return _bookshelves;
  }

  void extendBookshelves(List<Bookshelf> fetched) {
    _bookshelves.addAll(fetched);
    notifyListeners();
  }

  void appendBookshelf(Bookshelf tag) {
    _bookshelves.add(tag);
    notifyListeners();
  }

  int _reviewsPage = 1;
  final int _reviewsPerPage = 20;
  bool _isReviewsGettingMore = false;
  bool _isAllReviewsGot = false;
  Map<String, String> _reviewsQueryParameters = {};

  Future<void> reviewsGetMore() async {
    if (!_isAllReviewsGot && !_isReviewsGettingMore) {
      await reviewsGet(_reviewsQueryParameters);
    }
  }

  final List<Review> _reviews = [];
  UnmodifiableListView<Review> get reviews => UnmodifiableListView(_reviews);
  Future<List<Review>> reviewsGet(Map<String, String> queryParameters) async {
    _reviewsQueryParameters = queryParameters;
    _isReviewsGettingMore = true;
    notifyListeners();

    Uri endpoint = flaskUri(
      '/reviews',
      queryParameters: {
        ..._reviewsQueryParameters,
        'page': _reviewsPage.toString(),
        'per_page': _reviewsPerPage.toString(),
      },
      addProps: ['shelves', 'user_'],
    );

    final r = await flaskGet(endpoint);
    if (!r.isOk) throw Exception(r.error);

    List<Review> fetched = (r.data['reviews'] as List)
        .map((review) => Review.fromJson(review as Map<String, dynamic>))
        .toList();

    if (_reviewsPage == 1) _reviews.clear();
    if (fetched.length < _reviewsPerPage) {
      _isAllReviewsGot = true;
      _reviewsPage = 1;
    } else {
      _isAllReviewsGot = false;
      _reviewsPage += 1;
    }
    _reviews.addAll(fetched);
    _isReviewsGettingMore = false;

    notifyListeners();
    return fetched;
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

    var flaskMethod = _book.myRating == 0 ? flaskPost : flaskPut;
    final r = await flaskMethod(endpoint, body: body);
    if (!r.isOk) throw Exception(r.error);

    Review review = Review.fromJson(r.data['review'] as Map<String, dynamic>);
    if (_book.myRating == 0 && _book.myShelf == null) {
      shelfChangeMembership(
        bookId,
        shelves.firstWhere((s) => s.name == 'read'),
      );
    }

    notifyListeners();
    bookGet(bookId); // for updated _book.avgRating
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
    if (_book.myShelf == shelf) return shelf;
    if (_book.myShelf != null) {
      await _book.myShelf!.removeBook(_book, deleteTags: false);
    }
    Bookshelf newShelf = await shelf.addBook(_book);

    bookGet(bookId); // for updated _book.myShelf
    return newShelf;
  }

  Future unshelf() async {
    await _book.myShelf!.removeBook(_book, deleteTags: true);

    bookGet(_book.id.toString()); // for updated _book.myShelf
    return;
  }

  Future toggleTag(Bookshelf tag, bool isTagged) async {
    (isTagged ? tag.removeBook(_book) : tag.addBook(_book)).then((t) {
      isTagged ? _book.myShelves!.remove(t) : _book.myShelves!.add(t);
      notifyListeners();
      return;
    });
  }
}
