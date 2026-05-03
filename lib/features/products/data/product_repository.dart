import 'package:supabase_flutter/supabase_flutter.dart';

class ProductRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getProducts() async {
    return await _supabase
        .from('products')
        .select()
        .order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>> addProduct(
    String nama,
    String ukuran,
    int harga,
    bool isCoupon,
    int lastCoupon,
    bool isRedemption,
  ) async {
    return await _supabase
        .from('products')
        .insert({
          'user_id': _supabase.auth.currentUser!.id,
          'nama_produk': nama,
          'ukuran': ukuran.toUpperCase().trim(), // STANDARISASI: Selalu Uppercase (19L)
          'harga': harga,
          'is_coupon_enabled': isCoupon,
          'last_coupon_number': lastCoupon,
          'is_redemption_item': isRedemption,
        })
        .select()
        .single();
  }

  Future<void> updateProduct(
    String id,
    String nama,
    String ukuran,
    int harga,
    bool isCoupon,
    int lastCoupon,
    bool isRedemption,
  ) async {
    await _supabase
        .from('products')
        .update({
          'nama_produk': nama,
          'ukuran': ukuran.toUpperCase().trim(), // STANDARISASI
          'harga': harga,
          'is_coupon_enabled': isCoupon,
          'last_coupon_number': lastCoupon,
          'is_redemption_item': isRedemption,
        })
        .eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _supabase.from('products').delete().eq('id', id);
  }
}