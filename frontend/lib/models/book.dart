import 'package:flutter/material.dart';
import 'package:wellread2frontend/models/book_image.dart';
import 'package:wellread2frontend/models/bookshelf.dart';

class Book {
  final int id;
  final String title;
  final String author;
  final String? description;
  final List<BookImage> images;

  double? myRating;
  double? avgRating;
  List<Bookshelf> myShelves;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.description,
    required this.images,
    this.myRating,
    this.avgRating,
    this.myShelves = const [],
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    double? myRating = json.containsKey('my_rating') ? json['my_rating'] : 0.0;
    double? avgRating = json.containsKey('avg_rating')
        ? json['avg_rating']
        : 0.0;
    List<Bookshelf> myShelves = json.containsKey('my_shelves')
        ? (json['my_shelves'] as List)
              .map((shelf) => Bookshelf.fromJson(shelf))
              .toList()
        : [];

    return switch (json) {
      {
        'id': int id,
        'title': String title,
        'author': String author,
        'description': String description,
        'images': List images,
      } =>
        Book(
          id: id,
          title: title,
          author: author,
          description: description,
          images: images
              .map((i) => BookImage.fromJson(i as Map<String, dynamic>))
              .toList(),
          myRating: myRating,
          avgRating: avgRating,
          myShelves: myShelves,
        ),
      _ => throw const FormatException('Failed to load book.'),
    };
  }

  Image get cover128p => images.isEmpty
      ? Image.asset(width: 128, 'images/no-cover.png')
      : Image.network(width: 128, images.first.url);
  Image get cover => images.isEmpty
      ? Image.asset('images/no-cover.png')
      : Image.network(images.first.url);
}
