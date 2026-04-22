import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/product_model.dart';

class ProductRepository {
  final _supabase = Supabase.instance.client;

  // 1. READ: Ambil produk berdasarkan store_id
  Future<List<Map<String, dynamic>>> getProducts(String storeId) async {
    final data = await _supabase
        .from('products')
        .select()
        .eq('store_id', storeId)
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  // 2. CREATE: Tambah produk baru
  Future<void> addProduct(ProductModel product) async {
    await _supabase.from('products').insert(product.toMap());
  }

  // 3. UPDATE: Ubah data produk yang sudah ada
  Future<void> updateProduct(ProductModel product) async {
    if (product.id == null) return;
    await _supabase
        .from('products')
        .update(product.toMap())
        .eq('id', product.id!);
  }

  // 4. DELETE: Hapus produk
  Future<void> deleteProduct(String productId) async {
    await _supabase.from('products').delete().eq('id', productId);
  }
}