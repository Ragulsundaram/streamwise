import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LikedItem {
  final int id;
  final String mediaType;
  final DateTime likedAt;

  LikedItem({
    required this.id,
    required this.mediaType,
    required this.likedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'mediaType': mediaType,
    'likedAt': likedAt.toIso8601String(),
  };

  factory LikedItem.fromJson(Map<String, dynamic> json) {
    return LikedItem(
      id: json['id'],
      mediaType: json['mediaType'],
      likedAt: DateTime.parse(json['likedAt']),
    );
  }

  static Future<List<LikedItem>> loadLikedItems(String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likedItemsString = prefs.getString('liked_items_$username');
      
      if (likedItemsString == null) return [];

      final List<dynamic> likedItemsList = json.decode(likedItemsString);
      return likedItemsList
          .map((item) => LikedItem.fromJson(item))
          .toList();
    } catch (e) {
      print('Error loading liked items: $e');
      return [];
    }
  }

  static Future<bool> saveLikedItems(
      String username, List<LikedItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final likedItemsJson = items.map((item) => item.toJson()).toList();
      final String encodedJson = json.encode(likedItemsJson);
      return await prefs.setString('liked_items_$username', encodedJson);
    } catch (e) {
      print('Error saving liked items: $e');
      return false;
    }
  }
}