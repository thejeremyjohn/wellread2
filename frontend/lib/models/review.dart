import 'package:wellread2frontend/models/bookshelf.dart';
import 'package:wellread2frontend/models/user.dart';

class Review {
  final int bookId;
  final int userId;
  final int rating;
  final String review;
  final User? user;
  final List<Bookshelf> shelves;

  Review({
    required this.bookId,
    required this.userId,
    required this.rating,
    required this.review,
    this.user,
    this.shelves = const [],
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    User? user = json.containsKey('user') ? User.fromJson(json['user']) : null;
    List<Bookshelf> shelves = json.containsKey('shelves')
        ? (json['shelves'] as List)
              .map((shelf) => Bookshelf.fromJson(shelf))
              .toList()
        : [];

    return switch (json) {
      {
        'book_id': int bookId,
        'user_id': int userId,
        'rating': int rating,
        'review': String review,
      } =>
        Review(
          bookId: bookId,
          userId: userId,
          rating: rating,
          review: review,
          user: user,
          shelves: shelves,
        ),
      _ => throw const FormatException('Failed to load Review.'),
    };
  }

  List<Bookshelf> get tags => shelves;
}
