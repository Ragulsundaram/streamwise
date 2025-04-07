import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/tmdb_service.dart';
import '../../services/matcher_service.dart';
import '../../models/profile/taste_profile.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:iconsax/iconsax.dart'; // Add this import
import '../../models/likes/liked_item.dart'; 
import '../../models/watch/watched_item.dart';  // Add this import

class SeriesDetailsScreen extends StatefulWidget {
  final int seriesId;

  const SeriesDetailsScreen({
    super.key,
    required this.seriesId,
  });

  @override
  State<SeriesDetailsScreen> createState() => _SeriesDetailsScreenState();
}

class _SeriesDetailsScreenState extends State<SeriesDetailsScreen> {
  final TMDBService _tmdbService = TMDBService();
  bool _isLoading = true;
  Map<String, dynamic>? _seriesDetails;
  double? _matchPercentage;
  // Add these state variables
  bool _isLiked = false;
  bool _isDisliked = false;
  bool _isSaved = false;
  List<LikedItem> _likedItems = [];
  String? _username;

  @override
  void initState() {
    super.initState();
    _username = context.read<AuthProvider>().username;
    _fetchSeriesDetails();
    _loadLikedState();  // Add this
  }

  Future<void> _loadLikedState() async {
    if (_username != null) {
      final likedItems = await LikedItem.loadLikedItems(_username!);
      debugPrint('Loaded liked items for $_username: ${likedItems.length} items');
      setState(() {
        _likedItems = likedItems;
        _isLiked = likedItems.any((item) => 
          item.id == widget.seriesId && item.mediaType == 'tv');
        debugPrint('Series ${widget.seriesId} like status: $_isLiked');
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_username == null) return;

    setState(() => _isLiked = !_isLiked);

    if (_isLiked) {
      // Add to liked items
      _likedItems.add(LikedItem(
        id: widget.seriesId,
        mediaType: 'tv',
        likedAt: DateTime.now(),
      ));

      // Add to watched items
      if (_seriesDetails != null) {
        final watchedItem = WatchedItem(
          id: widget.seriesId,
          title: _seriesDetails!['name'],
          posterPath: 'https://image.tmdb.org/t/p/w500${_seriesDetails!['poster_path']}',
          mediaType: 'tv',
          watchedAt: DateTime.now(),
          voteAverage: (_seriesDetails!['vote_average'] as num).toDouble(),
        );
        final watchedItems = await WatchedItem.loadWatchedItems(_username!);
        if (!watchedItems.any((item) => item.id == widget.seriesId && item.mediaType == 'tv')) {
          watchedItems.add(watchedItem);
          await WatchedItem.saveWatchedItems(_username!, watchedItems);
        }
      }
    } else {
      _likedItems.removeWhere((item) => 
        item.id == widget.seriesId && item.mediaType == 'tv');
    }

    if (_isDisliked) setState(() => _isDisliked = false);
    await LikedItem.saveLikedItems(_username!, _likedItems);
  }

  Future<void> _fetchSeriesDetails() async {
    try {
      final details = await _tmdbService.getMediaDetails(widget.seriesId, 'tv');
      final credits = await _tmdbService.getMediaCredits(widget.seriesId, 'tv');
      details['credits'] = credits;
      
      final username = context.read<AuthProvider>().username;
      if (username != null) {
        final userProfile = await TasteProfile.loadSavedProfile(username);
        if (userProfile != null) {
          _matchPercentage = MatcherService.calculateMatchPercentage(details, userProfile);
        }
      }

      setState(() {
        _seriesDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching series details: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _seriesDetails == null
              ? const Center(child: Text('Failed to load series details'))
              : SingleChildScrollView( // Change Stack to SingleChildScrollView
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // !!! IMPORTANT: DO NOT MODIFY THESE VALUES !!!
                      // These specific dimensions and spacing values are crucial for maintaining
                      // consistent layout across different title lengths
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.35,
                        width: MediaQuery.of(context).size.width, // Make width responsive
                        child: Stack(
                          fit: StackFit.expand, // Ensure stack fills the available space
                          children: [
                            ShaderMask(
                              shaderCallback: (rect) {
                                return LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black,
                                    Colors.black.withOpacity(0.5),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.7, 1.0],
                                ).createShader(rect);
                              },
                              blendMode: BlendMode.dstIn,
                              child: Image.network(
                                'https://image.tmdb.org/t/p/original${_seriesDetails!['backdrop_path']}',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[900],
                                    child: const Center(
                                      child: Icon(
                                        Icons.error_outline,
                                        color: Colors.white54,
                                        size: 48,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            // Match percentage badge (already exists)
                            if (_matchPercentage != null)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: MatcherService.buildMatchBadge(_matchPercentage!),
                              ),
                            
                            // Add TMDB Rating
                            Positioned(
                              top: 16,
                              left: 16,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _seriesDetails!['vote_average'].toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Series Details Overlay
                                        Positioned(
                                          left: 16,
                                          right: 16,
                                          bottom: 16,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                _seriesDetails!['name'],
                                                textAlign: TextAlign.center,
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  height: 1.2,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    _seriesDetails!['genres'][0]['name'],
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const Text(
                                                    ' • ',
                                                    style: TextStyle(color: Colors.white70),
                                                  ),
                                                  Text(
                                                    _seriesDetails!['adult'] ? 'R' : 'PG-13',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const Text(
                                                    ' • ',
                                                    style: TextStyle(color: Colors.white70),
                                                  ),
                                                  Text(
                                                    DateTime.parse(_seriesDetails!['first_air_date']).year.toString(),
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const Text(
                                                    ' • ',
                                                    style: TextStyle(color: Colors.white70),
                                                  ),
                                                  Text(
                                                    '${_seriesDetails!['number_of_seasons']} Season${_seriesDetails!['number_of_seasons'] > 1 ? 's' : ''}',
                                                    style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  // Synopsis Section
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Synopsis',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _seriesDetails!['overview'] ?? 'No synopsis available.',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 14,
                                            height: 1.5,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Add Creator/Director section here
                                        Row(
                                          children: [
                                            const Text(
                                              'Creator: ',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Expanded(
                                              child: Text(
                                                (_seriesDetails!['created_by'] as List)
                                                    .map((creator) => creator['name'] as String)
                                                    .join(', '),
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        // Action Buttons Row
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // Share Button
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    width: 42,
                                                    height: 42,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: Colors.white24,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(
                                                        Iconsax.share,
                                                        color: Colors.white,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        // Handle share
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  const Text(
                                                    'Share',
                                                    style: TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Like Button
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    width: 42,
                                                    height: 42,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: _isLiked ? AppColors.primary : Colors.white24,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        _isLiked ? Iconsax.like_15 : Iconsax.like_1,
                                                        color: _isLiked ? AppColors.primary : Colors.white,
                                                        size: 20,
                                                      ),
                                                      onPressed: _toggleLike,  // Update this line
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Like',
                                                    style: TextStyle(
                                                      color: _isLiked ? AppColors.primary : Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Dislike Button
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    width: 42,
                                                    height: 42,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: _isDisliked ? AppColors.primary : Colors.white24,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        _isDisliked ? Iconsax.dislike5 : Iconsax.dislike,
                                                        color: _isDisliked ? AppColors.primary : Colors.white,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          if (_isLiked) _isLiked = false;
                                                          _isDisliked = !_isDisliked;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Dislike',
                                                    style: TextStyle(
                                                      color: _isDisliked ? AppColors.primary : Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Save Button
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 16),
                                              child: Column(
                                                children: [
                                                  Container(
                                                    width: 42,
                                                    height: 42,
                                                    decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                        color: _isSaved ? AppColors.primary : Colors.white24,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: IconButton(
                                                      icon: Icon(
                                                        _isSaved ? Iconsax.archive_add1 : Iconsax.archive_add,
                                                        color: _isSaved ? AppColors.primary : Colors.white,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          _isSaved = !_isSaved;
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Save',
                                                    style: TextStyle(
                                                      color: _isSaved ? AppColors.primary : Colors.white70,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        // Add the divider line here
                                        Container(
                                          height: 1,
                                          color: Colors.white12,
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    ),
                                  ),
                                  
                                  // Cast Section
                                  if (_seriesDetails!['credits'] != null && 
                                      _seriesDetails!['credits']['cast'] != null &&
                                      (_seriesDetails!['credits']['cast'] as List).isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0), // Adjusted padding
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Text(
                                                'Cast',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          SizedBox(
                                            height: 120,
                                            child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: (_seriesDetails!['credits']['cast'] as List).length,
                                              itemBuilder: (context, index) {
                                                final cast = _seriesDetails!['credits']['cast'][index];
                                                if (cast['profile_path'] == null) return const SizedBox.shrink();
                                                return Container(
                                                  width: 80,
                                                  margin: EdgeInsets.only(
                                                    right: 12,
                                                    left: index == 0 ? 0 : 0,
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      ClipRRect(
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Image.network(
                                                          'https://image.tmdb.org/t/p/w185${cast['profile_path']}',
                                                          width: 80,
                                                          height: 80,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) {
                                                            return Container(
                                                              width: 80,
                                                              height: 80,
                                                              color: Colors.grey[900],
                                                              child: const Icon(
                                                                Icons.person,
                                                                color: Colors.white54,
                                                                size: 40,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Expanded(
                                                        child: Text(
                                                          cast['name'],
                                                          textAlign: TextAlign.center,
                                                          maxLines: 2,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: const TextStyle(
                                                            color: Colors.white70,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                    ],
                  ),
                ),
    );
  }
}
