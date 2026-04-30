import 'package:flutter/material.dart';
import '../products/ui/product_list_screen.dart';

// Import file fitur Anda (jika belum ada, kita buat dummy dulu di bawah)
class MainNavigation extends StatefulWidget {
  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // PASTIKAN LIST INI TIDAK KOSONG DAN JUMLAHNYA SAMA DENGAN ITEM DI BOTTOM BAR
  final List<Widget> _pages = [
    const Center(child: Text("Dashboard")), // Index 0
    const Center(child: Text("Transaksi")), // Index 1
    ProductListScreen(),
    const Center(child: Text("Pelanggan")), // Index 3
    const Center(child: Text("Profil")), // Index 4
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Error terjadi di sini jika _pages kosong
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Transaksi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop),
            label: 'Produk',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Pelanggan'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}
