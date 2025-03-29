import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../services/tmdb_service.dart';
import '../../models/media_item.dart';
import '../../models/profile/taste_profile.dart';
import '../../providers/auth_provider.dart';
import '../details/movie_details_screen.dart';
import '../details/series_details_screen.dart';
import '../../widgets/matches/top_matches_section.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool isToday = true;
  bool isMovie = true;  // Add this
  final TMDBService _tmdbService = TMDBService();
  List<MediaItem> _trendingItems = [];
  List<MediaItem> _newReleaseItems = [];  // Add this
  bool _isLoading = false;
  bool _isNewReleasesLoading = false;  // Add this
  final ScrollController _scrollController = ScrollController();
  final ScrollController _newReleasesScrollController = ScrollController();  // Add this
  int _currentPage = 1;
  int _newReleasesPage = 1;  // Add this

  @override
  void initState() {
    super.initState();
    _fetchTrendingItems();
    _fetchNewReleases();  // Add this
    _scrollController.addListener(_onScroll);
    _newReleasesScrollController.addListener(_onNewReleasesScroll);  // Add this
  }

  // Add this method


  // Add this method
  void _onNewReleasesScroll() {
    if (_newReleasesScrollController.position.pixels == 
        _newReleasesScrollController.position.maxScrollExtent) {
      _loadMoreNewReleases();
    }
  }

  // Add this method
  Future<void> _loadMoreNewReleases() async {
    if (!_isNewReleasesLoading) {
      _newReleasesPage++;
      await _fetchNewReleases(page: _newReleasesPage, loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.background,
      onRefresh: () async {
        _currentPage = 1;
        _newReleasesPage = 1;  // Reset new releases page
        await Future.wait<void>([
          _fetchTrendingItems(),
          _fetchNewReleases(),
        ]);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Trending',
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
                          _buildToggleButton(true, 'Today'),
                          _buildToggleButton(false, 'This Week'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 220,
                child: _trendingItems.isEmpty && !_isLoading
                    ? const Center(
                        child: Text(
                          'No trending items found',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: _trendingItems.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _trendingItems.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final item = _trendingItems[index];
                          return _buildMediaCard(item);
                        },
                      ),
              ),
              const SizedBox(height: 24),  // Add spacing between sections

              // New Releases Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'New Releases',
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
                child: _newReleaseItems.isEmpty && !_isNewReleasesLoading
                    ? const Center(
                        child: Text(
                          'No new releases found',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        controller: _newReleasesScrollController,
                        scrollDirection: Axis.horizontal,
                        itemCount: _newReleaseItems.length + (_isNewReleasesLoading ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _newReleaseItems.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final item = _newReleaseItems[index];
                          return _buildMediaCard(item);
                        },
                      ),
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.username == null) {
                    return const SizedBox.shrink();
                  }
                  return FutureBuilder<TasteProfile?>(
                    future: TasteProfile.loadSavedProfile(authProvider.username!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const SizedBox.shrink();
                      }
                      return TopMatchesSection(userProfile: snapshot.data!);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Inside _DiscoverScreenState class
  // Fix 1: Remove extra indentation for _onMediaTap and _buildMediaCard methods
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

  Widget _buildMediaCard(MediaItem item) {
    return GestureDetector(
      onTap: () => _onMediaTap(item.id, item.mediaType),
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

  Widget _buildToggleButton(bool isForToday, String text) {
    final isSelected = isToday == isForToday;
    return GestureDetector(
      onTap: () {
        if (isToday != isForToday) {
          setState(() {
            isToday = isForToday;
            _currentPage = 1;
            _trendingItems.clear();
          });
          _fetchTrendingItems();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,  // Reduced from 16
          vertical: 6,    // Reduced from 8
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),  // Reduced from 20
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 12,  // Added smaller font size
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _newReleasesScrollController.dispose();  // Add this
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreItems();
    }
  }

  Future<void> _loadMoreItems() async {
    if (!_isLoading) {
      _currentPage++;
      await _fetchTrendingItems(page: _currentPage, loadMore: true);
    }
  }

  Future<void> _fetchTrendingItems({int page = 1, bool loadMore = false}) async {
    setState(() => _isLoading = true);
    try {
      final timeWindow = isToday ? 'day' : 'week';
      final response = await _tmdbService.getTrendingMedia(timeWindow, page);
      setState(() {
        if (loadMore) {
          _trendingItems.addAll(response);
        } else {
          _trendingItems = response;
        }
      });
    } catch (e) {
      debugPrint('Error fetching trending items: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Add these class variables at the top of _DiscoverScreenState
  List<MediaItem> _cachedMovies = [];
  List<MediaItem> _cachedTV = [];
  bool _hasCachedData = false;
  

  
  // Remove any other implementations of _fetchNewReleases in the file
  
  // Update the _buildMediaTypeToggle method
  Widget _buildMediaTypeToggle(bool isMovieToggle, String text) {
    final isSelected = isMovie == isMovieToggle;
    return GestureDetector(
      onTap: () {
        if (isMovie != isMovieToggle) {
          setState(() => isMovie = isMovieToggle);
          // Check if cached data exists before assigning
          final newItems = isMovie ? _cachedMovies : _cachedTV;
          if (newItems.isEmpty) {
            // Force fetch if cache is empty
            _hasCachedData = false;
            _fetchNewReleases();
          } else {
            setState(() => _newReleaseItems = newItems);
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

  // Update the caching implementation in _fetchNewReleases
  Future<void> _fetchNewReleases({int page = 1, bool loadMore = false}) async {
    setState(() => _isNewReleasesLoading = true);
    try {
      final currentType = isMovie ? 'movie' : 'tv';
      
      if (!_hasCachedData || (loadMore && page > 1)) {
        final response = await _tmdbService.getNewReleases(currentType, page);
        
        setState(() {
          if (isMovie) {
            _cachedMovies = loadMore ? [..._cachedMovies, ...response] : response;
            _hasCachedData = _cachedMovies.isNotEmpty;
          } else {
            _cachedTV = loadMore ? [..._cachedTV, ...response] : response;
            _hasCachedData = _cachedTV.isNotEmpty;
          }
          _newReleaseItems = isMovie ? _cachedMovies : _cachedTV;
        });
      } else {
        final cachedItems = isMovie ? _cachedMovies : _cachedTV;
        setState(() => _newReleaseItems = cachedItems.isNotEmpty 
            ? cachedItems 
            : []);
      }
    } catch (e) {
      debugPrint('Error fetching new releases: $e');
    } finally {
      setState(() => _isNewReleasesLoading = false);
    }
  }
}