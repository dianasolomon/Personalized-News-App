import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/news_feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool hasOnboarded = prefs.getBool('has_onboarded') ?? false;

  runApp(MyApp(hasOnboarded: hasOnboarded));
}

class MyApp extends StatelessWidget {
  final bool hasOnboarded;
  
  const MyApp({super.key, required this.hasOnboarded});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My ET - AI News',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark, // Sleek dark gamified UI
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF101014),
      ),
      initialRoute: hasOnboarded ? '/feed' : '/onboarding',
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/feed': (context) => const NewsFeedScreen(),
      },
    );
  }
}
