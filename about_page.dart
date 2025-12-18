import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          // Gradient Mewah (Senada dengan Login & Splash)
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade800, Colors.purple.shade600],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView( // Biar bisa discroll kalau HP kecil
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                const SizedBox(height: 10),
                // Header
                const Text(
                  'About Team',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1,
                  ),
                ),
                const Text(
                  'The creators behind My Diary',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 30),

                // --- PROFIL ORANG KE-1 ---
                _buildProfileCard(
                  name: "Aisya A5",
                  nim: "NIM: 2303421008",
                  role: "Backend Engineer",
                  // Ganti link foto di bawah ini dengan link fotomu
                  imageUrl: "https://media.licdn.com/dms/image/v2/D5603AQHAXYFzYKC3tA/profile-displayphoto-scale_400_400/B56Zr8ZV.vL4Ag-/0/1765171095413?e=1767225600&v=beta&t=7bxq0kO9fYckj397xLh4mrpESHBPb_RF1FGf3kL9l7E",
                ),

                const SizedBox(height: 20),

                // --- PROFIL ORANG KE-2 ---
                _buildProfileCard(
                  name: "Riski Isnawati",
                  nim: "NIM: 23203421020",
                  role: "Frontend Engineer",
                  // Ganti link foto di bawah ini
                  imageUrl: "https://media.licdn.com/dms/image/v2/D5603AQG-04qvL8TJvA/profile-displayphoto-scale_400_400/B56Zr9cQ1.IYAg-/0/1765188644212?e=1767225600&v=beta&t=pRs3ELLPejYDwQGBdRRN0XDJskShaniw49b34eWfPHQ",
                ),

                const SizedBox(height: 40),

                // Info Aplikasi
                const Divider(color: Colors.white24, indent: 40, endIndent: 40),
                const SizedBox(height: 20),
                const Text(
                  'My Diary App v1.0.0',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Dibuat dengan Flutter untuk Tugas Besar Aplikasi Bergerak.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

// --- Fungsi Pencetak Kartu (Versi Fix: Muka Gak Ketutupan) ---
  Widget _buildProfileCard({
    required String name,
    required String nim,
    required String role,
    required String imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), // Efek Kaca
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Foto Profil
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 35,
              backgroundColor: Colors.white24, // Warna cadangan kalau gambar loading
              backgroundImage: NetworkImage(imageUrl),
              onBackgroundImageError: (_, __) {
                // Kalau error biarin kosong atau handle state (opsional)
              },
              // HAPUS BAGIAN 'child: Icon(...)' DISINI BIAR GAK NUMPUK
            ),
          ),
          const SizedBox(width: 20),

          // Data Teks (Sama kayak sebelumnya)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    nim,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  role,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}