class ImageData {
  final String url;
  final String id;

  ImageData({required this.url, required this.id});

  factory ImageData.fromJson(Map<String, dynamic> json) {
    return ImageData(
      url: json['xt_image'],
      id: json['id'],
    );
  }
}
