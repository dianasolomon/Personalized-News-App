import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'article_detail_screen.dart';

class NewsFeedScreen extends StatefulWidget {
  const NewsFeedScreen({super.key});

  @override
  _NewsFeedScreenState createState() => _NewsFeedScreenState();
}

class _NewsFeedScreenState extends State<NewsFeedScreen> {
  String persona = "Student";
  List<String> interests = [];
  List<dynamic> feed = [];
  List<dynamic> trackedStories = [];
  bool isLoading = true;
  int xp = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      persona = prefs.getString('persona') ?? 'Student';
      interests = prefs.getStringList('interests') ?? [];
      xp = prefs.getInt('xp') ?? 100;
    });
    
    final data = await ApiService.getPersonalizedFeed(persona, interests);
    final trackedData = await ApiService.getTrackedStories("default_user");
    if(mounted) {
      setState(() {
        feed = data;
        trackedStories = trackedData;
        isLoading = false;
      });
    }
  }
  
  void _gainXp(int amount) async {
      setState(() { xp += amount; });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('xp', xp);
  }

  String? _getStoryImage(Map<String, dynamic> story) {
    final articles = story['articles'] as List<dynamic>?;
    if (articles != null && articles.isNotEmpty) {
      final imageUrl = articles[0]['image_url'];
      if (imageUrl != null && imageUrl.toString().isNotEmpty) {
        return imageUrl.toString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101014),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.cyanAccent),
          onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding'),
        ),
        title: Row(
          children: [
            const Icon(Icons.flash_on, color: Colors.amber),
            const SizedBox(width: 8),
            Text(
              "Level ${xp ~/ 100}",
              style: GoogleFonts.outfit(color: Colors.amber, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Chip(
              backgroundColor: Colors.deepPurple,
              label: Text(persona, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
        : feed.isEmpty 
            ? const Center(child: Text('No news available right now.', style: TextStyle(color: Colors.white)))
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: feed.length + (trackedStories.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (trackedStories.isNotEmpty && index == 0) {
                     return Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text("Tracked Stories", style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                         const SizedBox(height: 10),
                         SizedBox(
                           height: 100,
                           child: ListView.builder(
                             scrollDirection: Axis.horizontal,
                             itemCount: trackedStories.length,
                             itemBuilder: (context, idx) {
                               var ts = trackedStories[idx];
                               return Container(
                                 width: 250,
                                 margin: const EdgeInsets.only(right: 15),
                                 padding: const EdgeInsets.all(12),
                                 decoration: BoxDecoration(
                                   color: Colors.cyanAccent.withOpacity(0.05),
                                   borderRadius: BorderRadius.circular(15),
                                   border: Border.all(color: Colors.cyanAccent.withOpacity(0.3))
                                 ),
                                 child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                       Row(
                                         children: [
                                           const Icon(Icons.radar, color: Colors.cyanAccent, size: 16),
                                           const SizedBox(width: 5),
                                           Text("Tracking", style: GoogleFonts.inter(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                         ]
                                       ),
                                       const SizedBox(height: 8),
                                       Text(ts['title'] ?? 'Story', maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                    ]
                                 )
                               );
                             }
                           )
                         ),
                         const SizedBox(height: 25),
                         Text("Your Personalized Feed", style: GoogleFonts.outfit(color: Colors.cyanAccent.withOpacity(0.8), fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                         const SizedBox(height: 15),
                       ]
                     );
                  }
                  
                  final int storyIndex = trackedStories.isNotEmpty ? index - 1 : index;
                  final story = feed[storyIndex];
                  final tags = story['tags'] is List ? List<String>.from(story['tags']) : [];
                  final updatesCount = story['articles'] is List ? story['articles'].length : 1;
                  
                  return GestureDetector(
                    onTap: () {
                        _gainXp(30);
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArticleDetailScreen(story: story, persona: persona),
                            ),
                        );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A24),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                        boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 5))
                        ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Story cover image
                          if (_getStoryImage(story) != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(20),
                                topRight: Radius.circular(20),
                              ),
                              child: Image.network(
                                _getStoryImage(story)!,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  height: 180,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.deepPurple.withOpacity(0.3), Colors.cyanAccent.withOpacity(0.1)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(child: Icon(Icons.article, color: Colors.white30, size: 48)),
                                ),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 180,
                                    color: const Color(0xFF1A1A24),
                                    child: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 2)),
                                  );
                                },
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurpleAccent.withOpacity(0.3),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.deepPurpleAccent)
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.trending_up, color: Colors.cyanAccent, size: 14),
                                          const SizedBox(width: 5),
                                          Text(story['momentum'] ?? "Trending", style: GoogleFonts.outfit(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    Text("$updatesCount Updates", style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 15),
                                Text(story['storyTitle'] ?? 'Business Story', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                                const SizedBox(height: 10),
                                Text(story['summary'] ?? "Extracting insights...", style: GoogleFonts.inter(color: Colors.white70, height: 1.5)),
                                const SizedBox(height: 15),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: tags.take(3).map((tag) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(8)
                                    ),
                                    child: Text("#$tag", style: GoogleFonts.inter(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold))
                                  )).toList(),
                                )
                              ],
                            ),
                          ),
                        ],
                      )
                    ),
                  );
                },
              )
    );
  }
}
