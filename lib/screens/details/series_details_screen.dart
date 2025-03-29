import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../services/tmdb_service.dart';
import '../../services/matcher_service.dart';
import '../../models/profile/taste_profile.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchSeriesDetails();
  }

  Future<void> _fetchSeriesDetails() async {
    try {
      final details = await _tmdbService.getMediaDetails(widget.seriesId, 'tv');
      
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
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
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
                                    padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 16.0),
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
                                      ],
                                    ),
                                  ),
                    ],
                  ),
                ),
    );
  }
}