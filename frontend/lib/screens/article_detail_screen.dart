import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/chat_interface.dart';
import '../widgets/story_timeline.dart';
import '../widgets/story_arc_details_sheet.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> story;
  final String persona;

  const ArticleDetailScreen(
      {super.key, required this.story, required this.persona});

  @override
  _ArticleDetailScreenState createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  Map<String, dynamic>? narrative;
  bool isLoading = true;
  bool isTracked = false;

  @override
  void initState() {
    super.initState();
    _loadNarrative();
  }

  Future<void> _loadNarrative() async {
    final queryTerms = widget.story['queryTerms'] ??
        widget.story['storyTitle'] ??
        "Business Trend";
    final articlesList = widget.story['articles'] as List<dynamic>? ?? [];

    final articlesContext = articlesList.map((a) {
      final title = a['title'] ?? '';
      final desc = a['description'] ?? '';
      final source = a['source_id'] ?? a['source_name'] ?? '';
      final filtered = desc.contains('ONLY AVAILABLE') ? '' : desc;
      return '$title | $filtered | Source: $source';
    }).join(" \n ");

    final data = await ApiService.getStoryArc(
        queryTerms, articlesContext, widget.persona);
    final deviceId = await ApiService.getDeviceId();
    final trackedList = await ApiService.getTrackedStories(deviceId);
    final storyId = (widget.story['storyId'] ?? widget.story['id'])?.toString();
    bool currentlyTracked =
        trackedList.any((s) => s['id']?.toString() == storyId);

    if (mounted) {
      setState(() {
        narrative = data;
        isTracked = currentlyTracked;
        isLoading = false;
      });
    }
  }

  Future<void> _toggleTrack() async {
    final deviceId = await ApiService.getDeviceId();
    final storyId = (widget.story['storyId'] ?? widget.story['id'])?.toString() ?? 'unknown';
    final status = await ApiService.toggleTrackStory(deviceId, storyId, widget.story);
    if (status != null && mounted) {
      setState(() {
        isTracked = status == 'tracked';
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(isTracked ? "Story Tracked!" : "Tracking Removed")));
    }
  }

  void _onNodeExplored(dynamic phase) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StoryArcDetailsSheet(
        phase: phase,
        persona: widget.persona,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Story Tracker',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(isTracked ? Icons.favorite : Icons.favorite_border,
                color: isTracked ? Colors.redAccent : Colors.white24),
            onPressed: _toggleTrack,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   CircularProgressIndicator(color: Colors.cyanAccent),
                   SizedBox(height: 15),
                   Text("Synthesizing Narrative Timeline...",
                       style: TextStyle(color: Colors.white54))
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Display the dynamic heading here so it can wrap endlessly
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Text(
                      widget.story['storyTitle'] ?? 'Story Tracker',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        color: const Color(0xFF151520),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.cyanAccent.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: -5)
                        ]),
                    child: Text(
                      widget.story['summary'] ?? "Analyzing story...",
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: narrative == null ||
                          narrative!['phases'] == null ||
                          (narrative!['phases'] as List).isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              "Failed to generate AI Timeline.\nGemini API quota exceeded or connection failed.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: Colors.redAccent.withOpacity(0.8),
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                          ),
                        )
                      : StoryTimeline(
                          timelineEvents:
                              List<dynamic>.from(narrative!['phases']),
                          persona: widget.persona,
                          onNodeKlicked: _onNodeExplored,
                          nextStory: narrative!['next_story'],
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showChat,
        backgroundColor: const Color(0xFF1A1A24),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
        ),
        icon: const Icon(Icons.auto_awesome, color: Colors.cyanAccent),
        label: Text(
          "ASK AI",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  void _showChat() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => ChatInterface(
          queryTerms: widget.story['queryTerms'] ??
              widget.story['storyTitle'] ??
              'Business News',
          persona: widget.persona,
        ),
      ),
    );
  }
}
