import 'package:wellread2frontend/models/bookshelf.dart';
import 'package:wellread2frontend/models/user.dart';

class Review {
  final int bookId;
  final int userId;
  final int rating;
  final String content;

  final User? user;
  final List<Bookshelf>? shelves;

  Review({
    required this.bookId,
    required this.userId,
    required this.rating,
    required this.content,

    this.user,
    this.shelves,
  });

  Review.fromJson(Map<String, dynamic> json)
    : bookId = json['book_id'] as int,
      userId = json['user_id'] as int,
      rating = json['rating'] as int,
      content = json['content'] as String,

      user =
          json.containsKey('user') // via expand=user
          ? User.fromJson(json['user'])
          : json.containsKey('user_') // via add_props=user_
          ? User.fromJson(json['user_'])
          : null,
      shelves = json.containsKey('shelves')
          ? (json['shelves'] as List)
                .map((shelf) => Bookshelf.fromJson(shelf))
                .toList()
          : [];

  List<Bookshelf>? get tags => shelves;
}
