import 'package:wellread2frontend/models/user.dart';

class Review {
  final int bookId;
  final int userId;
  final int rating;
  final String review;
  final User? user;

  Review({
    required this.bookId,
    required this.userId,
    required this.rating,
    required this.review,
    this.user,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    User? user = json.containsKey('user') ? User.fromJson(json['user']) : null;
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
        ),
      _ => throw const FormatException('Failed to load Review.'),
    };
  }
}
