import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'article_detail_screen.dart';

class TrackedStoriesScreen extends StatefulWidget {
  const TrackedStoriesScreen({super.key});

  @override
  _TrackedStoriesScreenState createState() => _TrackedStoriesScreenState();
}

class _TrackedStoriesScreenState extends State<TrackedStoriesScreen> {
  List<dynamic> trackedStories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrackedStories();
  }

  Future<void> _loadTrackedStories() async {
    setState(() => isLoading = true);
    final deviceId = await ApiService.getDeviceId();
    final data = await ApiService.getTrackedStories(deviceId);
    if (mounted) {
      setState(() {
        trackedStories = data;
        isLoading = false;
      });
    }
  }

  Future<void> _toggleTrack(Map<String, dynamic> story) async {
    final storyId =
        story['id']?.toString() ?? story['storyId']?.toString() ?? 'unknown';
    final deviceId = await ApiService.getDeviceId();
    await ApiService.toggleTrackStory(deviceId, storyId, story);
    _loadTrackedStories();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "SAVED STORIES",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 1.2,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent))
          : trackedStories.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trackedStories.length,
                  itemBuilder: (context, index) {
                    final story = trackedStories[index];
                    final tags = story['tags'] is List
                        ? List<String>.from(story['tags'])
                        : [];

                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArticleDetailScreen(
                              story: story,
                              persona:
                                  "User", // Persona is less critical here as arc is already generated
                            ),
                          ),
                        );
                        _loadTrackedStories();
                      },
                      child: Container(
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
                            ]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_getStoryImage(story) != null)
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                                child: Image.network(
                                  _getStoryImage(story)!,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                            story['storyTitle'] ??
                                                story['title'] ??
                                                'Business Story',
                                            style: GoogleFonts.outfit(
                                                fontSize: 20,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.favorite,
                                            color: Colors.redAccent),
                                        onPressed: () => _toggleTrack(story),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                      story['summary'] ??
                                          "Extracting insights...",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          height: 1.4,
                                          fontSize: 13)),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: tags
                                        .take(3)
                                        .map((tag) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                                color: Colors.white10,
                                                borderRadius:
                                                    BorderRadius.circular(8)),
                                            child: Text("#$tag",
                                                style: GoogleFonts.inter(
                                                    color: Colors.amber,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold))))
                                        .toList(),
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.white10),
          const SizedBox(height: 20),
          Text(
            "No Saved Stories",
            style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white30),
          ),
          const SizedBox(height: 10),
          Text(
            "Tap the heart on any story to save it here.",
            style: GoogleFonts.inter(color: Colors.white24),
          ),
        ],
      ),
    );
  }
}
