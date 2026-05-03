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
      appBar: AppBar(title: const Text("Riwayat Transaksi")),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : prov.transactions.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: prov.transactions.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final tx = prov.transactions[index];
                    final List items = tx['transaction_items'] ?? [];
                    
                    DateTime date = DateTime.parse(tx['created_at']).toLocal();
                    String formattedDate = DateFormat('dd MMM, HH:mm').format(date);
                    
                    // Ambil 8 karakter terakhir ID sebagai nomor nota
                    String shortId = tx['id'].toString().substring(tx['id'].toString().length - 8).toUpperCase();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: InkWell( // Membuat kartu bisa diklik
                        onTap: () => _showTransactionDetail(context, tx),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // HEADER KARTU
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                    child: Text("#$shortId", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'monospace')),
                                  ),
                                  Text(formattedDate, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // INFO UTAMA
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue.shade50,
                                    child: const Icon(Icons.person, color: Colors.blue),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(tx['nama_pelanggan_input'] ?? "Pelanggan Umum", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        // Cuplikan barang yang dibeli
                                        Text(
                                          items.map((i) => "${i['nama_produk_snapshot']} (${i['qty']}x)").join(", "),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Rp ${tx['total_harga']}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                                  ),
                                ],
                              ),
                            ],
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
  // --- FUNGSI UNTUK MENAMPILKAN MODAL DETAIL (POIN 2) ---
  void _showTransactionDetail(BuildContext context, Map<String, dynamic> tx) {
    final List items = tx['transaction_items'] ?? [];
    String shortId = tx['id'].toString().substring(tx['id'].toString().length - 8).toUpperCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            const Center(child: Text("DETAIL TRANSAKSI", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            const SizedBox(height: 10),
            Center(child: Text("Nota: #$shortId", style: const TextStyle(color: Colors.grey, fontFamily: 'monospace'))),
            const Divider(height: 30),
            
            // Info Pelanggan
            Row(
              children: [
                const Icon(Icons.account_circle, color: Colors.blue),
                const SizedBox(width: 10),
                Text(tx['nama_pelanggan_input'] ?? "Pelanggan Umum", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 20),

            // Daftar Item (Tabel)
            const Text("Item Belanja:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 10),
            ...items.map((item) {
              bool isFree = item['is_redemption'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${item['nama_produk_snapshot']} ${item['ukuran_snapshot']}", style: const TextStyle(fontWeight: FontWeight.w500)),
                          if (!isFree && item['kupon_awal'] != 0)
                            Text("Kupon: ${item['kupon_awal']} - ${item['kupon_akhir']}", style: const TextStyle(fontSize: 11, color: Colors.blue)),
                          if (isFree)
                            const Text("Penukaran Kupon (Gratis)", style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Text("${item['qty']} x", style: const TextStyle(fontSize: 13)),
                    const SizedBox(width: 15),
                    Text(
                      isFree ? "Rp 0" : "Rp ${item['subtotal']}",
                      style: TextStyle(fontWeight: FontWeight.bold, color: isFree ? Colors.green : Colors.black),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            const Divider(height: 30),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("TOTAL BAYAR", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text("Rp ${tx['total_harga']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
              ],
            ),
            const SizedBox(height: 30),
            
            // Tombol Tutup
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("TUTUP"),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
