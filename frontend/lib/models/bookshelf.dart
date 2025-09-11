import 'package:equatable/equatable.dart';

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
  List<Object> get props => [id, name];
}
