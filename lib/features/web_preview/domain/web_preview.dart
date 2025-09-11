class WebPreview {
  final String url;
  final String title;
  final String? imagePath;
  final String? imageUrl;
  final String? mime;
  final String? etag;
  final String? lastModified;
  final int? statusCode;
  final DateTime fetchedAt;
  final DateTime? expiresAt;
  final String? hash;

  WebPreview({
    required this.url,
    required this.title,
    this.imagePath,
    this.imageUrl,
    this.mime,
    this.etag,
    this.lastModified,
    this.statusCode,
    required this.fetchedAt,
    this.expiresAt,
    this.hash,
  });

  bool get isExpired =>
      expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
