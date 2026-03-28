import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ContrarianCards extends StatelessWidget {
  final String? pos;
  final String? neg;

  const ContrarianCards({super.key, this.pos, this.neg});

  @override
  Widget build(BuildContext context) {
    if ((pos == null || pos!.isEmpty) && (neg == null || neg!.isEmpty)) return const SizedBox();

    return Column(
      children: [
        if (pos != null && pos!.isNotEmpty)
          _buildCard(
            context,
            title: "THE PROMISE (Bull Case)",
            content: pos!,
            color: Colors.greenAccent,
            icon: Icons.trending_up,
          ),
        if (neg != null && neg!.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildCard(
            context,
            title: "THE RISK (Bear Case)",
            content: neg!,
            color: Colors.orangeAccent,
            icon: Icons.trending_down,
          ),
        ],
      ],
    );
  }

  Widget _buildCard(BuildContext context, {required String title, required String content, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(16),
      width: double.infinity,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, height: 1.4, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
