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

  Future<void> _fetchTopMatches({bool forceRefresh = false}) async {
    if (_isLoading && !forceRefresh) return;
    
    setState(() {
      _isLoading = true;
      _matchedItems = []; // Clear existing items when starting new fetch
    });
    
    try {
      final mediaType = isMovie ? 'movie' : 'tv';
      await _tmdbService.getTopMatches(
        mediaType, 
        widget.userProfile,
        limit: 10,
        forceRefresh: forceRefresh,
        onMatchCalculated: (MediaItem item) {
          if (mounted) {
            setState(() {
              _matchedItems = [..._matchedItems, item]
                ..sort((a, b) => (b.matchPercentage ?? 0).compareTo(a.matchPercentage ?? 0));
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Error fetching top matches: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildMediaTypeToggle(bool isMovieToggle, String text) {
    final isSelected = isMovie == isMovieToggle;
    return GestureDetector(
      onTap: () {
        if (isMovie != isMovieToggle) {
          setState(() {
            isMovie = isMovieToggle;
            // Only clear items, don't force refresh
            _matchedItems = [];
          });
          // Use cached data if available
          _fetchTopMatches(forceRefresh: false);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
              Row(
                children: [
                  const Text(
                    'Top Matches',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                    onPressed: () => _fetchTopMatches(forceRefresh: true),
                    padding: const EdgeInsets.only(left: 4),
                    constraints: const BoxConstraints(),
                    iconSize: 20,
                  ),
                ],
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
          height: 210,
          child: _isLoading && _matchedItems.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
              : _matchedItems.isEmpty
                  ? const Center(
                      child: Text(
                        'No matches found',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
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
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => item.mediaType == 'movie'
                ? MovieDetailsScreen(movieId: item.id)
                : SeriesDetailsScreen(seriesId: item.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}