import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';  // Add this import
import '../../constants/colors.dart';
import '../../models/media_item.dart';
import '../../screens/details/movie_details_screen.dart';
import '../../screens/details/series_details_screen.dart';

class MediaCard extends StatelessWidget {
  final MediaItem item;
  final double width;
  final double? height;
  final EdgeInsets? margin;

  const MediaCard({
    super.key,
    required this.item,
    this.width = 140,
    this.height,
    this.margin,
  });

  void _onTap(BuildContext context) {
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
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        width: width,
        height: height,
        margin: margin ?? const EdgeInsets.only(right: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 2/3,
            child: Stack(
              children: [
                // Poster Image
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
                // Rating Badge
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
                            Iconsax.star1,  // Changed to Iconsax star
                            color: Colors.amber,
                            size: 14,  // Adjusted size to match discover screen
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.voteAverage.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,  // Changed to bold
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
    );
  }
}