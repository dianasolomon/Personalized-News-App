import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContrarianCards extends StatelessWidget {
  final String? perspective;

  const ContrarianCards({super.key, this.perspective});

  @override
  Widget build(BuildContext context) {
    if (perspective == null || perspective!.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.balance, color: Colors.blueAccent),
              const SizedBox(width: 8),
              Text("Contrarian Take", style: GoogleFonts.outfit(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            perspective!,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
