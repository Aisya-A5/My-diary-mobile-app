import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/diary_entry.dart';
import 'diary_entry_page.dart';

class DiaryEntryDetailPage extends StatelessWidget {
  final DiaryEntry entry;

  const DiaryEntryDetailPage({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // 1. HEADER GRADIENT
          Container(
            height: 250, // Header lebih tinggi buat info
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade800, Colors.purple.shade600],
              ),
            ),
          ),

          // 2. KONTEN
          SafeArea(
            child: Column(
              children: [
                // Nav Bar Transparan
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => DiaryEntryPage(entry: entry)),
                        ),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.edit, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Info Judul & Mood
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Mood Icon Besar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_getFeelingIconData(entry.feeling), color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _capitalizeFirst(entry.feeling),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        entry.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Colors.white70, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy • HH:mm').format(entry.createdAt),
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Kartu Konten Floating
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Text(
                        entry.content,
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.8,
                          color: Colors.black87,
                          fontFamily: 'Georgia', // Font agak serif biar enak dibaca kayak buku
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getFeelingIconData(String feeling) {
    switch (feeling.toLowerCase()) {
      case 'happy': return Icons.sentiment_very_satisfied;
      case 'sad': return Icons.sentiment_very_dissatisfied;
      case 'angry': return Icons.sentiment_dissatisfied;
      case 'excited': return Icons.celebration;
      case 'stressed': return Icons.psychology_alt;
      case 'calm': return Icons.self_improvement;
      default: return Icons.sentiment_neutral;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}