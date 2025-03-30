

class MediaItem {
  final int id;
  final String title;
  final String posterPath;
  final String mediaType;
  final double voteAverage;
  double? matchPercentage;
  bool isSelected;

  MediaItem({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.mediaType,
    required this.voteAverage,
    this.matchPercentage,
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
    );
  }
}