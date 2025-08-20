import 'package:flutter/material.dart';
import 'package:wellread2frontend/models/book_image.dart';

class Book {
  final int id;
  final String author;
  final String title;
  final List<BookImage> images;

  Book({
    required this.id,
    required this.author,
    required this.title,
    required this.images,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': int id,
        'author': String author,
        'title': String title,
        'images': List images,
      } =>
        Book(
          id: id,
          author: author,
          title: title,
          images: images
              .map((i) => BookImage.fromJson(i as Map<String, dynamic>))
              .toList(),
        ),
      _ => throw const FormatException('Failed to load book.'),
    };
  }

  Image get cover => images.isEmpty
      ? Image.asset(width: 128, 'images/no-cover.png')
      : Image.network(width: 128, images.first.url);
}
