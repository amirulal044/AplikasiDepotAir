import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/transaction_repository.dart';

class TransactionProvider extends ChangeNotifier {
  final _repo = TransactionRepository();
  final _supabase = Supabase.instance.client;

  bool isLoading = false;

  // Master data
  List<Map<String, dynamic>> masterProducts = [];
  List<Map<String, dynamic>> masterCustomers = [];
  List<Map<String, dynamic>> transactions = [];

  // --- KERANJANG BELANJA ---
  List<Map<String, dynamic>> cartItems = [];

  // Hitung Total Harga dari semua item di keranjang
  int get totalHarga {
    return cartItems.fold(0, (sum, item) => sum + (item['subtotal'] as int));
  }

  // Inisialisasi Form
  Future<void> initForm() async {
    isLoading = true;
    notifyListeners();
    try {
      final prodRes = await _supabase.from('products').select();
      masterProducts = List<Map<String, dynamic>>.from(prodRes);

      final custRes = await _supabase.from('customers').select();
      masterCustomers = List<Map<String, dynamic>>.from(custRes);
      
      cartItems = []; 
    } catch (e) {
      print("Error init form: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- PENYESUAIAN FUNGSI 1: Tambah ke Keranjang (Dengan Validasi) ---
  String? addToCart({
    required String? productId,
    required String namaProduk,
    required String ukuran,
    required int qty,
    required int unitPrice,
    required int subtotal,
    required bool isRedemption,
    required bool isCouponEnabled,
    required int kuponAwal,
    required int kuponAkhir,
    required int currentCustomerBalance, // Tambahan parameter untuk validasi
  }) {
    
    // 1. VALIDASI SALDO KUPON (Hanya jika isRedemption == true)
    if (isRedemption) {
      int kuponDibutuhkan = qty * 10;
      if (currentCustomerBalance < kuponDibutuhkan) {
        return "Saldo tidak cukup! Butuh $kuponDibutuhkan kupon untuk $qty galon gratis.";
      }
    }

    // 2. LOGIKA KUPON FISIK
    // Jika barang GRATIS, nomor kupon dipaksa 0
    int finalKuponAwal = isRedemption ? 0 : kuponAwal;
    int finalKuponAkhir = isRedemption ? 0 : kuponAkhir;

    // 3. MASUKKAN KE DAFTAR
    cartItems.add({
      'productId': productId,
      'namaProduk': namaProduk,
      'ukuran': ukuran,
      'qty': qty,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
      'isRedemption': isRedemption,
      'isCouponEnabled': isCouponEnabled,
      'kuponAwal': finalKuponAwal,
      'kuponAkhir': finalKuponAkhir,
    });
    
    notifyListeners(); 
    return null; // Mengembalikan null berarti sukses
  }

  // FUNGSI 2: Hapus dari Keranjang
  void removeFromCart(int index) {
    cartItems.removeAt(index);
    notifyListeners();
  }

  // FUNGSI 3: Checkout
  Future<bool> checkout({
    required String? customerId,
    required String namaPelanggan,
  }) async {
    if (cartItems.isEmpty) return false;

    isLoading = true;
    notifyListeners();
    try {
      await _repo.saveCompleteTransaction(
        customerId: customerId,
        namaPelanggan: namaPelanggan,
        totalHarga: totalHarga,
        items: cartItems,
      );
      
      cartItems = []; 
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

  // Riwayat Transaksi
  Future<void> fetchTransactions() async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .order('created_at', ascending: false);
      transactions = List<Map<String, dynamic>>.from(response);
      notifyListeners();
    } catch (e) {
      print("Error fetch: $e");
    }
  }

  // Refresh data pelanggan
  Future<void> refreshCustomerList() async {
    final custRes = await _supabase.from('customers').select();
    masterCustomers = List<Map<String, dynamic>>.from(custRes);
    notifyListeners();
  }
}