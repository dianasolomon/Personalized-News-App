import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentStep = 0;
  String? selectedPersona;
  List<String> selectedInterests = [];

  final List<String> availableInterests = [
    'AI', 'Startups', 'Finance', 'Economy', 'Policy', 
    'EV & Energy', 'Big Tech', 'Crypto', 'SaaS', 'Global Markets'
  ];

  final Map<String, IconData> personas = {
    'Investor': Icons.trending_up,
    'Founder': Icons.rocket_launch,
    'Student': Icons.school,
  };

  void nextStepOrFinish() async {
    if (_currentStep == 0 && selectedPersona != null) {
      setState(() { _currentStep = 1; });
    } else if (_currentStep == 1 && selectedInterests.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_onboarded', true);
      await prefs.setString('persona', selectedPersona!);
      await prefs.setStringList('interests', selectedInterests);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/feed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome, size: 80, color: Colors.amber),
                const SizedBox(height: 20),
                Text(
                  "Choose Your Avatar",
                  style: GoogleFonts.outfit(
                      fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  "Your news, tailored to your journey.",
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 40),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentStep == 0 ? _buildPersonaSelection() : _buildInterestsSelection(),
                ),
                const SizedBox(height: 40),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    elevation: 10,
                  ),
                  onPressed: (_currentStep == 0 && selectedPersona != null) || (_currentStep == 1 && selectedInterests.isNotEmpty) 
                      ? nextStepOrFinish : null,
                  child: Text(
                    _currentStep == 0 ? "NEXT" : "START READING",
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonaSelection() {
    return Column(
      key: const ValueKey("persona"),
      children: personas.entries.map((entry) {
        final isSelected = selectedPersona == entry.key;
        return GestureDetector(
          onTap: () {
            setState(() {
              selectedPersona = entry.key;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? Colors.deepPurpleAccent.withOpacity(0.5) : Colors.white10,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.cyanAccent : Colors.transparent,
                width: 2,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: Colors.cyanAccent.withOpacity(0.5),
                          blurRadius: 15,
                          spreadRadius: 2)
                    ]
                  : [],
            ),
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(entry.value, size: 40, color: isSelected ? Colors.amber : Colors.white54),
                const SizedBox(width: 20),
                Text(
                  entry.key,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInterestsSelection() {
    return Column(
      key: const ValueKey("interests"),
      children: [
        Text(
          "Pick your interests",
          style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.cyanAccent),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: availableInterests.map((interest) {
            final isSelected = selectedInterests.contains(interest);
            return FilterChip(
              label: Text(interest, style: GoogleFonts.inter(color: isSelected ? Colors.black : Colors.white)),
              selected: isSelected,
              selectedColor: Colors.amberAccent,
              backgroundColor: Colors.white10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Colors.amberAccent : Colors.white24)
              ),
              onSelected: (bool selected) {
                setState(() {
                  if (selected) {
                    selectedInterests.add(interest);
                  } else {
                    selectedInterests.remove(interest);
                  }
                });
              },
            );
          }).toList(),
        )
      ]
    );
  }
}
