import 'package:flutter/material.dart';
import 'package:wellread2frontend/models/book_image.dart';
import 'package:wellread2frontend/models/bookshelf.dart';

class Book {
  final int id;
  final String title;
  final String author;
  final String? description;
  final List<BookImage> images;

  final double? myRating;
  final double? avgRating;
  final List<Bookshelf>? myShelves;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.images,

    this.myRating,
    this.avgRating,
    this.myShelves,
  });

  Book.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      title = json['title'] as String,
      author = json['author'] as String,
      description = (json['description'] ?? '') as String,
      images = (json['images'] as List)
          .map((i) => BookImage.fromJson(i as Map<String, dynamic>))
          .toList(),

      myRating = json.containsKey('my_rating')
          ? json['my_rating'] as double
          : 0.0,
      avgRating = json.containsKey('avg_rating')
          ? json['avg_rating'] as double
          : 0.0,
      myShelves = json.containsKey('my_shelves')
          ? (json['my_shelves'] as List)
                .map((shelf) => Bookshelf.fromJson(shelf))
                .toList()
          : [];

  Image get cover128p => images.isEmpty
      ? Image.asset(width: 128, 'images/no-cover.png')
      : Image.network(width: 128, images.first.url);
  Image get cover => images.isEmpty
      ? Image.asset('images/no-cover.png')
      : Image.network(images.first.url);
}
