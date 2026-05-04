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
                String shortId = tx['id']
                    .toString()
                    .substring(tx['id'].toString().length - 8)
                    .toUpperCase();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () => _showTransactionDetail(context, tx),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- BARIS 1: ID, TANGGAL, HARGA ---
                          Row(
                            children: [
                              Text(
                                "#$shortId",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                "Rp ${tx['total_harga']}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // --- BARIS 2: RINGKASAN PRODUK (SIMPLE & DETAILED) ---
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.water_drop_outlined,
                                size: 18,
                                color: Colors.blue.shade300,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.black87,
                                    ),
                                    children: items.asMap().entries.map((
                                      entry,
                                    ) {
                                      int idx = entry.key;
                                      var item = entry.value;

                                      int qty = item['qty'];
                                      String size = item['ukuran_snapshot'];
                                      bool isFree =
                                          item['is_redemption'] == true;

                                      // --- LOGIKA KUPON DISESUAIKAN ---
                                      String kuponStr = "";
                                      if (size.toUpperCase() == '19L') {
                                        if (isFree) {
                                          kuponStr = " [GRATIS]";
                                        } else if (item['kupon_awal'] != 0) {
                                          // Cek QTY untuk menentukan format nomor
                                          if (qty == 1) {
                                            kuponStr =
                                                " (#${item['kupon_awal']})";
                                          } else {
                                            kuponStr =
                                                " (#${item['kupon_awal']}-${item['kupon_akhir']})";
                                          }
                                        }
                                      }

                                      return TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "$qty",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(text: "x $size"),
                                          TextSpan(
                                            text: kuponStr,
                                            style: TextStyle(
                                              color: isFree
                                                  ? Colors.green.shade700
                                                  : Colors.blue.shade700,
                                              fontWeight: isFree
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                              fontSize: 11,
                                            ),
                                          ),
                                          if (idx != items.length - 1)
                                            const TextSpan(
                                              text: " • ",
                                              style: TextStyle(
                                                color: Colors.grey,
                                              ),
                                            ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // --- BARIS 3: PELANGGAN (KECIL) ---
                          Row(
                            children: [
                              const Icon(
                                Icons.person,
                                size: 12,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  tx['nama_pelanggan_input'] ??
                                      "Pelanggan Umum",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    fontStyle: FontStyle.italic,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
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

  // --- FUNGSI UNTUK MENAMPILKAN MODAL DETAIL (VERSI UPDATE) ---
  void _showTransactionDetail(BuildContext context, Map<String, dynamic> tx) {
    final List items = tx['transaction_items'] ?? [];
    String shortId = tx['id']
        .toString()
        .substring(tx['id'].toString().length - 8)
        .toUpperCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                "DETAIL TRANSAKSI",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                "Nota: #$shortId",
                style: const TextStyle(
                  color: Colors.grey,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const Divider(height: 30),

            // Info Pelanggan
            Row(
              children: [
                const Icon(Icons.account_circle, color: Colors.blue),
                const SizedBox(width: 10),
                Text(
                  tx['nama_pelanggan_input'] ?? "Pelanggan Umum",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Daftar Item
            const Text(
              "Item Belanja:",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),

            ...items.map((item) {
              bool isFree = item['is_redemption'] == true;
              String ukuran =
                  item['ukuran_snapshot']?.toString().toUpperCase() ?? "";
              int qty = item['qty'] ?? 0;
              int kAwal = item['kupon_awal'] ?? 0;
              int kAkhir = item['kupon_akhir'] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${item['nama_produk_snapshot']} $ukuran",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),

                          // --- LOGIKA KUPON DISESUAIKAN ---
                          if (ukuran == '19L') ...[
                            if (isFree)
                              const Text(
                                "Penukaran Kupon (Gratis)",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            else if (kAwal != 0)
                              Text(
                                qty == 1
                                    ? "Kupon: #$kAwal"
                                    : "Kupon: #$kAwal - #$kAkhir",
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                          // Ukuran lain (15L, dll) tidak akan memunculkan teks kupon apa pun
                        ],
                      ),
                    ),
                    Text(
                      "$qty x",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Text(
                      isFree ? "Rp 0" : "Rp ${item['subtotal']}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isFree ? Colors.green : Colors.black,
                      ),
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
                const Text(
                  "TOTAL BAYAR",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  "Rp ${tx['total_harga']}",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Tombol Tutup
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "TUTUP",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
