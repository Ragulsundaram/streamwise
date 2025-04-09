import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // Add this
import '../models/media_item.dart';
import '../models/watch/watched_item.dart';
import '../models/likes/liked_item.dart';  // Add this import
import '../services/tmdb_service.dart';
import '../services/profile_service.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';  // Add this
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamwise/screens/home_screen.dart';
import 'dart:convert';  // Add this import

class MediaSelectionScreen extends StatefulWidget {
  const MediaSelectionScreen({super.key});

  @override
  State<MediaSelectionScreen> createState() => _MediaSelectionScreenState();
}

class _MediaSelectionScreenState extends State<MediaSelectionScreen> {
  final _tmdbService = TMDBService();
  final List<MediaItem> _mediaItems = [];
  int _currentPage = 1;
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_onScroll);
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final movies = await _tmdbService.getPopularMedia('movie', _currentPage);
      final tvShows = await _tmdbService.getPopularMedia('tv', _currentPage);
      setState(() {
        _mediaItems.addAll([...movies, ...tvShows]);
        _currentPage++;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMoreData();
    }
  }

  Future<void> _loadMoreData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    
    try {
      final movies = await _tmdbService.getPopularMedia('movie', _currentPage);
      final tvShows = await _tmdbService.getPopularMedia('tv', _currentPage);
      setState(() {
        _mediaItems.addAll([...movies, ...tvShows]);
        _currentPage++;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: const Text('Select Your Favorites'),
            backgroundColor: AppColors.background.withOpacity(0.95),
            floating: true,
            snap: true,
            elevation: 0,
          ),
        ],
        body: _isLoading && _mediaItems.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : GridView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(
                  left: 8,
                  right: 8,
                  top: 8,
                  bottom: 80, // Add padding for FAB
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2/3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _mediaItems.length + (_isLoading ? 2 : 0),
                itemBuilder: (context, index) {
                  if (index >= _mediaItems.length) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final item = _mediaItems[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        item.isSelected = !item.isSelected;
                      });
                    },
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            '${_tmdbService.imageBaseUrl}${item.posterPath}',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              );
                            },
                          ),
                        ),
                        if (item.isSelected)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleContinue,
        backgroundColor: AppColors.primaryDark,
        elevation: 4,
        label: const Text(
          'Continue',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    final selectedItems = _mediaItems.where((item) => item.isSelected).toList();
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            backgroundColor: AppColors.background,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                const Text(
                  'Building Your Taste Profile...',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  '${selectedItems.length} items selected',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      final authProvider = context.read<AuthProvider>();
      final username = authProvider.username;
      
      if (username != null && username.isNotEmpty) {
        // Save selected items as watched (existing functionality)
        final watchedItems = selectedItems.map((item) => 
          WatchedItem.fromMediaItem(item)).toList();
        final savedWatched = await WatchedItem.saveWatchedItems(username, watchedItems);
        print('Saved watched items: ${watchedItems.length} items, success: $savedWatched');

        // Add new functionality: Save as liked items
        final likedItems = selectedItems.map((item) => 
          LikedItem(
            id: item.id,
            mediaType: item.mediaType,
            likedAt: DateTime.now(),
          )).toList();
        final savedLiked = await LikedItem.saveLikedItems(username, likedItems);
        print('Saved liked items: ${likedItems.length} items, success: $savedLiked');

        // Continue with existing taste profile generation
        final profileService = ProfileService(_tmdbService);
        final profile = await profileService.generateProfile(selectedItems);
        
        final prefs = await SharedPreferences.getInstance();
        final profileJson = jsonEncode(profile.toJson());
        await prefs.setString('user_taste_profile_$username', profileJson);
        profile.logProfile();
      } else {
        throw Exception('No username found');
      }

      if (!mounted) return;
      
      // Close loading dialog and navigate
      Navigator.of(context).pop(); // Close dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving taste profile')),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}