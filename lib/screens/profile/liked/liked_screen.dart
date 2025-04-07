import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../models/likes/liked_item.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/tmdb_service.dart';
import '../../../widgets/media/media_card.dart';
import '../../../models/media_item.dart';  // Add this import
import '../../details/movie_details_screen.dart';
import '../../details/series_details_screen.dart';

class LikedScreen extends StatefulWidget {
  const LikedScreen({super.key});

  @override
  State<LikedScreen> createState() => _LikedScreenState();
}

class _LikedScreenState extends State<LikedScreen> {
  final TMDBService _tmdbService = TMDBService();
  List<Map<String, dynamic>> _likedContent = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLikedContent();
  }

  Future<void> _loadLikedContent() async {
    final username = context.read<AuthProvider>().username;
    if (username == null) return;

    final likedItems = await LikedItem.loadLikedItems(username);
    final contentDetails = <Map<String, dynamic>>[];

    for (var item in likedItems) {
      try {
        final details = await _tmdbService.getMediaDetails(item.id, item.mediaType);
        contentDetails.add({
          ...details,
          'mediaType': item.mediaType,
        });
      } catch (e) {
        debugPrint('Error loading details for ${item.mediaType} ${item.id}: $e');
      }
    }

    if (mounted) {
      setState(() {
        _likedContent = contentDetails;
        _isLoading = false;
      });
    }
  }

  void _onMediaTap(int id, String mediaType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => mediaType == 'movie'
            ? MovieDetailsScreen(movieId: id)
            : SeriesDetailsScreen(seriesId: id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Liked Content'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _likedContent.isEmpty
              ? const Center(child: Text('No liked content yet'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _likedContent.length,
                  itemBuilder: (context, index) {
                    final item = _likedContent[index];
                    return MediaCard(
                      item: MediaItem(
                        id: item['id'],
                        title: item['mediaType'] == 'movie' ? item['title'] : item['name'],
                        posterPath: item['poster_path'] != null 
                            ? 'https://image.tmdb.org/t/p/w500${item['poster_path']}'
                            : 'https://via.placeholder.com/500x750',
                        mediaType: item['mediaType'],
                        voteAverage: (item['vote_average'] as num?)?.toDouble() ?? 0.0,
                      ),
                      width: double.infinity,
                      margin: EdgeInsets.zero,
                    );
                  },
                ),
    );
  }
}