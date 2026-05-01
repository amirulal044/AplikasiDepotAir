import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final _repo = TransactionRepository();
  final _supabase = Supabase.instance.client;

  bool isLoading = false;
  int lastCouponNumber = 0;

  // Data Master untuk Rekomendasi
  List<Map<String, dynamic>> masterProducts = [];
  List<Map<String, dynamic>> masterCustomers = [];
  List<Map<String, dynamic>> transactions = [];

  // Ambil Riwayat Transaksi
  Future<void> fetchTransactions() async {
    isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .order('created_at', ascending: false);

      transactions = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print("Error fetch transactions: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Ambil data awal (Produk, Pelanggan, dan Nomor Kupon Terakhir)
  Future<void> initForm() async {
    isLoading = true;
    notifyListeners();
    try {
      final prodRes = await _supabase.from('products').select();
      masterProducts = List<Map<String, dynamic>>.from(prodRes);

      final custRes = await _supabase.from('customers').select();
      masterCustomers = List<Map<String, dynamic>>.from(custRes);

      final userId = _supabase.auth.currentUser!.id;
      final profileRes = await _supabase
          .from('profiles')
          .select('last_coupon_number')
          .eq('id', userId)
          .single();
      lastCouponNumber = profileRes['last_coupon_number'] ?? 0;
    } catch (e) {
      print("Error init form: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // PENYESUAIAN PADA FUNGSI CHECKOUT
  Future<bool> checkout({
    String? customerId,
    String? productId,
    required String namaPelanggan,
    required String namaProduk,
    required String ukuran,
    required int nomorKupon,
    required int qty, // <--- TAMBAHKAN PARAMETER QTY DI SINI
    required bool isRedemption,
    required int totalHarga,
  }) async {
    isLoading = true;
    notifyListeners();
    try {
      // Panggil Repo dengan parameter qty yang baru
      await _repo.saveTransaction(
        customerId: customerId,
        productId: productId,
        namaPelanggan: namaPelanggan,
        namaProduk: namaProduk,
        ukuran: ukuran,
        nomorKupon: nomorKupon,
        qty: qty, // <--- TERUSKAN KE REPOSITORY
        isRedemption: isRedemption,
        totalHarga: totalHarga,
      );

      // Setelah sukses simpan, ambil data transaksi terbaru
      await fetchTransactions();

      return true;
    } catch (e) {
      print("Checkout Error: $e");
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Refresh list pelanggan saja (Dipakai setelah Quick Add Pelanggan)
  Future<void> refreshCustomerList() async {
    try {
      final custRes = await _supabase.from('customers').select();
      masterCustomers = List<Map<String, dynamic>>.from(custRes);
      notifyListeners();
    } catch (e) {
      print("Refresh Customer Error: $e");
    }
  }
}
