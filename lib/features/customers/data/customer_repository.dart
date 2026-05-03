import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getCustomers() async {
    return await _supabase
        .from('customers')
        .select()
        .order('nama', ascending: true);
  }

  Future<Map<String, dynamic>> addCustomer(
    String nama,
    String telepon,
    String alamat,
  ) async {
    return await _supabase
        .from('customers')
        .insert({
          'user_id': _supabase.auth.currentUser!.id,
          'nama': nama,
          'telepon': telepon,
          'alamat': alamat,
          'coupon_balance_19l': 0, // Nama kolom baru
          'total_stats': {},        // Inisialisasi JSONB kosong
        })
        .select()
        .single();
  }

  Future<void> updateCustomer(
    String id,
    String nama,
    String telepon,
    String alamat,
  ) async {
    await _supabase
        .from('customers')
        .update({'nama': nama, 'telepon': telepon, 'alamat': alamat})
        .eq('id', id);
  }

  Future<void> deleteCustomer(String id) async {
    await _supabase.from('customers').delete().eq('id', id);
  }
}