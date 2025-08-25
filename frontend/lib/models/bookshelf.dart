class Bookshelf {
  final String name;
  // final User user;

  Bookshelf({
    required this.name,
    // required this.user,
  });

  factory Bookshelf.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        // 'user_id': int userId,
        'name': String name,
      } =>
        Bookshelf(
          name: name,
          // user: user,
        ),
      _ => throw const FormatException('Failed to load Bookshelf.'),
    };
  }
}
