import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/tmdb_service.dart';
import '../../services/matcher_service.dart';
import '../../models/profile/taste_profile.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class MovieDetailsScreen extends StatefulWidget {
  final int movieId;

  const MovieDetailsScreen({
    super.key,
    required this.movieId,
  });

  @override
  State<MovieDetailsScreen> createState() => _MovieDetailsScreenState();
}

class _MovieDetailsScreenState extends State<MovieDetailsScreen> {
  final TMDBService _tmdbService = TMDBService();
  bool _isLoading = true;
  Map<String, dynamic>? _movieDetails;
  double? _matchPercentage;

  @override
  void initState() {
    super.initState();
    _fetchMovieDetails();
  }

  Future<void> _fetchMovieDetails() async {
    try {
      final details = await _tmdbService.getMediaDetails(widget.movieId, 'movie');
      final credits = await _tmdbService.getMediaCredits(widget.movieId, 'movie');
      details['credits'] = credits;
      
      // Get user profile and calculate match
      final username = context.read<AuthProvider>().username;
      if (username != null) {
        final userProfile = await TasteProfile.loadSavedProfile(username);
        if (userProfile != null) {
          _matchPercentage = MatcherService.calculateMatchPercentage(details, userProfile);
        }
      }

      setState(() {
        _movieDetails = details;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching movie details: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // In the Stack children, add the match badge
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: false, // Change to false
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
          : _movieDetails == null
              ? const Center(child: Text('Failed to load movie details'))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Backdrop Image and Details Section
                      // !!! IMPORTANT: DO NOT MODIFY THESE VALUES !!!
                      // These specific dimensions and spacing values are crucial for maintaining
                      // consistent layout across different title lengths
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.35,
                        width: double.infinity,
                        child: Stack(
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
                                'https://image.tmdb.org/t/p/original${_movieDetails!['backdrop_path']}',
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
                            // Keep only this match percentage overlay
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
                                      _movieDetails!['vote_average'].toStringAsFixed(1),
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
                            // Movie Details Overlay
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 16,
                              child: Column(
                                mainAxisSize: MainAxisSize.min, // Important for consistent spacing
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    _movieDetails!['title'],
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
                                        _movieDetails!['genres'][0]['name'],
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
                                        _movieDetails!['adult'] ? 'R' : 'PG-13',
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
                                        DateTime.parse(_movieDetails!['release_date']).year.toString(),
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
                                        '${(_movieDetails!['runtime'] ~/ 60)}h ${_movieDetails!['runtime'] % 60}m',
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
                        padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0), // Adjusted padding
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
                              _movieDetails!['overview'] ?? 'No synopsis available.',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 16), // Reduced spacing
                            Container(
                              height: 1,
                              color: Colors.white12,
                            ),
                          ],
                        ),
                      ),
                      
                      // Cast Section
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
                                itemCount: _movieDetails!['credits']['cast'].length,
                                itemBuilder: (context, index) {
                                  final cast = _movieDetails!['credits']['cast'][index];
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