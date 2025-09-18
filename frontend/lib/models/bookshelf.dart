import 'package:equatable/equatable.dart';
import 'package:wellread2frontend/flask_util/flask_methods.dart';
import 'package:wellread2frontend/models/book.dart';

class Bookshelf extends Equatable {
  final int id;
  final String name;

  final int? nBooks;

  const Bookshelf({required this.id, required this.name, this.nBooks});

  Bookshelf.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      name = json['name'] as String,

      nBooks = json['n_books'] as int?;

  @override
  List<Object> get props => [id]; // id == id is all that matters

  Future<Bookshelf> _addOrRemoveBook(
    Book book,
    String method, {
    bool deleteTags = false,
  }) async {
    var flaskMethod = method == 'POST' ? flaskPost : flaskDelete;
    Uri endpoint = flaskUri(
      '/bookshelf/$id/book/${book.id}',
      queryParameters: method == 'POST'
          ? {}
          : {'delete_tags': deleteTags.toString()},
    );

    final r = await flaskMethod(endpoint);
    if (!r.isOk) throw Exception(r.error);

    return Bookshelf.fromJson(r.data['bookshelf'] as Map<String, dynamic>);
  }

  Future<Bookshelf> addBook(Book book) {
    return _addOrRemoveBook(book, 'POST');
  }

  Future<Bookshelf> removeBook(Book book, {bool deleteTags = false}) {
    return _addOrRemoveBook(book, 'DELETE', deleteTags: deleteTags);
  }
}
