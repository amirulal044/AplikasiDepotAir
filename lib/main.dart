import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase (Ganti URL & Key dengan milik Anda)
  await Supabase.initialize(
    url: 'https://sxawyieonvxwzulugqvv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4YXd5aWVvbnZ4d3p1bHVncXZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1NzY3NTgsImV4cCI6MjA5MjE1Mjc1OH0.RAmjuyWHMvbyqzw3lF2_cmaM2vRpRdXohIK3U6bNOD0',
  );

  runApp(MyApp());
}

// Di main.dart bagian MyApp class
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: StreamBuilder<AuthState>(
        stream: Supabase.instance.client.auth.onAuthStateChange,
        // Di dalam class MyApp atau StreamBuilder
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.session != null) {
            // JIKA SUDAH LOGIN, Tampilkan Home
            return const HomeScreen();
          }
          // JIKA BELUM LOGIN, Tampilkan Login
          return LoginScreen();
        },
      ),
    );
  }
}
