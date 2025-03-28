import '../models/profile/taste_profile.dart';
import 'package:flutter/material.dart';

class MatcherService {
  static double calculateMatchPercentage(Map<String, dynamic> mediaDetails, TasteProfile userProfile) {
    double genreSimilarity = 0;
    double actorSimilarity = 0;
    double directorSimilarity = 0;
    double decadeSimilarity = 0;

    // Calculate genre similarity
    final mediaGenres = mediaDetails['genres'] as List<dynamic>;
    for (var genre in mediaGenres) {
      final genreId = genre['id'].toString();
      if (userProfile.genres.containsKey(genreId)) {
        genreSimilarity += userProfile.genres[genreId]!['weight'] as double;
      }
    }

    // Calculate actor similarity
    final credits = mediaDetails['credits'] as Map<String, dynamic>;
    final cast = credits['cast'] as List<dynamic>;
    for (var actor in cast.take(5)) {
      final actorId = actor['id'].toString();
      if (userProfile.actors.containsKey(actorId)) {
        actorSimilarity += userProfile.actors[actorId]!['weight'] as double;
      }
    }

    // Calculate director/creator similarity
    final crew = credits['crew'] as List<dynamic>;
    for (var person in crew) {
      if (person['job'] == 'Director' || person['job'] == 'Creator') {
        final creatorId = person['id'].toString();
        if (userProfile.directors.containsKey(creatorId)) {
          directorSimilarity += userProfile.directors[creatorId]!['weight'] as double;
        }
      }
    }

    // Calculate decade similarity
    final releaseDate = mediaDetails['release_date'] ?? mediaDetails['first_air_date'];
    if (releaseDate != null) {
      final releaseYear = DateTime.parse(releaseDate).year;
      final decade = '${(releaseYear ~/ 10) * 10}';
      if (userProfile.decades.containsKey(decade)) {
        decadeSimilarity = userProfile.decades[decade]!['weight'] as double;
      }
    }

    // Apply category weights
    final weightedSimilarity = (
      genreSimilarity * 0.5 +
      actorSimilarity * 0.2 +
      directorSimilarity * 0.2 +
      decadeSimilarity * 0.1
    );

    // Apply rating adjustment
    final mediaRating = (mediaDetails['vote_average'] as num).toDouble();
    final ratingDifference = mediaRating - userProfile.averageRating;
    final ratingAdjustment = 1 + (ratingDifference / 10);

    // Calculate final percentage
    final matchPercentage = (weightedSimilarity * ratingAdjustment * 100).clamp(0.0, 100.0);

    return matchPercentage.roundToDouble();
  }

  static Color getMatchColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.amber;
    return Colors.red;
  }

  static Widget buildMatchBadge(double matchPercentage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            color: getMatchColor(matchPercentage),
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '${matchPercentage.round()}% Match',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}