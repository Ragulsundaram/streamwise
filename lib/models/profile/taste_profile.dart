import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TasteProfile {
  final Map<String, Map<String, dynamic>> genres;
  final Map<String, Map<String, dynamic>> actors;
  final Map<String, Map<String, dynamic>> directors;
  final Map<String, Map<String, dynamic>> decades;
  final double averageRating;
  final DateTime lastUpdated;

  TasteProfile({
    required this.genres,
    required this.actors,
    required this.directors,
    required this.decades,
    required this.averageRating,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'genres': genres,
    'actors': actors,
    'directors': directors,
    'decades': decades,
    'averageRating': averageRating,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory TasteProfile.fromJson(Map<String, dynamic> json) {
    return TasteProfile(
      genres: Map<String, Map<String, dynamic>>.from(json['genres']),
      actors: Map<String, Map<String, dynamic>>.from(json['actors']),
      directors: Map<String, Map<String, dynamic>>.from(json['directors']),
      decades: Map<String, Map<String, dynamic>>.from(json['decades']),
      averageRating: json['averageRating'],
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  void logProfile() {
    if (kDebugMode) {
      print('\n=== User Taste Profile ===');
      print('Last Updated: $lastUpdated\n');
      
      print('Top Genres:');
      _printSortedMap(genres);
      
      print('\nTop Actors:');
      _printSortedMap(actors);
      
      print('\nTop Directors:');
      _printSortedMap(directors);
      
      print('\nPreferred Decades:');
      _printSortedMap(decades);
      
      print('\nAverage Rating Preference: ${averageRating.toStringAsFixed(2)}');
    }
  }

  void _printSortedMap(Map<String, Map<String, dynamic>> map, {int? limit}) {
    final sortedEntries = map.entries.toList()
      ..sort((a, b) => (b.value['weight'] as double)
          .compareTo(a.value['weight'] as double));
    
    final entriesToShow = limit != null 
        ? sortedEntries.take(limit) 
        : sortedEntries;
    
    for (var entry in entriesToShow) {
      print('${entry.value['name']} (ID: ${entry.key}): '
          '${(entry.value['weight'] as double).toStringAsFixed(2)}');
    }
  }

  static Future<TasteProfile?> loadSavedProfile(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString('user_taste_profile_$username');
      
      if (profileJson != null) {
        final Map<String, dynamic> profileMap = json.decode(profileJson);
        return TasteProfile.fromJson(profileMap);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error loading taste profile: $e');
      }
      return null;
    }
  }

  // Add save method for convenience
  Future<bool> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString('user_taste_profile', json.encode(toJson()));
    } catch (e) {
      if (kDebugMode) {
        print('Error saving taste profile: $e');
      }
      return false;
    }
  }

  // Add this method after loadSavedProfile
  static Future<void> deleteProfile(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_taste_profile_$username');
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting taste profile: $e');
      }
    }
  }
}