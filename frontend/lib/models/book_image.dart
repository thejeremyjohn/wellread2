class BookImage {
  final String url;
  final String uuid;

  BookImage({required this.url, required this.uuid});

  factory BookImage.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {'url': String url, 'uuid': String uuid} => BookImage(
        uuid: uuid,
        url: url,
      ),
      _ => throw const FormatException('Failed to load BookImage.'),
    };
  }
}
