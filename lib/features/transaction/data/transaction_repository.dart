import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionRepository {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getTransactions(String storeId) async {
    final res = await _supabase
        .from('transactions')
        .select('*, customers(name)')
        .eq('store_id', storeId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res);
  }

  

  Future<void> create(Map<String, dynamic> data) async => await _supabase.from('transactions').insert(data);

  Future<void> update(String id, Map<String, dynamic> data) async => await _supabase.from('transactions').update(data).eq('id', id);

  Future<void> delete(String id) async => await _supabase.from('transactions').delete().eq('id', id);
}