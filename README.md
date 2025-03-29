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
```plaintext
```