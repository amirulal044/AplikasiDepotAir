import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionRepository {
  final _supabase = Supabase.instance.client;

  Future<void> saveCompleteTransaction({
    required String? customerId,
    required String namaPelanggan,
    required int totalHarga,
    required List<Map<String, dynamic>> items,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw "User tidak terautentikasi!";

    // 1. SIMPAN HEADER (Nota Utama)
    final header = await _supabase
        .from('transactions')
        .insert({
          'user_id': userId,
          'customer_id': customerId,
          'nama_pelanggan_input': namaPelanggan,
          'total_harga': totalHarga,
        })
        .select()
        .single();

    final transactionId = header['id'];

    // Variabel untuk kalkulasi saldo kupon 19L (untuk tabel customers)
    int totalCouponAdjustment = 0;

    // Variabel untuk menampung tambahan statistik ukuran (JSONB)
    Map<String, int> currentSessionStats = {};

    // 2. LOOPING SETIAP ITEM DI KERANJANG
    for (var item in items) {
      // A. Simpan ke tabel detail (transaction_items)
      await _supabase.from('transaction_items').insert({
        'transaction_id': transactionId,
        'product_id': item['productId'],
        'nama_produk_snapshot': item['namaProduk'],
        'ukuran_snapshot': item['ukuran'],
        'qty': item['qty'],
        'harga_satuan': item['unitPrice'],
        'subtotal': item['subtotal'],
        'is_redemption': item['isRedemption'],
        'kupon_awal': item['kuponAwal'],
        'kupon_akhir': item['kuponAkhir'],
      });

      // --- B. LOGIKA STATISTIK SEUMUR HIDUP (BUKU BESAR) ---
      String sizeKey = item['ukuran'].toString().toUpperCase().trim();

      // KHUSUS 19L: Kita pecah jadi PAID dan FREE untuk detail di fitur pelanggan
      if (sizeKey == '19L') {
        if (item['isRedemption'] == true) {
          sizeKey = '19L_FREE'; // Akan digunakan untuk hitungan "-10"
        } else {
          sizeKey = '19L_PAID'; // Akan digunakan untuk hitungan "+1"
        }
      }

      // Tambahkan jumlah galon ke map statistik sementara
      currentSessionStats[sizeKey] =
          (currentSessionStats[sizeKey] ?? 0) + (item['qty'] as int);

      // --- C. LOGIKA SALDO KUPON & UPDATE PRODUK ---
      if (item['isCouponEnabled'] == true) {
        if (item['isRedemption'] == true) {
          // Jika tukar kupon: Kurangi saldo (1 galon gratis = -10 poin)
          totalCouponAdjustment -= (10 * (item['qty'] as int));

          // Produk gratis TIDAK mengupdate last_coupon_number di tabel products
        } else {
          // Jika beli biasa: Tambah saldo (+1 poin per galon)
          totalCouponAdjustment += (item['qty'] as int);

          // Update nomor kupon fisik di tabel produk (karena ini berbayar)
          if (item['productId'] != null) {
            await _supabase
                .from('products')
                .update({'last_coupon_number': item['kuponAkhir']})
                .eq('id', item['productId']);
          }
        }
      }
    }

    // 3. UPDATE DATA PELANGGAN (SALDO & STATS JSONB)
    if (customerId != null) {
      // Ambil data lama pelanggan
      final customerData = await _supabase
          .from('customers')
          .select('coupon_balance_19l, total_stats')
          .eq('id', customerId)
          .single();

      // Hitung Saldo 19L Baru
      int oldBalance = customerData['coupon_balance_19l'] ?? 0;
      int newBalance = oldBalance + totalCouponAdjustment;
      if (newBalance < 0) newBalance = 0; // Keamanan agar tidak minus

      // Update Statistik JSONB (Menggabungkan data lama dan baru)
      Map<String, dynamic> oldStats = Map<String, dynamic>.from(
        customerData['total_stats'] ?? {},
      );

      currentSessionStats.forEach((key, qty) {
        int oldQty = oldStats[key] ?? 0;
        oldStats[key] = oldQty + qty;
      });

      // Simpan pembaruan ke database pelanggan
      await _supabase
          .from('customers')
          .update({'coupon_balance_19l': newBalance, 'total_stats': oldStats})
          .eq('id', customerId);
    }
  }
}
