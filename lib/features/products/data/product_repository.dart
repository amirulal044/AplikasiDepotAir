import 'package:supabase_flutter/supabase_flutter.dart';

class ProductRepository {
  final _supabase = Supabase.instance.client;

  // Ambil semua produk milik user yang sedang login
  Future<List<Map<String, dynamic>>> getProducts() async {
    return await _supabase
        .from('products')
        .select()
        .order('created_at', ascending: false);
  }

  // Tambah Produk
  Future<Map<String, dynamic>> addProduct(
    String nama,
    String ukuran,
    int harga,
    bool isCoupon,
    int lastCoupon, // <--- Tambahan
  ) async {
    return await _supabase
        .from('products')
        .insert({
          'user_id': _supabase.auth.currentUser!.id,
          'nama_produk': nama,
          'ukuran': ukuran,
          'harga': harga,
          'is_coupon_enabled': isCoupon,
          'last_coupon_number': lastCoupon, // <--- Simpan ke DB
        })
        .select()
        .single();
  }

  // Edit Produk
  Future<void> updateProduct(
    String id,
    String nama,
    String ukuran,
    int harga,
    bool isCoupon,
    int lastCoupon, // <--- Tambahan
  ) async {
    await _supabase
        .from('products')
        .update({
          'nama_produk': nama,
          'ukuran': ukuran,
          'harga': harga,
          'is_coupon_enabled': isCoupon,
          'last_coupon_number': lastCoupon, // <--- Update di DB
        })
        .eq('id', id);
  }

  // Hapus Produk
  Future<void> deleteProduct(String id) async {
    await _supabase.from('products').delete().eq('id', id);
  }
}
