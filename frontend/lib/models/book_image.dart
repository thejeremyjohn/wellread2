class BookImage {
  final String uuid;
  final String url;
  final String urlThumb;

  BookImage({required this.uuid, required this.url, required this.urlThumb});

  BookImage.fromJson(Map<String, dynamic> json)
    : uuid = json['uuid'] as String,
      url = json['url'] as String,
      urlThumb = json['url_thumb'] as String;
}
