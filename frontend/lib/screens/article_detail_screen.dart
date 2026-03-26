import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../widgets/chat_interface.dart';
import '../widgets/story_timeline.dart';
import '../widgets/sentiment_graph.dart';
import '../widgets/contrarian_cards.dart';

class ArticleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> story;
  final String persona;

  const ArticleDetailScreen({super.key, required this.story, required this.persona});

  @override
  _ArticleDetailScreenState createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  Map<String, dynamic>? narrative;
  bool isLoading = true;
  bool isTracked = false;
  double _xpProgress = 0.2; 

  @override
  void initState() {
    super.initState();
    _loadNarrative();
  }

  Future<void> _loadNarrative() async {
    final queryTerms = widget.story['queryTerms'] ?? widget.story['storyTitle'] ?? "Business Trend";
    final articlesList = widget.story['articles'] as List<dynamic>? ?? [];
    // Pass rich context: title + description + source for unique arc generation
    final articlesContext = articlesList.map((a) {
      final title = a['title'] ?? '';
      final desc = a['description'] ?? '';
      final source = a['source_id'] ?? a['source_name'] ?? '';
      final filtered = desc.contains('ONLY AVAILABLE') ? '' : desc;
      return '$title | $filtered | Source: $source';
    }).join(" \n ");
    
    final data = await ApiService.getStoryArc(queryTerms, articlesContext, widget.persona);
    final trackedList = await ApiService.getTrackedStories("default_user");
    bool currentlyTracked = trackedList.any((s) => s['id'] == widget.story['storyId']);

    if(mounted) {
      setState(() {
        narrative = data;
        isTracked = currentlyTracked;
        isLoading = false;
        _xpProgress = 0.5;
      });
    }
  }

  Future<void> _toggleTrack() async {
    final status = await ApiService.toggleTrackStory(
        "default_user", 
        widget.story['storyId'] ?? 'unknown', 
        widget.story['storyTitle'] ?? 'Story'
    );
    if (status != null && mounted) {
      setState(() {
         isTracked = status == 'tracked';
         if (isTracked) _xpProgress = (_xpProgress + 0.1).clamp(0.0, 1.0);
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isTracked ? "Story Tracked!" : "Tracking Removed")));
    }
  }

  void _onNodeExplored() {
    setState(() {
      _xpProgress = (_xpProgress + 0.1).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F), // Deep futuristic dark
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.cyanAccent),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text("Story Arc: ${widget.story['storyTitle']?.substring(0, 15) ?? 'Tracker'}...", 
                 style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 5),
            SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                value: _xpProgress,
                backgroundColor: Colors.white10,
                color: Colors.amber,
                borderRadius: BorderRadius.circular(10),
              ),
            )
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isTracked ? Icons.favorite : Icons.favorite_border, color: isTracked ? Colors.pinkAccent : Colors.white54),
            onPressed: _toggleTrack,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text("XP: ${(_xpProgress * 1000).toInt()}", 
                style: GoogleFonts.outfit(color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: isLoading 
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.cyanAccent),
                SizedBox(height: 15),
                Text("Synthesizing Narrative Timeline...", style: TextStyle(color: Colors.white54))
              ],
            )
          )
        : Column(
            children: [
              // Top Section: AI Summary & Avatar Tracker
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF151520),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 20, spreadRadius: -5)
                  ]
                ),
                child: Text(
                  widget.story['summary'] ?? "Analyzing story...",
                  style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                ),
              ),
              
              const SizedBox(height: 20),

              // Middle: Interactive Gamified Timeline
              Expanded(
                flex: 4,
                child: StoryTimeline(
                  timelineEvents: narrative?['phases'] is List ? List<dynamic>.from(narrative!['phases']) : [],
                  persona: widget.persona,
                  onNodeKlicked: _onNodeExplored,
                ),
              ),

              // Bottom Panel: Chat Only
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF12121A),
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Ask the AI Oracle", style: GoogleFonts.outfit(fontSize: 18, color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 250,
                          child: ChatInterface(articleContent: widget.story['summary'] ?? 'Business constraints', persona: widget.persona),
                        )
                      ],
                    ),
                  ),
                ),
              )
            ],
          )
    );
  }
}
