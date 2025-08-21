class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
        'id': int id,
        'first_name': String firstName,
        'last_name': String lastName,
        'email': String email,
      } =>
        User(id: id, firstName: firstName, lastName: lastName, email: email),
      _ => throw const FormatException('Failed to load User.'),
    };
  }
}
