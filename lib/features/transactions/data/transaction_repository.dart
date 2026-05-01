import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionRepository {
  final _supabase = Supabase.instance.client;

  Future<void> saveCompleteTransaction({
    required String? customerId,
    required String namaPelanggan,
    required int totalHarga,
    required List<Map<String, dynamic>> items, // List keranjang belanja
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw "User tidak terautentikasi!";

    // 1. SIMPAN HEADER (Ke tabel 'transactions')
    final header = await _supabase.from('transactions').insert({
      'user_id': userId,
      'customer_id': customerId,
      'nama_pelanggan_input': namaPelanggan,
      'total_harga': totalHarga,
    }).select().single();

    final transactionId = header['id'];

    // Variabel untuk menghitung total perubahan saldo kupon pelanggan
    int totalCouponAdjustment = 0;

    // 2. LOOPING: SIMPAN SETIAP ITEM (Ke tabel 'transaction_items')
    for (var item in items) {
      await _supabase.from('transaction_items').insert({
        'transaction_id': transactionId,
        'product_id': item['productId'], // Bisa NULL jika input manual
        'nama_produk_snapshot': item['namaProduk'],
        'ukuran_snapshot': item['ukuran'],
        'qty': item['qty'],
        'harga_satuan': item['unitPrice'],
        'subtotal': item['subtotal'],
        'is_redemption': item['isRedemption'],
        'kupon_awal': item['kuponAwal'],
        'kupon_akhir': item['kuponAkhir'],
      });

      // 3. LOGIKA KUPON (Hanya jika productId tidak NULL & fitur kupon aktif pada produk tersebut)
      if (item['productId'] != null && item['isCouponEnabled'] == true) {
        
        if (item['isRedemption'] == true) {
          // --- PENYESUAIAN: MULTI-REDEMPTION ---
          // Jika tukar kupon, kurangi saldo 10 poin DIKALI jumlah qty yang digratiskan
          int qtyGratis = item['qty'] as int;
          totalCouponAdjustment -= (10 * qtyGratis);

          // Catatan: last_coupon_number di tabel produk TIDAK diupdate karena ini barang gratis
        } else {
          // --- PEMBELIAN BIASA ---
          // 1. Tambahkan saldo kupon sejumlah barang yang dibayar
          totalCouponAdjustment += (item['qty'] as int);

          // 2. Update nomor kupon terakhir di tabel produk karena ini berbayar (pakai kupon fisik)
          await _supabase.from('products').update({
            'last_coupon_number': item['kuponAkhir'],
          }).eq('id', item['productId']);
        }
      }
    }

    // 4. UPDATE SALDO KUPON PELANGGAN (Hanya jika ada pelanggan terdaftar & ada adjustment)
    if (customerId != null && totalCouponAdjustment != 0) {
      try {
        final currentRes = await _supabase
            .from('customers')
            .select('coupon_balance')
            .eq('id', customerId)
            .single();

        int currentBalance = currentRes['coupon_balance'] ?? 0;
        int newBalance = currentBalance + totalCouponAdjustment;

        // Keamanan: Saldo tidak boleh negatif (mencegah manipulasi data)
        if (newBalance < 0) newBalance = 0;

        await _supabase.from('customers').update({
          'coupon_balance': newBalance,
        }).eq('id', customerId);
      } catch (e) {
        print("Gagal update saldo pelanggan: $e");
      }
    }
  }
}