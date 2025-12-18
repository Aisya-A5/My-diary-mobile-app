import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import '../services/diary_service.dart';
import '../models/diary_entry.dart';
import 'diary_entry_page.dart';
import 'diary_entry_detail_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();
  final DiaryService _diaryService = DiaryService();

  // API Key GROQ (Versi Gratisan & Ngebut)
  final String _apiKey = 'fill the api key';
  // Nama model yang aktif sekarang (Llama 3.1 Instant)
  final String _groqModel = 'llama-3.1-8b-instant';

  String _aiAdvice = '';
  bool _isGeneratingAdvice = false;
  // Loading state buat proses ganti foto
  bool _isUpdatingPhoto = false;

  // --- FUNGSI AI (SAFETY NET VERSION) ---
  Future<void> _generateAIAdvice(List<DiaryEntry> entries) async {
    if (entries.isEmpty) return;
    setState(() => _isGeneratingAdvice = true);

    try {
      String contextText = entries.take(5).map((e) =>
      "- ${DateFormat('dd MMM').format(e.createdAt)} (${e.feeling}): ${e.content}"
      ).join("\n");

      final url = Uri.parse('https://api.groq.com/openai/v1/chat/completions');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_apiKey.trim()}',
      };

      final body = jsonEncode({
        "model": _groqModel,
        "messages": [
          {
            "role": "user",
            "content": "Bertindaklah sebagai psikolog sahabat. Jawab dalam Bahasa Indonesia singkat (max 3 kalimat) tanpa markdown.\n\nIni jurnalku:\n$contextText\n\nBerikan saran positif."
          }
        ]
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'];
        if (mounted) setState(() => _aiAdvice = reply);
      } else {
        print("GROQ ERROR: ${response.body}");
        throw Exception('Server Error: ${response.statusCode}');
      }

    } catch (e) {
      print("ERROR ASLI: $e");
      if (mounted) {
        setState(() {
          _aiAdvice = "Wah, sepertinya kamu sedang melalui banyak hal ya. "
              "Ingat, valid kok untuk merasa lelah. Coba luangkan waktu sejenak "
              "untuk istirahat atau lakukan hobi kecil yang bikin kamu senyum. Semangat!";
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mode Offline: Menampilkan saran umum.'), duration: Duration(seconds: 2)),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingAdvice = false);
    }
  }

  // --- [FITUR BARU] FUNGSI GANTI FOTO ---
  Future<void> _showUpdatePhotoDialog() async {
    final TextEditingController urlController = TextEditingController();
    // Isi text field dengan URL yang sekarang (kalau ada)
    urlController.text = _authService.currentUser?.photoURL ?? '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ganti Foto Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Masukan link (URL) gambar langsung dari internet. Pastikan berakhiran .jpg atau .png biar aman.'),
            const SizedBox(height: 16),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                hintText: 'https://contoh.com/fotoku.jpg',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Tutup dialog
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = urlController.text.trim();
              if (url.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('URL gak boleh kosong, Dol!')));
                return;
              }

              // Mulai proses update
              Navigator.pop(context); // Tutup dialog dulu
              setState(() => _isUpdatingPhoto = true); // Munculin loading di foto

              try {
                // Panggil fungsi sakti di AuthService tadi
                await _authService.updatePhotoURL(url);

                // Kalo sukses, refresh halaman biar fotonya muncul
                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mantap! Foto berhasil diganti.')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal ganti foto: $e'), backgroundColor: Colors.red));
                }
              } finally {
                if (mounted) setState(() => _isUpdatingPhoto = false); // Matikan loading
              }
            },
            child: const Text('Simpan Foto'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kita panggil user-nya langsung dari service biar dapet data terupdate setelah reload
    final user = _authService.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          // Pas tarik ke bawah, kita reload user juga sekalian
          await user?.reload();
          if (mounted) setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // 1. HEADER GRADIENT (Udah dimodif biar bisa diklik fotonya)
              _buildCustomHeader(user),

              // 2. KONTEN BODY
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -40),
                      child: Column(
                        children: [
                          _buildStatisticsSection(),
                          const SizedBox(height: 20),
                          _buildFeelingsAnalysisSection(),
                        ],
                      ),
                    ),
                    _buildRecentEntriesSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const DiaryEntryPage()));
        },
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.edit_note),
        label: const Text('New Entry'),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildCustomHeader(user) {
    // Cek apakah user punya link foto
    final String? photoURL = user?.photoURL;
    final bool hasPhoto = photoURL != null && photoURL.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 60, bottom: 60, left: 20, right: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade800, Colors.purple.shade600],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        children: [
          // Baris atas: Judul & Logout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('My Profile', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: _showLogoutDialog,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.logout, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // --- FOTO PROFIL YANG BISA DIKLIK ---
          GestureDetector(
            onTap: _isUpdatingPhoto ? null : _showUpdatePhotoDialog, // Klik buat ganti foto
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  // Logika tampilan: Kalau loading -> muter, Kalau ada foto -> tampilin, Kalau gak ada -> inisial
                  child: _isUpdatingPhoto
                      ? const CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    child: CircularProgressIndicator(),
                  )
                      : CircleAvatar(
                    radius: 36,
                    backgroundColor: Colors.white,
                    // Kalau ada URL foto, pake NetworkImage. Kalau nggak, pake null.
                    backgroundImage: hasPhoto ? NetworkImage(photoURL) : null,
                    // Kalau nggak ada foto (backgroundImage null), tampilin child (inisial)
                    child: hasPhoto ? null : Text(
                      _getUserInitial(user),
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                    ),
                  ),
                ),
                // Ikon kamera kecil biar user tau ini bisa diklik
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          // ------------------------------------

          const SizedBox(height: 12),
          Text(_getUserDisplayName(user), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(user?.email ?? 'No email', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  // ... SISANYA SAMA PERSIS KAYAK FILE SEBELUMNYA ...
  // (Widget _buildStatisticsSection, _buildStatCard, _buildAIRecommendationCard,
  //  _buildFeelingsAnalysisSection, _buildRecentEntriesSection, _buildEntryCard,
  //  dan Helper Functions gak ada yang berubah, jadi aman.)

  Widget _buildStatisticsSection() {
    return StreamBuilder<List<DiaryEntry>>(
      stream: _diaryService.getDiaryEntries(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        return Row(
          children: [
            Expanded(child: _buildStatCard('Entries', entries.length.toString(), Icons.book, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Month', _getEntriesThisMonth(entries).toString(), Icons.calendar_month, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Week', _getEntriesThisWeek(entries).toString(), Icons.access_time, Colors.orange)),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    Color themeColor = Colors.purple.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 24, color: themeColor),
          ),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildAIRecommendationCard(List<DiaryEntry> entries) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.purple.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blue.shade800.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Stack(
        children: [
          Positioned(right: -20, top: -20, child: Icon(Icons.auto_awesome, size: 100, color: Colors.white.withOpacity(0.1))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text("AI Insight", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white, letterSpacing: 0.5)),
                    ],
                  ),
                  IconButton(
                    onPressed: _isGeneratingAdvice ? null : () => _generateAIAdvice(entries),
                    icon: _isGeneratingAdvice ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.refresh, color: Colors.white70),
                    tooltip: "Refresh Saran",
                  )
                ],
              ),
              const SizedBox(height: 20),
              Text(_aiAdvice.isEmpty ? "Tekan tombol refresh 🔄 untuk membiarkan AI menganalisis mood dan harimu." : _aiAdvice, style: TextStyle(fontSize: 15, height: 1.6, color: Colors.white.withOpacity(0.95), fontStyle: _aiAdvice.isEmpty ? FontStyle.italic : FontStyle.normal, fontWeight: _aiAdvice.isEmpty ? FontWeight.normal : FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeelingsAnalysisSection() {
    return Column(
      children: [
        StreamBuilder<List<DiaryEntry>>(
          stream: _diaryService.getDiaryEntries(),
          builder: (context, snapshot) {
            final entries = snapshot.data ?? [];
            return _buildAIRecommendationCard(entries);
          },
        ),
      ],
    );
  }

  Widget _buildRecentEntriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        StreamBuilder<List<DiaryEntry>>(
          stream: _diaryService.getLastNDiaryEntries(3),
          builder: (context, snapshot) {
            final entries = snapshot.data ?? [];
            if (entries.isEmpty) return const Padding(padding: EdgeInsets.all(20.0), child: Center(child: Text("Belum ada curhatan nih, mulai nulis yuk!", style: TextStyle(color: Colors.grey))));
            return Column(children: entries.map((entry) => _buildEntryCard(entry)).toList());
          },
        ),
      ],
    );
  }

  Widget _buildEntryCard(DiaryEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _getFeelingColor(entry.feeling).withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(_getFeelingIconData(entry.feeling), color: _getFeelingColor(entry.feeling)),
        ),
        title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(entry.content, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey[600], height: 1.3)),
            const SizedBox(height: 10),
            Row(children: [Icon(Icons.access_time, size: 12, color: Colors.grey[400]), const SizedBox(width: 4), Text(_formatDate(entry.createdAt), style: TextStyle(fontSize: 12, color: Colors.grey[400]))]),
          ],
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DiaryEntryDetailPage(entry: entry))),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin mau keluar?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () async { Navigator.pop(context); await _authService.signOut(); }, child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  String _getUserInitial(user) => user?.email?.substring(0, 1).toUpperCase() ?? 'U';
  String _getUserDisplayName(user) => user?.displayName ?? user?.email?.split('@')[0] ?? 'User';

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

  Color _getFeelingColor(String feeling) {
    switch (feeling.toLowerCase()) {
      case 'happy': return Colors.green;
      case 'sad': return Colors.blue;
      case 'angry': return Colors.red;
      case 'excited': return Colors.orange;
      case 'stressed': return Colors.purple;
      case 'calm': return Colors.teal;
      default: return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm').format(date);
  }

  int _getEntriesThisMonth(List<DiaryEntry> entries) {
    final now = DateTime.now();
    return entries.where((e) => e.createdAt.month == now.month && e.createdAt.year == now.year).length;
  }

  int _getEntriesThisWeek(List<DiaryEntry> entries) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return entries.where((e) => e.createdAt.isAfter(startOfWeek)).length;
  }
}