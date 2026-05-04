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
                Map<String, dynamic> stats = c['total_stats'] ?? {};

                // Hitung total pengisian seluruh ukuran
                int totalSemuaGalon = stats.values.fold(
                  0,
                  (sum, val) => sum + (val as int),
                );

                // Ambil detail khusus 19L
                int paid19L = stats['19L_PAID'] ?? 0;
                int free19L = stats['19L_FREE'] ?? 0;
                int total19L =
                    paid19L +
                    free19L; // <--- TOTAL FISIK GALON 19L (Bayar + Gratis)

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(c['nama'][0].toUpperCase()),
                    ),
                    title: Text(
                      c['nama'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      "Sisa Kupon: ${c['coupon_balance_19l']} | Total: $totalSemuaGalon Galon",
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "RINCIAN PEMBELIAN",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // 1. Total Keseluruhan (Semua Ukuran)
                            _buildInfoRow(
                              "Total Seluruh Galon Keluar",
                              "$totalSemuaGalon Galon",
                              isBold: true,
                            ),
                            const Divider(),

                            // 2. Detail per Ukuran (Statistik Dinamis)

                            // --- TAMBAHAN: Tampilkan Total Fisik 19L di sini ---
                            if (total19L > 0)
                              _buildInfoRow(
                                "Ukuran 19L (Total Isi)",
                                "$total19L pengisian",
                              ),

                            // Tampilkan ukuran selain 19L (15L, 8L, dll)
                            ...stats.entries
                                .where((e) => !e.key.contains('19L_'))
                                .map(
                                  (e) => _buildInfoRow(
                                    "Ukuran ${e.key}",
                                    "${e.value} pengisian",
                                  ),
                                )
                                .toList(),

                            const SizedBox(height: 15),

                            // 3. Logika Kupon 19L (Detail Matematika Saldo)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue.shade100),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "LOGIKA SALDO KUPON 19L",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildKuponRow(
                                    "Total 19L Berbayar",
                                    "+$paid19L",
                                    Colors.green,
                                  ),
                                  _buildKuponRow(
                                    "Total Penukaran Gratis",
                                    "-${free19L * 10}",
                                    Colors.red,
                                    subText: "($free19L kali tukar gratis)",
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Sisa Saldo Kupon",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "${c['coupon_balance_19l']}",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // 4. Tombol Aksi (Edit/Hapus)
                            const SizedBox(height: 15),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          CustomerFormScreen(customer: c),
                                    ),
                                  ),
                                  icon: const Icon(Icons.edit, size: 16),
                                  label: const Text("Edit"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
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
  // --- WIDGET HELPER UNTUK MEMPERMUDAH KODE UI ---

  Widget _buildInfoRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKuponRow(
    String label,
    String value,
    Color color, {
    String subText = "",
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12)),
              if (subText.isNotEmpty)
                Text(
                  subText,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
