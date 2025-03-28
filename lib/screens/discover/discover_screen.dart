import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../constants/colors.dart';
import '../../services/tmdb_service.dart';
import '../../models/media_item.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool isToday = true;
  final TMDBService _tmdbService = TMDBService();
  List<MediaItem> _trendingItems = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _fetchTrendingItems();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.primary,  // Add this
      backgroundColor: AppColors.background,  // Add this
      onRefresh: () async {
        _currentPage = 1;
        await _fetchTrendingItems();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),  // Changed padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),  // Add padding
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
                      padding: const EdgeInsets.all(2),  // Reduced from 4
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),  // Reduced from 20
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
                height: 220,  // Reduced from 280
                child: _trendingItems.isEmpty && !_isLoading
                    ? const Center(
                        child: Text(
                          'No trending items found',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),  // Add padding
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaCard(MediaItem item) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to detail page
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 140,  // Reduced from 160
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 2/3,  // Keeping the same aspect ratio
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
}