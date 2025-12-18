import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'agenda_page.dart';
import 'about_page.dart'; // Jangan lupa import halaman About yang baru dibuat

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  // Daftar Halaman
  final List<Widget> _pages = [
    const ProfilePage(),
    const AgendaPage(),
    const AboutPage(),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Fungsi saat Nav Bar ditekan
  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Animasi geser (Slide) ke halaman tujuan
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Gunakan PageView untuk efek slide
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        physics: const BouncingScrollPhysics(), // Efek mantul pas mentok
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: _onItemTapped,
          backgroundColor: Colors.white,
          indicatorColor: Colors.deepPurple.shade100,
          elevation: 0,
          height: 65,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Colors.deepPurple),
              label: 'Profile',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_month, color: Colors.deepPurple),
              label: 'Calendar',
            ),
            NavigationDestination(
              icon: Icon(Icons.info_outline),
              selectedIcon: Icon(Icons.info, color: Colors.deepPurple),
              label: 'About',
            ),
          ],
        ),
      ),
    );
  }
}