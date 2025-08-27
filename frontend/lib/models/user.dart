class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;

  final int? nReviews;

  User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,

    this.nReviews,
  });

  User.fromJson(Map<String, dynamic> json)
    : id = json['id'] as int,
      firstName = json['first_name'] as String,
      lastName = (json['last_name'] ?? '') as String,
      email = json['email'] as String,

      nReviews = json.containsKey('n_reviews')
          ? json['n_reviews'] as int
          : null;

  String get fullName => '$firstName $lastName'.trim();
}
