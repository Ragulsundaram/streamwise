# StreamWise

A Flutter application for video streaming with secure user authentication and content discovery.

## Features

- User Authentication
  - Username-based login system
  - Secure password hashing
  - Email verification during signup
  - Password strength validation
  - Duplicate username/email prevention

- Content Discovery
  - Trending movies and TV shows
  - New releases section with separate Movies and TV Shows tabs
  - Personalized recommendations based on taste profile
  - Rating display for media items
  - Infinite scrolling for content loading

- Media Management
  - Separate movie and TV show details screens
  - Cached content for better performance
  - Dynamic content loading with pagination
  - Vote average display with visual indicators

- UI Features
  - Clean and modern interface
  - Form validation
  - Responsive design
  - Custom icon integration using Iconsax
  - Consistent branding with primary color scheme
  - Pull-to-refresh functionality
  - Toggle switches for content filtering
  - Horizontal scrolling media cards

## Technical Details

- State Management: Provider
- Local Storage: SharedPreferences for user data
- Security: SHA-256 hashing with salt for passwords
- API Integration: TMDB API for media content
- Caching: In-memory caching for media lists
- Debug Features: User data clearing option in debug mode
- UI Components: Custom widgets for media cards and sections

## Getting Started

1. Clone the repository
```bash
git clone https://github.com/Ragulsundaram/streamwise.git

2. Install dependencies
```bash
flutter pub get
 ```

3. Run the application
```bash
flutter run
 ```

## Dependencies
- flutter_sdk: ">=3.0.0 <4.0.0"
- provider: State management
- iconsax: Icon pack
- shared_preferences: Local storage
- http: API requests

## Design Solutions

### Dynamic Content Spacing in Details Screens

The movie and series details screens implement a dynamic spacing solution to handle varying content lengths:

#### Problem
- With fixed spacing, short titles created unnecessary gaps between elements
- Long titles would push other content down inconsistently
- Inconsistent visual hierarchy between movie/series details and synopsis sections

#### Solution
- Anchored the title overlay to a fixed position at the bottom of the backdrop
- Implemented dynamic content growth downwards instead of pushing elements up
- Used `mainAxisSize: MainAxisSize.min` to ensure content takes minimum required space
- Maintained consistent padding between sections regardless of content length
- Standardized the approach across both movie and series detail screens

This solution ensures:
- Consistent visual layout regardless of title length
- Optimal space utilization
- Better user experience with predictable content placement
- Unified design language across different media types
