import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';  // Add this import for debugPrint
import '../models/media_item.dart';
import '../models/profile/taste_profile.dart';
import 'dart:math';
import '../services/matcher_service.dart';

class TMDBService {
  final String baseUrl = 'https://api.themoviedb.org/3';
  final String apiKey = dotenv.env['TMDB_API_KEY'] ?? '';
  final String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';
  
  // Add cache variables
  static Map<String, List<MediaItem>> _topMatchesCache = {};
  static Map<String, DateTime> _lastFetchTime = {};

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
    {int limit = 10, bool forceRefresh = false}
  ) async {
    final cacheKey = mediaType;
    final now = DateTime.now();

    debugPrint('🔍 Starting getTopMatches - ForceRefresh: $forceRefresh, MediaType: $mediaType');

    if (!forceRefresh && _topMatchesCache.containsKey(cacheKey)) {
      final lastFetch = _lastFetchTime[cacheKey];
      if (lastFetch != null && now.difference(lastFetch).inHours < 24) {
        debugPrint('📦 Returning cached data for $mediaType');
        return _topMatchesCache[cacheKey]!;
      }
    }

    List<MediaItem> potentialMatches = [];
    List<MediaItem> matchedItems = [];
    
    try {
      debugPrint('🎬 Fetching fresh content...');
      
      // Fetch multiple pages of content
      final random = Random();
      final pageToFetch = random.nextInt(5) + 1; // Random page between 1-5
      
      final popularItems = await getPopularMedia(mediaType, pageToFetch);
      debugPrint('📈 Popular items fetched from page $pageToFetch: ${popularItems.length}');
      
      final trendingItems = await getTrendingMedia(
        random.nextBool() ? 'day' : 'week', 
        random.nextInt(3) + 1
      );
      debugPrint('🔥 Trending items fetched: ${trendingItems.length}');
      
      // Remove duplicates before adding to potential matches
      final seenIds = <int>{};
      
      void addUniqueItems(List<MediaItem> items) {
        for (var item in items) {
          if (!seenIds.contains(item.id)) {
            seenIds.add(item.id);
            potentialMatches.add(item);
          }
        }
      }
      
      addUniqueItems(popularItems);
      addUniqueItems(trendingItems.where((item) => item.mediaType == mediaType).toList());
      
      debugPrint('🎲 Total unique potential matches before shuffle: ${potentialMatches.length}');
      potentialMatches.shuffle();
      
      // Calculate matches for the combined list
      for (var item in potentialMatches) {
        try {
          final details = await getMediaDetails(item.id, mediaType);
          final match = MatcherService.calculateMatchPercentage(details, userProfile);
          debugPrint('✨ Match calculated for ${item.title}: $match%');
          item.matchPercentage = match;
          matchedItems.add(item);
        } catch (e) {
          debugPrint('❌ Error calculating match for item ${item.id}: $e');
          continue;
        }
      }
      
      matchedItems.sort((a, b) => (b.matchPercentage ?? 0).compareTo(a.matchPercentage ?? 0));
      debugPrint('📊 Total matched items after sorting: ${matchedItems.length}');
      
      final topMatches = matchedItems.take(limit).toList();
      debugPrint('🏆 Final top matches count: ${topMatches.length}');
      
      _topMatchesCache[cacheKey] = topMatches;
      _lastFetchTime[cacheKey] = now;
      
      return topMatches;
    } catch (e) {
      debugPrint('❌ Error in getTopMatches: $e');
      return _topMatchesCache[cacheKey] ?? [];
    }
  }
}