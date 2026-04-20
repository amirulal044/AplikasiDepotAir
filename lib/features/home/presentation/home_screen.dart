import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../product/presentation/product_screen.dart'; // Sesuaikan path-nya

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? storeData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  // Fungsi untuk mengambil data Toko milik owner yang sedang login
  Future<void> _loadStoreData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        // Mencari di tabel stores yang owner_id-nya adalah ID user login
        final data = await supabase
            .from('stores')
            .select()
            .eq('owner_id', user.id)
            .single();

        setState(() {
          storeData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading store: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(storeData?['store_name'] ?? "Dashboard Depot"),
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
        actions: [
          // Tombol Logout untuk testing pindah akun
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async => await supabase.auth.signOut(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : storeData == null
          ? const Center(
              child: Text("Data Toko tidak ditemukan. Cek tabel stores!"),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Halo, Pemilik ${storeData!['store_name']}!",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "ID Depot: ${storeData!['id']}",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 30),

                  // MENU UTAMA (GRID)
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      children: [
                        // TOMBOL MENU PRODUK
                        _buildMenuCard(
                          context,
                          title: "Manajemen Produk",
                          icon: Icons.inventory_2,
                          color: Colors.orange,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductScreen(storeId: storeData!['id']),
                              ),
                            );
                          },
                        ),

                        // TOMBOL MENU TRANSAKSI (NANTI)
                        _buildMenuCard(
                          context,
                          title: "Kasir / Jual",
                          icon: Icons.shopping_cart,
                          color: Colors.green,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Fitur Kasir sedang kita siapkan!",
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Widget pendukung untuk tampilan kartu menu
  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: color),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
