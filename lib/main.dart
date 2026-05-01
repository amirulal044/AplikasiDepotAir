import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'features/auth/logic/auth_provider.dart';
import 'features/auth/ui/login_screen.dart';
import 'features/main/main_navigation.dart';
import 'features/products/logic/product_provider.dart';
import 'features/customers/logic/customer_provider.dart';
import 'features/transactions/logic/transaction_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Supabase (Ganti URL & Key dengan milik Anda)
  await Supabase.initialize(
    url: 'https://sxawyieonvxwzulugqvv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN4YXd5aWVvbnZ4d3p1bHVncXZ2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY1NzY3NTgsImV4cCI6MjA5MjE1Mjc1OH0.RAmjuyWHMvbyqzw3lF2_cmaM2vRpRdXohIK3U6bNOD0',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
      ],

      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Depot Air Universal',
      theme: ThemeData(primarySwatch: Colors.blue),
      // Cek jika user sudah login arahkan ke Main, jika belum ke Login
      home: Supabase.instance.client.auth.currentSession == null
          ? LoginScreen()
          : MainNavigation(),
      routes: {
        '/main': (context) => MainNavigation(),
        '/login': (context) => LoginScreen(),
      },
    );
  }
}
