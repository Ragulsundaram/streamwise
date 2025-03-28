import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';  // Add for icons
import '../../constants/colors.dart';
import '../../models/media_item.dart';
import '../../models/profile/taste_profile.dart';
import '../../services/tmdb_service.dart';
import '../../screens/details/movie_details_screen.dart';
import '../../screens/details/series_details_screen.dart';

// Remove unused import
// import '../media_card.dart';

class TopMatchesSection extends StatefulWidget {
  final TasteProfile userProfile;
  
  const TopMatchesSection({
    super.key,
    required this.userProfile,
  });

  @override
  State<TopMatchesSection> createState() => _TopMatchesSectionState();
}

class _TopMatchesSectionState extends State<TopMatchesSection> {
  final TMDBService _tmdbService = TMDBService();
  final ScrollController _scrollController = ScrollController();
  bool isMovie = true;
  List<MediaItem> _matchedItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTopMatches();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchTopMatches() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final mediaType = isMovie ? 'movie' : 'tv';
      final matches = await _tmdbService.getTopMatches(
        mediaType, 
        widget.userProfile,
        limit: 10,
      );
      setState(() => _matchedItems = matches);
    } catch (e) {
      debugPrint('Error fetching top matches: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildMediaTypeToggle(bool isMovieToggle, String text) {
    final isSelected = isMovie == isMovieToggle;
    return GestureDetector(
      onTap: () {
        if (isMovie != isMovieToggle) {
          setState(() {
            isMovie = isMovieToggle;
            _matchedItems.clear();
          });
          _fetchTopMatches();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Top Matches',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildMediaTypeToggle(true, 'Movies'),
                    _buildMediaTypeToggle(false, 'TV Shows'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 220,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _matchedItems.isEmpty
                  ? const Center(
                      child: Text(
                        'No matches found',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      scrollDirection: Axis.horizontal,
                      itemCount: _matchedItems.length,
                      itemBuilder: (context, index) {
                        return _buildMediaCard(_matchedItems[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildMediaCard(MediaItem item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => item.mediaType == 'movie'
              ? MovieDetailsScreen(movieId: item.id)
              : SeriesDetailsScreen(seriesId: item.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 140,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 2/3,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      image: DecorationImage(
                        image: NetworkImage(item.posterPath),
                        fit: BoxFit.cover,
                        onError: (_, __) {},
                      ),
                    ),
                  ),
                  // Match Percentage
                  if (item.matchPercentage != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.magic_star,
                              color: AppColors.primary,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.matchPercentage!.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // TMDB Rating
                  if (item.voteAverage > 0.0 && !item.voteAverage.isNaN)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Iconsax.star1,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.voteAverage.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}