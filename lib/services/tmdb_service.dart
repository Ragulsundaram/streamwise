import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';  // Add this import for debugPrint
import '../models/media_item.dart';
import '../models/profile/taste_profile.dart';
import '../services/matcher_service.dart';

class TMDBService {
  final String baseUrl = 'https://api.themoviedb.org/3';
  final String apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  final String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  Future<List<MediaItem>> getPopularMedia(String type, int page) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$type/popular?api_key=$apiKey&page=$page'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((item) => MediaItem.fromJson(item, type))
          .toList();
    } else {
      throw Exception('Failed to load media');
    }
  }

  Future<Map<String, dynamic>> getMediaDetails(int id, String type) async {
    final response = await http.get(
      Uri.parse('$baseUrl/$type/$id?api_key=$apiKey&append_to_response=credits'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load media details');
    }
  }

  Future<List<MediaItem>> getTrendingMedia(String timeWindow, [int page = 1]) async {
      final response = await http.get(
        Uri.parse('$baseUrl/trending/all/$timeWindow?api_key=$apiKey&page=$page'),
      );
  
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['results'] as List)
            .map((item) => MediaItem.fromJson(item, item['media_type']))
            .toList();
      } else {
        throw Exception('Failed to load trending media');
      }
    }

  Future<List<MediaItem>> getNewReleases(String mediaType, int page) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/discover/$mediaType?api_key=$apiKey'
        '&sort_by=release_date.desc'
        '&page=$page'
        '&vote_count.gte=20'
        '&with_original_language=en'
        '${mediaType == "movie" 
          ? "&primary_release_date.lte=${DateTime.now().toIso8601String()}"
            "&primary_release_date.gte=${DateTime.now().subtract(const Duration(days: 90)).toIso8601String()}"
          : "&first_air_date.lte=${DateTime.now().toIso8601String()}"
            "&first_air_date.gte=${DateTime.now().subtract(const Duration(days: 90)).toIso8601String()}"
        }'
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return (data['results'] as List)
          .map((item) => MediaItem.fromJson(item, mediaType))
          .toList();
    } else {
      throw Exception('Failed to load new releases');
    }
  }

  Future<List<MediaItem>> getTopMatches(
    String mediaType, 
    TasteProfile userProfile, 
    {int limit = 10}
  ) async {
    List<MediaItem> matchedItems = [];
    
    try {
      // Fetch more pages for better matches
      for (int page = 1; page <= 3; page++) {  // Increased to 3 pages
        final items = await getPopularMedia(mediaType, page);
        for (var item in items) {
          try {
            final details = await getMediaDetails(item.id, mediaType);
            final match = MatcherService.calculateMatchPercentage(details, userProfile);
            
            // Lower threshold and always add items
            item.matchPercentage = match;
            matchedItems.add(item);
          } catch (e) {
            debugPrint('Error calculating match for item ${item.id}: $e');
            continue;
          }
        }
      }
      
      // Sort by match percentage (highest first)
      matchedItems.sort((a, b) => (b.matchPercentage ?? 0).compareTo(a.matchPercentage ?? 0));
      
      // Return top matches up to the limit
      return matchedItems.take(limit).toList();
    } catch (e) {
      debugPrint('Error in getTopMatches: $e');
      return [];
    }
  }
}