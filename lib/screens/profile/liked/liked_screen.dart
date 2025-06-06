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
    // Add listener to focus changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focus = FocusScope.of(context);
      focus.addListener(() {
        if (focus.hasFocus) {
          _loadLikedContent();
        }
      });
    });
  }

  Future<void> _onMediaTap(int id, String mediaType) {
    debugPrint('Tapped media: $mediaType $id');
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: mediaType == 'movie'
              ? MovieDetailsScreen(
                  movieId: id,
                  onLikeToggled: () {
                    debugPrint('Movie unlike triggered in liked screen');
                    setState(() {
                      _likedContent.removeWhere((item) => 
                        item['id'] == id && item['mediaType'] == mediaType);
                      debugPrint('Removed movie from UI immediately, remaining: ${_likedContent.length}');
                    });
                    _loadLikedContent(); // Refresh content immediately
                  },
                )
              : SeriesDetailsScreen(
                  seriesId: id,
                  onLikeToggled: () {
                    debugPrint('Series unlike triggered in liked screen');
                    setState(() {
                      _likedContent.removeWhere((item) => 
                        item['id'] == id && item['mediaType'] == mediaType);
                      debugPrint('Removed series from UI immediately, remaining: ${_likedContent.length}');
                    });
                    _loadLikedContent(); // Refresh content immediately
                  },
                ),
        ),
      ),
    );
  }

  Future<void> _loadLikedContent() async {
    debugPrint('Loading liked content...');
    final username = context.read<AuthProvider>().username;
    if (username == null) {
      debugPrint('No username found, skipping load');
      return;
    }

    final likedItems = await LikedItem.loadLikedItems(username);
    debugPrint('Loaded ${likedItems.length} liked items for user: $username');
    final contentDetails = <Map<String, dynamic>>[];

    for (var item in likedItems) {
      try {
        final details = await _tmdbService.getMediaDetails(item.id, item.mediaType);
        contentDetails.add({
          ...details,
          'mediaType': item.mediaType,
        });
        debugPrint('Loaded details for ${item.mediaType} ${item.id}');
      } catch (e) {
        debugPrint('Error loading details for ${item.mediaType} ${item.id}: $e');
      }
    }

    if (mounted) {
      setState(() {
        _likedContent = contentDetails;
        _isLoading = false;
        debugPrint('Updated liked content: ${_likedContent.length} items');
      });
    }
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
                    return GestureDetector(
                      onTap: () => _onMediaTap(item['id'], item['mediaType']),
                      child: MediaCard(
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
                      ),
                    );
                  },
                ),
    );
  }
}