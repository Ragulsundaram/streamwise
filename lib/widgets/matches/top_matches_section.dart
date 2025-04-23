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
  List<MediaItem> _moviesList = [];
  List<MediaItem> _tvList = [];
  bool _isLoadingMovies = false;
  bool _isLoadingTV = false;
  String? _currentActiveMediaType;

  List<MediaItem> get _matchedItems => isMovie ? _moviesList : _tvList;
  bool get _isLoading => isMovie ? _isLoadingMovies : _isLoadingTV;

  @override
  void initState() {
    super.initState();
    // Load both movies and TV shows on init
    _fetchTopMatches();
    _fetchTopMatches(isMovieOverride: false);
  }

  Future<void> _fetchTopMatches({bool forceRefresh = false, bool? isMovieOverride}) async {
    final currentMediaType = (isMovieOverride ?? isMovie) ? 'movie' : 'tv';
    
    // Remove the currentList variable since it's not used
    if (_isLoading && !forceRefresh) return; // Remove currentActiveMediaType check
    
    setState(() {
      if (isMovieOverride ?? isMovie) {
        _isLoadingMovies = true;
        if (forceRefresh) _moviesList = [];
      } else {
        _isLoadingTV = true;
        if (forceRefresh) _tvList = [];
      }
    });
    
    try {
      await _tmdbService.getTopMatches(
        currentMediaType,
        widget.userProfile,
        limit: 10,
        forceRefresh: forceRefresh,
        onMatchCalculated: (MediaItem item) {
          if (mounted) {  // Remove currentActiveMediaType check
            setState(() {
              if (isMovieOverride ?? isMovie) {
                _moviesList = [..._moviesList, item]
                  ..sort((a, b) => (b.matchPercentage ?? 0).compareTo(a.matchPercentage ?? 0));
              } else {
                _tvList = [..._tvList, item]
                  ..sort((a, b) => (b.matchPercentage ?? 0).compareTo(a.matchPercentage ?? 0));
              }
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Error fetching top matches: $e');
    } finally {
      if (mounted) {  // Remove currentActiveMediaType check
        setState(() {
          if (isMovieOverride ?? isMovie) {
            _isLoadingMovies = false;
          } else {
            _isLoadingTV = false;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  

  Widget _buildMediaTypeToggle(bool isMovieToggle, String text) {
    final isSelected = isMovie == isMovieToggle;
    return GestureDetector(
      onTap: () {
        if (isMovie != isMovieToggle) {
          setState(() => isMovie = isMovieToggle);
          if (_matchedItems.isEmpty) {
            _fetchTopMatches(forceRefresh: false);
          }
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
              Row(
                mainAxisSize: MainAxisSize.min, // Add this
                children: [
                  const Text(
                    'Top Matches',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Transform.translate( // Wrap IconButton with Transform
                    offset: const Offset(0, 0), // Move left by 8 pixels
                    child: IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                      onPressed: () => _fetchTopMatches(forceRefresh: true),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      iconSize: 20,
                    ),
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
                  // TMDB Rating
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
                            Icons.star_rounded,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}