import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/customer_provider.dart';
import 'customer_form_screen.dart';

class CustomerListScreen extends StatefulWidget {
  @override
  _CustomerListScreenState createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<CustomerProvider>().fetchCustomers());
  }

  
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CustomerProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text("Daftar Pelanggan")),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: provider.customers.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                final c = provider.customers[index];
                
                // Ambil data statistik dari JSONB
                Map<String, dynamic> stats = c['total_stats'] ?? {};
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile( // Menggunakan ExpansionTile agar detail statistik bisa dibuka-tutup
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(c['nama'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Kupon 19L: ${c['coupon_balance_19l']} | Telp: ${c['telepon']}"),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Alamat: ${c['alamat'] ?? '-'}"),
                            const Divider(),
                            const Text("Total Pengisian Seumur Hidup:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),
                            // Menampilkan semua ukuran yang ada di JSON secara dinamis
                            stats.isEmpty 
                              ? const Text("Belum ada riwayat pengisian", style: TextStyle(fontSize: 12, color: Colors.grey))
                              : Wrap(
                                  spacing: 8,
                                  children: stats.entries.map((e) => Chip(
                                    label: Text("${e.key}: ${e.value}x", style: const TextStyle(fontSize: 11)),
                                    backgroundColor: Colors.blue.shade50,
                                  )).toList(),
                                ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.edit, size: 18),
                                  label: const Text("Edit"),
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: c))),
                                ),
                                TextButton.icon(
                                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                  label: const Text("Hapus", style: TextStyle(color: Colors.red)),
                                  onPressed: () => provider.removeCustomer(c['id']),
                                ),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
        ),
      ),
    );
  }
}
