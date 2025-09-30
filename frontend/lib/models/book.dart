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
  final int? nReviews;
  final int? nRatings;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.description,
    required this.images,

    this.myRating,
    this.avgRating,
    this.myShelves,
    this.nReviews,
    this.nRatings,
  });

  Book.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      title = json['title'] as String,
      author = json['author'] as String,
      description = (json['description'] ?? '') as String,
      images = (json['images'] as List)
          .map((i) => BookImage.fromJson(i as Map<String, dynamic>))
          .toList(),

      myRating = json['my_rating'] as double?,
      avgRating = json['avg_rating'] as double?,
      myShelves = json.containsKey('my_shelves')
          ? (json['my_shelves'] as List)
                .map((shelf) => Bookshelf.fromJson(shelf))
                .toList()
          : [],
      nReviews = json['n_reviews'] as int?,
      nRatings = json['n_ratings'] as int?;

  Image get cover => images.isEmpty
      ? Image.asset('assets/images/no-cover.png')
      : Image.network(images.first.url);
  Image get coverThumb => images.isEmpty
      ? Image.asset('assets/images/no-cover-thumb.png')
      : Image.network(images.first.urlThumb);

  String? get avgRatingString => avgRating?.toStringAsFixed(2);

  Bookshelf? get myShelf => myShelves!.isNotEmpty ? myShelves!.first : null;
  Set<Bookshelf> get myTags =>
      myShelves!.isNotEmpty ? myShelves!.sublist(1).toSet() : <Bookshelf>{};
}
