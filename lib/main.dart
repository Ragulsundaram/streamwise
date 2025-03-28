import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:streamwise/constants/colors.dart';
import 'package:streamwise/screens/login_screen.dart';
import 'package:streamwise/screens/home_screen.dart';  // Add this import
import 'package:streamwise/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();
  
  final authProvider = AuthProvider();
  await authProvider.initialize();
  
  runApp(
    ChangeNotifierProvider.value(  // Changed from Provider to ChangeNotifierProvider
      value: authProvider,
      child: Builder(
        builder: (context) => MyApp(
          authProvider: Provider.of<AuthProvider>(context, listen: true),  // Added listen: true
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  
  const MyApp({
    super.key,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Streamwise',
      theme: AppColors.lightTheme,
      darkTheme: AppColors.darkTheme,
      themeMode: ThemeMode.dark,
      home: authProvider.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
