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
      isLoading = true;
    });

    final allStories = await ApiService.getPersonalizedFeed(persona, interests);
    final deviceId = await ApiService.getDeviceId();
    final trackedData = await ApiService.getTrackedStories(deviceId);
    final trackedIds = trackedData.map((s) => s['id']?.toString()).toSet();

    if (mounted) {
      setState(() {
        trackedStories = trackedData;
        // Filter out stories that are already tracked
        feed = allStories.where((s) {
          final id = (s['storyId'] ?? s['id'])?.toString();
          return !trackedIds.contains(id);
        }).toList();
        isLoading = false;
      });
    }
  }

  Future<void> _changePersona(String newPersona) async {
    if (newPersona == persona) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('persona', newPersona);
    setState(() {
      persona = newPersona;
      isLoading = true;
    });
    await _loadData();
  }

  Future<void> _refreshTrackedStatusOnly() async {
    final deviceId = await ApiService.getDeviceId();
    final trackedData = await ApiService.getTrackedStories(deviceId);
    if (mounted) {
      setState(() {
        trackedStories = trackedData;
      });
    }
  }

  Future<void> _toggleTrack(Map<String, dynamic> story) async {
    final storyId = (story['storyId'] ?? story['id'])?.toString() ?? 'unknown';
    final deviceId = await ApiService.getDeviceId();

    await ApiService.toggleTrackStory(deviceId, storyId, story);

    final trackedData = await ApiService.getTrackedStories(deviceId);
    if (mounted) {
      setState(() {
        trackedStories = trackedData;
        // Story stays in `feed` visually until a hard refresh.
      });
    }
  }

  bool _isStoryTracked(String storyId) {
    return trackedStories.any((s) => s['id']?.toString() == storyId);
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.withOpacity(0.3),
            Colors.cyanAccent.withOpacity(0.1)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
          child: Icon(Icons.article, color: Colors.white30, size: 48)),
    );
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
        centerTitle: true,
        title: Text(
          "Personalized Feed",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.favorite, color: Colors.cyanAccent),
                if (trackedStories.isNotEmpty)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${trackedStories.length}',
                        style:
                            const TextStyle(fontSize: 9, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => Navigator.pushNamed(context, '/tracked')
                .then((_) => _loadData()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildPersonaSelector(),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent))
                : feed.isEmpty
                    ? const Center(
                        child: Text('No new stories.',
                            style: TextStyle(color: Colors.white54)))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: feed.length,
                        itemBuilder: (context, index) {
                          final story = feed[index];
                          final storyId =
                              (story['storyId'] ?? story['id'])?.toString() ??
                                  'unknown';
                          final isTracked = _isStoryTracked(storyId);
                          final tags = story['tags'] is List
                              ? List<String>.from(story['tags'])
                              : <String>[];
                          final updatesCount = story['articles'] is List
                              ? story['articles'].length
                              : 1;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A24),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white10),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Tappable image ─────────────────────────────
                                if (_getStoryImage(story) != null)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              ArticleDetailScreen(
                                                  story: story, persona: persona),
                                        ),
                                      ).then((_) => _loadData());
                                    },
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                    ).then((_) => _refreshTrackedStatusOnly());
                                  },
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(20),
                                      topRight: Radius.circular(20),
                                    ),
                                  ),

                                // ── Content below image ─────────────────────────
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 12, 12, 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Momentum chip + heart button in same row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurpleAccent
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color:
                                                      Colors.deepPurpleAccent),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.trending_up,
                                                    color: Colors.cyanAccent,
                                                    size: 14),
                                                const SizedBox(width: 5),
                                                Text(
                                                    story['momentum'] ??
                                                        "Trending",
                                                    style: GoogleFonts.outfit(
                                                        color:
                                                            Colors.cyanAccent,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                          // Heart button — clearly BELOW the image
                                          GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => _toggleTrack(story),
                                            child: Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Icon(
                                                isTracked
                                                    ? Icons.favorite
                                                    : Icons.favorite_border,
                                                color: isTracked
                                                    ? Colors.redAccent
                                                    : Colors.white30,
                                                size: 28,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Story text (tappable)
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ArticleDetailScreen(
                                                      story: story,
                                                      persona: persona),
                                            ),
                                          ).then((_) => _loadData());
                                        },
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                                story['storyTitle'] ??
                                                    'Business Story',
                                                style: GoogleFonts.outfit(
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white)),
                                            const SizedBox(height: 10),
                                            Text(
                                                story['summary'] ??
                                                    "Extracting insights...",
                                                style: GoogleFonts.inter(
                                                    color: Colors.white70,
                                                    height: 1.5)),
                                            const SizedBox(height: 15),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: tags
                                                      .take(2)
                                                      .map((tag) => Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        10,
                                                                    vertical:
                                                                        4),
                                                            decoration: BoxDecoration(
                                                                color: Colors
                                                                    .white10,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8)),
                                                            child: Text("#$tag",
                                                                style: GoogleFonts.inter(
                                                                    color: Colors
                                                                        .amber,
                                                                    fontSize:
                                                                        11,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold)),
                                                          ))
                                                      .toList(),
                                                ),
                                                Text("$updatesCount Updates",
                                                    style: GoogleFonts.inter(
                                                        color: Colors.white54,
                                                        fontSize: 12)),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonaSelector() {
    final List<String> personas = ['Investor', 'Founder', 'Student'];
    final Map<String, IconData> icons = {
      'Investor': Icons.trending_up,
      'Founder': Icons.rocket_launch,
      'Student': Icons.school,
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: personas.map((p) {
          final isSelected = p == persona;
          return GestureDetector(
            onTap: () => _changePersona(p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.cyanAccent.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isSelected ? Colors.cyanAccent : Colors.white12,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: Colors.cyanAccent.withOpacity(0.1),
                            blurRadius: 10)
                      ]
                    : [],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icons[p],
                    color: isSelected ? Colors.cyanAccent : Colors.white30,
                    size: 20,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p,
                    style: GoogleFonts.outfit(
                      color: isSelected ? Colors.white : Colors.white30,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
