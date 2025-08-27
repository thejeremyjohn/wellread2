class BookImage {
  final String url;
  final String uuid;

  BookImage({required this.url, required this.uuid});

  BookImage.fromJson(Map<String, dynamic> json)
    : url = json['url'] as String,
      uuid = json['uuid'] as String;
}
