import 'package:flutter/material.dart';
import 'constants/app_colors.dart';
import 'screens/home.dart'; // Import file HomeScreen yang baru dibuat

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UI Components Showcase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'InstrumentSans',
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.main,
          primary: AppColors.main,
          error: AppColors.danger,
        ),
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: const MainNavigationWrapper(),
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  // Daftar halaman aplikasi
  final List<Widget> _pages = [
    const HomeScreen(), // Indeks 0: Halaman Katalog Komponen Anda
    const Center(child: Text('Halaman CV (Fitur Selanjutnya)', style: TextStyle(fontSize: 16))), // Indeks 1
    const Center(child: Text('Halaman Saved (Fitur Selanjutnya)', style: TextStyle(fontSize: 16))), // Indeks 2
    const Center(child: Text('Halaman Profile (Fitur Selanjutnya)', style: TextStyle(fontSize: 16))), // Indeks 3
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages, // Menjaga state halaman agar tidak reload saat berpindah tab
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.main.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: AppColors.main),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description, color: AppColors.main),
            label: 'CV',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_border),
            selectedIcon: Icon(Icons.bookmark, color: AppColors.main),
            label: 'Saved',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.main),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}