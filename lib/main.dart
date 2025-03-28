import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:streamwise/constants/colors.dart';
import 'package:streamwise/screens/login_screen.dart';
import 'package:streamwise/providers/auth_provider.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: 'Streamwise',
        theme: AppColors.lightTheme,
        darkTheme: AppColors.darkTheme,
        themeMode: ThemeMode.dark,
        home: const LoginScreen(),
      ),
    );
  }
}
