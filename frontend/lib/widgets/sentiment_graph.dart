import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SentimentGraph extends StatelessWidget {
  final String sentiment;

  const SentimentGraph({super.key, required this.sentiment});

  @override
  Widget build(BuildContext context) {
    String shifted = "Uncertainty";
    Color sColor = Colors.orange;
    
    if (sentiment.toLowerCase().contains("positive") || sentiment.toLowerCase().contains("good")) {
      shifted = "Momentum / Optimism";
      sColor = Colors.greenAccent;
    } else if (sentiment.toLowerCase().contains("negative") || sentiment.toLowerCase().contains("bad")) {
      shifted = "Panic / Conflict";
      sColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.all(15),
      width: double.infinity,
      decoration: BoxDecoration(
        color: sColor.withOpacity(0.1),
        border: Border(left: BorderSide(color: sColor, width: 4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_heart, color: sColor, size: 18),
              const SizedBox(width: 8),
              Text("Market Emotion Pulse", style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 5),
          Text(shifted, style: GoogleFonts.outfit(color: sColor, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(sentiment, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}
