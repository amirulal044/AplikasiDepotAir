import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<AuthResponse> signIn(String email, String password) async {
    try {
      print("DEBUG: Mencoba login untuk $email...");
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password.trim(),
      );
      print("DEBUG: Login Berhasil! User ID: ${response.user?.id}");
      return response;
    } on AuthException catch (e) {
      print("DEBUG: Supabase Auth Error: ${e.message}");
      rethrow; // Melempar error agar ditangkap Provider
    } catch (e) {
      print("DEBUG: Error Tidak Terduga: $e");
      throw "Terjadi kesalahan koneksi atau sistem.";
    }
  }

  Future<AuthResponse> signUp(
    String email,
    String password,
    String depotName,
  ) async {
    try {
      print("DEBUG: Mencoba Register untuk $email...");
      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password.trim(),
      );

      if (response.user != null) {
        print("DEBUG: Auth sukses, mencoba input ke tabel profiles...");
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'nama_depot': depotName,
        });
        print("DEBUG: Input tabel profiles Berhasil!");
      }
      return response;
    } on AuthException catch (e) {
      print("DEBUG: Supabase Auth Error (Register): ${e.message}");
      rethrow;
    } catch (e) {
      print("DEBUG: Error Tabel Profile: $e");
      throw "Akun terbuat tapi gagal menyimpan nama depot. Cek tabel 'profiles' di Supabase.";
    }
  }
}
