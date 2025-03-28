import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/media_item.dart';

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
}