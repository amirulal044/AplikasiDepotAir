import 'package:flutter/material.dart';
import '../data/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final _repo = ProductRepository();
  List<Map<String, dynamic>> products = [];
  bool isLoading = false;

  Future<void> fetchProducts() async {
    isLoading = true;
    notifyListeners();
    try {
      products = await _repo.getProducts();
    } catch (e) {
      print("Error fetch: $e");
      // Kita tidak tampilkan snackbar di sini agar tidak mengganggu UI utama,
      // cukup list kosong atau error widget di UI.
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>?> saveProduct(
    String nama,
    String ukuran,
    String harga,
    bool isCoupon,
    int lastCoupon, // <--- Tambahan
  ) async {
    try {
      final newProd = await _repo.addProduct(
        nama,
        ukuran,
        int.parse(harga),
        isCoupon,
        lastCoupon, // <--- Teruskan ke repo
      );
      await fetchProducts();
      return newProd;
    } catch (e) {
      return null;
    }
  }

  Future<bool> editProduct(
    String id,
    String nama,
    String ukuran,
    String harga,
    bool isCoupon,
    int lastCoupon, // <--- Tambahan
  ) async {
    try {
      await _repo.updateProduct(
        id,
        nama,
        ukuran,
        int.parse(harga),
        isCoupon,
        lastCoupon, // <--- Teruskan
      );
      await fetchProducts();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Ubah menjadi mengembalikan Future<bool>
  Future<bool> removeProduct(String id) async {
    try {
      await _repo.deleteProduct(id);
      await fetchProducts();
      return true;
    } catch (e) {
      print("Error delete: $e");
      return false;
    }
  }
}
