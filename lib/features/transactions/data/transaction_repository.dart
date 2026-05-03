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

    // 1. SIMPAN HEADER
    final header = await _supabase.from('transactions').insert({
      'user_id': userId,
      'customer_id': customerId,
      'nama_pelanggan_input': namaPelanggan,
      'total_harga': totalHarga,
    }).select().single();

    final transactionId = header['id'];

    // Variabel untuk kalkulasi saldo kupon 19L
    int totalCouponAdjustment = 0;
    // Variabel untuk menampung tambahan statistik ukuran (Dinamis)
    Map<String, int> currentSessionStats = {};

    // 2. LOOPING ITEM
    for (var item in items) {
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

      // --- LOGIKA STATISTIK (SEUMUR HIDUP) ---
      String sizeKey = item['ukuran'].toString().toUpperCase();
      currentSessionStats[sizeKey] = (currentSessionStats[sizeKey] ?? 0) + (item['qty'] as int);

      // --- LOGIKA SALDO KUPON 19L ---
      if (item['isCouponEnabled'] == true) {
        if (item['isRedemption'] == true) {
          totalCouponAdjustment -= (10 * (item['qty'] as int));
        } else {
          totalCouponAdjustment += (item['qty'] as int);
          // Update nomor kupon fisik di tabel produk (hanya jika berbayar)
          if (item['productId'] != null) {
            await _supabase.from('products').update({
              'last_coupon_number': item['kuponAkhir'],
            }).eq('id', item['productId']);
          }
        }
      }
    }

    // 3. UPDATE DATA PELANGGAN (SALDO 19L & TOTAL STATS JSONB)
    if (customerId != null) {
      final customerData = await _supabase
          .from('customers')
          .select('coupon_balance_19l, total_stats')
          .eq('id', customerId)
          .single();

      // Hitung Saldo 19L baru
      int oldBalance = customerData['coupon_balance_19l'] ?? 0;
      int newBalance = (oldBalance + totalCouponAdjustment).clamp(0, 999999);

      // Hitung Statistik JSONB baru
      Map<String, dynamic> oldStats = Map<String, dynamic>.from(customerData['total_stats'] ?? {});
      
      currentSessionStats.forEach((size, qty) {
        int oldQty = oldStats[size] ?? 0;
        oldStats[size] = oldQty + qty;
      });

      // Simpan sekaligus ke Supabase
      await _supabase.from('customers').update({
        'coupon_balance_19l': newBalance,
        'total_stats': oldStats, // Menyimpan Map yang sudah diupdate
      }).eq('id', customerId);
    }
  }
}