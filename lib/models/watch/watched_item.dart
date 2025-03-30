import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../media_item.dart';
import '../../services/tmdb_service.dart';

class WatchedItem {
  final int id;
  final String title;
  final String posterPath;
  final String mediaType;
  final DateTime watchedAt;
  final double voteAverage;  // Add this field

  WatchedItem({
    required this.id,
    required this.title,
    required this.posterPath,
    required this.mediaType,
    required this.watchedAt,
    required this.voteAverage,  // Add this parameter
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'posterPath': posterPath,
    'mediaType': mediaType,
    'watchedAt': watchedAt.toIso8601String(),
    'voteAverage': voteAverage,  // Add this to JSON
  };

  factory WatchedItem.fromJson(Map<String, dynamic> json) {
    return WatchedItem(
      id: json['id'],
      title: json['title'],
      posterPath: json['posterPath'],
      mediaType: json['mediaType'],
      watchedAt: DateTime.parse(json['watchedAt']),
      voteAverage: json['voteAverage']?.toDouble() ?? 0.0,  // Parse from JSON
    );
  }

  // Add these static methods
  static Future<List<WatchedItem>> loadWatchedItems(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final watchedItemsString = prefs.getString('watched_items_$username');
      final tmdbService = TMDBService();
      
      if (watchedItemsString == null) {
        return [];
      }

      final List<dynamic> watchedItemsList = json.decode(watchedItemsString);
      List<WatchedItem> items = [];
      
      for (var item in watchedItemsList) {
        // Fetch current rating from TMDB
        final details = await tmdbService.getMediaDetails(
          item['id'],
          item['mediaType'],
        );
        
        items.add(WatchedItem(
          id: item['id'],
          title: item['title'],
          posterPath: item['posterPath'],
          mediaType: item['mediaType'],
          watchedAt: DateTime.parse(item['watchedAt']),
          voteAverage: details['vote_average']?.toDouble() ?? 0.0,
        ));
      }
      
      return items;
    } catch (e) {
      print('Error loading watched items: $e');
      return [];
    }
  }

  static Future<bool> saveWatchedItems(
      String username, List<WatchedItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final watchedItemsJson = items.map((item) => item.toJson()).toList();
      final String encodedJson = json.encode(watchedItemsJson);
      return await prefs.setString('watched_items_$username', encodedJson);
    } catch (e) {
      print('Error saving watched items: $e');
      return false;
    }
  }

  factory WatchedItem.fromMediaItem(MediaItem item) {
    return WatchedItem(
      id: item.id,
      title: item.title,
      posterPath: item.posterPath,
      mediaType: item.mediaType,
      watchedAt: DateTime.now(),
      voteAverage: item.voteAverage,
    );
  }
}