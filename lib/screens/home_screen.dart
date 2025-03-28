import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../constants/colors.dart';
import '../widgets/common/app_logo.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'discover/discover_screen.dart';  // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DiscoverScreen(),  // This will now use the correct implementation
    const SearchScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const AppLogo(
          iconSize: 24,
          fontSize: 20,
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthProvider>().logout();
              if (!mounted) return;
              
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          navigationBarTheme: NavigationBarThemeData(
            labelTextStyle: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const TextStyle(color: Colors.white);
              }
              return TextStyle(color: Colors.white.withOpacity(0.5));
            }),
          ),
        ),
        child: NavigationBar(
          backgroundColor: AppColors.background,
          indicatorColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          height: 65,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: [
            NavigationDestination(
              icon: Icon(
                _selectedIndex == 0 ? Iconsax.discover5 : Iconsax.discover,
                size: 24,
                color: _selectedIndex == 0 
                    ? AppColors.primary 
                    : Colors.white.withOpacity(0.5),
              ),
              label: 'Discover',
            ),
            NavigationDestination(
              icon: Icon(
                _selectedIndex == 1 ? Iconsax.search_favorite : Iconsax.search_normal,
                size: 24,
                color: _selectedIndex == 1 
                    ? AppColors.primary 
                    : Colors.white.withOpacity(0.5),
              ),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(
                _selectedIndex == 2 ? Iconsax.profile_circle5 : Iconsax.profile_circle,
                size: 24,
                color: _selectedIndex == 2 
                    ? AppColors.primary 
                    : Colors.white.withOpacity(0.5),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

// Remove the placeholder DiscoverScreen class
// Remove these classes:
// class DiscoverScreen extends StatelessWidget { ... }

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Search Screen',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profile Screen',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}