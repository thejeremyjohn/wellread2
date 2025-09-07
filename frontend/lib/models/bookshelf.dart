class Bookshelf {
  final int id;
  final String name;

  Bookshelf({required this.id, required this.name});

  Bookshelf.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      name = json['name'] as String;
}
