import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionRepository {
  final _supabase = Supabase.instance.client;

  Future<void> saveTransaction({
    required String? customerId,
    required String? productId,
    required String namaPelanggan,
    required String namaProduk,
    required String ukuran,
    required int nomorKupon, // Ini adalah nomor TERAKHIR dari rentang kupon
    required int qty, // <--- TAMBAHKAN PARAMETER QTY DI SINI
    required bool isRedemption,
    required int totalHarga,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    print("DEBUG: Menghubungi database dengan User ID: $userId");

    if (userId == null) {
      throw "User tidak terautentikasi!";
    }

    // 1. Simpan Transaksi ke tabel 'transactions'
    await _supabase.from('transactions').insert({
      'user_id': userId,
      'customer_id': customerId,
      'product_id': productId,
      'nama_pelanggan_input': namaPelanggan,
      'nama_produk_input': namaProduk,
      'ukuran_input': ukuran,
      'jumlah': qty, // <--- Masukkan jumlah pembelian ke database
      'nomor_kupon_fisik': nomorKupon,
      'is_redemption': isRedemption,
      'total_harga': totalHarga,
    });

    // 2. Update Nomor Kupon Terakhir di Profil Depot
    // Ini agar transaksi berikutnya otomatis muncul nomor (nomorKupon + 1)
    if (productId != null) {
      await _supabase
          .from('products')
          .update({
            'last_coupon_number': nomorKupon,
          }) // Simpan nomor akhir rentang
          .eq('id', productId);
    }

    // 3. Update Saldo Kupon Pelanggan (Hanya jika pelanggan terdaftar/pilih dari rekomendasi)
    if (customerId != null) {
      // Ambil saldo kupon saat ini
      final currentRes = await _supabase
          .from('customers')
          .select('coupon_balance')
          .eq('id', customerId)
          .single();

      int currentBalance = currentRes['coupon_balance'] ?? 0;

      int newBalance;
      if (isRedemption) {
        // Jika pelanggan menukar 10 kupon untuk dapat 1 gratis
        newBalance = currentBalance - 10;
      } else {
        // Jika beli biasa, tambahkan saldo sesuai jumlah galon (QTY) yang dibeli
        // Contoh: beli 3 galon 19L, maka saldo kupon nambah 3
        newBalance = currentBalance + qty;
      }

      // Update saldo terbaru ke database pelanggan
      await _supabase
          .from('customers')
          .update({'coupon_balance': newBalance})
          .eq('id', customerId);
    }
  }
}
