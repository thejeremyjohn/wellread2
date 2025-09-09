import 'package:equatable/equatable.dart';

class Bookshelf extends Equatable {
  final int id;
  final String name;

  const Bookshelf({required this.id, required this.name});

  Bookshelf.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      name = json['name'] as String;

  @override
  List<Object> get props => [id, name];
}
