import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../../../constants/colors.dart';
import '../../../models/watch/watched_item.dart';
import '../../../models/media_item.dart';  // Add this import
import '../../../providers/auth_provider.dart';
import '../../details/movie_details_screen.dart';
import '../../details/series_details_screen.dart';
import '../../../widgets/media/media_card.dart';

class WatchedScreen extends StatefulWidget {
  const WatchedScreen({super.key});

  @override
  State<WatchedScreen> createState() => _WatchedScreenState();
}

class _WatchedScreenState extends State<WatchedScreen> {
  List<WatchedItem> _watchedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWatchedItems();
  }

  Future<void> _loadWatchedItems() async {
    final username = context.read<AuthProvider>().username;
    if (username != null) {
      print('Loading watched items for user: $username'); // Debug print
      final items = await WatchedItem.loadWatchedItems(username);
      print('Loaded ${items.length} watched items'); // Debug print
      if (mounted) {
        setState(() {
          _watchedItems = items;
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToDetails(WatchedItem item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => item.mediaType == 'movie'
            ? MovieDetailsScreen(movieId: item.id)
            : SeriesDetailsScreen(seriesId: item.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Watched'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _watchedItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.play_circle,
                        size: 64,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No watched content yet',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2/3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: _watchedItems.length,
                  itemBuilder: (context, index) {
                    final MediaItem mediaItem = MediaItem(
                      id: _watchedItems[index].id,
                      title: _watchedItems[index].title,
                      posterPath: _watchedItems[index].posterPath,
                      mediaType: _watchedItems[index].mediaType,
                      voteAverage: _watchedItems[index].voteAverage, // Use the vote average from WatchedItem
                    );
                    
                    return MediaCard(
                      item: mediaItem,
                      width: double.infinity,
                      margin: EdgeInsets.zero,
                    );
                  },
                ),
    );
  }
}