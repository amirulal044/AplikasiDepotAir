import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/product_model.dart';

class ProductRepository {
  final _supabase = Supabase.instance.client;

  // AMBIL PRODUK (Hanya milik toko yang sedang login)
  Future<List<Map<String, dynamic>>> getProducts(String storeId) async {
    final data = await _supabase
        .from('products')
        .select()
        .eq('store_id', storeId) // Filter Multi-tenant
        .order('name');
    return List<Map<String, dynamic>>.from(data);
  }

  // TAMBAH PRODUK BARU
  Future<void> addProduct(ProductModel product) async {
    await _supabase.from('products').insert(product.toMap());
  }

  // HAPUS PRODUK
  Future<void> deleteProduct(String id) async {
    await _supabase.from('products').delete().eq('id', id);
  }
}
