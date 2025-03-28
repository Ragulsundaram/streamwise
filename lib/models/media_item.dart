import 'dart:convert';

class MediaItem {
  final int id;
  final String title;
  final String posterPath;
  final double voteAverage;
  final String mediaType;
  bool isSelected;

  MediaItem({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.voteAverage,
    required this.mediaType,
    this.isSelected = false,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json, String type) {
    return MediaItem(
      id: json['id'],
      title: type == 'movie' ? json['title'] : json['name'],
      posterPath: json['poster_path'] != null 
          ? 'https://image.tmdb.org/t/p/w500${json['poster_path']}'
          : 'https://via.placeholder.com/500x750',
      mediaType: type,
      voteAverage: (json['vote_average'] as num?)?.toDouble() ?? 0.0,
      isSelected: false,
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