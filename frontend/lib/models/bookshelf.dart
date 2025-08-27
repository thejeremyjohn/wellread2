class Bookshelf {
  final String name;

  Bookshelf({required this.name});

  Bookshelf.fromJson(Map<String, dynamic> json) : name = json['name'] as String;
}
