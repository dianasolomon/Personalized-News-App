import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sentiment_graph.dart';
import 'contrarian_cards.dart';

class StoryArcDetailsSheet extends StatelessWidget {
  final dynamic phase;
  final String persona;

  const StoryArcDetailsSheet({super.key, required this.phase, required this.persona});

  @override
  Widget build(BuildContext context) {
    final String title = phase['title'] ?? "Story Phase";
    final String summary = phase['summary'] ?? "Extracting details...";
    final String sentiment = phase['sentiment'] ?? "Neutral";
    final List<dynamic> players = phase['key_players'] is List ? phase['key_players'] : [];
    final String? pos = phase['contrarian_pos'];
    final String? neg = phase['contrarian_neg'];
    final List<dynamic> linkedArticles = phase['linked_articles'] is List ? phase['linked_articles'] : [];
    final String phaseName = phase['phase_name'] ?? "Progress";

    // Find the first available image URL for the header
    final String? headerImage = linkedArticles.firstWhere(
      (a) => a['image_url'] != null && a['image_url'].toString().isNotEmpty,
      orElse: () => {"image_url": null},
    )['image_url'];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F0F15),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (headerImage != null && headerImage.startsWith("http"))
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(headerImage),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.3),
                        BlendMode.darken,
                      ),
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 15,
                        right: 15,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 24,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            phaseName.toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled, color: Colors.cyanAccent, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            phaseName.toUpperCase(),
                            style: GoogleFonts.outfit(
                              color: Colors.cyanAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      )
                    ],
                  ),
                ),
              ],
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    
                    const SizedBox(height: 15),
                    Text(
                      summary,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.6,
                      ),
                    ),

                    const SizedBox(height: 25),
                    Text(
                      "SENTIMENT SHIFT",
                      style: GoogleFonts.outfit(
                        color: Colors.white30,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SentimentGraph(sentiment: sentiment),

                    if (players.isNotEmpty) ...[
                      const SizedBox(height: 25),
                      Text(
                        "KEY PLAYERS MAPPED",
                        style: GoogleFonts.outfit(
                          color: Colors.white30,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: players.map((p) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.person_outline, size: 12, color: Colors.amberAccent),
                              const SizedBox(width: 6),
                              Text(
                                p.toString(),
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 12),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ],

                    const SizedBox(height: 25),
                    Text(
                      "CONTRARIAN PERSPECTIVES",
                      style: GoogleFonts.outfit(
                        color: Colors.white30,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ContrarianCards(pos: pos, neg: neg),

                    if (linkedArticles.isNotEmpty) ...[
                      const SizedBox(height: 25),
                      Text(
                        "LINKED ARTICLES",
                        style: GoogleFonts.outfit(
                          color: Colors.white30,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...linkedArticles.map((art) {
                        final artUrl = art['url'] ?? "";
                        final artSource = art['source'] ?? "Original Source";
                        final artTitle = art['title'] ?? "View Article";
                        final artImage = art['image_url'];
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _launchURL(artUrl),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.cyanAccent.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: [
                                  if (artImage != null && artImage.toString().startsWith("http"))
                                    Container(
                                      width: 40,
                                      height: 40,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(artImage),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    )
                                  else
                                    const Icon(Icons.article_outlined, color: Colors.cyanAccent, size: 20),
                                  
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          artTitle,
                                          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          artSource,
                                          style: GoogleFonts.inter(color: Colors.cyanAccent, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.white24),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ],

                    if (phaseName.toLowerCase().contains("next")) ...[
                      const SizedBox(height: 25),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.deepPurple.withOpacity(0.4), Colors.blueAccent.withOpacity(0.1)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.auto_awesome, color: Colors.amberAccent),
                                const SizedBox(width: 8),
                                Text(
                                  "WHAT TO WATCH NEXT",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Our AI models predict a shift in this narrative over the next 48 hours based on the current sentiment velocity.",
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      // Direct launch is more reliable on modern Android than canLaunchUrl
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      print("Launch Error: $e");
    }
  }
}
