import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Tambahkan package intl di pubspec.yaml untuk format tanggal
import '../logic/transaction_provider.dart';
import 'transaction_form_screen.dart';

class TransactionListScreen extends StatefulWidget {
  @override
  _TransactionListScreenState createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends State<TransactionListScreen> {
  @override
  void initState() {
    super.initState();
    // Ambil data transaksi saat pertama kali dibuka
    Future.microtask(
      () => context.read<TransactionProvider>().fetchTransactions(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<TransactionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Transaksi"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => prov.fetchTransactions(),
          ),
        ],
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.transactions.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              itemCount: prov.transactions.length,
              padding: const EdgeInsets.all(10),
              itemBuilder: (context, index) {
                final tx = prov.transactions[index];

                // Parsing tanggal agar lebih rapi
                DateTime date = DateTime.parse(tx['created_at']).toLocal();
                String formattedDate = DateFormat(
                  'dd MMM yyyy, HH:mm',
                ).format(date);

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          tx['nama_pelanggan_input'] ?? "Pelanggan Umum",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          tx['total_harga'] == 0
                              ? "GRATIS"
                              : "Rp ${tx['total_harga']}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tx['total_harga'] == 0
                                ? Colors.green
                                : Colors.black,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          "${tx['nama_produk_input']} (${tx['ukuran_input']})",
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formattedDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const Spacer(),
                            if (tx['nomor_kupon_fisik'] != null &&
                                tx['nomor_kupon_fisik'] != 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  "Kupon: #${tx['nomor_kupon_fisik']}",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    leading: CircleAvatar(
                      backgroundColor: tx['is_redemption'] == true
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                      child: Icon(
                        tx['is_redemption'] == true
                            ? Icons.redeem
                            : Icons.local_shipping,
                        color: tx['is_redemption'] == true
                            ? Colors.orange
                            : Colors.blue,
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigasi ke form dan refresh list saat kembali
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TransactionFormScreen()),
          );
          prov.fetchTransactions();
        },
        label: const Text("Transaksi Baru"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "Belum ada transaksi hari ini",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
