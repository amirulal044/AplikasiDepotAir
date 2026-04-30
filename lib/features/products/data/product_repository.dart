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
  Future<void> addProduct(
    String nama,
    String ukuran,
    int harga,
    bool isCoupon,
  ) async {
    final userId = _supabase.auth.currentUser!.id;
    await _supabase.from('products').insert({
      'user_id': userId,
      'nama_produk': nama,
      'ukuran': ukuran,
      'harga': harga,
      'is_coupon_enabled': isCoupon,
    });
  }

  // Edit Produk
  Future<void> updateProduct(
    String id,
    String nama,
    String ukuran,
    int harga,
    bool isCoupon,
  ) async {
    await _supabase
        .from('products')
        .update({
          'nama_produk': nama,
          'ukuran': ukuran,
          'harga': harga,
          'is_coupon_enabled': isCoupon,
        })
        .eq('id', id);
  }

  // Hapus Produk
  Future<void> deleteProduct(String id) async {
    await _supabase.from('products').delete().eq('id', id);
  }
}
