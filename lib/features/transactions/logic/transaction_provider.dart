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

  // --- LOGIKA BARU: HITUNG PROYEKSI SALDO (LIVE BALANCE) ---
  // Fungsi ini menghitung saldo pelanggan berdasarkan isi keranjang belanja saat ini
  int calculateProjectedBalance(int dbBalance) {
    int adjustment = 0;
    for (var item in cartItems) {
      // Hanya hitung jika fitur kupon aktif pada produk tersebut
      if (item['isCouponEnabled'] == true) {
        if (item['isRedemption'] == true) {
          // Jika item di keranjang adalah GRATIS: Kurangi 10 per qty
          adjustment -= (item['qty'] as int) * 10;
        } else {
          // Jika item di keranjang adalah BAYAR: Tambah 1 per qty
          adjustment += (item['qty'] as int);
        }
      }
    }
    return dbBalance + adjustment;
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

  // --- PENYESUAIAN FUNGSI 1: Tambah ke Keranjang (Validasi Proyeksi) ---
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
    required int dbBalance, // Saldo asli dari database pelanggan
  }) {
    // 1. Hitung potensi saldo JIKA barang ini ditambahkan
    int currentProjected = calculateProjectedBalance(dbBalance);
    int itemAdjustment = 0;

    if (isCouponEnabled) {
      itemAdjustment = isRedemption ? -(qty * 10) : qty;
    }

    int finalPotentialBalance = currentProjected + itemAdjustment;

    // 2. VALIDASI: Jika saldo akhir diproyeksikan MINUS, maka tolak
    if (isRedemption && finalPotentialBalance < 0) {
      int sisaKebutuhan = finalPotentialBalance.abs();
      return "Saldo Kupon tidak cukup! Kurang $sisaKebutuhan kupon lagi untuk transaksi ini.";
    }

    // 3. MASUKKAN KE DAFTAR JIKA VALID
    cartItems.add({
      'productId': productId,
      'namaProduk': namaProduk,
      'ukuran': ukuran,
      'qty': qty,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
      'isRedemption': isRedemption,
      'isCouponEnabled': isCouponEnabled,
      'kuponAwal': isRedemption ? 0 : kuponAwal,
      'kuponAkhir': isRedemption ? 0 : kuponAkhir,
    });

    notifyListeners();
    return null; // Sukses
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
  isLoading = true;
  notifyListeners();
  try {
    // Query ini mengambil data dari tabel transactions 
    // DAN sekaligus mengambil semua baris dari tabel transaction_items yang terkait
    final response = await _supabase
        .from('transactions')
        .select('*, transaction_items(*)') 
        .order('created_at', ascending: false);

    transactions = List<Map<String, dynamic>>.from(response);
  } catch (e) {
    print("Error fetch transactions: $e");
  } finally {
    isLoading = false;
    notifyListeners();
  }
}
  // Refresh data pelanggan
  Future<void> refreshCustomerList() async {
    final custRes = await _supabase.from('customers').select();
    masterCustomers = List<Map<String, dynamic>>.from(custRes);
    notifyListeners();
  }
}
