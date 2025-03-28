import 'dart:math' show pow;
import 'package:flutter/foundation.dart';
import '../models/media_item.dart';
import '../models/profile/taste_profile.dart';
import 'tmdb_service.dart';

class ProfileService {
  final TMDBService _tmdbService;
  
  // Feature type weights (sum to 1.0)
  static const double _genreWeight = 0.4;
  static const double _actorWeight = 0.25;
  static const double _directorWeight = 0.25;
  static const double _decadeWeight = 0.1;
  
  ProfileService(this._tmdbService);

  Future<TasteProfile> generateProfile(List<MediaItem> selectedItems) async {
    final Map<String, Map<String, dynamic>> genres = {};
    final Map<String, Map<String, dynamic>> actors = {};
    final Map<String, Map<String, dynamic>> directors = {};
    final Map<String, Map<String, dynamic>> decades = {};
    double totalRating = 0;

    for (var item in selectedItems) {
      try {
        final details = await _tmdbService.getMediaDetails(
          item.id, 
          item.mediaType
        );

        final interactionStrength = _calculateInteractionStrength(
          (details['vote_average'] as num?)?.toDouble() ?? 0.0,
          DateTime.now(),
        );

        // Process genres with higher weight
        final genresList = details['genres'] as List<dynamic>? ?? [];
        for (var genre in genresList) {
          final genreId = genre['id'].toString();
          final genreName = genre['name'] as String;
          final weight = _genreWeight * interactionStrength;
          _updateFeatureWeight(genres, genreId, genreName, weight);
        }

        // Process cast with balanced weight
        final credits = details['credits'] as Map<String, dynamic>? ?? {};
        final castList = credits['cast'] as List<dynamic>? ?? [];
        for (var actor in castList.take(5)) {
          final actorId = actor['id'].toString();
          final actorName = actor['name'] as String;
          final weight = _actorWeight * interactionStrength;
          _updateFeatureWeight(actors, actorId, actorName, weight);
        }

        // Process directors with balanced weight
        final crewList = credits['crew'] as List<dynamic>? ?? [];
        for (var person in crewList) {
          if (person['job'] == 'Director') {
            final directorId = person['id'].toString();
            final directorName = person['name'] as String;
            final weight = _directorWeight * interactionStrength;
            _updateFeatureWeight(directors, directorId, directorName, weight);
          }
        }

        // Process decades
        final releaseDate = details['release_date'] ?? 
            details['first_air_date'] as String?;
        if (releaseDate != null && releaseDate.isNotEmpty) {
          final year = DateTime.parse(releaseDate).year;
          final decade = '${(year ~/ 10) * 10}';
          final weight = _decadeWeight * interactionStrength;
          _updateFeatureWeight(
            decades, 
            decade, 
            '${decade}s', 
            weight
          );
        }

        totalRating += (details['vote_average'] as num?)?.toDouble() ?? 0.0;
      } catch (e) {
        if (kDebugMode) {
          print('Error processing item ${item.id}: $e');
        }
      }
    }

    return TasteProfile(
      genres: _normalizeFeatureMap(genres),
      actors: _normalizeFeatureMap(actors),
      directors: _normalizeFeatureMap(directors),
      decades: _normalizeFeatureMap(decades),
      averageRating: selectedItems.isEmpty 
          ? 0.0 
          : totalRating / selectedItems.length,
      lastUpdated: DateTime.now(),
    );
  }

  void _updateFeatureWeight(
    Map<String, Map<String, dynamic>> map,
    String id,
    String name,
    double weight,
  ) {
    if (!map.containsKey(id)) {
      map[id] = {
        'name': name,
        'weight': 0.0,
      };
    }
    map[id]!['weight'] = (map[id]!['weight'] as double) + weight;
  }

  Map<String, Map<String, dynamic>> _normalizeFeatureMap(
    Map<String, Map<String, dynamic>> map
  ) {
    final total = map.values
        .fold(0.0, (sum, item) => sum + (item['weight'] as double));
    
    if (total == 0) return map;
    
    for (var entry in map.values) {
      entry['weight'] = (entry['weight'] as double) / total;
    }
    
    return map;
  }

  double _calculateInteractionStrength(
    double voteAverage,
    DateTime selectionTime,
  ) {
    final baseValue = 1.0;
    final ratingFactor = (voteAverage / 10) * 0.5 + 0.75;
    
    final daysSinceSelection = DateTime.now()
        .difference(selectionTime)
        .inDays;
    final decayFactor = pow(0.9, daysSinceSelection / 30);
    
    return baseValue * ratingFactor * decayFactor;
  }
}