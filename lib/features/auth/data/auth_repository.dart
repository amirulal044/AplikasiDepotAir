import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  // FUNGSI DAFTAR (Register)
  Future<void> register(String email, String password, String storeName) async {
    try {
      // 1. Buat User di Auth Supabase
      final res = await _supabase.auth.signUp(email: email, password: password);
      
      if (res.user != null) {
        // 2. Buat data Toko di tabel 'stores' secara otomatis
        await _supabase.from('stores').insert({
          'owner_id': res.user!.id,
          'store_name': storeName,
        });
      }
    } catch (e) {
      throw 'Gagal Daftar: $e';
    }
  }

  // FUNGSI MASUK (Login)
  Future<void> login(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      throw 'Gagal Login: $e';
    }
  }

  // FUNGSI KELUAR (Logout)
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}