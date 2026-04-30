import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/customer_model.dart';

class CustomerRepository {
  final _supabase = Supabase.instance.client;

  // READ: Ambil semua pelanggan berdasarkan storeId (Urut Abjad)
  Future<List<Map<String, dynamic>>> getCustomers(String storeId) async {
    final res = await _supabase
        .from('customers')
        .select()
        .eq('store_id', storeId)
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(res);
  }

  // CREATE: Tambah pelanggan baru
  Future<CustomerModel> addCustomer(CustomerModel customer) async {
  try {
    final response = await _supabase
        .from('customers')
        .insert(customer.toMap())
        .select() // Perintah agar Supabase mengembalikan data yang baru di-insert
        .single(); // Kita hanya mengambil satu baris data saja

    // Mengonversi Map dari Supabase kembali menjadi Object CustomerModel
    return CustomerModel.fromMap(response);
  } catch (e) {
    throw 'Gagal menambah pelanggan: $e';
  }
}

  // UPDATE: Ubah data pelanggan
  Future<void> updateCustomer(CustomerModel customer) async {
    if (customer.id == null) return;
    await _supabase
        .from('customers')
        .update(customer.toMap())
        .eq('id', customer.id!);
  }

  // DELETE: Hapus pelanggan
  Future<void> deleteCustomer(String customerId) async {
    await _supabase.from('customers').delete().eq('id', customerId);
  }
}