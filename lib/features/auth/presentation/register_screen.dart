import 'package:flutter/material.dart';
import '../data/auth_repository.dart';
import 'dart:developer' as dev; // Untuk logging yang lebih rapi di terminal

class RegisterScreen extends StatefulWidget {
  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _authRepo = AuthRepository();
  bool _isLoading = false;

  void _handleRegister() async {
    // 1. Log terminal: Menandakan proses dimulai
    debugPrint("================= AUTH LOG =================");
    debugPrint("INFO: Memulai proses pendaftaran...");
    debugPrint("DATA: Email: ${_emailController.text}");
    debugPrint("DATA: Store Name: ${_storeNameController.text}");

    setState(() => _isLoading = true);

    try {
      await _authRepo.register(
        _emailController.text,
        _passwordController.text,
        _storeNameController.text,
      );

      // 2. Log terminal: Jika sukses
      debugPrint("SUCCESS: Pendaftaran berhasil disimpan ke server.");
      debugPrint("============================================");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Berhasil Daftar! Silakan Login."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e, stacktrace) {
      // 3. Log terminal: Jika terjadi error
      debugPrint("ERROR TERDETEKSI!");
      debugPrint("JENIS ERROR: ${e.runtimeType}");
      debugPrint("PESAN: $e");

      // Menggunakan dev.log untuk menampilkan jejak error yang bisa diklik di terminal
      dev.log(
        "Detail Error Stacktrace:",
        error: e,
        stackTrace: stacktrace,
        name: "auth.register",
      );

      debugPrint("============================================");

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal: $e"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: "OK",
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Daftar Depot Baru")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          // Agar tidak error pixel saat keyboard muncul
          child: Column(
            children: [
              TextField(
                controller: _storeNameController,
                decoration: InputDecoration(
                  labelText: "Nama Depot Air",
                  prefixIcon: Icon(Icons.store),
                ),
              ),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              SizedBox(height: 30),
              _isLoading
                  ? Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10),
                        Text(
                          "Sedang memproses ke server...",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _handleRegister,
                        child: Text("DAFTAR SEKARANG"),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
