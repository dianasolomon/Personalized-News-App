import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/news_feed_screen.dart';
import 'screens/tracked_stories_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My ET - AI News',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark, // Sleek dark gamified UI
        primarySwatch: Colors.deepPurple,
        textTheme:
            GoogleFonts.outfitTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF101014),
      ),
      initialRoute: '/feed',
      routes: {
        '/feed': (context) => const NewsFeedScreen(),
        '/tracked': (context) => const TrackedStoriesScreen(),
      },
    );
  }
}
