import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthController extends ChangeNotifier {
  final AuthRepository _repository = AuthRepository();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> login(
    String email,
    String password,
    BuildContext context,
  ) async {
    // 1. Validasi Input Dasar
    if (email.isEmpty || password.isEmpty) {
      _showError(context, "Email dan Password tidak boleh kosong");
      return;
    }

    _setLoading(true);
    try {
      await _repository.signIn(email, password);
      if (context.mounted) Navigator.pushReplacementNamed(context, '/main');
    } on AuthException catch (e) {
      _showError(context, "Login Gagal: ${e.message}");
    } catch (e) {
      _showError(context, "Sistem Error: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(
    String email,
    String password,
    String depotName,
    BuildContext context,
  ) async {
    // 1. Validasi Input Dasar
    if (email.isEmpty || password.isEmpty || depotName.isEmpty) {
      _showError(context, "Semua kolom wajib diisi");
      return;
    }
    if (password.length < 6) {
      _showError(context, "Password minimal 6 karakter");
      return;
    }

    _setLoading(true);
    try {
      await _repository.signUp(email, password, depotName);
      if (context.mounted) {
        _showSuccess(
          context,
          "Registrasi Berhasil! Silakan cek email jika konfirmasi aktif.",
        );
        Navigator.pop(context);
      }
    } on AuthException catch (e) {
      _showError(context, "Registrasi Gagal: ${e.message}");
    } catch (e) {
      _showError(context, "Database Error: $e");
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
