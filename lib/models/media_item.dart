import 'dart:convert';

class MediaItem {
  final int id;
  final String title;
  final String posterPath;
  final String mediaType;
  bool isSelected;

  MediaItem({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.mediaType,
    this.isSelected = false,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json, String type) {
    return MediaItem(
      id: json['id'],
      title: type == 'movie' ? json['title'] : json['name'],
      posterPath: json['poster_path'] ?? '',
      mediaType: type,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'posterPath': posterPath,
    'mediaType': mediaType,
    'isSelected': isSelected,
  };
}