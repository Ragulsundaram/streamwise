import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../../constants/colors.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final username = context.watch<AuthProvider>().username;
    final email = context.watch<AuthProvider>().email ?? 'No email available';

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            width: MediaQuery.of(context).size.width,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withOpacity(0.6),
                        AppColors.background,
                      ],
                      stops: const [0.05, 0.6],  // Adjusted to stop at container
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 120),  // Updated margin
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.bottomLeft,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,  // Changed from start to center
                      children: [
                        // Profile Photo Container
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[800],
                            border: Border.all(
                              color: Colors.white24,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Iconsax.user,
                            color: Colors.white54,
                            size: 40,
                          ),
                        ),
                        const SizedBox(width: 20),
                        // Info Container
                        Expanded(
                          child: SizedBox(
                            height: 80,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  email,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  username ?? 'User',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                SizedBox(
                                  height: 28,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      // TODO: Implement settings navigation
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black38,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 0,
                                      ),
                                      minimumSize: const Size(0, 24),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    icon: const Icon(Iconsax.setting_2, size: 14),
                                    label: const Text(
                                      'Edit Settings',
                                      style: TextStyle(fontSize: 12),
                                    ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}