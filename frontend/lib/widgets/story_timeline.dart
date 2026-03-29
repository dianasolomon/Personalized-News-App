import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/article_detail_screen.dart';

class StoryTimeline extends StatelessWidget {
  final List<dynamic> timelineEvents;
  final String persona;
  final Function(dynamic) onNodeKlicked;
  final dynamic nextStory;

  const StoryTimeline({
    super.key,
    required this.timelineEvents,
    required this.persona,
    required this.onNodeKlicked,
    this.nextStory,
  });

  // Strict colors based on reference (Yellow, Purple, Blue, Orange, Purple, Teal)
  static const List<Color> _timelineColors = [
    Color(0xFFFFD54F), // Yellow/Amber
    Color(0xFFBA68C8), // Purple
    Color(0xFF4FC3F7), // Light Blue
    Color(0xFFFFB74D), // Orange
    Color(0xFF9575CD), // Deep Purple
    Color(0xFF4DB6AC), // Teal
  ];

  Color _getEventColor(int index) {
    return _timelineColors[index % _timelineColors.length];
  }

  @override
  Widget build(BuildContext context) {
    if (timelineEvents.isEmpty) {
      return const Center(
          child: Text("Timeline data is sparse...",
              style: TextStyle(color: Colors.white54)));
    }

    return Stack(
      children: [
        // Center Dashed Line spanning the full vertical list
        Positioned.fill(
          child: CustomPaint(painter: DashedLinePainter()),
        ),
        ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          itemCount: timelineEvents.length + 1,
          itemBuilder: (context, index) {
            if (index == timelineEvents.length) {
              return _buildWatchNextSection(context);
            }
            // Alternating pattern: Top event in the image is on the right (index 0 is right)
            bool isLeftNode = index % 2 != 0;
            return _buildTimelineRow(
                context, timelineEvents[index], isLeftNode, index);
          },
        ),
      ],
    );
  }

  Widget _buildTimelineRow(
      BuildContext context, dynamic phase, bool isLeftNode, int index) {
    Color eventColor = _getEventColor(index);
    int nodeNumber = index + 1;

    String title = phase['title'] ?? "Event $nodeNumber";
    String description = phase['summary'] ?? "";

    // 1) The main Event Heading Box (Rectangular, colored border)
    Widget headerElement = InkWell(
      onTap: () => onNodeKlicked(phase), // Trigger callback for engagement
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF151520),
          border: Border.all(color: eventColor, width: 2.5),
          borderRadius:
              BorderRadius.circular(4), // Crisp rectangular look from image
        ),
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );

    // 2) Content Box below the Event (Rounded, white/gray border)
    Widget contentElement = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        border: Border.all(color: Colors.white10, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        description,
        style:
            GoogleFonts.inter(fontSize: 11, color: Colors.white70, height: 1.3),
        textAlign: isLeftNode ? TextAlign.right : TextAlign.left,
      ),
    );

    // 3) Squarish Image Placeholder on opposite side (Perfect Square Aspect Ratio)
    // Use title hashCode for unique images per phase
    final imgSeed = title.hashCode.abs() % 10000;
    Widget imagePlaceholder = AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF12121A),
          border: Border.all(color: eventColor.withOpacity(0.5), width: 2),
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage("https://picsum.photos/seed/$imgSeed/300"),
            fit: BoxFit.cover,
            opacity: 0.8,
          ),
        ),
      ),
    );

    // 4) Center circular node with number
    Widget centerNode = Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: const Color(0xFF101014),
        shape: BoxShape.circle,
        border: Border.all(color: eventColor, width: 3),
        boxShadow: [
          BoxShadow(color: eventColor.withOpacity(0.3), blurRadius: 8)
        ],
      ),
      child: Center(
        child: Text(
          "$nodeNumber",
          style: GoogleFonts.outfit(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
    );

    // 5) Connector line joining header to center node
    Widget connectorLine = Container(
      width: 25,
      height: 3,
      color: eventColor,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 35.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT COLUMN
            Expanded(
              child: isLeftNode
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        headerElement,
                        const SizedBox(height: 8),
                        contentElement,
                      ],
                    )
                  : Align(
                      alignment: Alignment.topRight,
                      child: SizedBox(width: 80, child: imagePlaceholder),
                    ),
            ),

            // CONNECTOR + NODE
            Stack(
              alignment: Alignment.topCenter,
              children: [
                if (isLeftNode)
                  Positioned(left: 0, top: 18, child: connectorLine),
                if (!isLeftNode)
                  Positioned(right: 0, top: 18, child: connectorLine),
                centerNode,
              ],
            ),

            // RIGHT COLUMN
            Expanded(
              child: !isLeftNode
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        headerElement,
                        const SizedBox(height: 8),
                        contentElement,
                      ],
                    )
                  : Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(width: 80, child: imagePlaceholder),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchNextSection(BuildContext context) {
    if (nextStory == null) {
      return const SizedBox.shrink(); // Don't show if no recommendation
    }

    String title = nextStory['storyTitle'] ?? "Related Story";
    String summary = nextStory['summary'] ?? "Ready for the next narrative shift.";

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 40),
      child: GestureDetector(
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailScreen(
                story: nextStory,
                persona: persona,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.withOpacity(0.4),
                Colors.blueAccent.withOpacity(0.1)
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.explore,
                      color: Colors.amberAccent, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    "WHAT TO WATCH NEXT",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  color: Colors.cyanAccent,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                summary,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "Read Story",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 12),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

// Draws the dashed centerline down the middle
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 0) return;
    double dashHeight = 6, dashSpace = 6, startY = 0;

    final paint = Paint()
      ..color = Colors.white24 // Dashed black line mapped to dark theme
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
